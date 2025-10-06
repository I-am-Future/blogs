#!/bin/bash

set -e

# ------------------ Default Configuration ------------------
INSTALL_BASIC=false
INSTALL_NV_DRIVER=false
INSTALL_CUDA_TOOLKIT=false
INSTALL_MINICONDA=false
INSTALL_BLE_SH=false
CUDA_VERSION="12.1"

print_usage() {
  cat <<EOF
Usage: $0 [--basic] [--driver] [--cuda=<version>] [--conda] [--ble]

  --basic            Install base system packages (requires sudo).
  --driver           Install NVIDIA driver (requires sudo).
  --cuda=<version>   Install CUDA Toolkit for the given version (requires sudo). Default: ${CUDA_VERSION}
  --conda            Install Miniconda for current user (no sudo).
  --ble              Install ble.sh for current user (no sudo).
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
    software-properties-common ca-certificates gnupg lsb-release
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
  echo "[3] Installing CUDA Toolkit $CUDA_VERSION (requires sudo)..."

  CUDA_REPO_PIN="cuda-ubuntu2204.pin"
  wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/${CUDA_REPO_PIN}
  sudo mv ${CUDA_REPO_PIN} /etc/apt/preferences.d/cuda-repository-pin-600
  sudo apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/7fa2af80.pub
  sudo add-apt-repository -y "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /"
  sudo apt update
  sudo apt install -y cuda-toolkit-${CUDA_VERSION//./-}

  # Add CUDA to PATH
  if ! grep -q "/usr/local/cuda/bin" ~/.bashrc; then
    echo 'export PATH=/usr/local/cuda/bin:$PATH' >> ~/.bashrc
    echo 'export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
  fi

  echo "CUDA Toolkit $CUDA_VERSION installation complete."
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

  echo "[5] Installing common Python packages via conda..."
  conda install -y numpy scipy matplotlib ipython jupyter pandas scikit-learn
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

echo "[✅ DONE] All tasks completed."
# shellcheck disable=SC1090
[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"
