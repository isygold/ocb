# ocb

A user-controlled, cross-agent terminal handoff bridge between **OpenCode**, **Freebuff**, and other CLI AI tools—built for **Termux** (via Ubuntu `proot-distro`) and **Linux / WSL**.

`ocb` lets you switch seamlessly between AI coding agents when rate limits hit or when you want a second agent's perspective—preserving your conversation context, recent tool/file actions, working `git diff`, and continuous thread history without manual copy-pasting or accidental keystroke triggers.

```text
  █▀▀█ █▀▀ █▀▀▄   ocb v2.1.0
  █  █ █   █▀▀▄   cross-agent control · my-project
  ▀▀▀▀ ▀▀▀ ▀▀▀    ------------------------------------
```

---

## Features

> [!TIP]
> **Extensible Multi-Agent Registry (`~/.config/ocb/agents.json`)**
> Auto-detects installed CLIs (`opencode`, `freebuff`, `claude`, `aider`, `gemini`, `codex`) and lets you pick the exact **Source → Target** tool and thread.

> [!NOTE]
> **Full Tool-Action & Diff Handoff (`.bridge-handoff.md`)**
> Extracts both conversation history and OpenCode's recent `tool`/file actions alongside `git status`, recent commits, and working diffs (automatically ignored via `.git/info/exclude`), while passing direct startup handoff directives to target agents like Freebuff.
>
> **v2.1.0:** the package opens with a `## Task State` block (where the previous agent stopped, upstream sync, changed paths, stashes), scopes the action log to the current worktree, captures **untracked file contents**, and warns you when the tree is clean so an empty handoff can't be mistaken for finished work.

> [!IMPORTANT]
> **Input-Safe Interactive Control & Continuous Thread Resume**
> Resumes existing project sessions directly (`opencode -s <id>` and `freebuff --continue <id>`), drains buffered keystrokes after loading steps, rejects accidental empty `Enter` presses, exits cleanly on `Ctrl+C`, and displays elapsed-time spinners plus UTF-8 progress bars.

- **Workspace Isolation & Git Safety:** Keeps sessions scoped inside `~/projects/<slug>`, creates automatic checkpoint tags (`opencode-latest`), and includes an interactive `.git` lock/index health auditor (`ocb health`).
- **Selective `.tzst` Backup, Restore & Uninstall:** Compresses and restores individual or all detected agents (binaries, configs, and session databases) to `Download/TOOL BACKUP` using multi-threaded `zstd`, and includes a two-stage `ocb uninstall` flow that preserves backups and project repos.

---

## Quick Install

### Termux (Android) & Linux / WSL

```bash
curl -fsSL https://raw.githubusercontent.com/isygold/ocb/v2.1/install.sh | bash
```

**What the installer does:**
- **On Termux:** Ensures `proot-distro` and `ubuntu` are installed, installs dependencies (`python3`, `sqlite3`, `git`, `zstd`, `tar`, `curl`), places `oc-auto` in `/usr/local/bin/`, and generates a native Termux `ocb` wrapper in `$PREFIX/bin/ocb` that preserves your current working directory and handles clean two-stage uninstalls.
- **On Linux / WSL:** Installs dependencies and places `ocb` (`/usr/local/bin/oc-auto`) directly in your system `PATH`.

### Manual Install

```bash
git clone -b v2.1 https://github.com/isygold/ocb.git
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

| Option | Action | Description |
| :--- | :--- | :--- |
| `[1]` | **Bridge agents** | Choose source tool, session, target tool, and thread to package context/diff and launch. |
| `[2]` | **New project folder** | Create or switch to `~/projects/<name>` and initialize Git. |
| `[3]` | **Git health** | Audit `.git/index`, stale `.lock` files, branches, and `opencode-latest` tags. |
| `[4]` | **Backup tools** | Create a selective `.tzst` snapshot of detected tools in `Download/TOOL BACKUP`. |
| `[5]` | **Restore tools** | Select a `.tzst` snapshot from `Download/TOOL BACKUP` and selectively restore tools/configs. |
| `[6]` | **Agents registry** | Inspect detected CLIs and `~/.config/ocb/agents.json`. |
| `[7]` | **Uninstall ocb** | Safely remove the `ocb` binary and config after typing `UNINSTALL` (preserves backups and repos). |
| `[8]` | **Exit** | Close cleanly without launching an agent. |

### Direct CLI Commands

```bash
ocb                         # Launch interactive user-controlled menu
ocb bridge [src] [tgt]      # Direct cross-agent handoff (optional --new for fresh thread)
ocb agents                  # List detected tools & registry path
ocb backup [all|<agent>]    # Create a selective .tzst backup in Download/TOOL BACKUP
ocb restore                 # Restore tools/configs/sessions from a .tzst backup
ocb health                  # Run Git repository health audit and auto-repair
ocb uninstall               # Cleanly remove ocb binary & config (preserves backups)
ocb --version               # Print installed ocb version
```

---

## Requirements

- **Agents:** [OpenCode](https://opencode.ai) (`opencode`), [Freebuff](https://freebuff.com) (`freebuff`), or any supported CLI agent installed inside your Linux / `proot-distro` environment.
- **System Packages:** `bash`, `python3`, `sqlite3`, `git`, `zstd`, `tar` (installed automatically by `install.sh`).
- **Termux Storage (for Backups):** Run `termux-setup-storage` once in Termux so `/sdcard/Download` is accessible.

---

## AI & Safety Disclaimer

> [!WARNING]
> This project was developed with AI assistance. While `ocb` has been tested on Termux (Ubuntu `proot-distro`) and Linux environments, operations such as SQLite session pruning, Git index repairs, `.tzst` archive restores, and uninstallation modify local files and configurations. Always verify your backups before restoring over active setups. `ocb` is an independent community utility and is not officially affiliated with OpenCode or Freebuff.

---

## License

MIT
