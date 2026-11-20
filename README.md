# ocb

A minimalist terminal handoff bridge between **OpenCode** and **Freebuff** built for **Termux** (via Ubuntu `proot-distro`) and **Linux / WSL**.

`ocb` lets you switch seamlessly between OpenCode and Freebuff when rate limits hit or when you want a second agent's perspective—preserving your conversation context, working `git diff`, and continuous thread history without manual copy-pasting or cluttered session lists.

```text
  █▀▀█ █▀▀ █▀▀▄   ocb v1.0.0
  █  █ █   █▀▀▄   cross-agent bridge · my-project
  ▀▀▀▀ ▀▀▀ ▀▀▀    ------------------------------------
```

---

## Features

- **Cross-Agent Context & Diff Handoff:** Packages the active session's conversation history alongside `git status` and `git diff` into `.bridge-handoff.md` (automatically ignored via `.git/info/exclude`) before launching the target agent.
- **Continuous Thread Resume:** Resumes existing project sessions directly (`opencode -s <id>` and `freebuff --continue <id>`) via a numbered selector instead of forking duplicate threads on every handoff.
- **Zero-Clutter Session Discovery:** Filters out empty startup telemetry logs (`log.jsonl`-only stubs) and automatically purges `"Reply READY"` availability probes from `opencode.db`.
- **Workspace Isolation & Git Safety:** Keeps sessions scoped inside `~/projects/<slug>`, creates automatic checkpoint tags (`opencode-latest`), and includes an interactive `.git` lock/index health auditor (`ocb --health`).
- **Selective `.tzst` Backup & Restore:** Compresses and restores **Both**, **OpenCode only**, or **Freebuff only** (binaries, configs, and session databases) to `Download/TOOL BACKUP` using multi-threaded `zstd`.

---

## Quick Install

### Termux (Android) & Linux / WSL

```bash
curl -fsSL [https://raw.githubusercontent.com/isygold/ocb/main/install.sh](https://raw.githubusercontent.com/isygold/ocb/main/install.sh) | bash
```

**What the installer does:**
- **On Termux:** Ensures `proot-distro` and `ubuntu` are installed, installs dependencies (`python3`, `sqlite3`, `git`, `zstd`, `tar`, `curl`), places `oc-auto` in `/usr/local/bin/`, and generates a native Termux `ocb` wrapper in `$PREFIX/bin/ocb` that preserves your current working directory.
- **On Linux / WSL:** Installs dependencies and places `ocb` (`/usr/local/bin/oc-auto`) directly in your system `PATH`.

### Manual Install

```bash
git clone [https://github.com/isygold/ocb.git](https://github.com/isygold/ocb.git)
cd ocb
chmod +x install.sh oc-auto
./install.sh
```

---

## Usage

Run `ocb` inside any project folder (or anywhere inside `~/projects/`) to launch the interactive menu:

```bash
ocb
```

### Interactive Menu Controls

| Section | Action | Description |
| :--- | :--- | :--- |
| **OPENCODE -> FREEBUFF** | `[1..N]` | Select an OpenCode session to package its context & diff and resume a target Freebuff thread. |
| **FREEBUFF -> OPENCODE** | `[1..N]` | Select a Freebuff thread to package its context & diff and resume a target OpenCode session. |
| **WORKSPACE** | `New session` | Start a clean session in the current or a new `~/projects/<slug>` directory. |
| **WORKSPACE** | `Git health` | Audit `.git/index`, stale `.lock` files, branches, and `opencode-latest` tags. |
| **WORKSPACE** | `Backup tools` | Archive `Both`, `OpenCode only`, or `Freebuff only` as a `.tzst` snapshot in `Download/TOOL BACKUP`. |
| **WORKSPACE** | `Restore tools` | Select a `.tzst` snapshot from `Download/TOOL BACKUP` and selectively restore either or both tools. |

### Direct CLI Flags

```bash
ocb --health    # Run Git repository health audit and auto-repair
ocb --backup    # Create a selective .tzst backup in Download/TOOL BACKUP
ocb --restore   # Restore tools/configs/sessions from a .tzst backup
ocb --version   # Print installed ocb version
```

---

## Requirements

- **Agents:** [OpenCode](https://opencode.ai) (`opencode`) and/or [Freebuff](https://freebuff.com) (`freebuff`) installed inside your Linux / `proot-distro` environment.
- **System Packages:** `bash`, `python3`, `sqlite3`, `git`, `zstd`, `tar` (installed automatically by `install.sh`).
- **Termux Storage (for Backups):** Run `termux-setup-storage` once in Termux so `/sdcard/Download` is accessible.

---

## AI & Safety Disclaimer

This project was developed with AI assistance. While `ocb` has been tested on Termux (Ubuntu `proot-distro`) and Linux environments, operations such as SQLite session pruning, Git index repairs, and `.tzst` archive restores modify local files and configurations. Always verify your backups before restoring over active setups. `ocb` is an independent community utility and is not officially affiliated with OpenCode or Freebuff.

---

## License

MIT
