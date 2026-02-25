<h1 align="center">Hyperspace CLI</h1>

<p align="center">
  The command-line client for the <a href="https://hyper.space">Hyperspace</a> decentralized P2P AI inference network.
</p>

<p align="center">
  <a href="https://github.com/hyperspaceai/aios-cli/stargazers"><img src="https://img.shields.io/github/stars/hyperspaceai/aios-cli?style=flat-square&color=yellow" alt="GitHub Stars" /></a>
  <a href="https://github.com/hyperspaceai/aios-cli/releases/latest"><img src="https://img.shields.io/github/v/release/hyperspaceai/aios-cli?style=flat-square&color=blue" alt="Latest Release" /></a>
  <a href="https://github.com/hyperspaceai/aios-cli/releases"><img src="https://img.shields.io/github/downloads/hyperspaceai/aios-cli/total?style=flat-square&color=green" alt="Total Downloads" /></a>
  <a href="https://github.com/hyperspaceai/aios-cli/blob/main/LICENSE"><img src="https://img.shields.io/github/license/hyperspaceai/aios-cli?style=flat-square" alt="License" /></a>
</p>

<p align="center">
  <a href="https://hyper.space">Website</a> |
  <a href="https://p2p.hyper.space">Dashboard</a> |
  <a href="https://x.com/HyperspaceAI">Twitter/X</a>
</p>

---

**Hyperspace CLI** (`hyperspace`) is the primary way to run a node on the Hyperspace network -- a fully decentralized peer-to-peer AI inference network with over 2 million nodes worldwide. Run local AI models, earn points, and contribute compute to the network.

> This is a **release-only repository**. Binary releases are published here for direct download and auto-update. The source code lives in a private monorepo.

## Table of Contents

- [Install](#install)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Features](#features)
- [Platform Support](#platform-support)
- [GPU Recommendations](#gpu-recommendations)
- [Configuration](#configuration)
- [Migrating from v1](#migrating-from-v1)
- [Troubleshooting](#troubleshooting)
- [Uninstall](#uninstall)
- [Links](#links)
- [Maintainer](#maintainer)
- [License](#license)

## Install

### Linux / macOS

```bash
curl -fsSL https://download.hyper.space/api/install | bash
```

### Windows (PowerShell as Administrator)

```powershell
curl https://download.hyper.space/api/install?platform=windows | powershell -
```

### What the installer does

- Auto-detects your OS and CPU architecture
- Downloads the correct pre-built binary
- Installs to `~/.hyperspace/bin/` and adds it to your `PATH`
- Installs `llama-server` for native GPU inference (CUDA on Linux/Windows, Metal on macOS)
- Auto-detects and integrates with existing [Ollama](https://ollama.com) installations
- On desktop machines, installs the **Hyperspace Tray app** (use `--no-tray` to skip)

The binary is named `hyperspace`. The legacy name `aios-cli` is kept as an alias for backwards compatibility.

## Quick Start

```bash
# Start your node (auto-detects hardware and selects the best profile)
hyperspace start

# Or start with all 9 capabilities enabled
hyperspace start --profile full

# Start with the management API exposed on a specific port
hyperspace start --api-port 8080

# Auto-download the best models for your GPU
hyperspace models pull --auto

# Check your node status, peer count, and points
hyperspace status
```

## Commands

| Command | Description |
|---|---|
| `hyperspace start` | Start the node daemon (background mode, survives terminal close) |
| `hyperspace stop` | Stop the running node |
| `hyperspace status` | Show node status, peer count, points balance, and tier |
| `hyperspace models pull --auto` | Auto-download optimal models based on available VRAM |
| `hyperspace models downloaded` | List all locally downloaded models |
| `hyperspace models delete <name>` | Delete a downloaded model |
| `hyperspace chat` | Interactive AI chat session using local inference |
| `hyperspace version` | Show the installed version and check for updates |

### Node Profiles

When starting a node, you can specify a profile that determines which capabilities are active:

```bash
hyperspace start                     # Auto-detect best profile
hyperspace start --profile full      # All capabilities
hyperspace start --profile inference # GPU inference only
hyperspace start --profile embedding # CPU-only embedding node
hyperspace start --profile relay     # Lightweight relay node
```

## Features

- **Native GPU Inference** -- Full local AI inference via node-llama-cpp with CUDA (NVIDIA) and Metal (Apple Silicon) support
- **Auto Model Selection** -- Automatically picks the best models for your available VRAM
- **Ollama Integration** -- Discovers and uses locally installed Ollama models out of the box
- **Background Daemon** -- Runs as a persistent background process that survives terminal close
- **Points System** -- Earn points through pulse verification rounds and serving inference to the network
- **P2P Networking** -- Built on libp2p with GossipSub, Kademlia DHT, and Circuit Relay for NAT traversal
- **Auto-Update** -- Checks for new versions on startup and applies updates seamlessly
- **Management API** -- REST and WebSocket API on a configurable port for programmatic control

### Network Capabilities

Each node can provide up to 9 distinct capabilities to the network:

| Capability | Description |
|---|---|
| **Inference** | Serve AI model inference requests from peers |
| **Embedding** | Generate text embeddings (CPU-only, runs on any hardware) |
| **Storage** | Distributed content-addressed block storage |
| **Memory** | Distributed vector store with replication |
| **Relay** | Help peers behind NATs connect via circuit relay |
| **Validation** | Participate in pulse verification rounds |
| **Orchestration** | Coordinate multi-step AI task pipelines |
| **Caching** | Cache inference results to speed up repeated queries |
| **Proxy** | Provide residential IP proxy service for AI agents |

## Platform Support

Pre-built binaries are available for the following platforms:

| Platform | Binary | Architecture |
|---|---|---|
| macOS | `aios-cli-aarch64-apple-darwin.tar.gz` | Apple Silicon (ARM64) |
| macOS | `aios-cli-x86_64-apple-darwin.tar.gz` | Intel (x86_64) |
| Linux | `aios-cli-x86_64-unknown-linux-gnu.tar.gz` | x86_64 |
| Linux | `aios-cli-x86_64-unknown-linux-gnu-cuda.tar.gz` | x86_64 with CUDA |
| Windows | `aios-cli-x86_64-pc-windows-msvc.zip` | x86_64 |
| Windows | `aios-cli-x86_64-pc-windows-msvc-cuda.zip` | x86_64 with CUDA |

The CUDA variants include GPU acceleration support for NVIDIA GPUs. On macOS, Metal acceleration for Apple Silicon is included in the standard binary.

## GPU Recommendations

The CLI automatically selects the best model for your hardware. Here is a general guide:

| GPU | VRAM | Recommended Model | Best For |
|---|---|---|---|
| GTX 1650 | 4 GB | Gemma 3 1B | General tasks |
| RTX 3060 / RTX 4060 | 8 GB | Gemma 3 4B | General tasks |
| RTX 4070 | 12 GB | GLM-4 9B | Multilingual |
| RTX 4080 | 16 GB | GPT-oss 20B | Reasoning |
| RTX 4090 / RTX 3090 | 24 GB | Gemma 3 27B | General tasks |
| A100 / H100 | 40-80 GB | Qwen2.5 Coder 32B | Code generation |

CPU-only nodes can still contribute by running embedding models (all-MiniLM-L6-v2) and acting as relay or storage nodes.

## Configuration

All data is stored under the `~/.hyperspace/` directory:

| Path | Description |
|---|---|
| `~/.hyperspace/bin/` | Installed binaries |
| `~/.hyperspace/config.json` | Node configuration |
| `~/.hyperspace/logs/` | Log files |
| `~/.hyperspace/models/` | Downloaded AI models |
| `~/.hyperspace/identity/` | Persistent peer identity (Ed25519 keypair) |

On Windows, the equivalent base path is `%LOCALAPPDATA%\Hyperspace\`.

## Migrating from v1

If you are running the v1 CLI (`aios-cli`), the upgrade is automatic. Key changes:

| v1 Command | v2 Equivalent |
|---|---|
| `aios-cli hive connect` | `hyperspace start` |
| `aios-cli hive select-tier` | Automatic (based on hardware) |
| `aios-cli hive points` | `hyperspace status` |

- The binary auto-updates from v1 to v2 on next launch.
- Your v1 points are **frozen and preserved** -- they will not be lost.
- The `aios-cli` command name continues to work as an alias.
- V2 replaces manual tier selection with automatic hardware detection and profile assignment.

## Troubleshooting

### Node not starting

1. Check the logs for errors:
   ```bash
   # Linux / macOS
   cat ~/.hyperspace/logs/hyperspace.log

   # Windows
   type %LOCALAPPDATA%\Hyperspace\logs\hyperspace.log
   ```

2. Ensure no other instance is already running:
   ```bash
   hyperspace status
   ```

3. If the port is in use, specify a different API port:
   ```bash
   hyperspace start --api-port 9090
   ```

### No GPU detected

- **NVIDIA**: Ensure CUDA drivers are installed and `nvidia-smi` works. Use the `-cuda` binary variant.
- **Apple Silicon**: Metal support is built-in. Ensure you are using the `aarch64-apple-darwin` binary.
- **CPU-only**: The node will fall back to CPU inference with smaller models and can still earn points via relay, embedding, and validation.

### Models not downloading

- Check available disk space (models range from 1-20 GB).
- Downloads support resume -- if interrupted, re-run `hyperspace models pull --auto` to continue.

### Connection issues

- The node needs outbound internet access on TCP port 4002 (WebSocket) for P2P connections.
- Nodes behind NAT are supported via circuit relay -- no port forwarding required.

## Uninstall

### Linux / macOS

```bash
curl https://download.hyper.space/api/uninstall | bash
```

### Windows (PowerShell)

```powershell
(Invoke-WebRequest "https://download.hyper.space/uninstall?platform=windows").Content | powershell -
```

This removes the binary, tray app, and configuration. Downloaded models in `~/.hyperspace/models/` are preserved by default.

## Links

- **Website**: [https://hyper.space](https://hyper.space)
- **Dashboard**: [https://p2p.hyper.space](https://p2p.hyper.space)
- **Twitter/X**: [@HyperspaceAI](https://x.com/HyperspaceAI)

## Maintainer

Varun ([@twobitapps](https://github.com/twobitapps))

For project updates, follow [@HyperspaceAI](https://x.com/HyperspaceAI) on X.

## License

See [LICENSE](LICENSE) for details.
