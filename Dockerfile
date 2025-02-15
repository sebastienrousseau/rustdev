###############################################################################
# Dockerfile for a Rust Development Environment on Alpine Linux
#
# This Dockerfile creates a minimal yet feature-rich Alpine-based container
# with:
#   • Rust (via rustup, minimal profile, plus rust-analyzer and rust-src)
#   • Tooling for compilation and auditing (build-base, cargo-watch, cargo-audit)
#   • A non-root user (rustdev) with Bash shell and Neovim configuration
#   • Security hardening steps to remove extraneous files and restrict permissions
#
# The following optional files can be provided at build context or copied in
# later to customize the shell, environment variables, and Neovim plugins:
#   - .bash_aliases
#   - .bash_profile
#   - .bashrc
#   - .env
#   - .gitignore
#   - docker-compose.yml
#   - plugins/disabled.lua
#   - plugins/ui.lua
#   - plugins/coding.lua
#   - plugins/toggleterm.lua
###############################################################################

###############################################################################
# Base Alpine Linux (lightweight & secure)
###############################################################################
FROM alpine:3.21.3

# -----------------------------------------------------------------------------
# Metadata
#   - Provides human-readable metadata about the image, including source and
#     maintainer references.
# -----------------------------------------------------------------------------
LABEL org.opencontainers.image.source="https://github.com/rust-lang/docker-rust" \
    maintainer="Sebastien Rousseau"

###############################################################################
# Define build arguments
#   - ARG instructions define variables that can be passed at build time.
#   - Defaults are provided if none are passed from the CLI or docker-compose.
###############################################################################
ARG ARCH=$(apk --print-arch)
ARG LANG="C.UTF-8"
ARG NAME="RustDev"
ARG OS="linux"
ARG SHELL="/bin/bash"
ARG TZ="UTC"
ARG VERSION="0.0.1"

###############################################################################
# Set environment variables
#   - ENV instructions define environment variables available at build and
#     runtime. Here we define system settings, user paths, and Rust-specific
#     environment variables.
###############################################################################
ENV ARCH=${ARCH} \
    CARGO_HOME=/usr/local/cargo \
    LANG=${LANG} \
    NAME=${NAME} \
    OS=${OS} \
    PATH="/usr/local/cargo/bin:/usr/local/rustup/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/bin:/usr/sbin" \
    RUST_VERSION="1.84.1" \
    RUSTUP_HOME=/usr/local/rustup \
    SHELL=${SHELL} \
    TZ=${TZ} \
    USERHOME=/home/rustdev \
    USERNAME=rustdev \
    VERSION=${VERSION}

###############################################################################
# Install System Dependencies, Rust Toolchain, and Additional Tools
# Create Non-Root User, Configure Neovim, and Harden OS
###############################################################################
RUN set -eux; \
    \
    # -------------------------------------------------------------------------
    # 1. Update system packages and install essential utilities
    #    - 'build-base' provides GCC and other tools needed to compile crates.
    #    - 'ca-certificates' needed for secure HTTPS connections.
    #    - 'git' for version control.
    #    - 'neovim' for an in-container text editor and dev environment.
    #    - 'shadow' to manage user shells and passwords, among other tasks.
    #    - 'tzdata' for time zone info.
    #    - 'wget' for potential file fetching (though we use curl for rustup).
    # -------------------------------------------------------------------------
    apk update --no-cache && apk upgrade --no-cache && \
    apk add --no-cache \
    bash \
    build-base \
    ca-certificates \
    curl \
    git \
    neovim \
    shadow \
    tzdata \
    wget && \
    update-ca-certificates && \
    ln -snf /usr/share/zoneinfo/"${TZ}" /etc/localtime && echo "${TZ}" > /etc/timezone && \
    \
    # -------------------------------------------------------------------------
    # 2. Install Rust via rustup
    #    - Dynamically detect the Alpine architecture and match an appropriate
    #      rustup-init binary.
    #    - Validate the downloaded file against the known sha256 checksum.
    #    - Use the 'minimal' profile to save space while retaining key Rust
    #      components (rustc, cargo, stdlib).
    # -------------------------------------------------------------------------
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
    x86_64|amd64)  rustArch='x86_64-unknown-linux-musl'; \
    rustupSha256='1455d1df3825c5f24ba06d9dd1c7052908272a2cae9aa749ea49d67acbe22b47' ;; \
    arm64v8 | aarch64) rustArch='aarch64-unknown-linux-musl'; \
    rustupSha256='7087ada906cd27a00c8e0323401a46804a03a742bd07811da6dead016617cc64' ;; \
    *) echo >&2 "unsupported architecture: $apkArch"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.27.1/${rustArch}/rustup-init"; \
    curl -fsSL "${url}" -o rustup-init; \
    echo "${rustupSha256}  rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain "$RUST_VERSION" --default-host "${rustArch}"; \
    rm rustup-init; \
    \
    # Install rust-analyzer (LSP support) and rust-src (source code for certain build features)
    rustup component add rust-analyzer rust-src; \
    \
    # Validate Rust installation
    rustup --version; \
    cargo --version; \
    rustc --version && \
    \
    # -------------------------------------------------------------------------
    # 3. Install additional Cargo tools
    #    - 'cargo-watch' for watching code changes and re-running commands.
    #    - 'cargo-audit' for auditing Cargo dependencies for known security
    #      vulnerabilities.
    #    - Remove cached crates and git repos to save space.
    # -------------------------------------------------------------------------
    cargo install cargo-watch && \
    cargo install cargo-audit && \
    rm -rf /usr/local/cargo/registry /usr/local/cargo/git && \
    \
    # -------------------------------------------------------------------------
    # 4. Create a non-root user and configure permissions
    #    - 'adduser' creates a new user named rustdev with user ID 1000.
    #    - Give ownership of Rust home directories to avoid permission issues.
    # -------------------------------------------------------------------------
    adduser -D -h "$USERHOME" -u 1000 "$USERNAME" && \
    mkdir -p "$USERHOME/.cargo" /usr/local/cargo/registry /usr/local/cargo/git && \
    chown -R "$USERNAME":"$USERNAME" /usr/local/cargo /usr/local/rustup "$USERHOME" && \
    chmod -R 755 /usr/local/cargo /usr/local/rustup && \
    \
    # -------------------------------------------------------------------------
    # 5. Clone LazyVim starter repository to pre-configure Neovim
    #    - Removes unnecessary .git folder and example plugin file.
    # -------------------------------------------------------------------------
    mkdir -p "$USERHOME/.config" && \
    git clone https://github.com/LazyVim/starter "$USERHOME/.config/nvim" && \
    rm -rf "$USERHOME/.config/nvim/.git" && \
    rm -f "$USERHOME/.config/nvim/lua/plugins/example.lua" && \
    chown -R "$USERNAME":"$USERNAME" "$USERHOME/.config" && \
    \
    # -------------------------------------------------------------------------
    # 6. Harden the Alpine distribution for security
    #    - Remove cron-related directories and other unnecessary system files.
    #    - Restrict write permissions on directories/files that might otherwise
    #      be world-writable.
    #    - Lock down unused user accounts to prevent login.
    #    - Remove leftover package manager caches, temp files, history.
    # -------------------------------------------------------------------------
    rm -rf /var/spool/cron /etc/crontabs /etc/periodic && \
    find /sbin /usr/sbin ! -type d -a ! -name apk -a ! -name ln -delete && \
    find / -xdev -type d -perm /0002 -exec chmod o-w {} + && \
    find / -xdev -type f -perm /0002 -exec chmod o-w {} + && \
    chmod 777 /tmp/ && \
    sed -i -r '/^(root|nobody|'"$USERNAME"')/!d' /etc/group && \
    sed -i -r '/^(root|nobody|'"$USERNAME"')/!d' /etc/passwd && \
    sed -i -r '/^(root|nobody):/ s#^(.*):[^:]*$#\1:/sbin/nologin#' /etc/passwd && \
    while IFS=: read -r user _; do \
    if [ "$user" != "$USERNAME" ]; then \
    passwd -l "$user"; \
    fi; \
    done < /etc/passwd || true && \
    find /bin /etc /lib /sbin /usr -xdev -type f -regex '.*-$' -exec rm -f {} \; && \
    find /bin /etc /lib /sbin /usr -xdev -type d -exec chown root:root {} \; -exec chmod 0755 {} \; && \
    \
    # Final cleanup of caches and temporary files
    rm -rf /var/cache/apk/* /tmp/* /root/.ash_history

###############################################################################
# Copy Top-Level Shell Configs and NvChad Configuration Files
#   - These files ensure consistent shell environments and Neovim settings
#     for the 'rustdev' user.
###############################################################################
COPY --chown=$USERNAME:$USERNAME \
    .bash_aliases \
    .bash_profile \
    .bashrc \
    .env \
    .gitignore \
    $USERHOME/

COPY --chown=$USERNAME:$USERNAME plugins/disabled.lua $USERHOME/.config/nvim/lua/plugins/disabled.lua
COPY --chown=$USERNAME:$USERNAME plugins/ui.lua       $USERHOME/.config/nvim/lua/plugins/ui.lua
COPY --chown=$USERNAME:$USERNAME plugins/coding.lua   $USERHOME/.config/nvim/lua/plugins/coding.lua
COPY --chown=$USERNAME:$USERNAME plugins/toggleterm.lua $USERHOME/.config/nvim/lua/plugins/toggleterm.lua

# -----------------------------------------------------------------------------
# Remove any unused .cargo directory that was copied or remains from earlier
# steps (if relevant) to keep the container tidy.
# -----------------------------------------------------------------------------
RUN rm -rf "$USERHOME/.cargo"

###############################################################################
# Set up the Rust Environment & PATH Permanently
#   - Create a script in /etc/profile.d for system-wide environment variables.
#   - Ensure these are sourced in root's and rustdev user's profiles so that
#     cargo and rustc are always available in $PATH.
###############################################################################
RUN set -eux; \
    echo 'export CARGO_HOME=/usr/local/cargo' > /etc/profile.d/rust.sh; \
    echo 'export RUSTUP_HOME=/usr/local/rustup' >> /etc/profile.d/rust.sh; \
    echo 'export PATH="/usr/local/cargo/bin:/usr/local/rustup/bin:$PATH"' >> /etc/profile.d/rust.sh; \
    chmod +x /etc/profile.d/rust.sh && \
    echo 'source /etc/profile.d/rust.sh' >> /etc/profile && \
    echo 'source /etc/profile.d/rust.sh' >> "$USERHOME/.profile" && \
    echo 'source /etc/profile.d/rust.sh' >> "$USERHOME/.bash_profile" && \
    echo 'source /etc/profile.d/rust.sh' >> "$USERHOME/.bashrc" && \
    echo '[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"' >> "$USERHOME/.bash_profile" && \
    chown "$USERNAME":"$USERNAME" "$USERHOME/.profile" "$USERHOME/.bash_profile" "$USERHOME/.bashrc"

# -----------------------------------------------------------------------------
# Change the rustdev user's default shell to Bash, create a code directory,
# and assign ownership to rustdev for future development tasks.
# -----------------------------------------------------------------------------
RUN chsh -s /bin/bash "$USERNAME" && \
    mkdir -p "$USERHOME/code" && \
    chown -R "$USERNAME:$USERNAME" "$USERHOME/code"

###############################################################################
# Set User, Default Working Directory, and Persistent Volumes
###############################################################################

# -----------------------------------------------------------------------------
# Switch user to 'rustdev' (UID 1000) to prevent running as root.
# -----------------------------------------------------------------------------
USER 1000

# -----------------------------------------------------------------------------
# Default working directory for the 'rustdev' user.
# -----------------------------------------------------------------------------
WORKDIR "$USERHOME/code"

# -----------------------------------------------------------------------------
# Volumes for persisting and caching Cargo artifacts (registry and git repos).
# This speeds up builds if the container is frequently rebuilt.
# -----------------------------------------------------------------------------
VOLUME ["/usr/local/cargo/registry", "/usr/local/cargo/git"]

###############################################################################
# Healthcheck
#   - Periodically checks that rustc is callable to confirm the container's
#     Rust toolchain remains functional.
###############################################################################
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD rustc --version || exit 1

###############################################################################
# Default Command
#   - Container entrypoint defaults to Bash, allowing interactive dev sessions.
###############################################################################
CMD ["/bin/bash"]
