# ============================================
# FLAIR Build Environment
# Ubuntu 20.04 + Flair Toolchains + GUI dependencies
# ============================================

FROM ubuntu:20.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV FLAIR_ROOT=/root/flair

# --- Step 1: System dependencies ---
# Install all required packages, including gnome-terminal and locales
RUN apt-get update && apt-get install -y \
    build-essential make cmake git wget file expect python3 python3-pip bash \
    libgl1-mesa-dev mesa-utils sudo \
    gnome-terminal locales \
    # GUI + FlairGCS dependencies
    libx11-6 libxext6 libxrender1 libxrandr2 libxi6 libxtst6 libxfixes3 \
    libgtk-3-0 libglib2.0-0 libicu-dev libicu66 dbus-x11 xpra \
    && ln -s /usr/bin/python3 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

# --- Step 2: Configure Locale ---
# Generate the en_US.UTF-8 locale to fix gnome-terminal errors
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8    

# --- Step 3: Configure Flair environment ---
# Add FLAIR_ROOT and other variables to .bashrc
RUN echo '# Flair Environment Configuration' >> /root/.bashrc && \
    echo 'export FLAIR_ROOT=/root/flair' >> /root/.bashrc && \
    echo 'export PATH="$PATH:$FLAIR_ROOT/flair-src/bin"' >> /root/.bashrc && \
    echo 'source $FLAIR_ROOT/flair-src/scripts/flair_completion.sh || true' >> /root/.bashrc

# --- Step 4: Set real-time priority limits ---
RUN echo 'root soft rtprio 99' >> /etc/security/limits.conf && \
    echo 'root hard rtprio 99' >> /etc/security/limits.conf

# --- Step 5: Clone Flair source ---
RUN mkdir -p ${FLAIR_ROOT} && cd ${FLAIR_ROOT} && \
    git config --global http.sslVerify false && \
    git clone https://gitlab.utc.fr/uav-hds/flair/flair-src.git

# --- Step 6: Install Flair toolchains ---
# Download and install the necessary toolchains for cross-compilation
RUN cd /tmp && \
    TOOLCHAINS="x86_64-meta-toolchain-flair-x86_64 x86_64-meta-toolchain-flair-armv7a-neon" && \
    for toolchain in $TOOLCHAINS; do \
        echo "[+] Installing $toolchain..."; \
        wget --no-check-certificate "https://devel.hds.utc.fr/flair/old/toolchain/${toolchain}.sh"; \
        chmod +x "${toolchain}.sh"; \
        expect -c " \
            set timeout -1; \
            spawn ./${toolchain}.sh; \
            expect \"Enter target directory for SDK*\"; send \"\r\"; \
            expect \"Proceed\"; send \"Y\r\"; \
            expect \"license\"; send \"yes\r\"; \
            expect eof; \
        "; \
        rm -f "${toolchain}.sh"; \
    done

# --- Step 7: Fix toolchain make path ---
# Some SDKs lack /usr/bin/make inside their sysroots — link system make
RUN ln -sf /usr/bin/make /opt/robomap3/2.1.3/core2-64/sysroots/core2-64-poky-linux/usr/bin/make || true && \
    ln -sf /usr/bin/make /opt/robomap3/2.1.3/armv7a-neon/sysroots/core2-64-poky-linux/usr/bin/make || true && \
    ln -sf /usr/bin/make /opt/robomap3/2.1.3/armv5te/sysroots/core2-64-poky-linux/usr/bin/make || true

# --- Step 8: Workaround for FlairGCS expecting incorrect ICU version name ---
# FlairGCS tries to dynamically load "icui18n" or an unexpected ICU version
# This symlink makes libicui18n.so.70 available under the name libicui18n.so.67
# to satisfy that runtime expectation and prevent "Cannot load library icui18n" errors
RUN ln -sf /usr/lib/x86_64-linux-gnu/libicui18n.so.70 /usr/lib/x86_64-linux-gnu/libicui18n.so.67

# --- Default command ---
CMD ["/bin/bash"]
