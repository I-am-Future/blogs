#!/bin/bash
#
# Ubuntu Software Installation Script
# Author: Lai Wei
# Website: https://i-am-future.github.io/
#

set -e

# ------------------ Default Configuration ------------------
INSTALL_BASIC=false
INSTALL_NV_DRIVER=false
INSTALL_CUDA_TOOLKIT=false
INSTALL_MINICONDA=false
INSTALL_BLE_SH=false
INSTALL_COMMON=false
CUDA_VERSION="12.1"

print_usage() {
  cat <<EOF
Usage: $0 [--basic] [--driver] [--cuda=<version>] [--conda] [--ble] [--common]

  --basic            Install base system packages (requires sudo).
  --driver           Install NVIDIA driver (requires sudo).
  --cuda=<version>   Show CUDA Toolkit download link for the given version. Default: ${CUDA_VERSION}
  --conda            Install Miniconda for current user (no sudo).
  --ble              Install ble.sh for current user (no sudo).
  --common           Show common software download links.
EOF
}

# ------------------ Argument Parsing ------------------
for arg in "$@"; do
  case $arg in
    --basic)
      INSTALL_BASIC=true
      ;;
    --driver)
      INSTALL_NV_DRIVER=true
      ;;
    --cuda=*)
      INSTALL_CUDA_TOOLKIT=true
      CUDA_VERSION="${arg#*=}"
      ;;
    --conda)
      INSTALL_MINICONDA=true
      ;;
    --ble)
      INSTALL_BLE_SH=true
      ;;
    --common)
      INSTALL_COMMON=true
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg"
      print_usage
      exit 1
      ;;
  esac
done

# ------------------ Base Tools (now gated by --basic) ------------------
if $INSTALL_BASIC; then
  echo "[1] Updating system and installing base packages (requires sudo)..."
  sudo apt update && sudo apt upgrade -y
  sudo apt install -y \
    build-essential git curl wget unzip tmux htop zsh vim net-tools \
    software-properties-common ca-certificates gnupg lsb-release gawk
else
  echo "[1] Skipping base tools (use --basic to install system packages)."
fi

# ------------------ NVIDIA Driver ------------------
if $INSTALL_NV_DRIVER; then
  echo "[2] Installing NVIDIA driver (requires sudo)..."
  sudo apt --purge remove "*nvidia*" -y || true
  sudo apt update
  sudo apt install -y ubuntu-drivers-common
  sudo ubuntu-drivers devices
  sudo ubuntu-drivers autoinstall
  echo "NVIDIA driver installation complete. A reboot may be required."
fi

# ------------------ CUDA Toolkit ------------------
if $INSTALL_CUDA_TOOLKIT; then
  echo "[3] CUDA Toolkit $CUDA_VERSION Download Information"
  echo "======================================================"
  echo ""
  echo "CUDA Toolkit installation varies by system configuration."
  echo "Please download and install CUDA Toolkit manually from:"
  echo ""
  # Convert version format: 
  # If x.y is given -> x-y-0
  # If x.y.z is given -> x-y-z
  if [[ "$CUDA_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Version already has patch number (x.y.z)
    CUDA_VERSION_URL=$(echo "$CUDA_VERSION" | sed 's/\./-/g')
  else
    # Version is x.y, append .0 then convert
    CUDA_VERSION_URL=$(echo "$CUDA_VERSION" | sed 's/\./-/g')-0
  fi
  echo "  https://developer.nvidia.com/cuda-${CUDA_VERSION_URL}-download-archive?target_os=Linux"
  echo ""
  
  # Add CUDA to PATH in .bashrc if not already present
  if ! grep -q "/usr/local/cuda/bin" ~/.bashrc; then
    echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
    echo "✅ CUDA paths have been added to ~/.bashrc"
  else
    echo "ℹ️  CUDA paths already exist in ~/.bashrc"
  fi
  
fi

# ------------------ Miniconda ------------------
if $INSTALL_MINICONDA; then
  echo "[4] Installing Miniconda (no sudo)..."
  cd /tmp
  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
  bash miniconda.sh -b -p "$HOME/miniconda"
  echo 'export PATH="$HOME/miniconda/bin:$PATH"' >> ~/.bashrc
  export PATH="$HOME/miniconda/bin:$PATH"
  conda init bash || true
  # Reload shell config for current session if possible
  if [ -f "$HOME/.bashrc" ]; then
    # shellcheck disable=SC1090
    source "$HOME/.bashrc"
  fi
  echo "Miniconda installation complete."
fi

# ------------------ BLE.sh ------------------
if $INSTALL_BLE_SH; then
  echo "[#] Installing ble.sh (Bash Line Editor) (no sudo)..."

  git clone --recursive --depth 1 --shallow-submodules \
    https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh-tmp

  make -C /tmp/ble.sh-tmp install PREFIX="$HOME/.local"

  rm -rf /tmp/ble.sh-tmp

  grep -qxF 'source ~/.local/share/blesh/ble.sh' ~/.bashrc \
    || echo 'source ~/.local/share/blesh/ble.sh' >> ~/.bashrc

  echo "✅ ble.sh installed and configured. Restart terminal or run 'source ~/.bashrc' to start using."
fi

# ------------------ Common Software Links ------------------
if $INSTALL_COMMON; then
  echo "[#] Common Software Download Links"
  echo "======================================================"
  echo ""
  echo "Here are some commonly used software download links:"
  echo ""
  echo "  🖱️  Cursor (AI Code Editor):"
  echo "     https://cursor.com/"
  echo ""
  echo "  💻 Visual Studio Code:"
  echo "     https://code.visualstudio.com/download"
  echo ""
  echo "  🌐 Google Chrome:"
  echo "     https://www.google.com/chrome/dr/download/"
  echo ""
  echo "======================================================"
fi

echo "[✅ DONE] All tasks completed."
# shellcheck disable=SC1090
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"
