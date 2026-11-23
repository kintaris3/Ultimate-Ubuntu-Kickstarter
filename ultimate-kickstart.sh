#!/usr/bin/env bash

# Colors for clean terminal readability
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_banner() {
    clear
    cat << "BANNER_EOF"
 _   _ _ _   _                 _       
| | | | | |_(_)_ __ ___   __ _| |_ ___ 
| | | | | __| | '_ ` _ \ / _` | __/ _ \
| |_| | | |_| | | | | | | (_| | ||  __/
 \___/|_|\__|_|_| |_| |_|\__,_|\__\___|
  _   _ _                 _         _  ___      _        _             _   
 | | | | |__  _   _ _ __ | |_ _   _| |/ (_) ___| | _____| |_ __ _ _ __| |_ 
 | | | | '_ \| | | | '_ \| __| | | | ' /| |/ __| |/ / __| __/ _` | '__| __|
 | |_| | |_) | |_| | | | | |_| |_| | . \| | (__|   <\__ \ || (_| | |  | |_ 
  \___/|_.__/ \__,_|_| |_|\__|\__,_|_|\_\_|\___|_|\_\___/\__\__,_|_|   \__|
                                                                           
        /\_/\
       ( o.o )   "Let's get this rig dialed in!"
        > ^ <

        Code written by Christopher G. Pitts Jr.
BANNER_EOF
    echo ""
}

# Safe helper functions for APT and Snap
remove_pkg() {
    for pkg in "$@"; do
        if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            sudo apt purge -y "$pkg"
        fi
        if command -v snap &> /dev/null && snap list "$pkg" &> /dev/null; then
            sudo snap remove --purge "$pkg"
        fi
    done
}

# --- QUESTION 1: USE CASE ---
while true; do
    print_banner
    echo -e "${BOLD}${CYAN}[1/5] What do you intend to use this system for?${NC}"
    echo "  1) Gaming & Entertainment (Steam, Lutris, GameMode, MangoHud; strips office bloat)"
    echo "  2) Work & Productivity    (LibreOffice, PDF tools, Zoom/Slack ready; strips games)"
    echo "  3) Minimal / Older Rig    (Debloats heavy apps, installs ZRAM & lightweight tools)"
    echo "  4) Tinkerer / Power User  (Git, Curl, Btop, Fastfetch, Neovim, Tmux, build tools)"
    echo ""
    read -p "Select an option [1-4]: " USE_CASE
    case $USE_CASE in
        1) USE_LABEL="Gaming & Entertainment"; break ;;
        2) USE_LABEL="Work & Productivity"; break ;;
        3) USE_LABEL="Minimal / Older Rig"; break ;;
        4) USE_LABEL="Tinkerer / Power User"; break ;;
        *) echo -e "${RED}Invalid choice. Please enter 1-4.${NC}"; sleep 1 ;;
    esac
done

# --- QUESTION 2: PRIVACY LEVEL ---
while true; do
    print_banner
    echo -e "${BOLD}${CYAN}[2/5] How focused on privacy are you?${NC}"
    echo "  1) Standard (Keep Ubuntu defaults)"
    echo "  2) Balanced (Disable telemetry, apport crash reporting, & enable UFW firewall)"
    echo "  3) Strict   (Balanced + disable connectivity checks & enable DNS-over-TLS)"
    echo ""
    read -p "Select an option [1-3]: " PRIVACY_LEVEL
    case $PRIVACY_LEVEL in
        1) PRIV_LABEL="Standard"; break ;;
        2) PRIV_LABEL="Balanced"; break ;;
        3) PRIV_LABEL="Strict"; break ;;
        *) echo -e "${RED}Invalid choice. Please enter 1-3.${NC}"; sleep 1 ;;
    esac
done

# --- QUESTION 3: BROWSER ---
while true; do
    print_banner
    echo -e "${BOLD}${CYAN}[3/5] What is your preferred web browser?${NC}"
    echo "  1) Brave Browser (Official APT repo, built-in ad/tracker shield)"
    echo "  2) Firefox (.deb) (Replaces Snap Firefox with native Mozilla APT package)"
    echo "  3) LibreWolf      (Privacy-hardened Firefox fork via Flatpak)"
    echo "  4) Keep Current   (Leave existing browser as-is)"
    echo ""
    read -p "Select an option [1-4]: " BROWSER_CHOICE
    case $BROWSER_CHOICE in
        1) BROWSER_LABEL="Brave Browser"; break ;;
        2) BROWSER_LABEL="Firefox (Native .deb)"; break ;;
        3) BROWSER_LABEL="LibreWolf"; break ;;
        4) BROWSER_LABEL="Keep Current"; break ;;
        *) echo -e "${RED}Invalid choice. Please enter 1-4.${NC}"; sleep 1 ;;
    esac
done

# --- QUESTION 4: EXTRAS ---
print_banner
echo -e "${BOLD}${CYAN}[4/5] Foundation Extras${NC}"
read -p "Enable Flatpak + Flathub repository? [Y/n]: " ENABLE_FLATPAK
ENABLE_FLATPAK=${ENABLE_FLATPAK:-Y}

read -p "Install media codecs & restricted extras (MP4, DVD, fonts)? [Y/n]: " INSTALL_CODECS
INSTALL_CODECS=${INSTALL_CODECS:-Y}

# --- QUESTION 5: ULTIMATE UBUNTU UPDATER ---
print_banner
echo -e "${BOLD}${CYAN}[5/5] Companion Tool: Ultimate Ubuntu Updater${NC}"
echo "Keep your new setup clean and updated with one click from your app grid."
echo "Project Repo: https://github.com/kintaris3/Ultimate-Ubuntu-Updater"
echo ""
read -p "Would you like to install Ultimate Ubuntu Updater automatically? [Y/n]: " INSTALL_UPDATER
INSTALL_UPDATER=${INSTALL_UPDATER:-Y}

# --- SUMMARY & CONFIRMATION ---
print_banner
echo -e "${BOLD}${YELLOW}=== KICKSTART SUMMARY ===${NC}"
echo -e "  Profile:          ${GREEN}$USE_LABEL${NC}"
echo -e "  Privacy Level:    ${GREEN}$PRIV_LABEL${NC}"
echo -e "  Browser:          ${GREEN}$BROWSER_LABEL${NC}"
echo -e "  Flatpak/Flathub:  ${GREEN}$ENABLE_FLATPAK${NC}"
echo -e "  Media Codecs:     ${GREEN}$INSTALL_CODECS${NC}"
echo -e "  Install Updater:  ${GREEN}$INSTALL_UPDATER${NC}"
echo ""
read -p "Proceed with system configuration? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Aborted. No changes were made to your system."
    exit 0
fi

echo ""
sudo -v

echo -e "\n${CYAN}--> Updating package lists...${NC}"
sudo apt update

# 1. Flatpak Setup (Required early if LibreWolf or Gaming Flatpaks are chosen)
if [[ "$ENABLE_FLATPAK" =~ ^[Yy]$ ]] || [[ "$BROWSER_CHOICE" == "3" ]]; then
    echo -e "\n${CYAN}--> Setting up Flatpak & Flathub...${NC}"
    sudo apt install -y flatpak gnome-software-plugin-flatpak
    sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi

# 2. Apply Use-Case Profile
case $USE_CASE in
    1) # Gaming
        echo -e "\n${CYAN}--> Configuring Gaming & Entertainment profile...${NC}"
        remove_pkg thunderbird rhythmbox aisleriot gnome-mahjongg gnome-mines gnome-sudoku
        sudo apt purge -y "libreoffice*"
        sudo dpkg --add-architecture i386
        sudo apt update
        sudo apt install -y steam-installer gamemode mangohud vulkan-tools
        if command -v flatpak &> /dev/null; then
            flatpak install -y flathub net.lutris.Lutris com.heroicgameslauncher.hgl
        fi
        ;;
    2) # Work
        echo -e "\n${CYAN}--> Configuring Work & Productivity profile...${NC}"
        remove_pkg aisleriot gnome-mahjongg gnome-mines gnome-sudoku rhythmbox
        sudo apt install -y libreoffice pdfarranger flameshot
        ;;
    3) # Minimal / Older Hardware
        echo -e "\n${CYAN}--> Configuring Minimal / Older Rig profile...${NC}"
        remove_pkg thunderbird rhythmbox totem transmission-gtk aisleriot gnome-mahjongg gnome-mines gnome-sudoku
        sudo apt purge -y "libreoffice*"
        sudo apt install -y zram-tools btop fastfetch
        ;;
    4) # Tinkerer / Power User
        echo -e "\n${CYAN}--> Configuring Tinkerer / Power User profile...${NC}"
        sudo apt install -y git curl wget btop fastfetch neovim tmux build-essential net-tools
        ;;
esac

# 3. Apply Privacy Settings
if [[ "$PRIVACY_LEVEL" == "2" ]] || [[ "$PRIVACY_LEVEL" == "3" ]]; then
    echo -e "\n${CYAN}--> Applying Balanced privacy tweaks...${NC}"
    remove_pkg ubuntu-report popularity-contest apport whoopsie
    sudo ufw enable
fi

if [[ "$PRIVACY_LEVEL" == "3" ]]; then
    echo -e "\n${CYAN}--> Applying Strict privacy hardening...${NC}"
    gsettings set org.gnome.desktop.privacy report-technical-problems false 2>/dev/null || true
    sudo mkdir -p /etc/NetworkManager/conf.d
    echo -e "[connectivity]\nenabled=false" | sudo tee /etc/NetworkManager/conf.d/20-connectivity.conf > /dev/null
    sudo mkdir -p /etc/systemd/resolved.conf.d
    echo -e "[Resolve]\nDNS=9.9.9.9#dns.quad9.net 1.1.1.1#cloudflare-dns.com\nDNSOverTLS=yes" | sudo tee /etc/systemd/resolved.conf.d/dns_over_tls.conf > /dev/null
    sudo systemctl restart systemd-resolved
fi

# 4. Browser Installation
case $BROWSER_CHOICE in
    1) # Brave
        echo -e "\n${CYAN}--> Installing Brave Browser...${NC}"
        sudo apt install -y curl
        sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
        sudo apt update && sudo apt install -y brave-browser
        ;;
    2) # Firefox .deb
        echo -e "\n${CYAN}--> Replacing Snap Firefox with native Mozilla .deb...${NC}"
        if command -v snap &> /dev/null && snap list firefox &> /dev/null; then
            sudo snap remove --purge firefox
        fi
        sudo install -d -m 0755 /etc/apt/keyrings
        wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
        echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
        echo -e "Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000" | sudo tee /etc/apt/preferences.d/mozilla > /dev/null
        sudo apt update && sudo apt install -y firefox
        ;;
    3) # LibreWolf
        echo -e "\n${CYAN}--> Installing LibreWolf via Flatpak...${NC}"
        flatpak install -y flathub io.gitlab.librewolf-community
        ;;
esac

# 5. Media Codecs
if [[ "$INSTALL_CODECS" =~ ^[Yy]$ ]]; then
    echo -e "\n${CYAN}--> Installing Ubuntu Restricted Extras...${NC}"
    echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | sudo debconf-set-selections
    sudo apt install -y ubuntu-restricted-extras
fi

# 6. Install Ultimate Ubuntu Updater
if [[ "$INSTALL_UPDATER" =~ ^[Yy]$ ]]; then
    echo -e "\n${CYAN}--> Downloading & Installing Ultimate Ubuntu Updater...${NC}"
    sudo apt install -y unzip wget
    TMP_DIR=$(mktemp -d)
    wget -qO "$TMP_DIR/UUU_v1.1.zip" "https://github.com/kintaris3/Ultimate-Ubuntu-Updater/releases/download/v1.1/UUU_v1.1.zip"
    unzip -q "$TMP_DIR/UUU_v1.1.zip" -d "$TMP_DIR"
    sudo apt install -y "$TMP_DIR/UUU_v1.1/ultimate-ubuntu-updater_1.1_all.deb"
    rm -rf "$TMP_DIR"
else
    echo -e "\n${YELLOW}Tip: Check out Ultimate Ubuntu Updater anytime at:${NC}"
    echo "https://github.com/kintaris3/Ultimate-Ubuntu-Updater"
fi

# Final Cleanup
echo -e "\n${CYAN}--> Cleaning up leftover packages...${NC}"
sudo apt autopurge -y

echo -e "\n${GREEN}${BOLD}=== Kickstart Complete! A reboot is recommended. ===${NC}"
read -p "Press Enter to exit..."
