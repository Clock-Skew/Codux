#!/usr/bin/env bash
# Lightweight checks that do not run the Termux installer.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${CODUX_SCRIPT:-${ROOT_DIR}/codux.sh}"

fail() {
	printf '[FAIL] %s\n' "$*" >&2
	exit 1
}

contains() {
	local needle="$1"
	local haystack="$2"
	grep -Fq -- "$needle" "$haystack" || fail "Expected '${needle}' in ${haystack}"
}

bash -n "$SCRIPT"

help_out="$(mktemp)"
config_out="$(mktemp)"
no_upgrade_out="$(mktemp)"
bad_url_out="$(mktemp)"
bad_workdir_out="$(mktemp)"
trap 'rm -f "$help_out" "$config_out" "$no_upgrade_out" "$bad_url_out" "$bad_workdir_out"' EXIT

bash "$SCRIPT" --help >"$help_out"
contains "Codux - Codex CLI installer" "$help_out"
contains "--upgrade-termux" "$help_out"
contains "--no-enter-distro" "$help_out"
contains "--version" "$help_out"

version_out="$(mktemp)"
trap 'rm -f "$help_out" "$config_out" "$no_upgrade_out" "$version_out" "$bad_url_out" "$bad_workdir_out"' EXIT

bash "$SCRIPT" --version >"$version_out"
contains "0.1.4" "$version_out"

bash "$SCRIPT" \
	--distro ubuntu \
	--workdir mobile/codex \
	--codex-url https://example.com/codex.tar.gz \
	--upgrade-termux \
	--print-config >"$config_out"
contains "version:             0.1.4" "$config_out"
contains "distro:              ubuntu" "$config_out"
contains "workdir:             /root/mobile/codex" "$config_out"
contains "termux_pkg_upgrade:  1" "$config_out"
contains "enter_distro_after:  1" "$config_out"

bash "$SCRIPT" --no-upgrade --no-enter-distro --print-config >"$no_upgrade_out"
contains "termux_pkg_upgrade:  0" "$no_upgrade_out"
contains "enter_distro_after:  0" "$no_upgrade_out"

if bash "$SCRIPT" --codex-url http://example.com/codex.tar.gz --print-config >"$bad_url_out" 2>&1; then
	fail "Expected http codex URL to fail validation"
fi
contains "--codex-url must be an https URL" "$bad_url_out"

if bash "$SCRIPT" --workdir ../bad --print-config >"$bad_workdir_out" 2>&1; then
	fail "Expected unsafe workdir to fail validation"
fi
contains "--workdir must not contain '..'" "$bad_workdir_out"

printf '[OK] Codux smoke checks passed\n'
