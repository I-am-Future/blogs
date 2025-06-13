#!/bin/bash

set -e

# ------------------ Default Configuration ------------------
INSTALL_NV_DRIVER=false
INSTALL_CUDA_TOOLKIT=false
INSTALL_MINICONDA=false
INSTALL_BLE_SH=false
CUDA_VERSION="12.1"

# ------------------ Argument Parsing ------------------
for arg in "$@"; do
  case $arg in
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
    *)
      echo "Unknown argument: $arg"
      echo "Usage: $0 [--driver] [--cuda=<version>] [--conda] [--ble]"
      exit 1
      ;;
  esac
done

# ------------------ Base Tools ------------------
echo "[1] Updating system and installing base packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git curl wget unzip tmux htop zsh vim net-tools software-properties-common ca-certificates gnupg lsb-release

# ------------------ NVIDIA Driver ------------------
if $INSTALL_NV_DRIVER; then
  echo "[2] Installing NVIDIA driver..."
  sudo apt --purge remove "*nvidia*" -y || true
  sudo apt update
  sudo apt install -y ubuntu-drivers-common
  sudo ubuntu-drivers devices
  sudo ubuntu-drivers autoinstall
  echo "NVIDIA driver installation complete. A reboot may be required."
fi

# ------------------ CUDA Toolkit ------------------
if $INSTALL_CUDA_TOOLKIT; then
  echo "[3] Installing CUDA Toolkit $CUDA_VERSION..."

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
  echo "[4] Installing Miniconda..."
  cd /tmp
  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
  bash miniconda.sh -b -p $HOME/miniconda
  echo 'export PATH="$HOME/miniconda/bin:$PATH"' >> ~/.bashrc
  export PATH="$HOME/miniconda/bin:$PATH"
  conda init bash
  source ~/.bashrc
  echo "Miniconda installation complete."

  echo "[5] Installing common Python packages via conda..."
  conda install -y numpy scipy matplotlib ipython jupyter pandas scikit-learn
fi

# ------------------ BLE.sh ------------------
if $INSTALL_BLE_SH; then
  echo "[#] Installing ble.sh (Bash Line Editor)..."

  sudo apt update
  sudo apt install -y git make gawk

  git clone --recursive --depth 1 --shallow-submodules \
    https://github.com/akinomyoga/ble.sh.git /tmp/ble.sh-tmp

  make -C /tmp/ble.sh-tmp install PREFIX="$HOME/.local"

  rm -rf /tmp/ble.sh-tmp

  grep -qxF 'source ~/.local/share/blesh/ble.sh' ~/.bashrc \
    || echo 'source ~/.local/share/blesh/ble.sh' >> ~/.bashrc

  echo "✅ ble.sh installed and configured. Restart terminal or run 'source ~/.bashrc' to start using."
fi

# ------------------ Additional Software ------------------
echo "[6] Installing additional software..."
# sudo snap install code --classic
# sudo apt install -y vlc gnome-tweaks

echo "[✅ DONE] All tasks completed. Please reboot the system if NVIDIA driver was installed."
source ~/.bashrc
