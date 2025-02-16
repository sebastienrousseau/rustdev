# RustDev (rustdev)

<!-- markdownlint-disable MD033 MD041 -->
<img src="https://kura.pro/rustdev/images/logos/rustdev.webp"
alt="RustDev logo" height="66" align="right" />
<!-- markdownlint-enable MD033 MD041 -->

An opinionated, secure, Alpine-based Docker container providing a complete Rust development environment with NeoVim configuration. Engineered for safety, efficiency, and developer productivity. **This is not an official Rust project** and is not affiliated with or supported by the Rust Foundation.

<!-- markdownlint-disable MD033 MD041 -->
<center>
<!-- markdownlint-enable MD033 MD041 -->

[![Made with Alpine Linux][alpine-badge]][08] [![Docker][docker-badge]][03] [![Rust][rust-badge]][01] [![NeoVim][neovim-badge]][04] [![Security][security-badge]][06] [![Build Status][build-badge]][07]

• [Features](#key-features) • [Prerequisites](#prerequisites) • [Installation](#installation) • [Usage](#usage) • [Configuration](#configuration) • [Security](#security) • [Contributing](#contributing)

<!-- markdownlint-disable MD033 MD041 -->
</center>
<!-- markdownlint-enable MD033 MD041 -->

## Disclaimer

This is an opinionated development environment that reflects specific preferences for tooling, configuration, and workflow. It is:

- Not an official Rust project
- Not affiliated with or supported by the Rust Foundation or its contributors
- Not intended to be a one-size-fits-all solution, this is a personal project
- Maintained independently and based on [docker-rust][02] and other open-source projects
- Provided as-is with no warranties (see [Licence](#licence))

## Overview

**RustDev** is a containerised Rust development environment that prioritises security, performance, and developer convenience. Built on Alpine Linux for a minimal footprint, it includes a pre-configured NeoVim setup with Rust-specific tooling, intelligent code completion, and Git integration.

## Key Features

- **Secure by Design**  
  - Alpine Linux base with minimal attack surface  
  - Non-root user operation  
  - Comprehensive security hardening  
  - Regular security updates  
  - Container isolation and resource limits

- **Rust Development Tools**  
  - Rust 1.84.1 with Cargo  
  - `rust-analyzer` for intelligent code completion  
  - Clippy for linting  
  - Cargo Watch for live reloading  
  - Cargo Audit for dependency scanning

- **Enhanced Development Experience**  
  - NeoVim with LazyVim configuration  
  - Intelligent code completion  
  - Syntax highlighting  
  - Git integration  
  - Terminal integration  
  - Fuzzy finding

- **Developer Convenience**  
  - Custom shell aliases  
  - Git workflow optimisation  
  - Cargo command shortcuts  
  - Pre-configured development tools  
  - Comprehensive documentation

## Prerequisites

- Docker 20.10 or newer
- Docker Compose V2
- Minimum 2GB RAM (4GB recommended)
- At least 5GB free disk space
- Git (for cloning the repository)
- Terminal with SSH support

## Installation

1. **Clone the repository:**

   ```bash
   git clone https://github.com/sebastienrousseau/rustdev.git
   cd rustdev
   ```

2. **Configure the environment (optional):**

   ```bash
   # Edit .env with your preferred settings
   ```

3. **Build and start the development environment:**

   ```bash
   docker-compose up --build -d
   ```

4. **Access the container:**

   ```bash
   docker exec -it rustdev bash
   ```

## Usage

### Shell Aliases

RustDev provides various productivity-enhancing aliases:

#### Cargo Commands

- `cgb` – Build the project
- `cgr` – Run the project
- `cgt` – Run tests
- `cgc` – Run Clippy
- `cgf` – Format code
- `cga` – Add dependency
- `cgu` – Update dependencies
- `cgd` – Show dependency tree

#### Git Commands

- `ga` – Stage all changes
- `gc` – Commit changes
- `gp` – Push changes
- `gpl` – Pull changes
- `gst` – Show status
- `gco` – Switch branches
- `gcb` – Create a new branch
- `glast` – Show the last commit

#### Navigation

- `e` or `v` – Launch NeoVim
- `l` – List files
- `t` – System monitor
- `x` – Exit shell

For a full list of aliases, type:

```bash
help
```

### NeoVim Configuration

NeoVim is set up to streamline Rust development, including:

- Intelligent code completion (`nvim-cmp`)
- Fuzzy finding (Telescope)
- Git integration
- Terminal integration (Toggleterm)
- Rust-specific tooling (`rust-analyzer`)
- Custom key mappings

To open NeoVim:

```bash
v
```

**Key mappings:**

- `<C-space>` – Hover actions
- `<Leader>a` – Code actions
- `<Leader>ff` – Find files
- `<Leader>fg` – Live grep
- `<Leader>fb` – Browse files

### Development Workflow

1. **Create a new Rust project:**

   ```bash
   cgn my-project
   cd my-project
   ```

2. **Edit your code:**

   ```bash
   v src/main.rs
   ```

3. **Build and run:**

   ```bash
   cgb   # Build project
   cgr   # Run project
   ```

4. **Typical cycle:**

   ```bash
   cgf   # Format code
   cgc   # Run Clippy
   cgt   # Run tests
   ```

## Configuration

### Environment Variables

Customise your environment in `.env`:

```bash
RUST_VERSION=1.84.1        # Rust toolchain version
USERNAME=rustdev           # Container username
USER_HOME=/home/rustdev    # Home directory path
CARGO_HOME=/usr/local/cargo
RUSTUP_HOME=/usr/local/rustup
```

### Docker Configuration

In `docker-compose.yml`, you can adjust the container settings:

```yaml
services:
  rust-app:
    # Name your final image if you like
    image: rustdev
    container_name: rustdev

    # Use the Dockerfile in the current directory
    build:
      context: .
      # Pass build-time args from the .env (substitution):
      args:
        RUST_VERSION: "${RUST_VERSION}"
        USERNAME: "${USERNAME}"
        USER_HOME: "${USER_HOME}"

    # Instruct Docker Compose to load environment variables from .env
    env_file:
      - .env

    # Drop privileges to user 1000:1000 inside container
    user: "1000:1000"

    # Default working directory inside the container
    working_dir: "/home/rustdev/code"

    # Keep STDIN open and allocate a pseudo-TTY (handy for interactive dev)
    stdin_open: true
    tty: true

    # Pass environment variables to the container at runtime
    # referencing the same .env variables
    environment:
      RUSTUP_HOME: "${RUSTUP_HOME}"
      CARGO_HOME: "${CARGO_HOME}"
      PATH: "${PATH}"
      RUST_VERSION: "${RUST_VERSION}"
      USERNAME: "${USERNAME}"
      USER_HOME: "${USER_HOME}"

    # Default command to run on container start
    command: ["/bin/bash", "--login"]
```

### NeoVim Configuration

Modify files in `plugins/` to change or add plugins:

- `coding.lua` – Code completion and LSP settings

  ```lua
  {
    "hrsh7th/nvim-cmp",
    opts = {
      -- Adjust completion behaviour
    }
  }
  ```

- `telescope.lua` – Fuzzy finder configuration

  ```lua
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      -- Customise finder settings
    }
  }
  ```

- `toggleterm.lua` – Terminal integration

  ```lua
  {
    "akinsho/toggleterm.nvim",
    opts = {
      -- Configure terminal behaviour
    }
  }
  ```

## Security

RustDev employs robust security measures:

- **Container Security**  
  - Non-root user operation  
  - Minimal Alpine Linux base  
  - Frequent security updates  
  - Limited attack surface  
  - Resource limits and isolation

- **Access Control**  
  - Restricted file permissions  
  - No sudo access  
  - Controlled environment variables  
  - Secure shell configuration

- **Build Security**  
  - Dependency scanning  
  - Cargo Audit integration  
  - Secure dependency management  
  - Version pinning

- **Runtime Security**  
  - Process isolation  
  - Memory restrictions  
  - CPU constraints  
  - Network limitations

## Troubleshooting

Common issues and how to resolve them:

1. **Container fails to build**  

   ```bash
   # Clear Docker build cache
   docker builder prune

   # Rebuild without cache
   docker compose build --no-cache
   ```

2. **Permission issues**

   ```bash
   # Fix ownership
   chown -R 1000:1000 .

   # Adjust permissions
   chmod -R 755 .
   ```

3. **Rust toolchain problems**

   ```bash
   # Update Rust
   rustup update

   # Validate installations
   rustc --version
   cargo --version
   ```

## Development Roadmap

Future features and enhancements include:

- [ ] Automated testing suite
- [ ] CI/CD pipeline templates
- [ ] Deployment scripts for cloud platforms
- [ ] Enhanced security features
- [ ] Further development tools integration
- [ ] Increase architecture support
- [ ] Kill switch for container
- [ ] Language Server Protocol (LSP) improvements
- [ ] Multi-language support
- [ ] Performance optimisations

## Contributing

We value contributions! To contribute:

1. Fork this repository
2. Create a feature branch
3. Implement your changes
4. Run all tests
5. Open a pull request

For major changes:

1. Open an issue first
2. Discuss proposed modifications
3. Implement changes
4. Update documentation

## Licence

This project is licensed under the MIT Licence. See the [LICENCE](LICENCE) file for details.

## Acknowledgements

- [Rust](https://www.rust-lang.org) – The Rust Programming Language
- [Alpine Linux](https://alpinelinux.org) – Security-focused Linux distribution
- [Docker](https://www.docker.com) – Container platform
- [NeoVim](https://neovim.io) – Hyperext    ension Vim-based editor
- [LazyVim](https://www.lazyvim.org) – NeoVim configuration framework
- [docker-rust](https://github.com/rust-lang/docker-rust) – Official Rust Docker images

[alpine-badge]: https://img.shields.io/badge/Alpine_Linux-0D597F?style=for-the-badge&logo=alpine-linux&logoColor=white
[docker-badge]: https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white
[rust-badge]: https://img.shields.io/badge/Rust-000000?style=for-the-badge&logo=rust&logoColor=white
[neovim-badge]: https://img.shields.io/badge/NeoVim-57A143?style=for-the-badge&logo=neovim&logoColor=white
[security-badge]: https://img.shields.io/badge/Security-Hardened-success?style=for-the-badge
[build-badge]: https://img.shields.io/badge/Build-Passing-success?style=for-the-badge

[01]: https://www.rust-lang.org
[02]: https://github.com/rust-lang/docker-rust
[03]: https://www.docker.com
[04]: https://neovim.io
[06]: #security
[07]: #contributing
[08]: https://alpinelinux.org
