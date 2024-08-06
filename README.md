# aiOS CLI

## Overview

`aios-cli` is a command-line interface to access similar functionalities as the [aiOS desktop app](https://aios.network/). The CLI is a nicer UX if you're a developer and tend to stay in the terminal or would like to run a node on servers as this does not require a desktop environment to run.

The CLI has a lot of commands, but the basic idea is that it allows you to run your local models (for personal inferences), host your downloaded models to provide inference to the network and earn points, and to use models other people are hosting for personal inference.

## Installation

To install on all platforms you can use our install script (located here in the repo or) available hosted on our download endpoint. These scripts will download the latest release, install any required GPU drivers, and move the binary to somewhere in  your `PATH` so that you can access `aios-cli` globally. You can learn more about how the script works [here](/scripts/README.md).

While the script is the recommended way to install, you can also download the binaries directly from the releases section of this repository.

### Linux

```shell
curl https://download.hyper.space/api/install | bash
```

### Mac

```shell
curl https://download.hyper.space/api/install | sh
```

### Windows

You must be running in an Administrator PowerShell for both installation and uninstallation scripts to work on Windows

```shell
# If you have a real version of `curl` (i.e. something that returns a valid version when you do `curl --version`)
curl https://download.hyper.space/api/install?platform=windows | powershell -
# Otherwise
(Invoke-WebRequest "https://download.hyper.space/install?platform=windows").Content | powershell -
```

## Uninstallation

Uninstallation is similar but just change the endpoint to `/uninstall`

### Linux

```shell
curl https://download.hyper.space/api/uninstall | bash
```

### Mac

```shell
curl https://download.hyper.space/api/uninstall | sh
```

### Windows

```shell
(Invoke-WebRequest "https://download.hyper.space/uninstall?platform=windows").Content | powershell -
```

## Docker

There are 2 pre-built docker images available, one on CPU that will install and serves Mistral 7B and one that requires an Nvidia GPU that installs and serves Llama3.

- [`cpu-mistral-7b`](https://hub.docker.com/repository/docker/kartikhyper/aios)
- [`nvidia-llama-3`](https://hub.docker.com/repository/docker/kartikhyper/aios-nvidia)

Make sure that the environment you run the Nvidia image in has `nvidia-container-toolkit` installed and selected as the default runtime.

## Usage

```
aios-cli [OPTIONS] <COMMAND>
```

## Example

Since there's a lot of commands coming up here is a basic example of some common use cases:

```shell
# Start the actual daemon
aios-cli start

# See what models are available
aios-cli models available
# Install one of them locally
aios-cli models add hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf
# Run a local inference using it
aios-cli infer --model hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf --prompt "Can you explain how to write an HTTP server in Rust?"

# Import your private key from a .pem or .base58 file
aios-cli hive import-keys ./my.pem
# Set those keys as the preferred keys for this session
aios-cli hive login
# Connect to the network (now providing inference for the model you installed before)
aios-cli hive connect

# Run an inference through someone else on the network (as you can see it's the exact same format as the normal `infer` just prefixed with `hive`)
aios-cli hive infer --model hf:TheBloke/Mistral-7B-Instruct-v0.1-GGUF:mistral-7b-instruct-v0.1.Q4_K_S.gguf --prompt "Can you explain how to write an HTTP server in Rust?"

# There's a shortcut to start and login/connect to immediately start hosting local models as well
aios-cli start --connect
```

## Global Options

- `--verbose`: Increases the verbosity of the output. Useful for debugging or getting more detailed information.
- `-h, --help`: Prints the help message, showing available commands and options.

## Commands

### `start`

Starts the local aiOS daemon.

Usage: `aios-cli start`

### `status`

Checks the status of your local aiOS daemon, shows you whether it is still running.

Usage: `aios-cli status`

### `kill`

Terminates the currently running local aiOS daemon. This can be useful if you find yourself in a broken state and need a clean way to restart.

Usage: `aios-cli kill`

### `models`

Commands to manage your local models.

Usage: `aios-cli models [OPTIONS] <COMMAND>`

Subcommands:

- `list`: Lists currently downloaded models.
- `add`: Downloads a new model.
- `remove`: Removes a downloaded model.
- `check`: Checks if the given model is valid on disk.
- `migrate`: Migrates a model from V0 of aiOS to the new location. It is highly unlikely that you would need to use this now.
- `available`: Lists the models available on the network.
- `help`: Prints the help message for the models command or its subcommands.

### `system-info`

Shows you your system specifications that are relevant for model inference.

Usage: `aios-cli system-info`

### `infer`

Uses local models to perform inference.

Usage: `aios-cli infer [OPTIONS]`

(Additional options and parameters for inference would be listed here)

### `hive`

Runs commands using the Hive servers. For context Hive is what the Hyperspace hosted servers are referred to as.

Usage: `aios-cli hive [OPTIONS] <COMMAND>`

Subcommands:

- `login`: Login with your keypair credentials.
- `import-keys`: Import your keys (either ed25519 PEM file or base58 file).
- `connect`: Connect to the network and provide inference using local models.
- `whoami`: Get currently signed in keys.
- `disconnect`: Disconnect from the network.
- `infer`: Run an inference on the network.
- `listen`: Listen for all hive events.
- `interrupt`: Interrupt an inference you are currently doing for the network.
- `help`: Print the help message for the hive command or its subcommands.

### `version`

Prints the current version of the aiOS CLI tool.

Usage: `aios-cli version`

### `help`

Prints the help message or the help of the given subcommand(s).

Usage:
- `aios-cli help`: Prints general help
- `aios-cli help [COMMAND]`: Prints help for a specific command

## Updates

When you run `start` the CLI will be constantly polling and checking for updates as this software is in an early version and it is likely that there are breaking changes made at the network level that can make your node obsolete. These checks for updates and whether they were successful or not will show up in your logs for troubleshooting if you think something has gone wrong in the process.

To ensure that you are on the latest version or update while not in a started state, just run the `version` command while connected to the internet and the CLI will automatically check and update itself. If for some reason that's not working you can re-run the installation steps and the script will install the latest version.

## Troubleshooting

For help with issues please make sure to attach the most recent few log files. These can be found at:

- `linux`: `~/.cache/hyperspace/kernel-logs`
- `mac`: `~/Library/Caches/hyperspace/kernel-logs`
- `windows`: `%LOCALAPPDATA%\Hyperspace\kernel-logs`

## Support

Feel free to open an issue here in the GitHub if you run into any issues or think the documentation can be improved.
