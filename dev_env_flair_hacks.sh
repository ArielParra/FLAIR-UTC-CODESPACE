#!/usr/bin/env bash
# =====================================================================================
# FLAIR Build Environment Setup Script
# Debian 12+ / Ubuntu compatible
# Slim + Flair Toolchains + GUI dependencies + HDS student hacks
# =====================================================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[*] Script is not running as root. Re-running with sudo..."
    exec sudo "$0" "$@"
fi

export DEBIAN_FRONTEND=noninteractive
export FLAIR_ROOT=/root/flair

# --- Step 1: System dependencies ---
apt-get update

LIBICU_PACKAGE=$(apt-cache search '^libicu[0-9]+$' | awk '{print $1}' | sort -r | head -n1)
if [ -z "$LIBICU_PACKAGE" ]; then
    echo "[!] No libicu package found in repo."
    exit 1
fi

apt-get install -y \
    python-is-python3 git build-essential cmake file \
    mesa-utils libgl1-mesa-dev gnome-terminal \
    make wget python3 python3-pip bash sudo qemu-user doxygen \
    qtbase5-dev qtchooser qt5-qmake qtbase5-dev-tools libxml2-dev \
    libx11-6 libxext6 libxrender1 libxrandr2 libxi6 libxtst6 libxfixes3 \
    libgtk-3-0 libglib2.0-0 \
    libicu-dev "$LIBICU_PACKAGE" \
    dbus-x11 locales expect

# --- Step 2: Configure locale ---
sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen

# --- Step 4: Real-time limits ---
echo 'root soft rtprio 99' >> /etc/security/limits.conf
echo 'root hard rtprio 99' >> /etc/security/limits.conf

# --- Step 5: Clone Flair source ---
mkdir -p "${FLAIR_ROOT}"
git -c http.sslVerify=false clone https://gitlab.utc.fr/uav-hds/flair/flair-src.git "${FLAIR_ROOT}/flair-src"
cd "${FLAIR_ROOT}/flair-src"
git remote remove origin

# --- Step 5.1: Optional flair-hds folder ---
if [ -d "./flair-hds" ]; then
    mkdir -p "${FLAIR_ROOT}/flair-hds"
    cp -r ./flair-hds/* "${FLAIR_ROOT}/flair-hds/"
    echo "flair-hds copied"
fi

# --- Step 6: Install Flair toolchains ---
cd /tmp
TOOLCHAINS=("x86_64-meta-toolchain-flair-x86_64" "x86_64-meta-toolchain-flair-armv7a-neon" "x86_64-meta-toolchain-flair-armv5e")
echo "[*] Installing toolchains in parallel..."
for toolchain in "${TOOLCHAINS[@]}"; do
(
    wget -q --no-check-certificate "https://devel.hds.utc.fr/flair/old/toolchain/${toolchain}.sh" -O "${toolchain}.sh"
    chmod +x "${toolchain}.sh"
    expect -c "
        set timeout -1;
        spawn ./${toolchain}.sh;
        expect \"Enter target directory for SDK*\";
        send \"\r\";
        expect \"Proceed\";
        send \"Y\r\";
        expect eof;
    "
    rm -f "${toolchain}.sh"
) &
done
wait

# --- Step 7: Fix make path ---
ARCHS=("core2-64" "armv7a-neon" "armv5te")
for arch in "${ARCHS[@]}"; do
    SYSROOT_DIR=$(echo /opt/robomap3/2.1.3/$arch/sysroots/*poky-linux*/usr/bin)
    if [ -d "$SYSROOT_DIR" ]; then
        ln -sf /usr/bin/make "$SYSROOT_DIR/make"
    fi
done

# --- Step 8: Configure .bashrc ---
{
    echo '# Flair Environment Configuration'
    echo "export FLAIR_ROOT=${FLAIR_ROOT}"
    echo 'export PATH="$PATH:$FLAIR_ROOT/flair-src/bin:$FLAIR_ROOT/flair-src/scripts"'
    echo 'export QEMU_LD_PREFIX="/opt/robomap3/2.1.3/armv7a-neon/sysroots/armv7a-neon-poky-linux-gnueabi"'
    echo 'export QT_X11_NO_MITSHM=1'
    echo 'export LANG=en_US.UTF-8'
    echo 'export LANGUAGE=en_US:en'
    echo 'export LC_ALL=en_US.UTF-8'
    echo 'source $FLAIR_ROOT/flair-src/scripts/flair_completion.sh'
} >> /root/.bashrc

# --- Step 9: ICU workaround ---
ICU_SO=$(ls /usr/lib/x86_64-linux-gnu/libicui18n.so.* | sort -V | tail -n1)
if [ -n "$ICU_SO" ]; then
    ln -sf "$ICU_SO" /usr/lib/x86_64-linux-gnu/libicui18n.so.67
fi

# --- Step 10: Add Alejandro's template ---
git clone https://github.com/ateveraz/customCtrl.git "${FLAIR_ROOT}/flair-src/demos/customCtrl"
cd "${FLAIR_ROOT}/flair-src/demos/customCtrl"
git remote remove origin

# --- Step 11 & 12: Clone and install global scripts ---
git clone --depth=1 https://github.com/ArielParra/FLAIR-UTC-CODESPACE /tmp/FLAIR-UTC-CODESPACE
install -m 755 /tmp/FLAIR-UTC-CODESPACE/configure_flair_project.sh /usr/local/bin/configure_flair_project.sh
install -m 755 /tmp/FLAIR-UTC-CODESPACE/flair_compile_all_non_interactive.sh /usr/local/bin/flair_compile_all_non_interactive.sh
sed -i '$a /usr/local/bin/configure_flair_project.sh' "${FLAIR_ROOT}/flair-src/scripts/clone_demo.sh"
rm -rf /tmp/FLAIR-UTC-CODESPACE

# --- Step 12: Compile Flair non-interactively ---
# Source the bashrc to load all environment variables
source /root/.bashrc

# Run the non-interactive Flair compile script
/usr/local/bin/flair_compile_all_non_interactive.sh

echo "FLAIR build environment setup complete!"
