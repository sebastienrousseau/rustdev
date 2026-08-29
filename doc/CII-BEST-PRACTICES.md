<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

# OpenSSF Best Practices Badge — self-assessment

The `CII-Best-Practices` check on
[`scorecard.dev`](https://scorecard.dev/viewer/?uri=github.com/sebastienrousseau/langdev)
scores `0/10` until the project is **registered by the owner** at
<https://www.bestpractices.dev/> and the self-assessment is submitted.
Registration and submission are a human step the maintainer performs on
that site; nothing in this repository can set the badge on its own. This
file is the prefilled checklist so the application takes minutes.

Every row maps a criterion to concrete evidence in this repo, and is
marked **MET**, **N/A**, or **GAP**. Paths are repo-relative; across
repos use
`https://github.com/sebastienrousseau/langdev/blob/main/<path>`.

## Application

- Register: <https://www.bestpractices.dev/en/projects/new>
- Project URL: `https://github.com/sebastienrousseau/langdev`
- Note: langdev is a **container/shell** project, so a few criteria that
  are Rust/library-specific (published package registry, API docs) are
  marked N/A with the container-equivalent evidence given instead.

---

## Passing level

### Basics

| Criterion | Status | Evidence |
| :--- | :--- | :--- |
| Project homepage / repo URL | MET | `https://github.com/sebastienrousseau/langdev` |
| Describes what it does | MET | `README.md` header + tagline |
| Discussion mechanism | MET | GitHub Issues + Discussions |
| OSI-approved licence | MET | `Apache-2.0 OR MIT` — `LICENSE-APACHE`, `LICENSE-MIT` |
| Licence in standard location | MET | Repo root `LICENSE-APACHE` / `LICENSE-MIT`; SPDX header on every file (see `STYLE.md`) |
| Documentation (basics + how-to) | MET | `README.md`, `SECURITY.md`, `CONTRIBUTING.md`, `STYLE.md`, `test/README.md` |
| Documentation quick-start | MET | `README.md` §"Quick start" |
| English for the project | MET | All docs are English |
| Maintainer-direct contact | MET | `sebastian.rousseau@gmail.com` (`SECURITY.md`, `SUPPORT.md`) |

### Change control

| Criterion | Status | Evidence |
| :--- | :--- | :--- |
| Public version-controlled source | MET | Git, GitHub-hosted |
| Interim/dev versions available | MET | `main` is public; every commit browsable |
| Unique version identifier | MET | Git SHAs; releases tagged SemVer; base image pinned by digest in `templates/Containerfile` |
| Release notes | MET | `CHANGELOG.md` (Keep-a-Changelog) |
| Release notes name fixed vulns | MET | `CHANGELOG.md` "Security" sections; `SECURITY.md` disclosure flow |

### Reporting

| Criterion | Status | Evidence |
| :--- | :--- | :--- |
| Bug-report process documented | MET | `.github/ISSUE_TEMPLATE/`, `SUPPORT.md` |
| Responses to bug reports | MET | Maintainer triages Issues; `SUPPORT.md` sets expectations |
| Vulnerability report process | MET | `SECURITY.md` — private GitHub Security Advisory or email |
| Private vuln reporting supported | MET | `SECURITY.md` — advisory + `sebastian.rousseau@gmail.com` |
| Vuln report initial response ≤ 14 days | MET | `SECURITY.md` states 48 h initial response, fix/mitigation plan ≤ 7 days |

### Quality

| Criterion | Status | Evidence |
| :--- | :--- | :--- |
| Working build system | MET | `templates/Makefile` (`make build`), OCI `templates/Containerfile` |
| Automated test suite | MET | `test/*.bats` (bats-core); `make test` |
| Tests documented / invocable | MET | `test/README.md`, `test/run.sh`, `make test` |
| New functionality → tests policy | MET | `CONTRIBUTING.md`; coverage gate blocks untested code |
| Test coverage measured | MET | kcov, ≥95% line gate — `test/run.sh`, ci.yml `coverage` job |
| Warning flags enabled | MET | `set -euo pipefail` in every script; `shellcheck -x` in CI; `hadolint` on the Containerfile |
| Warnings addressed | MET | CI fails on shellcheck/hadolint findings |
| Coding style documented | MET | `STYLE.md`; shell = `set -euo pipefail`, 2-space indent |
| Automated style enforcement | MET | `shellcheck` (ci.yml) + `hadolint` (ci.yml) |

### Security

| Criterion | Status | Evidence |
| :--- | :--- | :--- |
| Developer secure-development knowledge | MET | `SECURITY.md` threat model; hardening rationale in `README.md` §"Why this approach?" |
| Good cryptographic practices | N/A | No crypto is implemented; TLS for `git clone` is provided by the OS/ca-certificates. No home-grown crypto. |
| Secured delivery vs MITM | MET | Base image pinned **by digest**; HTTPS clones; no `curl \| sh`; actions SHA-pinned (`templates/github-workflows/*.yml`) |
| Publicly-known vulns fixed | MET | Trivy HIGH/CRITICAL gate on every build (ci.yml `build-scan`) |
| No leaked credentials | MET | `.dockerignore`/`.gitignore` block `.env`; Checkov `secrets` scan in `sast.yml`; `SECURITY.md` §"No committed secrets" |

### Analysis

| Criterion | Status | Evidence |
| :--- | :--- | :--- |
| Static analysis applied | MET | `shellcheck` (shell) + Trivy config + Checkov (Dockerfile/IaC), SARIF → code-scanning — `templates/github-workflows/sast.yml`. **CodeQL has no shell/Dockerfile analyzer, so it is intentionally omitted rather than added as a no-op.** |
| Static analysis for common vulns | MET | Trivy misconfig + Checkov policy rules cover container-misconfiguration classes |
| Static-analysis findings fixed | MET | SARIF surfaces in code-scanning; ci.yml fails on shellcheck/hadolint |
| Dynamic analysis | MET | Trivy **image** vulnerability scan of the built image (ci.yml `build-scan`); the bats suite exercises the scripts end-to-end under kcov |

**Passing level: MET (repo-side).** The badge itself issues once the
owner submits the form above.

---

## Silver level

Silver adds project-maturity and process criteria on top of Passing.

| Criterion | Status | Evidence |
| :--- | :--- | :--- |
| DCO or CLA for contributions | MET | `CONTRIBUTING.md` — signed commits required; inbound = outbound (Apache-2.0 §5) |
| Documented code-of-conduct | MET | `CODE_OF_CONDUCT.md` |
| Documented governance | MET | `GOVERNANCE.md` |
| Roadmap / project direction | MET | `README.md` §"The suite" + `CHANGELOG.md` |
| Documented architecture/design | MET | `README.md` §"Architecture"; `SECURITY.md` threat model |
| Document security requirements | MET | `SECURITY.md` §"Threat model" / §"Security controls" |
| Threat model documented | MET | `SECURITY.md` §"Threat model" (assets, in/out of scope) |
| Hardening mechanisms used | MET | Non-root, `cap_drop: ALL`, `no-new-privileges`, read-only rootfs, `pids/mem` limits, setuid stripped — `templates/Containerfile`, `templates/compose.yaml`, `SECURITY.md` |
| Input validation on untrusted input | MET | Scripts run `set -euo pipefail`, quote expansions, and validate `--source`/args (`bin/langdev-sync`); regression-tested in `test/` |
| Secure release signing (commits) | MET | Signed commits enforced; `scripts/set-branch-protection.sh` requires signatures |
| Two-person review available | PARTIAL | `.github/CODEOWNERS` + branch-protection PR review (`scripts/set-branch-protection.sh`); effective two-person review is capped by the solo-maintainer reality (see Gold) |
| Continuous integration | MET | `templates/github-workflows/ci.yml` on push + PR |
| Reproducible build | MET | Base image pinned by digest, OS packages pinned, Neovim plugins via `lazy-lock.json`, `DOTFILES_REF` pinnable — `templates/Containerfile`, `README.md` §"Why this approach?" #4 |
| Coverage ≥ 80% (statement) | MET | kcov gate at **≥95%** — `test/run.sh` |
| Test suite in CI on every change | MET | ci.yml `coverage` job on push + PR |

**Silver: achievable repo-side.** The only soft spot is genuine
two-person review, which a solo project cannot fully satisfy; the
machinery (CODEOWNERS, required reviews, signed commits) is in place for
the moment a second maintainer joins.

---

## Gold level

Gold is where a solo, pre-1.0 project hits honest, structural GAPs.

| Criterion | Status | Evidence / gap |
| :--- | :--- | :--- |
| **≥ 2 independent maintainers with 2FA** | **GAP** | Solo project (`GOVERNANCE.md`). GitHub 2FA is enabled on the sole maintainer account, but the "two unassociated significant contributors" bar is not met. Unblocks only when a second maintainer joins. |
| Continuity / bus-factor plan | PARTIAL | `GOVERNANCE.md` describes intent to grow the maintainer base; no second maintainer yet. |
| **Signed releases** | **GAP** | Commits and tags are signed, but there is no release **artifact**-signing pipeline (cosign/GPG on a published image or tarball) yet. Container images are not yet published+signed to a registry. Planned; blocked on first tagged release. |
| **Reproducible release verification** | **GAP** | Inputs are pinned (digest/lockfiles) so builds are *reproducible in principle*, but there is no published, independently-verified reproducible-build attestation (e.g. SLSA provenance) yet. Planned alongside signed releases. |
| SAST covers all common weaknesses | PARTIAL | shellcheck + Trivy + Checkov cover shell + container-misconfig classes; no dataflow SAST (CodeQL does not support shell/Dockerfile — documented above). |
| Dependencies monitored for vulns | MET | Dependabot (`.github/dependabot.yml`) + `dependency-review.yml` + Trivy |
| Hardening headers / signed artifacts on distribution | GAP | Ties to signed-releases above; no registry distribution yet. |
| Reach & pass a security review | PARTIAL | Internal threat model + automated SAST/scan; no external audit. |

### Honest summary

- **Achievable now (repo-side): Silver.** All Passing criteria and the
  Silver criteria are met by artifacts in this repository; the badge
  simply awaits the owner's registration + submission on
  <https://www.bestpractices.dev/>.
- **Gold is blocked** on three structural items that a solo, unreleased
  project cannot satisfy from inside the repo:
  1. **≥ 2 independent maintainers, each with 2FA** — needs a second
     human maintainer.
  2. **Signed releases** — needs a release pipeline that signs a
     published artifact (cosign/GPG), which lands with the first tagged
     image release.
  3. **Reproducible-release verification** (independent provenance, e.g.
     SLSA) — lands with the same release pipeline.

When langdev ships its first signed, provenance-attested release and a
second maintainer joins, the Gold GAPs close; nothing else in the Gold
list is outstanding.

## How to apply

1. Visit <https://www.bestpractices.dev/en/projects/new>.
2. Enter `https://github.com/sebastienrousseau/langdev`.
3. Answer each criterion using the rows above (most accept a URL —
   paste the corresponding repo path).
4. Submit. Target **Silver**; declare the three Gold items above as
   future work.
5. Once issued, the next OpenSSF Scorecard refresh lifts the
   `CII-Best-Practices` check from 0 → 10. Add the badge URL
   (`https://www.bestpractices.dev/projects/<id>`) to `README.md`.
