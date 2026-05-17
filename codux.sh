#!/data/data/com.termux/files/usr/bin/bash
# codux.sh
#
# Install OpenAI Codex CLI on Android/Termux by using Debian through
# proot-distro. This targets ARM64 Android devices where native Termux npm
# optional dependencies may fail, but the official Linux ARM64 musl Codex
# release can run inside a Debian userland.
#
# Tested POC device:
#   Moto G Play 2024 XT2413V, ARM64, Termux, Debian proot-distro.

set -Eeuo pipefail

readonly DEFAULT_DISTRO="debian"
readonly DEFAULT_WORKDIR_NAME="codex-work"
readonly DEFAULT_CODEX_ASSET="codex-aarch64-unknown-linux-musl.tar.gz"
readonly DEFAULT_CODEX_URL="https://github.com/openai/codex/releases/latest/download/${DEFAULT_CODEX_ASSET}"
readonly VERSION="0.1.4"

DISTRO="${DEFAULT_DISTRO}"
WORKDIR_NAME="${DEFAULT_WORKDIR_NAME}"
CODEX_URL="${DEFAULT_CODEX_URL}"
RUN_TERMUX_UPGRADE=1
ENTER_DISTRO_AFTER_INSTALL=1
PRINT_CONFIG=0

info() {
	printf '\033[1;34m[INFO]\033[0m %s\n' "$*"
}

warn() {
	printf '\033[1;33m[WARN]\033[0m %s\n' "$*"
}

fail() {
	printf '\033[1;31m[FAIL]\033[0m %s\n' "$*" >&2
	exit 1
}

on_error() {
	local status=$?
	printf '\033[1;31m[FAIL]\033[0m Install failed near line %s with exit code %s.\n' "${1:-unknown}" "$status" >&2
	exit "$status"
}

trap 'on_error "$LINENO"' ERR

usage() {
	cat <<'USAGE'
Codux - Codex CLI installer for Termux + Debian proot

Usage:
  ./codux.sh [options]

Options:
  --distro NAME          proot-distro container name to use. Default: debian
  --workdir NAME         Codex workspace directory under root home. Default: codex-work
  --codex-url URL        Codex release archive URL. Default: latest ARM64 musl release
  --upgrade-termux       Run pkg upgrade -y before installing dependencies. Default
  --no-upgrade           Skip pkg upgrade -y. Not recommended on fresh/stale Termux
  --no-enter-distro      Do not enter the Debian proot shell after install
  --print-config         Print resolved install settings and exit
  --version              Print the Codux version and exit
  -h, --help             Show this help text

Installed Termux commands:
  codex-debian           Start Codex inside Debian/proot
  codex-login-debian     Run Codex device-code login inside Debian/proot
  codex-version-debian   Print the installed Codex version

Examples:
  chmod +x codux.sh
  ./codux.sh
  ./codux.sh --no-upgrade
  ./codux.sh --workdir projects/codex-work
  ./codux.sh --version
USAGE
}

parse_args() {
	while [ "$#" -gt 0 ]; do
		case "$1" in
		--distro)
			shift
			[ "$#" -gt 0 ] || fail "--distro requires a value."
			DISTRO="$1"
			;;
		--workdir)
			shift
			[ "$#" -gt 0 ] || fail "--workdir requires a value."
			WORKDIR_NAME="$1"
			;;
		--codex-url)
			shift
			[ "$#" -gt 0 ] || fail "--codex-url requires a value."
			CODEX_URL="$1"
			;;
		--upgrade-termux)
			RUN_TERMUX_UPGRADE=1
			;;
		--no-upgrade)
			RUN_TERMUX_UPGRADE=0
			;;
		--no-enter-distro)
			ENTER_DISTRO_AFTER_INSTALL=0
			;;
		--print-config)
			PRINT_CONFIG=1
			;;
		--version)
			printf '%s\n' "$VERSION"
			exit 0
			;;
		-h | --help)
			usage
			exit 0
			;;
		*)
			fail "Unknown option: $1"
			;;
		esac
		shift
	done
}

validate_config() {
	[[ "$DISTRO" =~ ^[A-Za-z0-9._-]+$ ]] || fail "Unsafe distro name: $DISTRO"
	[[ "$WORKDIR_NAME" =~ ^[A-Za-z0-9._/-]+$ ]] || fail "Unsafe workdir path: $WORKDIR_NAME"
	[[ "$WORKDIR_NAME" != /* ]] || fail "--workdir must be relative to the Debian root home."
	[[ "$WORKDIR_NAME" != *".."* ]] || fail "--workdir must not contain '..'."
	[[ "$CODEX_URL" =~ ^https:// ]] || fail "--codex-url must be an https URL."
}

print_config() {
	cat <<CONFIG
Codux install configuration:
  version:             ${VERSION}
  distro:              ${DISTRO}
  workdir:             /root/${WORKDIR_NAME}
  codex_url:           ${CODEX_URL}
  termux_pkg_upgrade:  ${RUN_TERMUX_UPGRADE}
  enter_distro_after:  ${ENTER_DISTRO_AFTER_INSTALL}
CONFIG
}

require_command() {
	command -v "$1" >/dev/null 2>&1 || fail "Required command not found: $1"
}

ensure_termux() {
	require_command pkg

	if [ -z "${PREFIX:-}" ] || [[ "$PREFIX" != *"com.termux"* ]]; then
		warn "PREFIX does not look like Termux: ${PREFIX:-unset}"
	fi
}

ensure_arm64_host() {
	local host_arch
	host_arch="$(uname -m || true)"

	case "$host_arch" in
	aarch64 | arm64)
		info "Detected ARM64 host: $host_arch"
		;;
	*)
		fail "This installer currently supports ARM64 Android/Termux only. Detected: $host_arch"
		;;
	esac
}

install_termux_packages() {
	info "Updating Termux package metadata..."
	pkg update -y

	if [ "$RUN_TERMUX_UPGRADE" -eq 1 ]; then
		info "Upgrading Termux packages to avoid partial-upgrade library mismatches..."
		pkg upgrade -y
	else
		warn "Skipping full Termux upgrade. This can break curl/proot-distro on stale Termux installs."
	fi

	info "Installing Termux dependencies..."
	pkg install -y proot-distro curl ca-certificates openssl

	curl --version >/dev/null 2>&1 || fail "curl is installed but cannot run. Run 'pkg upgrade -y', then rerun this installer."
}

distro_installed() {
	local runtime_dir
	runtime_dir="${PREFIX}/var/lib/proot-distro"

	# Check both the current and legacy proot-distro layouts. This avoids treating
	# a distro catalog entry as installed on older proot-distro versions.
	[ -d "${runtime_dir}/containers/${DISTRO}/rootfs" ] && return 0
	[ -d "${runtime_dir}/installed-rootfs/${DISTRO}" ] && return 0

	return 1
}

ensure_distro() {
	require_command proot-distro

	if distro_installed; then
		info "proot-distro container '${DISTRO}' is already installed."
		return
	fi

	info "Installing '${DISTRO}' through proot-distro..."
	proot-distro install "$DISTRO"
}

bootstrap_debian() {
	local codex_asset
	codex_asset="${CODEX_URL##*/}"

	info "Bootstrapping '${DISTRO}' and installing Codex dependencies..."

	proot-distro login "$DISTRO" -- /bin/bash -s -- "$CODEX_URL" "$codex_asset" "$WORKDIR_NAME" <<'DEBIAN_BOOTSTRAP'
set -Eeuo pipefail

CODEX_URL="$1"
CODEX_ASSET="$2"
WORKDIR_NAME="$3"

info() {
  printf '\033[1;34m[DEBIAN]\033[0m %s\n' "$*"
}

fail() {
  printf '\033[1;31m[DEBIAN FAIL]\033[0m %s\n' "$*" >&2
  exit 1
}

on_error() {
  local status=$?
  printf '\033[1;31m[DEBIAN FAIL]\033[0m Bootstrap failed near line %s with exit code %s.\n' "${1:-unknown}" "$status" >&2
  exit "$status"
}

trap 'on_error "$LINENO"' ERR

ARCH="$(uname -m || true)"
case "$ARCH" in
  aarch64|arm64)
    info "Detected Debian architecture: $ARCH"
    ;;
  *)
    fail "Expected ARM64/aarch64 Debian. Detected: $ARCH"
    ;;
esac

export DEBIAN_FRONTEND=noninteractive

info "Updating apt package lists..."
apt-get update

info "Installing baseline development and sandbox packages..."
apt-get install -y \
  ca-certificates \
  curl \
  tar \
  gzip \
  git \
  ripgrep \
  python3 \
  python3-pip \
  build-essential \
  pkg-config \
  bubblewrap

info "Downloading Codex archive..."
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

curl -fL --retry 3 --retry-delay 2 \
  -o "${TMPDIR}/${CODEX_ASSET}" \
  "$CODEX_URL"

info "Extracting Codex binary..."
mkdir -p "${TMPDIR}/extract"
tar -xzf "${TMPDIR}/${CODEX_ASSET}" -C "${TMPDIR}/extract"

CODEX_BIN="$(find "${TMPDIR}/extract" -type f -name codex -print -quit || true)"

if [ -z "$CODEX_BIN" ]; then
  CODEX_BIN="$(find "${TMPDIR}/extract" -type f -perm /111 -print -quit || true)"
fi

if [ -z "$CODEX_BIN" ]; then
  CODEX_BIN="$(find "${TMPDIR}/extract" -type f -print -quit || true)"
fi

if [ -z "$CODEX_BIN" ]; then
  fail "Could not locate a Codex binary inside the downloaded archive."
fi

chmod +x "$CODEX_BIN"
install -m 0755 "$CODEX_BIN" /usr/local/bin/codex

mkdir -p "/root/${WORKDIR_NAME}"

info "Installed Codex binary:"
/usr/local/bin/codex --version || fail "Codex installed but did not execute successfully."

if command -v bwrap >/dev/null 2>&1; then
  info "bubblewrap found: $(command -v bwrap)"
  bwrap --version || true
else
  info "bubblewrap not found; Codex may use its vendored sandbox helper."
fi

info "Debian Codex install complete."
DEBIAN_BOOTSTRAP
}

write_launchers() {
	local launcher_suffix
	local quoted_workdir

	launcher_suffix="$DISTRO"
	quoted_workdir="$(printf '%q' "$WORKDIR_NAME")"

	info "Creating Termux launcher commands..."

	cat >"${PREFIX}/bin/codex-${launcher_suffix}" <<LAUNCHER
#!/data/data/com.termux/files/usr/bin/bash
# Launch Codex inside ${DISTRO}/proot from Termux.

set -euo pipefail

DISTRO="${DISTRO}"
WORKDIR_NAME="${WORKDIR_NAME}"

if [ "\$#" -gt 0 ]; then
  printf -v CODEX_ARGS '%q ' "\$@"
  proot-distro login "\$DISTRO" -- /bin/bash -lc "mkdir -p ~/${quoted_workdir} && cd ~/${quoted_workdir} && exec codex \${CODEX_ARGS}"
else
  proot-distro login "\$DISTRO" -- /bin/bash -lc "mkdir -p ~/${quoted_workdir} && cd ~/${quoted_workdir} && exec codex"
fi
LAUNCHER

	cat >"${PREFIX}/bin/codex-login-${launcher_suffix}" <<LAUNCHER
#!/data/data/com.termux/files/usr/bin/bash
# Run ChatGPT device-code login for Codex inside ${DISTRO}/proot.

set -euo pipefail

DISTRO="${DISTRO}"
WORKDIR_NAME="${WORKDIR_NAME}"

proot-distro login "\$DISTRO" -- /bin/bash -lc "mkdir -p ~/${quoted_workdir} && cd ~/${quoted_workdir} && exec codex login --device-auth"
LAUNCHER

	cat >"${PREFIX}/bin/codex-version-${launcher_suffix}" <<LAUNCHER
#!/data/data/com.termux/files/usr/bin/bash
# Print the Codex version installed inside ${DISTRO}/proot.

set -euo pipefail

DISTRO="${DISTRO}"

proot-distro login "\$DISTRO" -- /bin/bash -lc 'codex --version'
LAUNCHER

	chmod +x \
		"${PREFIX}/bin/codex-${launcher_suffix}" \
		"${PREFIX}/bin/codex-login-${launcher_suffix}" \
		"${PREFIX}/bin/codex-version-${launcher_suffix}"
}

print_next_steps() {
	local red
	local reset
	red="$(printf '\033[1;31m')"
	reset="$(printf '\033[0m')"

	cat <<STEPS

Install complete.

${red}IMPORTANT:${reset}
  Codex was installed inside the ${DISTRO} proot environment, not directly in Termux.
  If you want to run Codex manually, enter Debian first:

     proot-distro login ${DISTRO}

  Then run:

     codex

Next steps:
  1. Sign in from Termux using the helper:
     codex-login-${DISTRO}

  2. Start Codex from Termux using the helper:
     codex-${DISTRO}

  3. Check version:
     codex-version-${DISTRO}

Notes:
  - Your Codex workspace inside ${DISTRO} is: /root/${WORKDIR_NAME}
  - If Codex warns about bubblewrap, that is usually a proot/Android limitation.
  - Re-run this installer later to update Codex from the configured release URL.
STEPS
}

enter_distro_shell() {
	if [ "$ENTER_DISTRO_AFTER_INSTALL" -ne 1 ]; then
		return
	fi

	info "Opening '${DISTRO}' proot shell now. Type 'exit' to return to Termux."
	proot-distro login "$DISTRO"
}

main() {
	parse_args "$@"
	validate_config

	if [ "$PRINT_CONFIG" -eq 1 ]; then
		print_config
		exit 0
	fi

	ensure_termux
	ensure_arm64_host
	install_termux_packages
	ensure_distro
	bootstrap_debian
	write_launchers
	print_next_steps
	enter_distro_shell
}

main "$@"
