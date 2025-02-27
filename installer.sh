#!/usr/bin/env bash

set -e

# Detect OS and install required packages
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  echo "Running on Linux"
  sudo apt-get update
  for PACKAGE in "${PACKAGES_LINUX[@]}"; do
    if ! dpkg -s $PACKAGE &>/dev/null; then
      echo "Installing $PACKAGE..."
      sudo apt-get install -y $PACKAGE
    else
      echo "$PACKAGE is already installed."
    fi
  done
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  echo "Running on Windows"
  for PACKAGE in "${PACKAGES_WINDOWS[@]}"; do
    if ! command -v $PACKAGE &>/dev/null; then
      echo "Installing $PACKAGE..."
      choco install $PACKAGE -y
    else
      echo "$PACKAGE is already installed."
    fi
  done
else
  echo "Unsupported OS type: $OSTYPE"
  exit 1
fi

sudo apt update && sudo apt upgrade -y
sudo apt autoremove
rm -rf ~/neovim/
rm -rf ~/.config/dotfiles/
skip_system_packages="${1}"

os_type="$(uname -s)"

apt_packages="curl git iproute2 python3 python3-pip cmake ripgrep tmux zsh ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip doxygen gpg curl gawk"
apt_packages_optional="gnupg htop npm rsync zsh-syntax-highlighting zsh-autosuggestions fonts-firacode"

# Ensure necessary directories exist
mkdir -p ~/.local/share/fonts ~/.config ~/.zsh ~/.tmux
rm -rf $HOME/.dotfiles
# Clean up unusual directories
# unusual_dirs=($HOME/neovim ~/neovim ~/.config/Dotfiles ~/.config/dotfiles ~/.config/.dotfiles ~/.zshrc ~/.aliases ~/.asdf ~/.config/nvim)
# for dir in "${unusual_dirs[@]}"; do
#     [ -e "$dir" ] && rm -rf "$dir"
# done

###############################################################################
# Detect OS and distro type
###############################################################################

# Detect OS and install required packages
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  echo "Running on Linux"
  sudo apt-get update
  for PACKAGE in "${PACKAGES_LINUX[@]}"; do
    if ! dpkg -s $PACKAGE &>/dev/null; then
      echo "Installing $PACKAGE..."
      sudo apt-get install -y $PACKAGE
    else
      echo "$PACKAGE is already installed."
    fi
  done
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  echo "Running on Windows"
  for PACKAGE in "${PACKAGES_WINDOWS[@]}"; do
    if ! command -v $PACKAGE &>/dev/null; then
      echo "Installing $PACKAGE..."
      choco install $PACKAGE -y
    else
      echo "$PACKAGE is already installed."
    fi
  done
else
  echo "Unsupported OS type: $OSTYPE"
  exit 1
fi

###############################################################################
###############################################################################

function no_system_packages {
  cat <<EOF
This script will ONLY install neovim, zsh, tmux.
Nothing big, just what I have researched and copied from good developers and things that will work just right for myself.
EOF
  exit 1
}

case "${os_type}" in
Linux*)
  os_type="Linux"
  if [ ! -f "/etc/debian_version" ]; then
    [ -z "${skip_system_packages}" ] && no_system_packages
  fi
  ;;
Darwin*) os_type="macOS" ;;
CYGWIN* | MINGW32* | MSYS* | MINGW*)
  os_type="Windows"
  ;;
*)
  os_type="Other"
  [ -z "${skip_system_packages}" ] && no_system_packages
  ;;
esac

###############################################################################
# Install packages using your OS' package manager
###############################################################################

function apt_install_packages {
  sudo apt-get update && sudo apt-get install -y ${apt_packages} ${apt_packages_optional}
}

function display_packages {
  if [ "${os_type}" == "Linux" ]; then
    echo "${apt_packages} ${apt_packages_optional}"
  else
    echo "${brew_packages} ${brew_packages_optional}"
  fi
}

if [ -z "${skip_system_packages}" ]; then
  cat <<EOF
If you choose yes, all of the system packages below will be installed:
$(display_packages)
If you choose no, the above packages will not be installed and this script will exit. This gives you a chance to edit the list of packages if you don't agree with any of the decisions.
The packages listed after zsh are technically optional but are quite useful. Keep in mind if you don't install pwgen you won't be able to generate random passwords using a custom alias that's included in these dotfiles.
EOF
  while true; do
    read -rp "Do you want to install the above packages? (y/n) " yn
    case "${yn}" in
    [Yy]*)
      if [ "${os_type}" == "Linux" ]; then
        apt_install_packages
      else
        brew_install_packages
      fi
      break
      ;;
    [Nn]*) exit 0 ;;
    *) echo "Please answer y or n" ;;
    esac
  done
else
  echo "System package installation was skipped!"
fi

###############################################################################
# NVIM FROM SOURCE
###############################################################################

git clone https://github.com/neovim/neovim
cd neovim && make
sudo make install
cd ..
rm -rf ~/neovim

###############################################################################
# Install NerdFonts
###############################################################################

rm -rf ~/.cache/fontconfig/*

wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip &&
  cd ~/.local/share/fonts &&
  unzip JetBrainsMono.zip &&
  rm JetBrainsMono.zip &&
  fc-cache -fv

###############################################################################
# Clone dotfiles
###############################################################################

read -rep $'\nWhere do you want to clone these dotfiles to [~/.config/dotfiles]? ' clone_path
clone_path="${clone_path:-"${HOME}/.config/dotfiles"}"

# Ensure path doesn't exist.
while [ -e "${clone_path}" ]; do
  read -rep $'\nPath exists, try again? (y) ' y
  case "${y}" in
  [Yy]*)
    break
    ;;
  *) echo "Please answer y or CTRL+c the script to abort everything" ;;
  esac
done

echo

# This is used to locally develop the install script.
if [ "${DEBUG}" == "1" ]; then
  cp -R "${PWD}/." "${clone_path}"
else
  git clone https://github.com/ryucode2/dotfiles.git "${clone_path}"
fi

###############################################################################
# Install fzf (fuzzy finder on the terminal and used by a Vim plugin)
###############################################################################

rm -rf "${HOME}/.local/share/fzf"
git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.local/share/fzf" &&
  yes | "${HOME}/.local/share/fzf/install" --bin --no-update-rc

###############################################################################
# Carefully create symlinks
###############################################################################

mkdir -p "${HOME}/.config/.tmux"

cat <<EOF
-------------------------------------------------------------------------------
ln -fs "${clone_path}/zsh/.zshrc" "${HOME}/.zsh/.zshrc"
ln -fs "${clone_path}/zsh/.aliases" "${HOME}/.zsh.aliases"
ln -fs "${clone_path}/tmux/.tmux.conf" "${HOME}/.tmux/.tmux.conf"
ln -fs "${clone_path}/nvim" "${HOME}/.config"
-------------------------------------------------------------------------------
EOF

while true; do
  read -rep $'\nReady to continue and apply the symlinks? (y) ' y
  case "${y}" in
  [Yy]*)
    break
    ;;
  *) echo "Please answer y or CTRL+c the script to abort everything" ;;
  esac
done

ln -fs "${clone_path}/zsh/.zshrc" "${HOME}/.zshrc" &&
  ln -fs "${clone_path}/zsh/.aliases" "${HOME}/.aliases" &&
  ln -fs "${clone_path}/.tmux/.tmux.conf" "${HOME}/.tmux.conf" &&
  ln -fs "${clone_path}/nvim/" "${HOME}/.config/nvim"

if grep -qE "(Microsoft|microsoft|WSL)" /proc/version &>/dev/null; then
  sudo ln -fs "${clone_path}/etc/wsl.conf" /etc/wsl.conf
fi

###############################################################################
# Install tmux plugins
###############################################################################

printf "\n\nInstalling tmux plugins...\n"

# Ensure tmux plugin manager is installed
if [ ! -d "${HOME}/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
fi

export TMUX_PLUGIN_MANAGER_PATH="${HOME}/.tmux/plugins"
"${HOME}/.tmux/plugins/tpm/bin/install_plugins"

###############################################################################
# Change default shell to zsh
###############################################################################

[ "${os_type}" != "macOS" ] && chsh -s "$(command -v zsh)"

###############################################################################
# Done!
###############################################################################

cat <<EOF
Everything was installed successfully!
Your new system will restart now!
EOF
exit 0
