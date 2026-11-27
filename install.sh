#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/isygold/ocb/v2.3"
# Bump together with REPO_RAW and VERSION in oc-auto on every release.
EXPECTED_VERSION="2.3.0"
# Piped installs (curl ... | bash) have no script path, so a sibling oc-auto can
# only be used when this file actually exists on disk.
SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# The installer is pinned to a release branch, so a forgotten bump ships an old
# engine silently. Fail loudly instead of installing the wrong version.
verify_engine() {
  local file="$1" found
  found=$(sed -n 's/^VERSION="\([^"]*\)".*/\1/p' "$file" 2>/dev/null | head -1)
  if [ "$found" != "$EXPECTED_VERSION" ]; then
    echo "ocb install aborted: fetched engine is v${found:-unknown}, expected v$EXPECTED_VERSION." >&2
    echo "REPO_RAW ($REPO_RAW) does not carry this release; fix REPO_RAW and EXPECTED_VERSION together." >&2
    return 1
  fi
}

echo "Installing ocb (OpenCode <-> Freebuff Bridge)..."

# Only a Termux host needs the proot wrapper. Inside the Ubuntu container both
# /data/data/com.termux and Termux's bin stay visible, and proot-distro refuses
# to run, so key off $PREFIX (as oc-auto does) and exclude proot sessions.
in_termux_host() {
  case "${PREFIX:-}" in
    *com.termux*) ;;
    *) return 1 ;;
  esac
  [ -z "${PROOT_L2S_DIR:-}${PROOT_TMP_DIR:-}" ]
}

if in_termux_host; then
  command -v proot-distro >/dev/null 2>&1 || pkg install -y proot-distro
  if ! distros=$(proot-distro list 2>/dev/null); then
    echo "ocb install aborted: proot-distro is not usable from this shell." >&2
    echo "Run the installer from Termux, not from inside the Ubuntu container." >&2
    exit 1
  fi
  if ! grep -q "ubuntu.*installed" <<<"$distros"; then
    echo "Installing Ubuntu proot-distro..."
    proot-distro install ubuntu
  fi

  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/oc-auto" ]; then
    cp "$SCRIPT_DIR/oc-auto" "$PREFIX/tmp/oc-auto.install"
  else
    curl -fsSL "$REPO_RAW/oc-auto" -o "$PREFIX/tmp/oc-auto.install"
  fi
  verify_engine "$PREFIX/tmp/oc-auto.install" || { rm -f "$PREFIX/tmp/oc-auto.install"; exit 1; }

  proot-distro login ubuntu -- bash -c "
    apt-get update -qq && apt-get install -y -qq python3 sqlite3 git zstd tar curl >/dev/null
    mv /data/data/com.termux/files/usr/tmp/oc-auto.install /usr/local/bin/oc-auto
    chmod +x /usr/local/bin/oc-auto
    ln -sf /usr/local/bin/oc-auto /usr/local/bin/ocb
  "

  cat << 'WRAP' > "$PREFIX/bin/ocb"
#!/usr/bin/env bash
REL_DIR="."
case "$PWD" in
  /data/data/com.termux/files/home*)
    REL_DIR="${PWD#/data/data/com.termux/files/home}"
    REL_DIR="${REL_DIR#/}"
    [ -z "$REL_DIR" ] && REL_DIR="."
    ;;
esac
exec proot-distro login ubuntu --shared-tmp -- bash -lc "
  export TERMUX_HOME=/data/data/com.termux/files/home
  cd \"\$TERMUX_HOME/$REL_DIR\" 2>/dev/null || cd \"\$TERMUX_HOME\"
  exec /usr/local/bin/oc-auto \"\$@\"
" -- "$@"
WRAP
  chmod +x "$PREFIX/bin/ocb"
  echo "Done! Run: ocb"
else
  # Native host: Linux/WSL, a proot container, or macOS. Use whatever package
  # manager and install prefix exists instead of assuming Debian with a
  # writable /usr/local/bin.
  SUDO=""; [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1 && SUDO="sudo"

  install_deps() {
    if command -v apt-get >/dev/null 2>&1; then
      $SUDO apt-get update -qq && $SUDO apt-get install -y -qq python3 sqlite3 git zstd tar curl >/dev/null
    elif command -v dnf >/dev/null 2>&1; then
      $SUDO dnf install -y python3 sqlite git zstd tar curl >/dev/null
    elif command -v yum >/dev/null 2>&1; then
      $SUDO yum install -y python3 sqlite git zstd tar curl >/dev/null
    elif command -v pacman >/dev/null 2>&1; then
      $SUDO pacman -Sy --noconfirm python sqlite git zstd tar curl >/dev/null
    elif command -v apk >/dev/null 2>&1; then
      $SUDO apk add --no-cache python3 sqlite git zstd tar curl >/dev/null
    elif command -v brew >/dev/null 2>&1; then
      brew install python3 sqlite git zstd curl >/dev/null
    else
      echo "No known package manager; install python3, sqlite3, git, zstd, tar and curl manually." >&2
    fi
  }
  install_deps

  # Containers and admin-less hosts may not allow /usr/local/bin; ~/.local/bin
  # is also where `ocb install` puts its launcher.
  if [ "$(id -u)" -eq 0 ] || [ -w /usr/local/bin ] || [ -n "$SUDO" ]; then
    TARGET_DIR="/usr/local/bin"
  else
    TARGET_DIR="$HOME/.local/bin"
  fi
  [ -d "$TARGET_DIR" ] || $SUDO mkdir -p "$TARGET_DIR"

  # Stage first so a mismatched engine never reaches the install path.
  TMP_ENGINE=$(mktemp)
  trap 'rm -f "$TMP_ENGINE"' EXIT
  if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/oc-auto" ]; then
    cp "$SCRIPT_DIR/oc-auto" "$TMP_ENGINE"
  else
    curl -fsSL "$REPO_RAW/oc-auto" -o "$TMP_ENGINE"
  fi
  verify_engine "$TMP_ENGINE" || exit 1
  $SUDO install -m 755 "$TMP_ENGINE" "$TARGET_DIR/oc-auto"
  $SUDO ln -sf "$TARGET_DIR/oc-auto" "$TARGET_DIR/ocb"
  echo "Done! Run: ocb"
  case ":$PATH:" in
    *":$TARGET_DIR:"*) ;;
    *) echo "Add $TARGET_DIR to PATH: export PATH=\"$TARGET_DIR:\$PATH\"" ;;
  esac
fi
