#!/bin/bash

#
# Copyright (C) 2024-2025 Vladimir `rifux` Blinkov
#
# SPDX-License-Identifier: MIT
#

# Prepare environment variables
set -e  # Exit immediately if any command fails
t="$HOME/.cache/tumbleweed-hyprland-installer"
c="$HOME/.config/"
usr=$(whoami)
term="gnome-terminal --"

# Unified printing function
_log() {
    echo -e "\n$1"
}

_fetch() {
	wget --quiet --progress=bar --show-progress --tries=inf --waitretry=5 $1
}

_gitSparceClone() {
	pwd_dir="$(pwd)"
	git_repo_url="$1"
	shift 1
	git clone --filter=blob:none --sparse "$git_repo_url"
	cd "${git_repo_url##*/}"
	git sparse-checkout add $@
	git checkout
	cd "$pwd_dir"
}

_zypper() {
    _log "Creating symlink 'zy' to 'zypper'"
    sudo ln -s /usr/bin/zypper /usr/bin/zy

    _log "Removing PackageKit aka 'kill my system instead of update'"
    sudo zy rm -u PackageKit gnome-packagekit gnome-software-plugin-packagekit \
	    PackageKit-backend-zypp PackageKit-branding-upstream PackageKit-gstreamer-plugin \
 	    PackageKit-gtk3-module typelib-1_0-PackageKitGlib-1_0

    _log "Disabling recommended packages and openSUSE branding in 'zypp' conf"
    sudo sed -i 's/# solver.onlyRequires = false/solver.onlyRequires = true/g' /etc/zypp/zypp.conf

    _log "Get rid of openSUSE theming"
    sudo zy in \
        branding-upstream libreoffice-branding-upstream NetworkManager-branding-upstream \
        gdm-branding-upstream gio-branding-upstream gnome-menus-branding-upstream \
        gtk2-branding-upstream gtk3-branding-upstream gtk4-branding-upstream

    _log "Adding home:rifux.dev repository"
    sudo zy --gpg-auto-import-keys ar -f https://download.opensuse.org/repositories/home:/rifux.dev/openSUSE_Tumbleweed/home:rifux.dev.repo
    sudo zy ref
}

_system() {
    _log "Enabling Docker service"
    sudo systemctl enable --now docker

    _log "Adding $usr to Docker"
    sudo usermod $usr -aG docker

    _log "Enabling Power Profiles Daemon service"
    sudo systemctl enable --now power-profiles-daemon
}

_fonts() {
    cd "$t"
    _log "Istalling usable Nerd Fonts"
    _gitSparceClone https://github.com/ryanoasis/nerd-fonts \
        "patched-fonts/NerdFontsSymbolsOnly" \
        "patched-fonts/Overpass" \
        "patched-fonts/JetBrainsMono" \
        "patched-fonts/Mononoki" \
        "patched-fonts/FiraCode" \
        "patched-fonts/IBMPlexMono" \
        "patched-fonts/Ubuntu" \
        "patched-fonts/UbuntuSans" \
        "patched-fonts/UbuntuMono" \
        "patched-fonts/Monoid"
    find nerd-fonts -type f -name "*.ttf" -exec mv {} . \;
    rm -rf nerd-fonts
    sudo mv -v *.ttf /usr/share/fonts
}

_defaults() {
    _log "Setting python3 as python"
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
    
    _log "Setting up app defaults"
    xdg-mime default org.gnome.Nautilus.desktop inode/directorydu
    xdg-settings set default-web-browser io.github.zen_browser.zen.desktop
}

_apps() {
    _log "Installing necessary software: work stuff, code editors, terminal, file manager, dev tools, etc."
    sudo zy in --no-confirm --auto-agree-with-licenses	\
        neovim micro-editor helix \
        \
        fish eza bat fd nnn btop progress bmon ncdu NetworkManager-tui fzf tealdeer zoxide \
        \
        terminology terminology-theme-upstream terminology-theme-dark enlightenment enlightenment-branding-upstream \
        \
        mpv \
        \
        mkvtoolnix-gui \
        \
        qbittorrent \
        \
        nemo nemo-extension-audio-tab nemo-extension-compare \
        nemo-extension-image-converter nemo-extension-preview \
        \
        golang gopls git \
        \
        extension-manager gnome-power-manager power-profiles-daemon \
        \
        opi \
        \
        docker \
        \
        pinta shotwell ristretto \
        \
        jetbrains-mono-fonts fetchmsttfonts \
        \
        keepassxc \
        \
        MozillaThunderbird \
        \
        bleachbit czkawka \
        \
        gnome-boxes virtualbox \
        \
        torbrowser-launcher falkon angelfish \
        \
        godot

    opi codecs

    _log "Installing Flatpak apps"
    cat >./install_flatpak_apps.sh <<EOL
#!/usr/bin/sh
rm ./install_flatpak_apps.sh

sleep_time=2

# Unified printing function
_log() {
    echo -e "\n$1"
}

flatinstall()
{
	# Main loop to install and check the package
	while true; do
	# Attempt to install the package
	sudo flatpak install --system --assumeyes \$1
	
	# Check if the package is installed
	if ! [ -z "\$(flatpak list --app | grep "\$1")" ]; then
		echo "\$1 successfully installed."
		break
	else
		# Wait for the specified delay before retrying
		echo "Installation failed. Retrying in \$((sleep_time * 3)) seconds..."
		sleep \$((sleep_time * 3))
	fi
	done
}

_log "Installing LocalSend"
flatinstall org.localsend.localsend_app

_log "Installing Media apps"
flatinstall io.freetubeapp.FreeTube
flatinstall com.github.neithern.g4music
flatinstall com.github.unrud.VideoDownloader
flatinstall net.fasterland.converseen
flatinstall garden.jamie.Morphosis
flatinstall info.febvre.Komikku
flatinstall net.agalwood.Motrix
flatinstall io.github.jliljebl.Flowblade
flatinstall com.github.wwmm.easyeffects

_log "Installing Upscayl"
flatinstall org.upscayl.Upscayl

_log "Installing Chatting software"
flatinstall im.nheko.Nheko
flatinstall im.fluffychat.Fluffychat
flatinstall org.ferdium.Ferdium
flatinstall chat.revolt.RevoltDesktop
flatinstall io.github.milkshiift.GoofCord

_log "Installing Productivity software: coding"
flatinstall com.jetpackduba.Gitnuro
flatinstall com.mardojai.ForgeSparks
flatinstall io.github.nokse22.asciidraw
flatinstall me.iepure.devtoolbox
flatinstall io.github.fizzyizzy05.binary
flatinstall net.werwolv.ImHex
flatinstall org.gaphor.Gaphor
flatinstall io.github.ungoogled_software.ungoogled_chromium

_log "Installing Productivity software: general"
flatinstall org.garudalinux.firedragon
flatinstall org.onlyoffice.desktopeditors
flatinstall io.gitlab.idevecore.Pomodoro
flatinstall io.github.alainm23.planify
flatinstall com.github.flxzt.rnote
flatinstall com.github.tenderowl.frog
flatinstall com.beavernotes.beavernotes
flatinstall org.kde.CrowTranslate
flatinstall io.github.nokse22.minitext
flatinstall io.github.wazzaps.Fingerpaint
flatinstall io.github.amit9838.mousam

_log "Installing customization software"
flatinstall com.github.tchx84.Flatseal

_log "Installing gaming software"
flatinstall page.kramo.Cartridges
flatinstall org.ryujinx.Ryujinx

echo -e "[ THE SCRIPT IS DONE. EXITING IN 5sec. ]"
sleep 5
EOL
    chmod +x install_flatpak_apps.sh
    nohup "$term" "./install_flatpak_apps.sh" >> /dev/null 2>&1 &

    _log "Removing useless apps: Firefox, Transmission, Evolution"
    sudo zy rm -u MozillaFirefox transmission-gtk evolution
}

_codium() {
    _log "Installing VSCodium"
    opi codium

    cat >./install_vscodium_extensions.sh <<EOL
#!/usr/bin/sh
rm ./install_vscodium_extensions.sh
echo -e "[ Installing VSCodium extensions: General coding, Golang, C++.. ]"
sleep 3

codium --install-extension golang.Go
codium --install-extension r3inbowari.gomodexplorer
codium --install-extension furkanozalp.go-syntax
codium --install-extension neonxp.gotools
codium --install-extension EdwinKofler.vscode-assorted-languages 
codium --install-extension jeff-hykin.better-cpp-syntax
codium --install-extension alefragnani.Bookmarks
codium --install-extension danielpinto8zz6.c-cpp-project-generator
codium --install-extension llvm-vs-code-extensions.vscode-clangd
codium --install-extension twxs.cmake
codium --install-extension formulahendry.code-runner
codium --install-extension streetsidesoftware.code-spell-checker
codium --install-extension streetsidesoftware.code-spell-checker-russian
codium --install-extension naumovs.color-highlight
codium --install-extension ms-azuretools.vscode-docker
codium --install-extension bierner.docs-view
codium --install-extension cschlosser.doxdocgen
codium --install-extension usernamehw.errorlens
codium --install-extension tamasfe.even-better-toml
codium --install-extension waderyan.gitblame
codium --install-extension mhutchie.git-graph
codium --install-extension donjayamanne.githistory
codium --install-extension GitHub.vscode-pull-request-github
codium --install-extension eamodio.gitlens
codium --install-extension PKief.material-icon-theme

rm -rv Microsoft.VisualStudio.Services.VSIXPackage*
wget --quiet --progress=bar --show-progress "https://quicktype.gallery.vsassets.io/_apis/public/gallery/publisher/quicktype/extension/quicktype/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"
mv -v Microsoft.VisualStudio.Services.VSIXPackage quicktype-latest.vsix

codium --install-extension ./quicktype-latest.vsix

rm -v quicktype-latest.vsix
rm -rv Microsoft.VisualStudio.Services.VSIXPackage*

codium --install-extension christian-kohler.path-intellisense
codium --install-extension bradlc.vscode-tailwindcss
codium --install-extension 13xforever.language-x86-64-assembly
codium --install-extension pr1sm8.theme-panda

echo -e "[ THE SCRIPT IS DONE. EXITING IN 5sec. ]"
sleep 5
EOL
    chmod +x install_vscodium_extensions.sh
    nohup "$term" "./install_vscodium_extensions.sh" >> /dev/null 2>&1 &

    _log "Applying VSCodium settings"
    mkdir -pv "/home/$usr/.config/VSCodium/User/"
    cat >"/home/$usr/.config/VSCodium/User/settings.json" <<EOL
{
	"workbench.colorTheme": "Panda Syntax",
	"editor.fontFamily": "JetBrainsMono Nerd Font Mono",
	"editor.fontSize": 16.5,
	"editor.fontLigatures": true,
	"editor.wordWrap": "on",
	"workbench.iconTheme": "material-icon-theme",
	"cSpell.language": "en,ru",
	"cmake.showOptionsMovedNotification": false,
 	"go.formatTool": "gofmt",
} 
EOL
}

_hyprland() {
    git clone https://github.com/rifux/opensuse-hyprland
    cd opensuse-hyprland
    bash install.sh
}

_fish() {
    _log "Changing $usr's shell to fish"
    sudo chsh $usr -s /usr/bin/fish

    _log "Installing fisher plugin installer for 'fish' shell"
    fish -c "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher"

    _log "Installing fzf hotkeys for 'fish' shell"
    fish -c "fisher install PatrickF1/fzf.fish"

    _log "Installing 'done notifications' for 'fish' shell"
    fish -c "fisher install franciscolourenco/done"

    _log "Installing 'auto-complete matching pairs' for 'fish' shell"
    fish -c "fisher install jorgebucaran/autopair.fish"

    _log "Updating 'tealdeer'"
    tldr --update

    _log "Enabling 'zoxide'"
    fish -c "zoxide init fish >> /home/$usr/.config/fish/zoxide.fish"

    _log "Installing aliases to fish shell"
    _fetch https://raw.githubusercontent.com/rifux/dots/main/fish/aliases.fish
    mkdir -pv /home/$usr/.config/fish
    mv -v aliases.fish /home/$usr/.config/fish
    cat >>/home/$usr/.config/fish/config.fish <<EOL
set -q CONFIG_FISH_HOME || set CONFIG_FISH_HOME "\$HOME/.config/fish"

source \$CONFIG_FISH_HOME/aliases.fish
source \$CONFIG_FISH_HOME/zoxide.fish
EOL
}

_end() {
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    echo -e "\n\n$(tput bold)Elapsed time: $((elapsed_time/60)) min, $((elapsed_time%60)) sec instead of few hours. ;)"

    echo -e "\n\n\n\n\n$(tput setaf 5)$(tput bold)Installed CLI programs that should increase your productivity:"
    echo -e ""
    echo -e "$(tput sgr0)$(tput bold)'tldr' $(tput sgr0)- Alternative to 'man' with much shorter texts."
    echo -e "$(tput bold)'z' $(tput sgr0)or$(tput bold) 'zoxide' $(tput sgr0)- smarter 'cd' alternative."
    echo -e "$(tput bold)'exa' $(tput sgr0)- Modern 'ls' alternative with better coloring and usage."
    echo -e "$(tput bold)'btop' $(tput sgr0)- Similar to 'htop', but much more comfortable!"
    echo -e "$(tput bold)'bat' $(tput sgr0)- Finally! 'cat' with syntax highlighting!"
    echo -e "$(tput bold)'bmon' $(tput sgr0)- Network monitor in your terminal (i.e. bandwidth monitor)."
    echo -e "$(tput bold)'fd' $(tput sgr0)- Alternative to 'find' where you can use multithreaded regular expression search."
    echo -e "$(tput bold)'ncdu' $(tput sgr0)- Find out big files and dirs you don't need and delete them by pressing 'd' key."
    echo -e "$(tput bold)'micro' $(tput sgr0)- comfy command-line text editor with familiar shortcuts and code syntax highlighting."
    echo -e "$(tput bold)'progress' $(tput sgr0)- Huh? It looks like 'dd' is stuck? Nervously copying important files using 'cp' without any status info? Check out the progress of cp/mv/dd and other read & write processes in percentage."
    echo -e ""
    echo -e "$(tput setaf 5)$(tput bold)Just try it out! Enter:"
    echo -e "$(tput sgr0)tldr fd"
}

_program() {
    _zypper
    _fonts
    _apps
    _codium
    _defaults
    _hyprland
    _fish
    _system
    _end
}

_program