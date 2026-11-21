#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/isygold/ocb/v2.1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
  if [ -f "$SCRIPT_DIR/oc-auto" ]; then
    $SUDO cp "$SCRIPT_DIR/oc-auto" /usr/local/bin/oc-auto
  else
    $SUDO curl -fsSL "$REPO_RAW/oc-auto" -o /usr/local/bin/oc-auto
  fi
  $SUDO chmod +x /usr/local/bin/oc-auto
  $SUDO ln -sf /usr/local/bin/oc-auto /usr/local/bin/ocb
  echo "Done! Run: ocb"
fi
