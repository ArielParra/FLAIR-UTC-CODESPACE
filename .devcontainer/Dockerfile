# ============================================
# FLAIR Build Environment
# Ubuntu 22.04 + Flair Toolchains + GUI dependencies
# ============================================

FROM ubuntu:22.04

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive
ENV FLAIR_ROOT=/root/flair

# --- Step 1: System dependencies ---
# Install all required packages for 22.04

RUN apt-get update && apt-get install -y \
    python-is-python3 git build-essential cmake file \
    mesa-utils libgl1-mesa-dev \
    # not stated in the wiki but needed to compile & run flair
    make wget file expect python3 python3-pip bash sudo qemu doxygen\
    gnome-terminal locales \
    # GUI dependencies
    libx11-6 libxext6 libxrender1 libxrandr2 libxi6 libxtst6 libxfixes3 \
    libgtk-3-0 libglib2.0-0 \
    #FLairGCS dependencies
    libicu-dev libicu70 \
    dbus-x11 xpra \
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
    echo 'export QEMU_LD_PREFIX="/opt/robomap3/2.1.3/armv7a-neon/sysroots/armv7a-neon-poky-linux-gnueabi"' >> /root/.bashrc && \
    echo 'source $FLAIR_ROOT/flair-src/scripts/flair_completion.sh ' >> /root/.bashrc

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
    TOOLCHAINS="x86_64-meta-toolchain-flair-x86_64 x86_64-meta-toolchain-flair-armv7a-neon x86_64-meta-toolchain-flair-armv5e" && \
    for toolchain in $TOOLCHAINS; do \
        echo "[+] Installing $toolchain..."; \
        wget --no-check-certificate "https://devel.hds.utc.fr/flair/old/toolchain/${toolchain}.sh"; \
        chmod +x "${toolchain}.sh"; \
        expect -c " \
            set timeout -1; \
            spawn ./${toolchain}.sh; \
            expect \"Enter target directory for SDK*\"; send \"\r\"; \
            expect \"Proceed\"; send \"Y\r\"; \
            expect eof; \
        "; \
        rm -f "${toolchain}.sh"; \
    done

# --- Step 7: Fix toolchain make path ---
# Some SDKs lack make inside their sysroots — link system make
RUN bash -c '\
  for arch in armv7a-neon armv5te; do \
      TARGET_DIR=$(find /opt/robomap3/2.1.3/${arch}/sysroots -type d -path "*/usr/bin" | grep -E "poky-linux-gnueabi"); \
      if [ -n "$TARGET_DIR" ]; then \
          ln -sf /usr/bin/make "${TARGET_DIR}/make"; \
          echo "Linked /usr/bin/make → ${TARGET_DIR}/make"; \
      else \
          echo "⚠️  No matching sysroot usr/bin found for $arch"; \
      fi; \
  done'


# --- Step 8: Workaround for FlairGCS expecting incorrect ICU version name ---
# FlairGCS tries to dynamically load "icui18n" or an unexpected ICU version
# This symlink makes libicui18n.so.70 available under the name libicui18n.so.67
# to satisfy that runtime expectation and prevent "Cannot load library icui18n" errors
RUN ln -sf /usr/lib/x86_64-linux-gnu/libicui18n.so.70 /usr/lib/x86_64-linux-gnu/libicui18n.so.67

# --- Step 9: Build Flair automatically (non-interactive) ---
# Use `expect` to answer prompts in flair_compile_all.sh
RUN expect -c "set timeout -1; spawn bash -c \"source /opt/robomap3/2.1.3/armv7a-neon/environment-setup-armv7a-neon-poky-linux-gnueabi && export FLAIR_ROOT=/root/flair && ./flair_compile_all.sh\"; expect eof"

# --- Default command ---
CMD ["/bin/bash"]
