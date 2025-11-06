# =====================================================================================
# FLAIR Build Environment
# Debian 12 (Bookworm) Slim + Flair Toolchains + GUI dependencies + HDS students hacks
# =====================================================================================

FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV FLAIR_ROOT=/root/flair
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# --- Step 1: System dependencies ---
RUN apt-get update && apt-get install -y \
    python-is-python3 git build-essential cmake file \
    mesa-utils libgl1-mesa-dev \
    # not stated in the wiki but needed to compile & run flair
    make wget python3 python3-pip bash sudo qemu-user doxygen \
    gnome-terminal locales expect\
    # GUI dependencies
    libx11-6 libxext6 libxrender1 libxrandr2 libxi6 libxtst6 libxfixes3 \
    libgtk-3-0 libglib2.0-0 \
    #FLairGCS dependencies
    libicu-dev libicu72 \
    dbus-x11 xpra \
    && rm -rf /var/lib/apt/lists/*

# --- Step 2: Configure Locale ---
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

# --- Step 4: Set real-time priority limits ---
RUN echo 'root soft rtprio 99' >> /etc/security/limits.conf && \
    echo 'root hard rtprio 99' >> /etc/security/limits.conf

# --- Step 5: Clone Flair source---
RUN mkdir -p ${FLAIR_ROOT} && \
    git -c http.sslVerify=false clone https://gitlab.utc.fr/uav-hds/flair/flair-src.git ${FLAIR_ROOT}/flair-src

# --- Step 6: Install Flair toolchains (Parallel) ---
RUN cd /tmp && \
    TOOLCHAINS="x86_64-meta-toolchain-flair-x86_64 \
                x86_64-meta-toolchain-flair-armv7a-neon \
                x86_64-meta-toolchain-flair-armv5e" && \
    echo "[*] Starting parallel toolchain installs..." && \
    for toolchain in $TOOLCHAINS; do \
        ( \
            echo "[+] Downloading and installing $toolchain..."; \
            wget -q --no-check-certificate "https://devel.hds.utc.fr/flair/old/toolchain/${toolchain}.sh" -O "${toolchain}.sh" && \
            chmod +x "${toolchain}.sh" && \
            expect -c " \
                set timeout -1; \
                spawn ./${toolchain}.sh; \
                expect \"Enter target directory for SDK*\"; send \"\r\"; \
                expect \"Proceed\"; send \"Y\r\"; \
                expect eof; \
            " && \
            rm -f "${toolchain}.sh" && \
            echo \"Finished installing $toolchain\" \
        ) & \
    done && \
    wait && echo "All toolchains installed in parallel successfully."

    # --- Step 7: Fix toolchain make path ---
RUN ARCHS="core2-64 armv7a-neon armv5te" && \
    for arch in $ARCHS; do \
        SYSROOT_DIR=$(echo /opt/robomap3/2.1.3/$arch/sysroots/*poky-linux*/usr/bin) && \
        if [ -d "$SYSROOT_DIR" ]; then \
            ln -sf /usr/bin/make "$SYSROOT_DIR/make" && \
            echo "Linked /usr/bin/make → $SYSROOT_DIR/make"; \
        else \
            echo "No matching 'poky-linux' sysroot found for $arch (path: $SYSROOT_DIR)"; \
        fi; \
    done

# --- Step 8: Workaround for FlairGCS ICU version ---
RUN ln -sf /usr/lib/x86_64-linux-gnu/libicui18n.so.72 /usr/lib/x86_64-linux-gnu/libicui18n.so.67

# --- Step 9: Add Global CMake Config Script ---
COPY configure-flair-cmake.sh /usr/local/bin/configure-flair-cmake.sh
RUN chmod +x /usr/local/bin/configure-flair-cmake.sh

# --- Step 10: Configure .bashrc  ---
RUN echo '# Flair Environment Configuration' >> /root/.bashrc && \
    echo 'export PATH="$PATH:$FLAIR_ROOT/flair-src/bin"' >> /root/.bashrc && \
    # fix an error with arm crosscompilation 
    echo 'export QEMU_LD_PREFIX="/opt/robomap3/2.1.3/armv7a-neon/sysroots/armv7a-neon-poky-linux-gnueabi"' >> /root/.bashrc && \
    # QT_X11_NO_MITSHM to fix specific GUI errors in FLairGCS for debain
    echo 'export QT_X11_NO_MITSHM=1' >> /root/.bashrc && \
    echo 'source $FLAIR_ROOT/flair-src/scripts/flair_completion.sh ' >> /root/.bashrc

# --- Step 11: Add Alejandro's Template ---
RUN git clone https://github.com/ateveraz/customCtrl.git /root/customCtrl


# --- Default command ---
CMD ["/bin/bash"]