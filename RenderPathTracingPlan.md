# Path Tracing with DLSS Ray Reconstruction

Plan for a real-time path tracer in `Malterlib/Render`, first on NVIDIA hardware (RTX 5090 on Windows, D3D12
and Vulkan). The noisy frame is denoised and upscaled with DLSS Ray Reconstruction (DLSS-RR). The rasterizing
renderer also gets DLSS Super Resolution (DLSS-SR). Metal, other vendors and frame generation come later; the
design leaves room for them.

The goal is the beach and the sample path traced at 2560x1440 output and 60 fps on the 5090, shown locally or
over remote rendering on the Mac.

## Status (2026-09-29)

Phases 0 to 5 are done, uncommitted on mal-206. The tests pass on D3D12 and Vulkan on the 5090 over SSH, where the
tests of DLSS are skipped, and the tests of DLSS pass in a desktop session. `Malterlib/Render/CLAUDE.md` describes
what was built. Measured at 2560x1440 in Debug on the 5090: the beach path traced at 88 to 93 frames per second, and
the sample at about 170 with `mc_Engine` and 84 to 93 with `mc_MaterialX`.

What differs from the plan:

- Metal traces rays too (Apple9, M3 and later), since the GPU layer has ray queries on all three backends. The Mac
  that the tests run on is an M1 Max, so the path tracer has not been run on Metal.
- NGX is shut down when the last `CRenderDLSS` of a device is destroyed. Shutting down waits for the telemetry of
  the driver, which never finishes in a session without a desktop, as over SSH, so the tests of DLSS are skipped
  there (`fg_RenderHasDesktopSession`). Skipping the shutdown is not an option: NGX keeps the handles of the device
  it was initialized for, and the next device crashed with Vulkan.
- There is one `ERenderUpscaler::mc_DLSS`, which is super resolution for what is rasterized and ray reconstruction
  for what is path traced. `m_DLSSPreset` chooses the preset of both.
- A cut is `CFramePacket::m_bCut`, not `CRenderFrameInfo::m_bReset`.
- No pre-exposure: the exposure is applied after DLSS, which gets the scene as it is. Colors below 0 are cut off
  before DLSS, which does not take them.
- Energy compensation uses the analytic fit of Karis for the albedo of GGX, as Filament does, instead of tables
  that are made when the context is created. The sheen takes its albedo from the analytic fit of MaterialX.
- A surface shader without a mapping to `CPathSurface` renders white and diffuse with both models, and the frame
  says so in `m_PathTracingProblem`, instead of failing or estimating from the closures.
- With `mc_MaterialX` the shade kernels evaluate the closures with one light, less what the graph gives without
  it. Light from behind a surface, and surfaces smoother than `gc_PathMinClosureAlpha`, use the BSDF of the engine.
- Primary surface replacement is done for smooth metals, through at most three mirrors. Glass keeps its own
  guides, since the path reflects or refracts it at random and the guides would differ between frames.
- The transparency layer of DLSS-RR has not been tried. What is not opaque is passed through at random, and the
  guides are of the surface in front, with albedos that go towards 1 by how much is seen through it.
- NGX for Linux is in a shared library of its own, `MalterlibRenderNGX.so`, with the libstdc++ that it is built for,
  since its static library cannot be linked together with the C++ runtime of Malterlib. It is built and loaded on
  Linux x64 with Vulkan, and has not been run with an NVIDIA GPU there.
- Anisotropy and thin film are not in `CPathSurface`. Disney Principled has a sheen of another kind, which is not
  mapped.

Ray reconstruction of a still scene has a PSNR above 30 dB against the accumulated reference
(`Malterlib/Render/PathTracing/RayReconstructionReference`), with D3D12 and Vulkan in a desktop session.

Phase 6, done:

- Motion for meshes that change: `CRenderItem::m_pPreviousMesh`, which the water of the beach has.
- Sampling emissive triangles, of the materials of the engine that emit, weighed against the lobes, and ReSTIR DI for
  them (`m_bResampleEmitters`): candidates, and the samples of the frame before where the surface was and around it,
  in the shading of the first bounce.
- Dynamic resolution from the frame time on the GPU, with DLSS (`m_DynamicResolutionTime`).
- A megakernel for frames without material shaders, which is 2.5 to 3 times as fast as the wavefront at 1080p.
- The wavefront cut short the paths that passed through what is not opaque, which comparing it with the megakernel
  found.
- ReSTIR GI with the materials of the engine (`m_bResampleIndirect`), in a pass after the last bounce, with the
  unbiased reuse of Bitterli et al., which the reference of the CPU checks. It costs about 0.8 ms at 1080p.

- Ray tracing pipelines in the GPU layer, on Vulkan and D3D12, with a ray generation shader and callable shaders. Frames
  with material shaders are traced by a ray generation shader that calls the callable shaders that the shader
  compiler generates for the materials, which is 1.7 to 1.9 times as fast as the wavefront, except on D3D12 with many
  materials that are mixed, where it is 10 % slower.
- Shader execution reordering on Vulkan (`m_bReorderThreads`), which is off since it measured slower. D3D12 does not
  reorder, since that needs shader model 6.9, which the compiler of the Windows SDK does not have.

## Where things are today

What the surveys of the module found:

- **GPU layer**
  - Nothing for ray tracing, and no indirect dispatch.
  - Stages are `Transfer`, `Compute`, `VertexShader`, `PixelShader`, `RasterColorOut`, `RasterDepthOut` and
    `All`.
  - Buffers are carved from arenas, one `VkBuffer` or committed `ID3D12Resource` for each arena.
  - A D3D12 address is `(heap slot << 32) | offset`, not a GPU virtual address.
- **Device creation**
  - Vulkan enables a fixed list of extensions and picks the discrete GPU.
  - D3D12 takes the default adapter (`D3D12CreateDevice(nullptr, …)`) with `ID3D12Device10`, enhanced
    barriers, shader model 6.6 and one direct queue. Its device name is the string "D3D12".
- **Shaders** are compiled for `spirv_1_6`, `sm_6_6` and MSL, with no Slang capabilities requested.
- **Native handles** are held in the backend `CInternal` structs behind `f_GetInternal()`, which nothing outside
  `Source/Gpu/Backend` includes.
- **Renderer**
  - Renders at the target resolution.
  - Passes: shadow map, then opaque, sky and blended items, then the output pass (exposure, gamut, tone
    mapping, curve).
  - The output pass loads the scene texture one to one, and the scene is rendered straight to the target
    when that pass is not needed.
  - No jitter, no motion vectors, no history. Depth is not stored.
- **Frame packet**
  - One camera (view and projection), one directional light with ambient, one environment, and items of mesh,
    material and transform.
  - Items have no identity, so nothing ties an item to the one it was in the previous frame.
- **Meshes** are 44-byte vertices (position, normal, UV, tangent) with `uint32` indices, in two allocations,
  and cannot change. The beach makes a new water mesh, water textures and water material for every frame.
- **Materials**
  - MaterialX materials are pixel shaders. The Slang generator of MaterialX writes them, and they are lit by
    the hardware closures of MaterialX (`mx_*_bsdf`) with one light and a prefiltered environment.
  - The unfiltered environment is not kept.
  - The other materials are diffuse with a texture and emission.
- **Remote rendering** only needs the renderer to fill a texture of the display size. The encoder does not care
  how it was made.

## The main decisions

1. **Ray queries in compute shaders, not ray tracing pipelines.**
   - Inline ray tracing (`RayQuery`, DXR 1.1, `VK_KHR_ray_query`, Metal intersection queries) fits the layer:
     one root pointer, no shader binding tables, and pipelines that hold little state.
   - Ray tracing pipelines and shader execution reordering can come later as an optimization for NVIDIA.
2. **Wavefront path tracing.** Materials are separate shaders from separate packages, so one kernel cannot call
   all of them. Each bounce is a series of dispatches:
   1. **Trace:** a ray query writes one hit record per path (instance, primitive, barycentrics, distance) and
      counts the hits of each material shader.
   2. **Bin:** a prefix sum over the counts writes the arguments of indirect dispatches and the order of the
      paths for each shader.
   3. **Surface:** for every material shader in the frame, one indirect dispatch evaluates the MaterialX graph
      at its hits. It writes the parameters of the BSDF of the engine.
   4. **Shade:**
      - Direct light from the sun and the environment, each with a shadow ray.
      - Emission, with multiple importance sampling.
      - A sampled next direction and Russian roulette.
      - On the first bounce, the guide buffers for Ray Reconstruction.

   A megakernel for each package, or one generated for each application, can replace the wavefront later where
   it is faster.
3. **A fixed BSDF, with parameters from MaterialX.**
   - The path tracer needs to sample BSDFs, and Ray Reconstruction needs the diffuse albedo, specular albedo,
     normal and roughness of the surface. The hardware closures of MaterialX give neither.
   - So the shader compiler generates a second entry point for each material, `fg_MaterialSurface_<Name>`. It
     evaluates the node graph up to the surface shader, maps its inputs to `CPathSurface`, and returns that.
   - `CPathSurface` covers OpenPBR and Standard Surface: base, metalness, specular (color, roughness,
     anisotropy, IOR), coat, transmission (thin and thick), sheen, emission, opacity and the shading frame.
   - Standard Surface, OpenPBR, glTF PBR, UsdPreviewSurface and Disney Principled each get a mapping, and a
     surface shader without one fails to compile.
   - The other materials of the engine map to diffuse plus emission.
   - An option evaluates the closures of MaterialX for the directions instead, for the look of the rasterizer.
     Directions are still sampled from `CPathSurface`, and the guides come from it (phase 4).
4. **DLSS through the NGX SDK directly, not Streamline.**
   - DLSS SDK 310.9.1 (github.com/NVIDIA/DLSS) has headers, static libraries for Windows and Linux x64, and
     runtimes: `nvngx_dlss.dll` for SR and `nvngx_dlssd.dll` for RR, or `libnvidia-ngx-dlss*.so`.
   - Streamline is not used. It is for Windows only and adds DLLs of its own, and it gives nothing for Ray
     Reconstruction and Super Resolution that NGX does not. Frame generation and Reflex, which it would add,
     are not part of this.
5. **The upscaler sits between the scene and the output pass.**
   - The scene is rendered at the render resolution.
   - DLSS writes the output resolution as linear HDR in the working space.
   - The existing output pass then does exposure, gamut mapping, tone mapping and the curve, as now.
   - With an upscaler the renderer never renders straight to the target.
6. **Motion needs identity.**
   - `CRenderItem` gets `m_ID`, which the application sets and 0 means none. The renderer keeps the transform
     of each ID from the previous frame, and the camera of the previous frame.
   - Items without an ID have no motion of their own.

## Phases

Each phase ends with tests that pass on D3D12 and Vulkan on the 5090. Where it applies, the tests also skip
cleanly on Metal, MoltenVK, Mesa and vkd3d-proton, and a real run with the beach checks the result.

### Phase 0: Spikes that decide the design (days)

Small throwaway programs on the Windows host that answer the questions the plan depends on:

- Does Slang compile `RayQuery` for `sm_6_6` DXIL and for SPIR-V with the current compiler options, and what
  does it need?
  - Capabilities (`spvRayQueryKHR`), and SPIR-V without optimization.
  - How it reaches a TLAS through `DescriptorHandle<RaytracingAccelerationStructure>` on both backends.
  - Whether Metal intersection queries compile, for later.
- NGX on D3D12 with enhanced barriers:
  - Does `NVSDK_NGX_D3D12_EvaluateFeature` accept textures in `D3D12_BARRIER_LAYOUT_DIRECT_QUEUE_COMMON`?
  - Does it record legacy `ResourceBarrier`s on our command list, and does the debug layer accept the mix?
- NGX on Vulkan with images in `VK_IMAGE_LAYOUT_GENERAL`:
  - Which instance and device extensions `NVSDK_NGX_VULKAN_GetFeature*ExtensionRequirements` asks for.
  - What state it leaves bound on the command buffer.
- Which NGX static library fits the C runtime of Malterlib on Windows (`nvsdk_ngx_s` or `_d`), with the linker
  of MalterlibLLVM.
- Initializing with `NVSDK_NGX_*_Init_with_ProjectID`: engine type custom, a project GUID of our own, and a
  data path under the program directory.
- Whether Mesa's lavapipe in the Linux container has `VK_KHR_ray_query`, so that the ray tracing tests of the
  GPU layer can run where the module is developed.

### Phase 1: Ray tracing in the GPU layer

**Capabilities and device**

- `CGpuCapabilities::m_bRayQuery`, and the limits: instances, primitives, and the alignment of scratch memory
  and of acceleration structures.
- `m_VendorID` and the real adapter name.
- `CGpuDeviceDesc::m_bRequireRayQuery`.
- D3D12 picks the adapter with DXGI (`EnumAdapterByGpuPreference`, high performance), and can be overridden
  by an environment variable as the libraries are.
- Vulkan enables:
  - `VK_KHR_acceleration_structure`, `VK_KHR_ray_query` and `VK_KHR_deferred_host_operations` when present.
  - Their features, and their functions in the optional lists of `CVulkanFunctions`.

**Memory**

- Vulkan arenas get the usages `ACCELERATION_STRUCTURE_BUILD_INPUT_READ_ONLY` and
  `ACCELERATION_STRUCTURE_STORAGE` when ray queries are enabled. Structures live in ordinary GPU-only arenas,
  as `VkAccelerationStructureKHR` objects on ranges of them.
- D3D12 gets a new kind of arena, since a structure has to be in a buffer created for acceleration
  structures and nothing else.
- Builds read vertices, indices and instances by GPU virtual address. D3D12 translates
  `CGpuAddress` → `ID3D12Resource` VA inside the backend (`f_FindBuffer`), and callers never see a VA.

**API** (in `Malterlib_Render_Gpu.h` and `_Types.h`)

- `CGpuAccelerationStructureDesc`:
  - The kind: bottom or top level.
  - Geometries: triangles given by a vertex address, stride, format and count, and an index address and count.
  - Opaque or not, per geometry.
  - Flags: fast trace, fast build, allow update, allow compaction.
- `CGpuDevice`:
  - `f_GetAccelerationStructureSizes`.
  - `f_CreateAccelerationStructure` and `f_DestroyAccelerationStructure`, released with the submits before
    them, like everything else.
  - `f_GetAccelerationStructureDescriptor`, which gives the handle for shaders.
- Command buffer:
  - `f_BuildAccelerationStructures`, which takes a span of builds with scratch memory from the caller.
  - `f_CopyAccelerationStructure` for compaction, and `f_WriteCompactedSizes`.
- `CGpuAccelerationInstance`, mirrored in Slang:
  - A 3x4 transform.
  - A custom index of 24 bits, a mask of 8 bits and flags (cull disable, flip facing, force opaque).
  - A reference to a bottom level structure. It is the VA on D3D12 and Vulkan, filled in by the layer from the
    handle.
- `EGpuStage::mc_AccelerationBuild`, for barriers between builds and the shaders that trace.
- `f_DispatchIndirect(Data, Arguments)` on all backends.
- Atomics for shaders that work on every backend: `DMibGpuAtomicAdd`, through `RWByteAddressBuffer` on D3D12.
- The descriptor of a structure for shaders: a heap slot on D3D12, a new binding in set 0 on Vulkan (binding 1
  is unused), and a resource ID on Metal later.

**Tests** (`Test_Malterlib_Render_Gpu_RayTracing.cpp`)

- Build a bottom level structure and trace rays from a compute shader against it. Compare the hits with a CPU
  intersection.
- Instances with transforms, mirrored transforms, masks, and geometry that is not opaque.
- Compaction, and an update that refits.
- Indirect dispatch.
- Destroying structures that frames still use.
- The barrier counts, as the other GPU tests check them.
- Skip when `m_bRayQuery` is false.

### Phase 2: The scene for ray tracing

- `CRenderContextDesc::m_bRayTracing` makes meshes build their bottom level structure when they are created, on
  the command buffer that uploads them. The structure is compacted, owned by `CRenderMesh`, and freed with it.
- The water mesh that is new for every frame builds its structure in the frame, with fast build and no
  compaction.
- A top level structure is built for every frame from all items, not only the visible ones, in the setup
  command buffer.
  - The instance data comes from the prepare jobs on the thread pool, which already make instance data.
  - Its custom index is the index of the item.
  - The mask separates what casts shadows from what does not. Blended items do not, which is what the shadow
    map does now.
- `CPathInstance` for shaders holds, for each item:
  - The transform and the transform of the previous frame, and their cofactors.
  - The material.
  - The addresses of the vertices and indices of its mesh, so hits get their attributes with
    `DMibGpuLoadElement`.
- `CRenderItem::m_ID`, and a map in the renderer from ID to the transform of the previous frame, kept for one
  frame. The previous camera is kept the same way.

### Phase 3: Motion vectors, jitter, and DLSS Super Resolution for the rasterizer

This phase brings in NGX with the simpler of the two features, before the path tracer exists, so the
integration is proven on its own.

**External repository**

- `External/DLSS` is `https://github.com/NVIDIA/DLSS.git` as its origin, without a fork, pinned in
  `Malterlib/Render/External.MRepo` like the other external repositories, and registered with
  `%Repository "DLSS"` in `Malterlib_Render.MHeader`. The SDK is then fetched from NVIDIA, never
  redistributed by Malterlib.
- `MalterlibRender_DLSS` (a `User(Render)` bool) is on by default for D3D12 and Vulkan on Windows x64 and
  Linux x64. It defines `DMibRenderDLSS`.
- The static library of NGX is linked, and the runtime libraries go next to executables with
  `MalterlibPostCopySources`, using the `rel` libraries.
  - The survey could not confirm that a `Property` set in the injection group of Render reaches the
    executables. Check it, and otherwise add the entries in the apps and in the test target.

**Upscaler**

- `Source/Upscale/` has `CRenderUpscaler`: none, DLSS-SR or DLSS-RR, and later MetalFX.
  - The code that talks to NGX is in `Source/Upscale/Backend/D3D12` and `Backend/Vulkan`. These are the only
    files outside the GPU layer that include its internal headers.
  - After an evaluation they mark the state of the command buffer as unknown, since NGX binds its own
    pipelines, descriptor heaps and root signatures. The layer then sets the heaps, root signatures, pipeline
    layout, descriptor set and root constants again before the next command.
- Vulkan device creation asks NGX for its extensions. `CGpuDeviceDesc` gets a hook that the backend calls with
  the native instance and physical device, and that returns the instance and device extensions to enable. This
  keeps NGX out of the GPU layer.

**Renderer**

- `CRendererSettings::m_Upscaler` and `m_UpscaleQuality`, which is DLAA, Quality, Balanced, Performance or
  Ultra Performance.
  - The render resolution comes from `NGX_DLSS_GET_OPTIMAL_SETTINGS`.
  - `CFrameResult` reports the upscaler and the render resolution.
  - When DLSS is not available the renderer falls back to no upscaler and says so.
- Jitter is a Halton (2, 3) sequence, with as many phases as DLSS asks for at the ratio. It is added to the
  projection, and the sky and the output use the same offset.
- The scene pass gets a second target for motion vectors (`RG16_Float`, in pixels of the render resolution),
  written from the current and previous clip positions. Depth is stored.
- `CRenderFrameInfo` gets `m_bReset` for cuts, which the application sets and which is passed to DLSS.

**Tests**

- Motion vectors of a camera and of an item that move, checked by reprojection.
- Jitter.
- DLSS-SR creates, evaluates and gives an image close to the one rendered at the output resolution. This is
  measured as PSNR above a threshold, and skipped without an NVIDIA GPU.
- Test with the beach locally and over remote rendering.

### Phase 4: The path tracer

**Settings**

- `CRendererSettings::m_Mode`, raster or path traced.
- `CRenderPathTracingSettings`: the most bounces (default 4), samples for each pixel (default 1), clamping of
  indirect light, and `m_bAccumulate` for a converged reference while nothing moves.

**Shaders**

- `Shaders/Malterlib_Render_PathTrace*.slang(h)`: ray generation with jitter, trace, bin, shade, and the resolve
  for accumulation.
- `Malterlib_Render_PathSurface.slangh` has `CPathSurface` and the BSDF:
  - GGX with sampling of visible normals, a Lambert base, and dielectric and conductor Fresnel.
  - Coat, sheen and transmission.
  - Energy compensation from lookup tables made when the context is created.
- The random numbers are the same for a pixel, frame and seed, so tests can repeat them.

**Materials**

- `CRenderPathTracingSettings::m_MaterialModel` chooses how MaterialX materials reflect light. Both models
  sample directions and fill the guide buffers from `CPathSurface`, so they differ only in the value that the
  path gets for a direction.

  | Model | The BSDF for a direction is | Suits |
  |---|---|---|
  | `mc_Engine`, the default | The BSDF of the engine with the parameters of `CPathSurface` | Speed, and paths that conserve energy |
  | `mc_MaterialX` | The closures of MaterialX (`mx_*_bsdf`), with the direction as a light of `Malterlib_Render_MaterialLights.slangh` | Looking the same as when rasterized |

- `CMaterialGenerator` emits two compute entry points next to the pixel shader. Both read the hit and evaluate
  the graph with the same inputs as the pixel shader.
  - `fg_MaterialSurface_<Name>` maps the graph to `CPathSurface`.
  - `fg_MaterialShade_<Name>`, which exists only for `mc_MaterialX`, also does the shading of the bounce for
    its hits: it traces the shadow rays, samples the next direction from `CPathSurface`, and weighs each with
    the closures of MaterialX divided by the probability of sampling it. The shade kernel of the engine then
    only handles the paths of the other materials.
- `CRenderMaterialShader` gets a compute pipeline for each entry point. The pipelines of the model that is not
  used are not created.
- A surface shader without a mapping to `CPathSurface` still compiles with `mc_MaterialX`. It samples from a
  mix of cosine and GGX, with albedo and roughness estimated from the closures of MaterialX for the guides.
  With `mc_Engine` it cannot be rendered, and the renderer throws when it is in a frame.
- With `mc_MaterialX`, transmission uses the BSDF of the engine. The hardware code of MaterialX only shows
  the environment through what lets light through.
- The materials that are not of MaterialX use the surface kernel of the engine in both models.

**Light**

- Next event estimation for the directional light, which gets an angular size for soft shadows, and for the
  environment.
- `CRenderEnvironment` keeps the unfiltered radiance and gets a table for importance sampling, made on the
  thread pool with the filtering.
- Emissive surfaces are found by the BSDF samples, weighted with multiple importance sampling. Sampling
  emissive triangles directly is phase 6.

**Transparency**

- Blended items are passed through at random by their opacity, which the surface kernel evaluates. A path
  that passes through continues from the hit without counting a bounce.
- Glass is transmission in the BSDF.
- Shadow rays skip blended items by the mask.

**Overlays**

- `CRenderItem::m_bOverlay` marks items that are drawn after the upscaler, by rasterizing at the output
  resolution. It is for the frame counter and the numbers of `CRenderNumberDisplay`, which should not be
  denoised.

**Accumulation without DLSS**

- This is the reference. It has a history that is cleared when the camera, the items or the settings change.

**Tests**

- A furnace test: a diffuse sphere with white albedo in a uniform environment converges to the environment.
  It runs with `mc_Engine` only, since the layering of MaterialX does not conserve energy along a path.
- The two material models converge to the same image, within a bound, for materials where MaterialX and the
  engine have the same formulas: Lambert, and GGX without layers.
- A CPU path tracer in `Test/` for small scenes, like the reference encoder of the codec. The converged GPU
  images are compared with it within a statistical bound.
- Mirrors and glass against analytic results.
- The same image for the same seed.
- Bins with no hits, and one material shader against many.

### Phase 5: DLSS Ray Reconstruction

- Guide buffers from the first bounce, at the render resolution:
  - diffuse albedo and specular albedo (the directional albedo of the BSDF, from the same tables);
  - normals in world space with roughness in `w` (`Roughness_Mode_Packed`);
  - depth, the hit distance of the specular sample, and motion vectors.
- The matrices from the world to the view and from the view to clip space are also passed.
- Mirrors and glass that are almost perfect get their guides and motion from the first surface that is not
  specular (primary surface replacement). This follows the guide of DLSS-RR and is a later refinement within
  this phase.
- Evaluation settings:
  - `NVSDK_NGX_Feature_RayReconstruction` with `NVSDK_NGX_*_DLSSD_Eval_Params`.
  - The preset is left to the default (F, the transformer model), and `m_RayReconstructionPreset` can
    override it.
  - Pre-exposure comes from the exposure of the output settings. The frame time is passed as well.
- Blended items that were passed through give their surface to the guides of the pixel when they are the
  first surface. What DLSS-RR does with its transparency layer inputs is tried and measured, but not relied on.
- `CFrameResult` gets the GPU time of each pass, using timestamp queries added to the GPU layer, so the
  budget can be followed.

**Tests**

- Ray Reconstruction evaluates without errors from the debug layer or validation.
- For a still scene it converges close to the accumulated reference (PSNR threshold).
- A moving camera gives no NaNs, and the reset is honored.

**Real check**

- The beach path traced on the 5090, shown on the Mac over remote rendering, with the frame times and the
  statistics of the session.
- It is looked at by the user for ghosting of the water, which has no motion of its vertices (see below).

### Phase 6: Quality and speed (after the first version works)

- Motion for meshes that change: an item can give the positions of the previous frame, so the water gets its
  real motion.
- Sampling emissive triangles, and then ReSTIR DI and GI for many lights.
- Shader execution reordering, or ray tracing pipelines, on NVIDIA where the wavefront costs too much.
- Dynamic resolution from the frame time.
- A megakernel for scenes with few material shaders.

## Later: other platforms

- **Metal:**
  - Acceleration structures in `MTLResidencySet` and intersection queries.
  - MetalFX has a temporal upscaler that denoises on macOS 26 (check the API), which could take the place of
    DLSS-RR behind `CRenderUpscaler`.
  - The M1 Max traces without hardware for it, so this is for correctness more than speed there.
- **AMD and Intel:** the path tracer works through Vulkan and D3D12 as it is. They need another denoiser (FSR
  or NRD) behind `CRenderUpscaler`.
- **MoltenVK** has no ray queries. The path tracer is not available there, and the tests skip.

## Decisions

1. **Decided:** the NGX SDK directly, without Streamline. `External/DLSS` has NVIDIA's repository as its
   origin, without a fork.
2. **Decided:** the rasterizer gets DLSS-SR first (phase 3), before the path tracer.
3. **Decided:** both material models, with the fixed BSDF of the engine as the default and the closures of
   MaterialX as an option (`m_MaterialModel`, phase 4).
4. **Decided:** NVIDIA is verified on Windows only, on the 5090 host with D3D12 and Vulkan. On Linux x64,
   DLSS is compiled against the Linux libraries of the SDK and is not run. Where the driver has ray queries,
   Linux runs the path tracer without DLSS: RADV on the Radeon, and lavapipe in the container if phase 0
   finds it there. The Render documentation says this in "What has been run where".

## Risks

- NGX and the enhanced barriers of D3D12 (phase 0). If they do not mix, the textures that DLSS reads and
  writes need legacy states around the evaluation.
- Slang and SPIR-V without optimization for ray queries. `slang-glslang` is not built, and a driver can be
  stricter than validation.
- The wavefront adds dispatches and memory traffic for each bounce. At 1 sample and 4 bounces at about
  1280x720 of render resolution this should be well inside the 5090, and it is measured in phase 4 before
  optimizing.
- Mapping MaterialX graphs to one BSDF loses what the model does not have, such as thin film and closures
  that are layered in unusual ways. Surface shaders without a mapping fail to compile rather than render wrong.
