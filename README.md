# Codux

<img src="./codux.jpg" alt="Codux banner" width="100%">

Codux is a lightweight Bash installer for **OpenAI Codex on Termux**. It sets up a Debian proot environment on **Android ARM64**, installs the Codex CLI release inside Debian, and opens the shell so Codex can run in the environment it expects.

[![Version](https://img.shields.io/badge/version-0.1.4-1f6feb?style=flat-square)](./codux.sh)
[![Shell](https://img.shields.io/badge/shell-bash-89e051?style=flat-square&logo=gnubash&logoColor=white)](./codux.sh)
[![Platform](https://img.shields.io/badge/platform-Android%20%2B%20Termux-3DDC84?style=flat-square&logo=android&logoColor=white)](https://termux.dev/)
[![Runtime](https://img.shields.io/badge/runtime-Debian%20proot-olive?style=flat-square)](https://github.com/termux/proot-distro)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](./LICENSE)
[![Codex](https://img.shields.io/badge/OpenAI-Codex-black?style=flat-square)](https://github.com/openai/codex)

## Why Codux

Most "Codex on Termux" guides are either too manual, too fragile, or tied to heavier packaging layers. Codux stays compact:

- one installer script
- Debian via `proot-distro`
- official Codex Linux ARM64 musl release
- Termux launcher helpers after install
- predictable behavior on ARM64 Android

This makes it easier to audit, easier to adapt, and easier to keep working on phones that are only partly compatible with desktop-style install flows.

## What It Does

- detects ARM64 Android/Termux
- updates Termux packages by default to avoid partial-upgrade breakage
- installs `proot-distro`, `curl`, `ca-certificates`, and `openssl`
- installs Debian through `proot-distro`
- downloads the latest Codex Linux ARM64 musl archive
- extracts and installs Codex inside Debian
- creates Termux helper commands
- opens Debian after installation by default

## What It Does Not Do

- does not support non-ARM64 devices
- does not replace Debian or Termux
- does not build a custom Codex fork
- does not hide the proot boundary
- does not try to be a generic package manager

## Requirements

- Android device with ARM64 CPU
- Termux
- working internet connection
- enough storage for Termux, Debian, and the Codex binary

## Install

```bash
chmod +x codux.sh
./codux.sh
```

The installer will:

1. update Termux packages
2. install proot dependencies
3. install Debian
4. install Codex inside Debian
5. open the Debian shell when finished

## First Run

After install, Codux will already be inside the Debian proot shell.

If you want the manual flow, the command you need is:

```bash
proot-distro login debian
```

Then run Codex from inside Debian:

```bash
codex
```

## Helper Commands

Codux creates these Termux commands:

- `codex-debian` - launch Codex inside Debian
- `codex-login-debian` - run Codex device-auth login inside Debian
- `codex-version-debian` - print the installed Codex version

## Flags

```bash
./codux.sh --help
./codux.sh --version
./codux.sh --no-enter-distro
./codux.sh --no-upgrade
./codux.sh --distro debian
./codux.sh --workdir codex-work
```

Useful options:

- `--no-enter-distro` keeps the installer from dropping into Debian after install
- `--no-upgrade` skips the default Termux upgrade path
- `--workdir` changes the workspace directory inside Debian
- `--distro` changes the `proot-distro` container name
- `--codex-url` overrides the release archive URL

## Compatibility

Validated on:

- Moto G Play 2024 XT2413V
- ARM64 Android
- Termux
- Debian proot

Codux is intentionally conservative about compatibility. If a device is not ARM64 or Termux is badly out of date, expect install issues.

## Troubleshooting

### Termux asks for a mirror

Run:

```bash
termux-change-repo
```

Then select a working Termux mirror and rerun the installer.

### `curl` or `proot-distro` fails after a partial upgrade

Run:

```bash
pkg upgrade -y
```

Then rerun Codux. This repo defaults to a full upgrade because partial upgrades can break native Termux libraries.

### I am back in Termux and Codex does not run

Enter Debian first:

```bash
proot-distro login debian
```

Then run:

```bash
codex
```

## Search Terms

Codux targets the same search intent people use when looking for:

- Codex on Termux
- OpenAI Codex Android
- Codex CLI Termux
- Termux Debian proot
- OpenAI Codex ARM64 Android
- Codex installer for Termux
- lightweight Codex Android setup

## Release Notes

- Version: `0.1.4`
- Language: Bash
- License: MIT
- Project type: Android/Termux installer

