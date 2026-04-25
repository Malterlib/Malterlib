# Malterlib CLA signing & contribution instructions
_Last updated: 2026-04-25_

This document explains **how to sign** the Malterlib contributor agreements and what to do if you **do not own or control the relevant rights** in what you want to contribute.

> These instructions are **operational guidance**. The legally binding terms are in the agreements themselves:
> - [Individual Contributor Assignment Agreement](https://claccord.unbroken.se/cla?orgId=11143720&repoId=48914147)
> - Entity Contributor Assignment Agreement, provided during the manual e-signature workflow

---

## 1. Who needs to sign what?

### 1.1 Individuals (natural persons)
If you submit pull requests or other Contributions yourself, you must sign the **Individual** agreement.

This is true even if your employer has already signed the Entity agreement, because the Individual agreement also covers (among other things) individual confirmations and moral-rights consents under Swedish law.

### 1.2 Entities (companies and other legal entities)
An entity should sign the **Entity** agreement when a Contribution is submitted on the entity’s behalf, or when the entity or its affiliates own or control rights needed for the Contribution.

If your employer/client owns or controls the relevant economic rights, do not submit the Contribution until that employer/client has signed the Entity agreement, or has otherwise approved the Individual agreement where that is the applicable route.

Entity signing does not replace Individual signing. Each natural person who submits a Contribution must still sign the Individual agreement through GitHub.

---

## 2. How to sign as an individual (GitHub CLA Assistant)

Malterlib uses an automated CLA workflow for individuals.

You can view and sign the Individual Contributor Assignment Agreement at https://claccord.unbroken.se/cla?orgId=11143720&repoId=48914147.

1. Open a Pull Request in a Malterlib repository.
2. The Pull Request checks will include a **CLA** check.
3. Follow the instructions shown by the CLA check/bot to review and accept the Individual Contributor Assignment Agreement using your GitHub account.
4. Once you have signed, the check should pass for future pull requests made with the same GitHub account.

If you have problems signing through GitHub (for example you cannot access the signing link, the check does not appear, or you need to sign using a different identity), email **cla@malterlib.org** with:
- your GitHub username, and
- a link to the Pull Request where the check is failing.

---

## 3. How to sign as an entity (manual request + e-signature)

Entity signing is handled manually.

### 3.1 Start the process
Email **cla@malterlib.org** with the subject line:

**“Entity CLA signature request – <Legal Entity Name>”**

### 3.2 Include the following information
Please include:

**A. Entity details**
- Legal entity name (full registered name)
- Registration number (Swedish: **org.nr**; otherwise local registration number)
- Country of registration
- Registered address

**B. Signatory/signatories (authorised representative(s))**
- Name(s)
- Title(s)/role(s)
- Email address(es)
- Confirmation that the person or persons signing are authorised to bind the entity, including whether the entity requires several signatories acting jointly (Swedish entities: **firmatecknare**, joint signatories, or persons with a valid **fullmakt** / power of attorney)

**C. Scope**
- Whether the signature should cover affiliates/subsidiaries (list legal names + registration numbers where relevant)

**D. Administrative contact (optional but recommended)**
- Primary contact person for CLA questions (name + email)

Entity signing is not managed through a GitHub username allowlist or corporate email domain policy. Each contributing individual must still sign the Individual Contributor Assignment Agreement and confirm there that they own/control the relevant rights or have the necessary employer/client permission, including employer/client approval or an Entity Contributor Assignment Agreement where needed.

### 3.3 What happens next
After receiving the email, Unbroken AB will:
1. Confirm the details needed for signature, and
2. Set up an electronic signature workflow (for example via GetAccept) for the Entity Contributor Assignment Agreement, including all required signatories.

Once fully executed, we will confirm the entity’s status and keep a record of the executed agreement.

> Note: An entity signature does **not** remove the requirement for each contributing individual to sign the Individual agreement through GitHub.

---

## 4. If rights are owned or controlled by someone else
_Guidance for employer/client-owned work, third-party material, and other cases where you need permission before contributing_

You must only submit a Contribution if you have the legal right to do so.

### 4.1 Employer/client-owned work
If you are contributing as part of your employment or consultancy:

- Assume your employer/client may own (or control) the economic rights in your work.
- Make sure you are authorised to contribute under your employment/consultancy terms and internal policies.
- If your employer/client owns or controls the relevant economic rights, do not submit the Contribution until that employer/client has signed the Entity Contributor Assignment Agreement, or has otherwise approved the Individual Contributor Assignment Agreement where that is the applicable route.
- You should still sign the Individual Contributor Assignment Agreement via GitHub for your personal confirmations and moral-rights consent.

If you are unsure, email **cla@malterlib.org** before submitting the Contribution.

### 4.2 Third-party code, content, or data
Do **not** submit third-party material unless you have obtained all necessary permissions, it is compatible with Malterlib’s licensing model, and Unbroken AB has approved an exception for including that material.

If you include third-party material:
- Prefer material under licences that do not require attribution or licence notices to be provided with binary distributions, such as the Boost Software License 1.0 or Apache-2.0 WITH LLVM-exception.
- Keep all required copyright, licence and attribution notices.
- Clearly identify the third-party material and its licence in your Pull Request description, and in the repository where appropriate (for example in a `ThirdParty/` directory, `NOTICE`, `LICENSES`, or similar).

Do **not** include:
- material under “strong copyleft” licences (for example AGPL/GPL-style) or under non-commercial licences;
- material copied from proprietary sources, leaked code, or anything you received under an NDA or confidentiality obligation;
- code generated from or derived from sources where you do not have the rights to contribute it (including “copy/paste” from unknown licence sources).

### 4.3 No secrets or confidential information
Before submitting:
- remove any passwords, tokens, private keys, credentials, customer data, or other secrets;
- remove any third-party confidential information or trade secrets.

### 4.4 If you want to discuss an idea without contributing code
If you are sending suggestions or design ideas that you do **not** want treated as a Contribution under the definition of “Submit”, clearly mark the communication as:

**“Not a Contribution”**

### 4.5 When in doubt
If you are unsure whether you have the right to submit something, do not submit it yet. Email **cla@malterlib.org** with:
- a short description of what you want to contribute, and
- where it comes from (employment, client work, third-party project, etc.).

---

## 5. Data handling (high level)

To manage contributor agreements, Unbroken AB may process personal data relating to signatories and contributors, including:
- names and contact details,
- GitHub usernames and email addresses,
- contribution history,
- the applicable agreement version,
- the fact, date, and time of acceptance or signature, and
- related workflow metadata.

This is done to manage the project, record Contributions, provide appropriate attribution, comply with legal obligations, and maintain a clear rights chain for open source distribution, in accordance with applicable data protection laws (including GDPR). See the agreements’ “Personal data” sections for more detail.
