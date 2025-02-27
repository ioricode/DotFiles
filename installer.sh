#!/usr/bin/env bash

set -e

echo "Running on $(uname -s)"

# Variables
skip_system_packages="${1}"
os_type="$(uname -s)"
apt_packages="curl git iproute2 python3 python3-pip cmake ripgrep tmux zsh ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip doxygen gpg curl gawk"
apt_packages_optional="gnupg htop npm rsync zsh-syntax-highlighting zsh-autosuggestions fonts-firacode"

# Functions
function no_system_packages {
    cat <<EOF
This script will ONLY install neovim, zsh, tmux.
EOF
    exit 1
}

function apt_install_packages {
    sudo apt-get update && sudo apt-get install -y ${apt_packages} ${apt_packages_optional}
}

function display_packages {
    echo "${apt_packages} ${apt_packages_optional}"
}

# Detect OS and handle system packages
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

if [ -z "${skip_system_packages}" ]; then
    cat <<EOF
The following packages will be installed:
$(display_packages)
EOF
    while true; do
        read -rp "Do you want to install the above packages? (y/n) " yn
        case "${yn}" in
        [Yy]*)
            apt_install_packages
            break
            ;;
        [Nn]*) exit 0 ;;
        *) echo "Please answer y or n" ;;
        esac
    done
else
    echo "System package installation was skipped!"
fi

# Install NVIM from source
git clone https://github.com/neovim/neovim
cd neovim && make
sudo make install
cd ..
rm -rf ~/neovim

# Install NerdFonts
rm -rf ~/.cache/fontconfig/*
wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip &&
    cd ~/.local/share/fonts &&
    unzip JetBrainsMono.zip &&
    rm JetBrainsMono.zip &&
    fc-cache -fv -r

rm -rf ~/.config/DotFiles
# Clone dotfiles
read -rep $'\nWhere do you want to clone these dotfiles to [~/.config/dotfiles]? ' clone_path
clone_path="${clone_path:-"${HOME}/.config/DotFiles"}"

while [ -e "${clone_path}" ]; do
    read -rep $'\nPath exists, try again? (y) ' y
    case "${y}" in
    [Yy]*) break ;;
    *) echo "Please answer y or CTRL+c the script to abort everything" ;;
    esac
done

if [ "${DEBUG}" == "1" ]; then
    cp -R "${PWD}/." "${clone_path}"
else
    git clone https://github.com/ioricode/DotFiles.git "${clone_path}"
fi

# Install fzf
rm -rf "${HOME}/.local/share/fzf"
git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.local/share/fzf" &&
    yes | "${HOME}/.local/share/fzf/install" --bin --no-update-rc

# Create symlinks
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
    [Yy]*) break ;;
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

# Install tmux plugins
mkdir -p "${HOME}/.config/tmux"

if [ ! -d "${HOME}/.tmux/plugins/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
fi

export TMUX_PLUGIN_MANAGER_PATH="${HOME}/.tmux/plugins"
"${HOME}/.tmux/plugins/tpm/bin/install_plugins"

# Change default shell to zsh "$(command -v zsh)"
[ "${os_type}" != "macOS" ] && chsh -s "$(command -v zsh)"
echo "Default shell changed to zsh. The system will reboot in 10 seconds..."
for i in {10..1}; do
    echo -ne " Rebooting.... $i\033\\n"
    sleep 1
done

sudo reboot
