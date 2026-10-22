# Plugin security review — 2026-10-22

Source review, exact-version advisory searches, available publisher verification and current ClamAV scans accompanied this installation. Private files were not uploaded to scanning services. This records the checked versions and boundaries; empty advisory or malware results do not establish the absence of unknown vulnerabilities.

## Findings addressed

| Area | Action |
| --- | --- |
| OmaConnect remote metadata | Fork commit `1e78baa215e79b3408c6976c8348000ed16341eb` includes `ad3b69a` and treats device metadata as plain text, including composer headings, while restricting artwork requests. Remote commands and SMS remain hidden in this desktop profile. |
| TaskNotes writes | Fork commit `0e2a3f804ca7bb9e0c9ce39a64341770e268b4b3` defaults to read-only, preserves Base view ordering and opens native Obsidian for writes. This keeps recurring occurrence handling and existing sync bridges under TaskNotes. |
| Keystroke privacy and confirmation | Preserved disabled provider and extension guards, clipboard file-read gating and confirmation before provider callbacks. Added clearing on clipboard disable and rejection of late load events. Actual-palette regression tests cover these cases. |
| Keystroke optional Python runtime | Changed its pinned `certifi` dependency to 2026.10.19 with publisher hashes. The runtime was not installed; Smart Match remains off. |
| Syncshell TLS verification | Rebuilt the Linux core from pinned source with Go 1.27.3, adding the compromised-intermediate denylist for [GO-2026-6809 / CVE-2026-111943](https://pkg.go.dev/vuln/GO-2026-6809). |
| Host CA trust | Installed only the signed Arch packages `ca-certificates-mozilla 3.132-1` and `python-certifi 2026.10.19-1`; the normal package hook rebuilt the consolidated trust store. |

OmaConnect sources: [security fork](https://github.com/jackzasian/omaconnect/tree/codex/security-20261022). TaskNotes sources: [desktop branch](https://github.com/jackzasian/omatasknotes/tree/desktop/tasknotes-readonly-20261022). Full upstream and fork commits are recorded in [plugins.lock.json](plugins.lock.json).

## Host certificate verification

The existing system trusted the affected emSign roots. Arch's `certifi/cacert.pem` points to the system TLS bundle, and its NSS built-in CA module points to p11-kit. Updating the CA data therefore repaired those system trust consumers without replacing the NSS library or running a full system upgrade.

Mozilla's [NSS security announcement](https://groups.google.com/a/mozilla.org/g/dev-tech-crypto/c/vSxZxnOMMvs) removes C1, C3 and G3; the [incident explanation](https://blog.mozilla.org/security/2026/10/20/protecting-firefox-users-following-the-compromise-of-emudhra-intermediate-certificates/) identifies the compromised G3 chain. Fresh Python TLS contexts no longer contain these SHA256 fingerprints:

| Root | Removed fingerprint |
| --- | --- |
| emSign Root CA – C1 | `125609aa301da0a249b97a8239cb6a34216f44dcac9f3954b14292f2e8c8608f` |
| emSign ECC Root CA – C3 | `bc4d809b15189d78db3e1d8cf4f9726a795da1643ca5f1358e1ddb0edc0d7eb3` |
| emSign ECC Root CA – G3 | `86a1ecba089c4a8d3bbe2734c612ba341d813e043cf9e8a862cd5c57a36bbe6b` |

The retained G1 root, SHA256 `40f6af0346a99aa1cd1d555a4e9cce62c7f9634603ee406615833dc8c8d00367`, is expected. [Python's security guidance](https://discuss.python.org/t/information-for-python-users-regarding-emudhra-emsign-ca-certificate-security-incident/109576) recommends certifi 2026.10.19 for compatibility with unaffected roots. This system-store repair does not claim to update every embedded CA bundle or existing virtual environment.

The two artifacts came from the official Arch mirror and passed detached signature verification against existing trusted packager keys:

| Package | SHA256 | Signing key |
| --- | --- | --- |
| ca-certificates-mozilla 3.132-1 | `d2305ed8c1426e018ad611cb6e7fa387c3cac0f2e7040401dae2f1f78e0867ab` | `83BC8889351B5DEBBB68416EB8AC08600F108CDF` — heftig |
| python-certifi 2026.10.19-1 | `cbc17648f076b7a96771bb458b0053a5047ce577ed08b5fb5c8f6a7b984c344d` | `62CC73F884E52957B2FDD8839B7A287D9A2EC608` — dvzrv signing subkey |

The CA package contains static trust data and no install script or executable. Certifi's core and main Python modules are unchanged; its version and metadata changed. Both package artifacts passed current malware scans. No update-guard bypass was used.

## Runtime boundaries and coverage

GitHub links are restricted to `https://github.com` and launched through argv arrays. Cache directories are mode 0700 and files 0600. The helper pins the active credential in process memory and stores only its hash in refresh metadata. Keystroke's AI, clipboard and extensions remain disabled; no matching model or Python runtime was downloaded. Its optional bundled matching binary's GitHub attestation was verified against source commit `933a245fd50f7bd9def87b46808a452d3f5008ce`.

Oma Cast hands prompts to the selected agent only on explicit activation, using bounded argv input. Its calculator uses a parser rather than dynamic evaluation. Currency-rate fetching uses the fixed public Frankfurter endpoint and does not transmit launcher queries. EQ keeps AutoEq downloads opt-in and preserves the existing backend and local audio adaptations.

Syncshell's rebuilt binary passed all eight package race suites. OSV returned no matches for stdlib 1.27.3. The remaining `golang.org/x/sys v0.31.0` finding, [GO-2026-5024](https://pkg.go.dev/vuln/GO-2026-5024), concerns Windows `NewNTUnicodeString`; the compiled Linux dependency graph contains `x/sys/unix` and excludes `x/sys/windows`. Global Go was not updated.

The final installed-plugin scan covered821 files with zero detections. Scans used ClamAV 1.5.4 with current daily database 28161, main 63 and bytecode 339. The downloaded Go archive, all ten extracted compiler/tool executables and the final Syncshell binary were clean. Repository advisory checks for the four updated projects returned no published advisories. Review also inspected the new plugins' command, filesystem, network and credential boundaries.

Limits: the EQ PKGBUILD still skips its source archive checksum; this task updated its verified Git checkout and did not build that PKGBUILD. Activity Monitor tests skip foreign-user and kernel-thread cases when the sandbox exposes neither. Omaplug's compressed catalog fetch retains HTTPS certificate verification, a bounded120-second timeout and16MiB expanded-size limit; it reuses existing RelayPilot only when no HTTPS/ALL proxy is inherited. Its full suite and compression, size-bound and proxy regressions passed, and the live desktop loaded5856 entries. Security automation and its held unattended updater retain their existing permissions and read-only policy.

## Local evidence

Under `~/.local/state/omarchy-plugin-upgrade/20261022-213736/`:

- `audio-cast-report.json`, `github-keystroke-update-metadata.json` and the exact local patches.
- `security/independent-update-security-review.json` and per-plugin test logs.
- `security/host-trust-packages/`: publisher downloads, detached signature results and exact removed-root verification.
- `security/go1273/`: publisher checksum metadata, build recipe, module sums, race-test output, Linux dependency graph, OSV response, build information and malware logs.

Only source patches, public hashes and this summary are maintained here. Private feeds, authentication files, task data, screenshots, downloaded toolchains and compiled binaries remain outside Git.
