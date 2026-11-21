#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/isygold/ocb/v2.2"
# Bump together with REPO_RAW and VERSION in oc-auto on every release.
EXPECTED_VERSION="2.2.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

if [ -d "/data/data/com.termux" ] && command -v pkg >/dev/null 2>&1; then
  command -v proot-distro >/dev/null 2>&1 || pkg install -y proot-distro
  if ! proot-distro list 2>/dev/null | grep -q "ubuntu.*installed"; then
    echo "Installing Ubuntu proot-distro..."
    proot-distro install ubuntu
  fi

  if [ -f "$SCRIPT_DIR/oc-auto" ]; then
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
  SUDO=""; [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null 2>&1 && SUDO="sudo"
  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update -qq && $SUDO apt-get install -y -qq python3 sqlite3 git zstd tar curl >/dev/null
  fi
  # Stage first so a mismatched engine never reaches the system path.
  TMP_ENGINE=$(mktemp)
  trap 'rm -f "$TMP_ENGINE"' EXIT
  if [ -f "$SCRIPT_DIR/oc-auto" ]; then
    cp "$SCRIPT_DIR/oc-auto" "$TMP_ENGINE"
  else
    curl -fsSL "$REPO_RAW/oc-auto" -o "$TMP_ENGINE"
  fi
  verify_engine "$TMP_ENGINE" || exit 1
  $SUDO install -m 755 "$TMP_ENGINE" /usr/local/bin/oc-auto
  $SUDO ln -sf /usr/local/bin/oc-auto /usr/local/bin/ocb
  echo "Done! Run: ocb"
fi
