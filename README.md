# Codux

<img src="./codux.jpg" alt="Codux banner" width="100%">

<p align="center">
  <strong>OpenAI Codex on Termux, packaged as a compact Debian proot installer for Android ARM64.</strong>
</p>

<p align="center">
  <em>One Bash script. One Debian boundary. One clean path to Codex on Android.</em>
</p>

Codux is a lightweight Bash installer for **OpenAI Codex on Termux**. It is built for **Android ARM64** devices and uses `proot-distro` to place Debian between Termux and the Codex binary, which keeps the install path compact and predictable.

[![Release](https://img.shields.io/github/v/release/Clock-Skew/Codux?style=flat-square)](https://github.com/Clock-Skew/Codux/releases/latest)
[![Version](https://img.shields.io/badge/version-0.1.4-1f6feb?style=flat-square)](./codux.sh)
[![Shell](https://img.shields.io/badge/shell-bash-89e051?style=flat-square&logo=gnubash&logoColor=white)](./codux.sh)
[![Platform](https://img.shields.io/badge/platform-Android%20%2B%20Termux-3DDC84?style=flat-square&logo=android&logoColor=white)](https://termux.dev/)
[![Runtime](https://img.shields.io/badge/runtime-Debian%20proot-olive?style=flat-square)](https://github.com/termux/proot-distro)
[![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](./LICENSE)
[![Codex](https://img.shields.io/badge/OpenAI-Codex-black?style=flat-square)](https://github.com/openai/codex)

## What Codux Is For

If you are searching for any of the following, this repo is meant to be a practical answer:

- Codex on Termux
- OpenAI Codex Android
- Codex CLI Termux
- Termux Debian proot
- OpenAI Codex ARM64 Android

Codux keeps the workflow small:

- one Bash installer
- Debian via `proot-distro`
- official Codex Linux ARM64 musl release
- helper launchers in Termux after install
- no Rust toolchain and no npm packaging layer

That makes it easier to audit, easier to adapt, and easier to understand than heavier wrapper stacks.

## How It Works

Codux follows a simple path:

1. confirm the device is ARM64 Android/Termux
2. refresh Termux packages to avoid partial-upgrade breakage
3. install `proot-distro`, `curl`, `ca-certificates`, and `openssl`
4. install Debian with `proot-distro`
5. download the latest Codex Linux ARM64 musl archive
6. install Codex inside Debian
7. create helper commands for later use
8. open the Debian shell so Codex is ready to run

## Install

```bash
chmod +x codux.sh
./codux.sh
```

The default install path is intentionally opinionated because Termux upgrades can break if the package stack is only partially updated.

### Manual Clone

If you want to clone the repo first:

```bash
git clone https://github.com/Clock-Skew/Codux.git
cd Codux
chmod +x codux.sh
./codux.sh
```

## First Run

Codux will open the Debian proot shell after installation by default.

If you are doing the manual flow, the important step is:

```bash
proot-distro login debian
```

Codex runs inside Debian, not directly in the Termux shell.

Then run:

```bash
codex
```

## Helper Commands

Codux creates these Termux helpers:

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

- `--no-enter-distro` skips the automatic `proot-distro login` step after install
- `--no-upgrade` skips the Termux package upgrade path
- `--workdir` changes the workspace directory inside Debian
- `--distro` changes the `proot-distro` container name
- `--codex-url` overrides the release archive URL

## Screenshots

These sequential captures show the real install flow on device.

<p><img src="./1.png" alt="Codux screenshot 1" width="100%"></p>
<p><img src="./2.png" alt="Codux screenshot 2" width="100%"></p>
<p><img src="./3.png" alt="Codux screenshot 3" width="100%"></p>
<p><img src="./4.png" alt="Codux screenshot 4" width="100%"></p>
<p><img src="./5.png" alt="Codux screenshot 5" width="100%"></p>
<p><img src="./6.png" alt="Codux screenshot 6" width="100%"></p>

## Compatibility

Codux is conservative about compatibility. If the device is not ARM64 or Termux is badly out of date, expect install issues.

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

Then rerun Codux. This repo upgrades Termux by default because partial upgrades can break native libraries.

### I am back in Termux and Codex does not run

Enter Debian first:

```bash
proot-distro login debian
```

Then run:

```bash
codex
```

## Project Facts

- Version: `0.1.4`
- Language: Bash
- License: MIT
- Project type: Android/Termux installer
- Default Debian workspace: `/root/codex-work`
