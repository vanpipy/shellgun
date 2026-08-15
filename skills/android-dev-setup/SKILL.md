# android-dev-setup

> Install or troubleshoot the Android SDK + NDK + Java dev environment on
> Linux. This document describes how to use `./bin/android-dev-setup` from
> this repository — a single, idempotent bash installer that handles
> SDKMAN/Java install, cmdline-tools, platforms/build-tools/NDK, licenses,
> and proxy auto-detection.

## When to Use

Use this document whenever the user asks any of:

- "Set up / install / configure the Android dev environment"
- "Install the Android SDK / NDK / build-tools"
- "I need adb / sdkmanager / aapt to work"
- "`sdkmanager: command not found`" or "`JAVA_HOME is not set`" errors
- "Java 17 for Android" / "Zulu JDK for Android"
- Adding Android as a target on a new dev machine

Do **not** use this for: Gradle/Android-Studio troubleshooting, building a
project, fixing a `Build failed` from an Android app — those are project
problems, not environment problems.

## Quick Reference

```bash
# Default install (interactive — accepts licenses via prompts)
./bin/android-dev-setup

# Non-interactive (CI / scripted / agent runs)
./bin/android-dev-setup --yes

# Show what would be done without changing anything
./bin/android-dev-setup --dry-run

# Help / flag reference
./bin/android-dev-setup --help

# Override defaults
./bin/android-dev-setup \
  --android-version android-35 \
  --build-tools 35.0.0 \
  --ndk-version 27.1.12297006 \
  --java-version 21.0.2-zulu \
  --sdk-root /opt/android-sdk \
  --yes
```

## Defaults

| Component        | Default              |
|------------------|----------------------|
| Android API      | `android-36`         |
| Build Tools      | `36.0.0`             |
| NDK              | `27.1.12297006`      |
| Java (SDKMAN)    | `17.0.19-zulu`       |
| SDK Root         | `$HOME/Android/Sdk`  |

## Standard Workflow

1. **Read the script first.** Before running, read `bin/android-dev-setup` so
   you know the current default versions and any flags you may want to pass.
   Defaults change over time.

2. **Run with `--dry-run`** to confirm the configuration matches the user's
   intent without making changes.

3. **Run with `--yes`.** This is a long-running install (~5–10 min for NDK).
   Run it **in the foreground and wait for it** so you can report the
   result. The script writes live progress for sdkmanager / sdk-install
   stages.

4. **Verify.** After a successful run, confirm all four checks pass:
   - `sdkmanager --version` → should print a version
   - `adb --version` → should print a version
   - `java -version` → should print `openjdk 17.0.19 ... LTS`
   - `sdkmanager --list_installed` → should show `platforms;android-36`,
     `build-tools;36.0.0`, `platform-tools`, `ndk;27.1.12297006`

5. **Tell the user to `source ~/.zshrc`** (or open a new terminal) so the
   `ANDROID_HOME` / `PATH` exports take effect for new shells.

## Environment & Proxy

The script auto-detects a proxy from `git config --global http(s).proxy` if
`HTTPS_PROXY` / `https_proxy` aren't already exported. This matters because:

- `get.sdkman.io` is often firewalled in dev networks (it was unreachable from
  the network this script was first run on — the only path to it was through a
  Clash/V2Ray proxy at `http://127.0.0.1:7890`).
- The script's `setup_proxy()` helper reads git's proxy config and exports
  `http_proxy` / `https_proxy` so `curl` and SDKMAN can reach it.
- If the user has no proxy at all, the install still works: `dl.google.com`
  is directly reachable; only SDKMAN needs the proxy, and SDKMAN is only
  needed if Java isn't already on PATH.

If the install hangs at the SDKMAN download step, that's the symptom of a
proxy not being detected — check `git config --global --get http.proxy` and
either set `HTTPS_PROXY` before running or fix the git config.

## Common Pitfalls (and the bugs that were fixed in this script)

These are non-obvious failures we hit while building this script. Do not
re-introduce them.

1. **`install_sdk_components` before `setup_java`** — `sdkmanager` is a Java
   app and exits with `JAVA_HOME is not set` if Java isn't installed first.
   Order in `main()` must be: `setup_proxy` → `download_commandlinetools` →
   `configure_environment` → export `ANDROID_HOME` for current shell →
   `setup_sdkman` → `setup_java` → `accept_licenses` → `install_sdk_components`.

2. **`sdk list java | grep` doesn't mean "installed"** — `sdk list java`
   shows the **catalog** of available versions, which always contains
   requested versions. The canonical "is this JDK installed?" check is
   `[[ -d ~/.sdkman/candidates/java/${JAVA_VERSION} ]]`.

3. **`sdkmanager` not on PATH after `configure_environment`** — that function
   only writes to `~/.zshrc`, which doesn't affect the current shell. The
   script must also `export PATH=...` for itself.

4. **`set -u` + SDKMAN init** — `sdkman-init.sh` references unset variables
   (e.g. `SDKMAN_CANDIDATES_API`) and crashes under `nounset`. Wrap every
   `source ~/.sdkman/bin/sdkman-init.sh` in `set +u; source ...; set -u`
   (the script's `source_sdkman()` helper does this).

5. **`curl get.sdkman.io` with no `--max-time`** — install hangs forever
   behind a flaky proxy. Always pass `--max-time 180`.

## Troubleshooting

| Symptom                                              | Likely cause                                     | Fix                                                                                            |
|------------------------------------------------------|--------------------------------------------------|------------------------------------------------------------------------------------------------|
| `sdkmanager: command not found` after install        | User hasn't sourced `~/.zshrc` / new shell       | `source ~/.zshrc` or open a new terminal                                                        |
| `JAVA_HOME is not set` from sdkmanager               | Java install step was skipped or failed          | Check `~/.sdkman/candidates/java/`; re-run script with `--yes` (don't pass `--skip-java`)       |
| `curl get.sdkman.io` hangs                           | Proxy not detected                               | Export `HTTPS_PROXY=http://127.0.0.1:7890` (or set `git config --global http.proxy <url>`)      |
| `sdkman-init.sh: ... unbound variable`               | Script doesn't `set +u` around source            | Use `source_sdkman()` helper                                                                   |
| `4 component(s) failed to install`                   | Old script bug — Java installed after components  | Update `bin/android-dev-setup`; ensure `setup_java` runs before `install_sdk_components`        |
| `apt install openjdk-17-jdk` fails (no such package) | Kali/Debian rolling only ships JDK 21            | Use SDKMAN's Java (script does this); or `--java-version 21.0.2-zulu` if you really need apt 21  |

## Notes for Maintainers

- Source of truth is the script itself. When you change defaults or flags in
  `bin/android-dev-setup`, update this document's **Defaults** and **Quick
  Reference** tables in the same commit.
- Commit message convention: `feat(android-dev-setup): ...` /
  `fix(android-dev-setup): ...`.
- `bin/android-dev-setup` is one of several setup scripts in this repo
  (others: `linux-env-setup`, `git-push-current-branch`, `security-configure`,
  `speckit-configure`). They share a similar bash idiom (defaults block,
  `parse_args`, color helpers) — when adding a new setup script, mirror
  `android-dev-setup`'s structure rather than reinventing it.