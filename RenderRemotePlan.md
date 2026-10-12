# Remote rendering plan

The scene is rendered on a server (the Windows machine with the RTX 5090), each frame is compressed on its GPU and sent over the network,
and the client (for example the Mac) shows the frames in its window and sends keyboard, pointer and gamepad input back.

## Decisions

| Question | Decision |
|---|---|
| PyroWave: reuse or reimplement | Reimplement in Malterlib, on the GPU layer of Render with Slang shaders. Keep the bitstream of upstream so their tools can check ours |
| Transport | Distributed actors (WebSocket over TLS over TCP). Frames that are late are skipped by the sender, nothing is dropped in the transport |
| Interface | Modelled on `ICCommandLine` / `ICCommandLineControl`: the client calls one function that lasts as long as the session and hands the server a control actor |
| Apps | Each app is its own server: one executable has both roles. `fg_RunRenderAppLoop` gets a remote mode, so the setup and frame callbacks of an app are the same for local, off screen and remote |
| Colors | The server renders for the display of the client. The output transform runs on the server, the video carries encoded values (sRGB or PQ) |

## Why PyroWave is reimplemented

What upstream consists of (commit `89f7e47`, 2026-09-25, MIT):

- About 2600 lines of GLSL compute shaders and about 3500 lines of C++, of which a large part is statistics, debugging and the fragment shader path for mobile GPUs.
- The C++ is written against Granite (`Vulkan::Device`, `Vulkan::CommandBuffer`, `Vulkan::ImageView`). Shaders are compiled to SPIR-V ahead of time into `slangmosh.hpp`.
- The C API either shares a `VkDevice` or imports textures and fences through operating system handles.
- The Metal version under `metal/` is a separate port with its own API. Upstream's note says it cannot be maintained by them and may be removed.
- The bitstream is documented in `bitstream/bitstream.md` and is a draft that may change.

Reusing it would mean:

- Vulkan only on the server, so no D3D12, which is the default backend on Windows.
- Granite, volk and the Vulkan headers as new external repositories, and a second way of talking to the GPU next to the GPU layer of Render.
- Either a second Vulkan device with textures shared through handles, which the GPU layer does not expose, or handing our `VkDevice` to Granite, which then expects to own the queues.
- A different library with a different API on the Mac, that upstream says it does not support.
- Two code bases to keep in step with the bitstream.

Reimplementing means:

- One implementation for Metal, Vulkan and D3D12, which is tested like the rest of Render on all backends.
- The frame is encoded in the same submit as it is rendered, with no copies between devices.
- The size is modest: six compute shaders for the encoder, two for the decoder, and the C++ that prepares block tables and reads the result.

The cost is that improvements upstream are picked up by hand. The bitstream stays compatible to keep that possible and to have an independent check.

The shaders are a port of upstream's, so the ported files keep the copyright notice of Hans-Kristian Arntzen and are declared as MIT in the `Repository` block of `Malterlib_Render.MHeader`.

## Risks found so far

1. **Subgroup operations.** The encoder and the dequantizer depend on Vulkan subgroups: ballot, shuffle, shuffle xor, clustered sums over 8 and 16 lanes, and a required subgroup size of 16, 32 or 64.
	- Slang has `WaveReadLaneAt`, `WaveActiveBallot`, `WavePrefixSum` and so on for SPIR-V, HLSL and Metal. It has no clustered operations; upstream's Metal port builds them from shuffle xor, and we do the same.
	- The GPU layer has no way to require a subgroup size. Vulkan needs `requiredSubgroupSize`, D3D12 needs `[WaveSize]` of shader model 6.6, and Metal has the size of the device.
	- If a backend cannot give what is needed, that stage gets a variant that uses shared memory of the thread group instead. It is slower but has no requirements.
2. **Bytes in GPU memory.** The bitstream is written as bytes and 16-bit words. On Vulkan and Metal memory is reached through pointers. On D3D12 it is a `RWByteAddressBuffer`, which only has 32-bit words, so two threads that write different bytes of one word race. D3D12 needs the words to be assembled per thread group or written with `InterlockedOr`.
3. **Formats.** `EGpuFormat` has no `R16_UNorm`, which the planes need with PQ. On Metal only some formats can be read and written as storage textures.
4. **Latency of the transport.** The two machines are 76 ms apart (round trip), so this is not a local network.
	A lost TCP segment stalls everything behind it for at least one round trip, which is 5 frames at 60 frames per second. PyroWave's tolerance for lost packets is not used with this transport.
5. **Bandwidth.** The path carries just above 500 Mbit/s, which is enough for PyroWave: it is meant for 200 Mbit/s and more.
	- The video uses at most 300 Mbit/s (`m_MaxBitsPerSecond`), which leaves room for other traffic and for sending again what was lost. At 60 frames per second that is 625 kB per frame.
	- One TCP connection that is 76 ms long only keeps 300 Mbit/s when fewer than about 4 of 10 million packets are lost, with the classic behavior at loss.
		The connection to the server is therefore added with `--connection-concurrency 4`, which the distributed actors support with the order kept.
	- The amount of data in flight is 300 Mbit/s times 76 ms, which is 2.9 MB, and far more than the default send window of eight frames of the transport.
		The window is given as the link to fill, `--send-window 500mbit@76ms`, which is twice the bandwidth-delay product (9.5 MB) for each connection.
	- Phase 1 measures the quality at 100, 200 and 300 Mbit/s for 1080p, 1440p and 2160p, which gives the default for each size.

Risks 1 and 2 decide how the shaders are written, so phase 1 starts with the block packing shader, which uses the most of both, on all three backends before anything else is ported.

## Architecture

```
Client (Mac, Metal)                                   Server (Windows, D3D12 or Vulkan)
-------------------                                   ---------------------------------
Window, input, gamepads                               App callbacks: setup, frame
  |  CRenderRemoteInput (high priority)                 ^
  +--------------------------------------------------->  | events, window state
                                                        v
                                                      Renderer: scene, output transform for the client's display
                                                        |
                                                      Encoder passes in the same frame graph
                                                        |  bitstream in mc_CpuCached memory
  <---------------------------------------------------+
  |  CRenderRemoteFrame (normal priority)
Decoder passes -> planes -> present pass -> surface
```

### New files in Render

| Directory | Contents |
|---|---|
| `Source/Codec` | `CRenderVideoEncoder`, `CRenderVideoDecoder`, block tables, bitstream structures. Depends on the GPU layer only |
| `Shaders/Malterlib_Render_Codec_*.slang` | `Dwt`, `Quant`, `RateControl`, `BlockPacking`, `Dequant`, `Idwt`, and the conversions between RGB and YCbCr |
| `Source/Remote` | The interfaces, the server actor, the client actor, the remote window |
| `Include/Mib/Render/Codec`, `Include/Mib/Render/Remote` | Public includes |
| `Test/Test_Malterlib_Render_Codec.cpp`, `Test/Test_Malterlib_Render_Remote.cpp` | Tests |

### Interface

Namespace `com.malterlib/Render/Remote`, protocol version `0x101`, permission `Render/RunRemote`.

```cpp
struct ICRenderRemote : public CActor
{
	static constexpr ch8 const *mc_pDefaultNamespace = "com.malterlib/Render/Remote";

	// Resolves when the app has ended. Destroying the call ends the app, a lost connection does not
	virtual TCFuture<CRenderRemoteResult> f_Run(NStr::CStr _App, NEncoding::CEJsonSorted _Parameters, CRenderRemoteControl _Control) = 0;
};

struct CRenderRemoteControl // Streamed as a parameter, like CCommandLineControl
{
	TCDistributedActorInterfaceWithID<ICRenderRemoteControl, gc_SubscriptionNotRequired> m_ControlActor;
	CRenderRemoteDisplay m_Display; // Size in pixels, scale, color spaces of the surface, peak and white nits
	CRenderRemoteVideo m_Video; // Chroma resolution, frame rate, most bytes per frame, most frames that may be unanswered
};

struct ICRenderRemoteControl : public CActor // Lives in the client
{
	using FOnInput = TCActorFunctorWithID<TCFuture<void> (CRenderRemoteInput _Input)>;
	using FOnDisplay = TCActorFunctorWithID<TCFuture<void> (CRenderRemoteDisplay _Display)>;

	virtual TCFuture<TCActorSubscriptionWithID<>> f_RegisterForInput(FOnInput _fOnInput) = 0;
	virtual TCFuture<TCActorSubscriptionWithID<>> f_RegisterForDisplay(FOnDisplay _fOnDisplay) = 0;

	virtual TCFuture<CRenderRemoteFrameResult> f_Frame(CRenderRemoteFrame _Frame) = 0; // Resolves when the frame is decoded
	virtual TCFuture<void> f_MeasurePath() = 0; // Resolves at once, for the path time before the first frame
	virtual TCFuture<void> f_SetTitle(NStr::CStr _Title) = 0;
	virtual TCFuture<void> f_SetMode(ERenderWindowMode _Mode) = 0;
};
```

- `CRenderRemoteInput` is a vector of `CRenderWindowEvent` with the number of the newest event. Events that happened since the last send go in one call.
- `CRenderRemoteFrame` has the bitstream as a `CSharedByteVector`, the size, the color space and curve, the frame number, the number of the newest input that the frame includes, and the times for rendering and encoding.
- `CRenderRemoteFrameResult` has the time to decode, which the server uses together with the time of the call to choose the limit of unanswered frames and the bytes per frame.
- Input is sent with `CPriorityScope(mc_PriorityHigh)`, frames with normal priority, so a frame that is being sent does not hold input back.
- Structures are streamed with `f_Stream` and checks against the protocol version, as `CCommandLineControl` does.

A frame at 200 Mbit/s and 60 frames per second is about 400 kB, far below the message limit of 24 MiB, so a frame is one call.

### Skipping frames

The transport is reliable, so frames must not queue up.

The server has a limit for calls to `f_Frame` without a result. When the limit is reached the server waits with the next frame callback,
so the next frame that is rendered has the newest input.

A fixed limit does not work: the measured round trip to the Windows machine is 76 ms, so a limit of 2 would give 26 frames per second however fast both ends are.
The limit follows the latency, and the bytes per frame follow the congestion. They are kept apart, because raising the limit when the network is congested makes the queue longer.

| Value | How it is found |
|---|---|
| Answer time of a frame | From the call to `f_Frame` until its result |
| Path time of a frame | Answer time minus the decode time that the result reports |
| Base path time | The smallest path time of the last 10 seconds. A queue in the network cannot make it smaller, so it is the latency without congestion |
| Frame interval | From the refresh rate of the client's display, or the frame rate that was asked for |
| Limit | `ceil((base path time + decode time) / frame interval) + 1`, at least 2 and at most `m_nMaxFramesUnanswered` (32 by default) |
| Queue time | Smoothed path time minus base path time |

- With 76 ms and 60 frames per second the limit is `ceil(80 / 16.7) + 1 = 6`. On a local network with 1 ms it is 2.
- Before the first frame the client and server exchange a few empty calls at high priority, so the session starts with a measured limit and not with 2.
- The bytes per frame go down when the queue time is more than half a frame interval, and go up slowly while it is not.
  They start low and are never more than what the measured rate of answered bytes and `m_MaxBitsPerSecond` allow.
- When the limit is reached although the base path time allows the frame rate, the frame is skipped and counted. The frame counter shows skipped frames.
- The send window of the connection is not changed by the session. It is given with `--send-window` when the listen and the connection are added, see the setup of the machines.
  The server logs a warning when a session starts and the window of the connection is smaller than the limit times the bytes per frame.
- The latency from input to picture cannot be less than the round trip. At 76 ms it is about 76 ms plus rendering, encoding, decoding and up to one refresh of the display.

### Lost connections

When a client is connected to a daemon the actor system keeps the remote alive until the connection is back, so the control actor, the functors and the subscriptions of a session are valid after a reconnect.
The session builds on this and has no reconnect of its own.

- While the connection is away the calls to `f_Frame` stay unanswered, the limit is reached and the server stops calling the frame callback. The app does not run ahead without anyone seeing it.
- Time stands still for the app meanwhile: `CRenderFrameInfo::m_DeltaTime` of the first frame after the pause is one frame interval and not the length of the pause.
- The unanswered frames are delivered after the reconnect. They are at most the limit, and the client shows the newest only.
- The client sends the state of keys and buttons that are held with the first input after a reconnect, so a key that was released meanwhile does not stay down in the app.
- The base path time is measured again after a reconnect, since the path may be another one.
- The session ends when the actor system gives the remote up, when the client ends the call to `f_Run`, or when the app ends.

### Key codes

Key codes are the platform's own today, and RenderBeach has a table per platform. A remote client on another platform than the server needs them to mean the same.

The window layer uses the input types of the CommandLine module (`<Mib/CommandLine/Input>`), as the UserInterface module does.
CommandLine is part of `Lib_Malterlib`, so Render gets no new dependency.

| Type | Use in Render |
|---|---|
| `CKeyEvent`, `EKey`, `EKeyModifier`, `EKeyEventType` | `CRenderWindowEvent::m_Key` replaces `m_KeyCode`, `m_bRepeat` and `m_Characters`. `mc_KeyDown` and `mc_KeyUp` become one `mc_Key` |
| `EMouseButton`, `EMouseEventType` | Replace `m_Button` as a number and the four pointer event types |
| `CTerminalMouseEvent` | Not used, it has cell coordinates. Render gets `CRenderPointerEvent` in pixels with the movement since the last event, in the way UserInterface has `CMouseEvent` |

- Each window implementation translates its events: `NSEvent` on macOS, `WM_KEYDOWN`/`WM_CHAR` on Windows, XCB with xkb on Linux.
	The translation is a function of plain values, as `fg_TranslateMacOSKeyEvent` in UserInterface, so it is tested without a window on every platform.
- The samples compare with `f_Is(EKey::...)` and lose their tables per platform.

What has to be added to CommandLine for this:

1. **Keys that `EKey` lacks.** RenderBeach holds Shift to run and RenderSample uses plus and minus of the keypad.
	`EKey` gets the keypad keys (57399 to 57426) and the modifier keys as keys (57441 to 57452), with the numbers of the kitty protocol as for the keys that exist.
	The terminal parser already gets these numbers from terminals with the kitty protocol, so they only get names.
2. **Streaming.** `CKeyEvent` has no `f_Stream`. It gets one that leaves out `m_HandlingReportID`, which is about the terminal that the event came from.
3. **The position of a key.** `m_ScanCode` is the character of the key in the keyboard layout of the user, so W, A, S and D are where the layout has them and not where the fingers are on for example AZERTY.
	The kitty protocol reports the key of the base layout as the third part of `unicode[:shifted[:base]]` when `mc_ReportAlternateKeys` is asked for.
	The parser in `Malterlib_CommandLine_AnsiEncodingParseInput.cpp` already splits these parts and uses the shifted one for the text, so the terminal can fill it in and it goes into `CKeyEvent` as `m_BaseLayoutKey`, without a subclass in Render.
	- The terminal leaves the part out when it is the same as the key, so the parser sets `m_BaseLayoutKey` to `m_ScanCode` then. It is never 0 for a key that has a code.
	- Terminals without the kitty protocol and the legacy sequences give `m_ScanCode` as well.
	- `f_IsBaseLayout(EKey)` is added next to `f_Is`.
	- The window implementations fill it in from the position of the key: the virtual key code on macOS, the scan code on Windows, the key code of xkb on Linux, each through a table for the US layout.
	- The samples walk with the base layout key and use `m_ScanCode` for commands as F and P.

The translations from the events of the platforms are Render's own, in its window layer. UserInterface keeps its translation, so the one for macOS exists twice until UserInterface is ready for production.

### App layer

- `CRenderAppSettings` gets `m_Remote`, with the host to run on. `fg_RunRenderAppLoop` then runs `fg_RunRenderAppRemoteClient`: window, device, decoder and the control actor, no renderer and no callbacks.
- On the server `f_Run` runs `fg_RunRenderAppRemoteServer`: the off-screen loop with events and window state from the client, the target in the color space that fits the client's display, and the encoder after the output pass.
- `CRenderAppContext::m_Window` is used by apps for title and mode. The window actor gets a remote implementation that forwards these to the control actor, so apps do not change.
- The off-screen target is fixed to sRGB with 8 bits today. It gets the format and `CRenderOutput` from the display of the client, with PQ in `RGBA16_Float` or `RGB10A2_UNorm` for HDR.
- The frame counter of the samples shows the latency from input to the frame that includes it, measured on the client.

### Encoder in the frame

Added as passes after "Output" in the frame graph of `CRendererActor`, so rendering and encoding are one submit:

1. RGB to YCbCr: a graphics pass to three color targets, with chroma at half size for 4:2:0.
2. `Dwt`: five levels for luma, four for chroma with 4:2:0.
3. `Quant`, the rate control passes, `BlockPacking`: bitstream and block table into `mc_CpuCached` memory.
4. After the semaphore of the frame, the CPU collects the blocks in order of block index and adds the start of frame header.

The decoder is the reverse: upload of the bitstream, `Dequant`, `Idwt` to planes, and a present pass that converts YCbCr to the surface.
The present pass replaces `f_ConvertToLinear` here, since values are already encoded for the display.

### Additions to the GPU layer

- `EGpuFormat::mc_R16_UNorm` in all backends.
- `CGpuShader::m_WaveSizeMin/m_WaveSizeMax` and `CGpuCapabilities` with the subgroup sizes and operations of the device.
- A mirrored repeat address mode for samplers, if it is missing.
- A helper for reading GPU memory back, which exists as a repeated pattern in `fg_SaveRenderedFrame` and four tests.

## Phases

### Phase 1: Codec

1. Spike: `BlockPacking` in Slang on Metal, Vulkan and D3D12 with fixed input, compared with bytes computed on the CPU. Decides between subgroups and shared memory per backend and how bytes are written on D3D12.
2. GPU layer additions.
3. Block tables and bitstream structures, with a reference decoder on the CPU in the test. It follows the specification and is the oracle for the tests.
4. Decoder shaders, tested with bitstreams made by an encoder on the CPU in the test.
5. Encoder shaders and rate control.
6. Conversions between RGB and YCbCr, 4:4:4 and 4:2:0, sRGB and PQ.

Tests: round trip with limits on the error for a set of images and sizes (including sizes that are not multiples of 32 and the smallest size), the size of the result against the target, decoding with blocks missing, and errors for invalid bitstreams.
Once, by hand: files encoded by upstream's `pyrowave-encode` are decoded by ours and the other way around, built in the Linux container. A few such files are kept as test data.

Measured: time to encode and decode at 1080p, 1440p and 2160p on the RTX 5090 and the M1 Max. Upstream states less than 0.2 ms at 2160p on desktop GPUs.

### Phase 2: Interface and session

1. Additions to CommandLine (keys, streaming, base layout key) and the input types of CommandLine in the three window implementations and the samples.
	This changes the local apps as well and is verified with them before anything is remote.
2. Interfaces and streaming.
3. Server actor with permission check, client control actor, skipping of frames, choice of bytes per frame.
4. Remote modes of the app layer and the remote window.

Tests: server and client in one process connected through a trust manager each, as `Test_Malterlib_Cloud_NetworkTunnels.cpp` does. The client decodes to a texture without a window.
Cases: frames arrive and match what was rendered, input reaches the frame callback in order, change of size, the app ends, no permission,
the connection is lost and comes back (frames continue, time stood still, held keys are right), the client ends the call.

The choice of limit and bytes per frame is a type of its own without actors or clocks, which is given answer times and tested directly:
a path of 1 ms gives the limit 2, 76 ms gives 6, a queue that grows lowers the bytes per frame and leaves the limit, a path that becomes longer raises the limit after the 10 seconds.
The session test delays the answers of the client by 76 ms and checks that the frame rate is kept.

### Phase 3: Samples

1. RenderSample and RenderBeach publish `ICRenderRemote` in `fp_StartApp` and get `--remote-host <HostID>`, `--video-rate`, `--video-chroma`.
2. Latency in the frame counter.
3. HDR from server to client.

Setting up the two machines, with the commands that exist:

```
Server:  MibRenderBeach --trust-listen-add wss://0.0.0.0:<Port>/ --primary --send-window 500mbit@76ms
         MibRenderBeach --trust-generate-ticket --permissions Render/RunRemote
         MibRenderBeach --daemon-run
Client:  MibRenderBeach --trust-connection-add <Ticket> --trusted-namespaces com.malterlib/Render/Remote --send-window 500mbit@76ms --connection-concurrency 4
         MibRenderBeach --remote-host <HostID of the server>
```

### Phase 4: Verification and documentation

- All backends as for the other work in Render: Metal, MoltenVK with validation, Linux Vulkan, Linux D3D12 through vkd3d-proton, Windows D3D12 and Vulkan.
- The real setup: the Windows machine as server with D3D12 and with Vulkan, the Mac as client, at 1080p, 1440p and 2160p, with frames per second, bytes per frame and latency reported.
- "Remote rendering" section in `Malterlib/Render/CLAUDE.md`, `./mib update-agents`.

## Not included

- Sound.
- Prediction between frames. PyroWave has none, which is what makes it fast and the bandwidth high.
- A transport over UDP with error correction. The interface does not prevent adding one for the frames later.
- Several clients for one session.
- Relative pointer movement with a captured pointer beyond what the window layer does today.

## Answered questions

| Question | Answer |
|---|---|
| Chroma by default | 4:4:4, since the path carries 500 Mbit/s. 4:2:0 is chosen by the server when the bytes per frame are too few for the size |
| Bandwidth of the path | Just above 500 Mbit/s, the video uses at most 300 Mbit/s |
| A lost connection | The session continues, through what the actor system does for daemons |
| A separate server app | No, each app is its own server |
| One home for the translations of events | No, Render has its own for now |
| `m_BaseLayoutKey` | In `CKeyEvent`, since the kitty protocol reports it |

## Open questions

None.

## What was implemented differently

| The plan | What was done | Why |
|---|---|---|
| Shaders as in PyroWave, with storage textures, subgroup operations and atomics | Compute shaders on GPU memory only, which write words of 32 bits with one thread for each word. The bitstream is the same | It is the same on the three backends, and D3D12 has neither writes of bytes nor the subgroup operations that were needed |
| Additions to the GPU layer: `mc_R16_UNorm`, wave sizes, mirrored repeat | None | The codec does not use textures that shaders write, and mirrors in the shader |
| The encoder in the submit of the frame | A submit of its own right after the frame | The renderer submits the frame itself. The cost is measured in the encoding times |
| A remote window actor for the title and the mode | `CRenderAppControl::m_Title` and `m_WindowMode` | Applications are the same with a window and without |
| Keys that are held are sent again after a reconnect | Not done | The transport loses nothing. Keys are released when the window loses the keyboard |
| Connections of the client in a database of its own | The database of the remote command line, `TrustDatabase.<App>.Remote` | `--remote-command-line-configure` has the commands for it already |
| The size of frames follows the answers only | Also goes down when frames cannot be sent, and the path is measured every 3 seconds | Without that one late answer made frames small for good on a path with no queue |

The documentation is in `Malterlib/Render/CLAUDE.md`, "Video" and "Remote Rendering".

## Measured on the real path

The Windows machine with the RTX 5090 rendered with D3D12 in Release, and a Mac with an M1 Max showed it with Metal
in Debug, through a WireGuard tunnel with 75 ms between them.

| | Frames per second | Video | Answers at least | Answers as a mean | Decoding | Frames that can be unanswered |
|---|---|---|---|---|---|---|
| 1920x1080 | 58.4 | 72 Mbit/s | 74.0 ms | 87.1 ms | 5.3 ms | 7 |
| 2560x1440 | 57.3 | 61 Mbit/s | 74.4 ms | 88.3 ms | 8.0 ms | 7 |
| 3840x2160 | 56.5 | 76 Mbit/s | 75.1 ms | 86.5 ms | 14.7 ms | 8 |

- Plain TCP between the two carried 57 to 102 Mbit/s when it was measured, 86 as a mean, so the video used what the
  path carried. The 300 Mbit/s that the video is limited to was reached between two processes on the Mac.
- 1, 2, 4 and 8 connections gave the same, within what the path changed by from one run to the next.
- The firewall of the Windows machine lets port 39301 in, which is the one of the benchmarks of the transport.

### Without the tunnel

Port 39301 was forwarded by the firewall of the Windows site, for the address of the Mac only.

| | Plain TCP, one flow | Plain TCP, four flows | Session at 2560x1440 | Answers at least |
|---|---|---|---|---|
| Through WireGuard | 72 to 86 Mbit/s | | 61 to 78 Mbit/s | 74 to 78 ms |
| Forwarded port | 51 Mbit/s | 86 Mbit/s | 65 to 82 Mbit/s | 66 to 68 ms |

- The tunnel is not what limits the path. Without it answers take 10 ms less, and the path carries the same.
- The Windows site sent at least 330 Mbit/s to Cloudflare and the Mac received 465 Mbit/s from it, so it is the path between
  the two sites that carries less than each of them does to what is near.
- The Windows host sent 0.17 % of its segments again during a session, with a queue of 12 ms as a mean.

### The two directions

| | Mac to Windows | Windows to Mac, which is the way of the video |
|---|---|---|
| Async socket benchmark with TLS, forwarded port | 417 to 485 Mbit/s | Not measured, the Windows host does not reach the Mac |
| Async socket benchmark with TLS, through WireGuard | 129 Mbit/s | Not measured |
| Plain TCP, forwarded port | 465 Mbit/s | 51 Mbit/s with one flow, 86 with four |
| Plain TCP, through WireGuard | 131 Mbit/s | 72 to 86 Mbit/s |

- The path carries 9 times more to the Windows host than from it, with the same tool, so it is what the Windows host
  sends that is held back, and the video goes that way.

### BBR2 on the Windows host

`netsh int tcp set supplemental template=<each> congestionprovider=bbr2` on the host that renders, for all templates.

| Windows to Mac | CUBIC | BBR2 |
|---|---|---|
| Async socket benchmark, forwarded port | 51 Mbit/s | 146 to 149 Mbit/s |
| Async socket benchmark, WireGuard | 49 Mbit/s | 109 Mbit/s |
| Sessions, 1080p to 2160p | 61 to 82 Mbit/s | 31 to 36 Mbit/s with the pacing before, 61 to 83 after it was changed |

- BBR sends a frame at the rate that it has measured, which is the rate of the video, so a frame takes a frame
  interval to leave. The pacing took that to be a queue until it allowed two frames of queue time.
- The video sends a frame at a time, so BBR does not measure more than the video uses, and the sessions do not get
  what the benchmark gets, which always has more to send.

### The tail

Frames grow by a tail of the blocks that the frame would have had with more room, which follows the frame in the
same call and replaces the blocks that came before it. The pacing grows the tail slowly, drops it first for a queue,
and makes it part of the frames when frames with it have been answered without a queue for two round trips.

| Windows to Mac, BBR2, 60 frames per second | Before the tail | With the tail |
|---|---|---|
| 1920x1080 | 61 Mbit/s | 107 Mbit/s |
| 2560x1440 | 68 Mbit/s | 94 to 106 Mbit/s |
| 3840x2160 | 83 Mbit/s | 95 Mbit/s |

- About 85 % of the frames had a tail, of 56 to 66 kB as a mean, which was dropped 15 to 21 times in 20 seconds and
  taken over 38 to 43 times.
- The benchmark carries 146 Mbit/s in the same direction, so a third is still not used.
