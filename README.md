<h1 align="center">Hyperspace CLI</h1>

<p align="center">
  The command-line agent for the <a href="https://hyper.space">Hyperspace</a> decentralized P2P AI inference network.
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

**Hyperspace CLI** (`hyperspace`) is the primary way to run an agent on the Hyperspace network -- a fully decentralized peer-to-peer AI inference network with over 2 million agents worldwide. Run local AI models, earn points, and contribute compute to the network.

> This is a **release-only repository**. Binary releases are published here for direct download and auto-update. The source code lives in a private monorepo.

## Table of Contents

- [Install](#install)
- [Quick Start](#quick-start)
- [Command Reference](#command-reference)
- [Features](#features)
- [Platform Support](#platform-support)
- [GPU Recommendations](#gpu-recommendations)
- [Configuration](#configuration)
- [Migrating from v1](#migrating-from-v1)
- [Troubleshooting](#troubleshooting)
- [Uninstall](#uninstall)
- [Links](#links)
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

The binary is named `hyperspace`. The legacy name `aios-cli` is kept as an alias for backward compatibility.

## Quick Start

```bash
# Start your agent (auto-detects hardware and selects the best profile)
hyperspace start

# Or start with all 9 capabilities enabled
hyperspace start --profile full

# Start with the management API on a specific port
hyperspace start --api-port 8080

# Auto-download the best models for your GPU
hyperspace models pull --auto

# Check your agent status, peer count, and points
hyperspace status
```

## Command Reference

### Core Commands

| Command | Description |
|---------|-------------|
| `hyperspace start` | Start the agent daemon |
| `hyperspace status` | Show agent status, peers, tier, points, uptime |
| `hyperspace kill` | Stop the running agent (`-f` to force) |
| `hyperspace chat` | Interactive conversational agent mode |
| `hyperspace system-info` | Display system specs, GPU, VRAM, recommended tier |
| `hyperspace version` | Show version (`--check-update` to check for new) |
| `hyperspace update` | Check for and install updates (`--check` for dry run) |
| `hyperspace hive listen` | Stream live agent events (polls every 5s) |

### Start Options

```bash
hyperspace start                          # Auto-detect everything
hyperspace start --profile full           # All 9 capabilities
hyperspace start --profile inference      # GPU inference only
hyperspace start --profile embedding      # CPU-only embedding agent
hyperspace start --profile relay          # Lightweight relay agent
hyperspace start --profile storage        # Storage + memory
hyperspace start --api-port 8080          # Management API port
hyperspace start --cuda                   # Force CUDA acceleration
hyperspace start --verbose                # Verbose logging
hyperspace start --no-api                 # Disable management API
```

### Model Management

| Command | Description |
|---------|-------------|
| `hyperspace models list` | Show all models in the catalog |
| `hyperspace models available` | List models compatible with your VRAM |
| `hyperspace models pull --auto` | Auto-download best models for your GPU |
| `hyperspace models pull <model-id>` | Download a specific GGUF model |
| `hyperspace models downloaded` | List locally downloaded models |
| `hyperspace models delete <model-id>` | Delete a downloaded model |
| `hyperspace models add <model-id>` | Register a model on the network |
| `hyperspace models remove <model-id>` | Unregister a model |
| `hyperspace models check` | Check loaded models and network status |

### Inference

```bash
hyperspace infer --prompt "Explain quantum computing" --p2p   # P2P network inference
hyperspace infer --prompt "Hello" --local                      # Local inference
hyperspace infer --model <model-id> --prompt "Hello"           # Specific model
hyperspace infer --interactive                                 # Interactive chat
hyperspace chat                                                # Agent chat mode
```

### Wallet and Staking

| Command | Description |
|---------|-------------|
| `hyperspace wallet show` | Display address, balance, points, USDC equivalent |
| `hyperspace wallet export` | Export address (machine-readable, for scripting) |
| `hyperspace wallet costs` | Show task cost estimates per capability |
| `hyperspace wallet settle` | Trigger manual USDC settlement check |
| `hyperspace wallet staking` | Show staking status, delegations, rewards |
| `hyperspace wallet stake <amount>` | Stake points |
| `hyperspace wallet unstake <amount>` | Begin unstaking |
| `hyperspace wallet claim-rewards` | Claim accumulated staking rewards |
| `hyperspace wallet delegate <amount> <peer-id>` | Delegate to a validator |
| `hyperspace wallet revoke <delegation-id>` | Revoke a delegation |

### Identity

| Command | Description |
|---------|-------------|
| `hyperspace identity export` | Export private key, public key, peer ID |
| `hyperspace identity export --json` | Export as JSON |
| `hyperspace identity export -o key.json` | Export to file |
| `hyperspace hive whoami` | Display agent identity and connection status |
| `hyperspace hive login -k <base58>` | Import identity from Ed25519 private key |
| `hyperspace hive import-keys <path>` | Import identity from key file |

### Configuration

| Command | Description |
|---------|-------------|
| `hyperspace hive select-tier --auto` | Auto-detect tier from GPU |
| `hyperspace hive select-tier --tier <n>` | Manually set compute tier |
| `hyperspace hive allocate --mode power` | Maximum earnings, higher resource usage |
| `hyperspace hive allocate --mode chill` | Lower resource usage, reduced earnings |

### Proxy

| Command | Description |
|---------|-------------|
| `hyperspace proxy status` | Show proxy service status and bandwidth |
| `hyperspace proxy test [url]` | Test-fetch a URL through a proxy peer |
| `hyperspace proxy info` | Show proxy capability details |

### System

| Command | Description |
|---------|-------------|
| `hyperspace install-service` | Register as OS service (auto-start on boot) |
| `hyperspace uninstall-service` | Remove OS service registration |
| `hyperspace migrate` | Migrate from v1 (`--dry-run` to preview) |
| `hyperspace login` | Log in via browser OAuth (for Thor analysis) |
| `hyperspace logout` | Log out |

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

Each agent provides up to 9 capabilities:

| Capability | Description |
|------------|-------------|
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

| Platform | Binary | Architecture |
|----------|--------|-------------|
| macOS | `aios-cli-aarch64-apple-darwin.tar.gz` | Apple Silicon (ARM64) |
| macOS | `aios-cli-x86_64-apple-darwin.tar.gz` | Intel (x86_64) |
| Linux | `aios-cli-x86_64-unknown-linux-gnu.tar.gz` | x86_64 |
| Linux | `aios-cli-x86_64-unknown-linux-gnu-cuda.tar.gz` | x86_64 with CUDA |
| Windows | `aios-cli-x86_64-pc-windows-msvc.zip` | x86_64 |
| Windows | `aios-cli-x86_64-pc-windows-msvc-cuda.zip` | x86_64 with CUDA |

The CUDA variants include GPU acceleration for NVIDIA GPUs. On macOS, Metal acceleration for Apple Silicon is included in the standard binary.

## GPU Recommendations

| GPU | VRAM | Recommended Model | Best For |
|-----|------|-------------------|----------|
| GTX 1650 | 4 GB | Gemma 3 1B | General |
| RTX 3060 / RTX 4060 | 8 GB | Gemma 3 4B | General |
| RTX 4070 | 12 GB | GLM-4 9B | Multilingual |
| RTX 4080 | 16 GB | GPT-oss 20B | Reasoning |
| RTX 4090 / RTX 3090 | 24 GB | Gemma 3 27B | General |
| A100 / H100 | 40-80 GB | Qwen2.5 Coder 32B | Code |

CPU-only agents can still contribute by running embedding models and acting as relay or storage agents.

## Configuration

All data is stored under `~/.hyperspace/`:

| Path | Description |
|------|-------------|
| `~/.hyperspace/bin/` | Installed binaries |
| `~/.hyperspace/config.json` | Agent configuration |
| `~/.hyperspace/logs/` | Log files |
| `~/.hyperspace/models/` | Downloaded AI models |
| `~/.hyperspace/identity.json` | Persistent Ed25519 keypair and peer ID |
| `~/.hyperspace/status.json` | Points and status data |
| `~/.hyperspace/install-method` | Install source marker (analytics) |

On Windows, the equivalent base path is `%LOCALAPPDATA%\Hyperspace\`.

## Migrating from v1

| v1 Command | v2 Equivalent |
|------------|---------------|
| `aios-cli hive connect` | `hyperspace start` |
| `aios-cli hive select-tier` | Automatic (hardware detection) |
| `aios-cli hive points` | `hyperspace status` |

- The binary auto-updates from v1 to v2 on next launch.
- Your v1 points are **frozen and preserved**.
- The `aios-cli` command name continues to work as an alias.
- V2 replaces manual tier selection with automatic hardware detection.

## Troubleshooting

### Agent not starting

```bash
# Check logs
cat ~/.hyperspace/logs/hyperspace.log

# Ensure no other instance running
hyperspace status

# Try different API port
hyperspace start --api-port 9090
```

### No GPU detected

- **NVIDIA**: Ensure CUDA drivers are installed and `nvidia-smi` works.
- **Apple Silicon**: Metal support is built-in with the `aarch64-apple-darwin` binary.
- **CPU-only**: Falls back to CPU inference with smaller models. Use `--profile embedding`.

### Models not downloading

- Check available disk space (models range from 1-20 GB).
- Downloads support resume -- re-run `hyperspace models pull --auto` to continue.

### Connection issues

- Outbound internet access on TCP port 4002 (WebSocket) required.
- Agents behind NAT are supported via circuit relay -- no port forwarding needed.

## Uninstall

### Linux / macOS

```bash
curl https://download.hyper.space/api/uninstall | bash
```

### Windows (PowerShell)

```powershell
(Invoke-WebRequest "https://download.hyper.space/uninstall?platform=windows").Content | powershell -
```

Removes the binary, tray app, and configuration. Downloaded models in `~/.hyperspace/models/` are preserved by default.

## Links

- **Website**: [https://hyper.space](https://hyper.space)
- **Dashboard**: [https://p2p.hyper.space](https://p2p.hyper.space)
- **Twitter/X**: [@HyperspaceAI](https://x.com/HyperspaceAI)

## Maintainer

Varun ([@twobitapps](https://github.com/twobitapps))

## License

See [LICENSE](LICENSE) for details.
