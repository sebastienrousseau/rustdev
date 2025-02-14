# Base Alpine Linux (lightweight & secure)
FROM alpine:3.21

# Metadata
LABEL org.opencontainers.image.source="https://github.com/rust-lang/docker-rust" \
    maintainer="Sebastien Rousseau"

################################################################################
##### Define build arguments 
################################################################################
ARG ARCH=$(apk --print-arch)
ARG LANG="C.UTF-8"
ARG NAME="RustDev"
ARG OS="linux"
ARG SHELL="/bin/bash"
ARG TIMEZONE="Europe/London"
ARG TZ="UTC"
ARG VERSION="0.0.1"

################################################################################
##### Set environment variables
################################################################################
ENV ARCH=${ARCH} \
    CARGO_HOME=/usr/local/cargo \
    LANG=${LANG} \
    NAME=${NAME} \
    OS=${OS} \
    PATH="/usr/local/cargo/bin:/usr/local/rustup/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/bin:/usr/sbin" \
    RUST_VERSION=1.84.1 \
    RUSTUP_HOME=/usr/local/rustup \
    SHELL=${SHELL} \
    TIMEZONE=${TIMEZONE} \
    TZ=${TZ} \
    USERHOME=/home/rustdev \
    USERNAME=rustdev \
    VERSION=${VERSION}

################################################################################
##### Install Required System Dependencies Securely
################################################################################
RUN set -eux; \
    apk update && apk upgrade && \
    apk add --no-cache \
    bash \
    btop \
    ca-certificates \
    coreutils \
    curl \
    gcc \
    git \
    libc-dev \
    musl-dev \
    nodejs \
    neovim \
    ripgrep \
    build-base \
    wget \
    openssl-dev \
    pkgconfig \
    shadow \
    vim \
    tzdata && \
    update-ca-certificates && \
    ln -snf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && echo ${TIMEZONE} > /etc/timezone && \
    rm -rf /var/cache/apk/* /tmp/* /root/.ash_history

################################################################################
##### Securely Install Rust using Rustup
################################################################################
RUN set -eux; \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
    x86_64) rustArch='x86_64-unknown-linux-musl'; \
    rustupSha256='1455d1df3825c5f24ba06d9dd1c7052908272a2cae9aa749ea49d67acbe22b47' ;; \
    aarch64) rustArch='aarch64-unknown-linux-musl'; \
    rustupSha256='7087ada906cd27a00c8e0323401a46804a03a742bd07811da6dead016617cc64' ;; \
    *) echo >&2 "unsupported architecture: $apkArch"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/1.27.1/${rustArch}/rustup-init"; \
    wget "$url"; \
    echo "${rustupSha256} *rustup-init" | sha256sum -c -; \
    chmod +x rustup-init; \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain $RUST_VERSION --default-host ${rustArch}; \
    rm rustup-init; \
    rustup --version; \
    cargo --version; \
    rustc --version

################################################################################
##### Install Useful Development Tools Inside the Container
################################################################################
RUN set -eux; \
    cargo install cargo-watch && \
    cargo install cargo-audit && \
    rm -rf /usr/local/cargo/registry /usr/local/cargo/git

################################################################################
##### Create a Non-Root User for Security and Set Permissions
################################################################################
RUN set -eux; \
    adduser -D -h "$USERHOME" -u 1000 "$USERNAME" && \
    mkdir -p "$USERHOME/.cargo" /usr/local/cargo/registry /usr/local/cargo/git && \
    chown -R "$USERNAME":"$USERNAME" /usr/local/cargo /usr/local/rustup "$USERHOME" && \
    chmod -R 755 /usr/local/cargo /usr/local/rustup

################################################################################
##### Clone the NvChad repository
################################################################################
RUN set -eux; \
    mkdir -p "$USERHOME/.config" && \
    git clone https://github.com/NvChad/starter "$USERHOME/.config/nvim" && \
    chown -R "$USERNAME":"$USERNAME" "$USERHOME/.config"

################################################################################
##### Set up the Rust Environment & PATH Permanently
################################################################################
COPY --chown=$USERNAME:$USERNAME .bashrc $USERHOME/.bashrc
COPY --chown=$USERNAME:$USERNAME .bash_aliases $USERHOME/.bash_aliases
COPY --chown=$USERNAME:$USERNAME .bash_profile $USERHOME/.bash_profile

# Create and configure the rust environment file
RUN set -eux; \
    echo 'export CARGO_HOME=/usr/local/cargo' > /etc/profile.d/rust.sh && \
    echo 'export RUSTUP_HOME=/usr/local/rustup' >> /etc/profile.d/rust.sh && \
    echo 'export PATH="/usr/local/cargo/bin:/usr/local/rustup/bin:$PATH"' >> /etc/profile.d/rust.sh && \
    chmod +x /etc/profile.d/rust.sh && \
    # Ensure rust.sh is sourced in all relevant profile files
    echo 'source /etc/profile.d/rust.sh' >> /etc/profile && \
    echo 'source /etc/profile.d/rust.sh' >> "$USERHOME/.profile" && \
    echo 'source /etc/profile.d/rust.sh' >> "$USERHOME/.bash_profile" && \
    echo 'source /etc/profile.d/rust.sh' >> "$USERHOME/.bashrc" && \
    # Ensure .bashrc is sourced in .bash_profile
    echo '[ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"' >> "$USERHOME/.bash_profile" && \
    # Set proper ownership
    chown "$USERNAME":"$USERNAME" "$USERHOME/.profile" "$USERHOME/.bash_profile" "$USERHOME/.bashrc" && \
    # Ensure the shell is interactive
    echo 'export PS1="\u@\h:\w\$ "' >> "$USERHOME/.bashrc"

# Make bash the default shell for the user
RUN chsh -s /bin/bash "$USERNAME"

################################################################################
##### Harden the Alpine Distribution for Security
################################################################################
RUN set -eux; \
    # Remove unneeded cron directories
    rm -rf /var/spool/cron /etc/crontabs /etc/periodic; \
    # Remove unnecessary binaries from sbin directories
    find /sbin /usr/sbin ! -type d -a ! -name apk -a ! -name ln -delete; \
    # Remove world-writable permissions (for both files and directories)
    find / -xdev -type d -perm /0002 -exec chmod o-w {} +; \
    find / -xdev -type f -perm /0002 -exec chmod o-w {} +; \
    # Secure /tmp (if required)
    chmod 777 /tmp/; \
    # Retain only essential accounts in /etc/group and /etc/passwd
    sed -i -r '/^(root|nobody|'"$USERNAME"')/!d' /etc/group; \
    sed -i -r '/^(root|nobody|'"$USERNAME"')/!d' /etc/passwd; \
    # Lock root and nobody (but keep $USERNAME interactive)
    sed -i -r '/^(root|nobody):/ s#^(.*):[^:]*$#\1:/sbin/nologin#' /etc/passwd; \
    while IFS=: read -r user _; do \
    if [ "$user" != "$USERNAME" ]; then \
    passwd -l "$user"; \
    fi; \
    done < /etc/passwd || true; \
    # Remove suspicious executables ending with '-'
    find /bin /etc /lib /sbin /usr -xdev -type f -regex '.*-$' -exec rm -f {} \; ; \
    # Ensure directories have proper ownership and permissions
    find /bin /etc /lib /sbin /usr -xdev -type d -exec chown root:root {} \; -exec chmod 0755 {} \;

################################################################################
##### Final Cleanup
################################################################################
RUN rm -rf /var/cache/apk/* /tmp/* /root/.ash_history "$USERHOME/.bash_history"

################################################################################
##### Set User, Default Working Directory, and Persistent Volumes
################################################################################
USER "$USERNAME"
WORKDIR "$USERHOME/app"
VOLUME ["/usr/local/cargo/registry", "/usr/local/cargo/git"]

################################################################################
##### Ensure Rust is Available in All Shell Sessions
################################################################################
CMD ["/bin/bash"]
