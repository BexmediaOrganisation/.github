#!/bin/bash
# Bexmedia repo setup: Mac launcher.
# Installs what the setup script needs (with your OK), then runs the same setup
# script Windows uses (setup-repo.ps1), so there is only one set of steps to maintain.
#
# Mac Terminal:  curl -fsSL https://raw.githubusercontent.com/BexmediaOrganisation/.github/main/scripts/setup-repo.sh | bash

SCRIPT_URL="https://raw.githubusercontent.com/BexmediaOrganisation/.github/main/scripts/setup-repo.ps1"

say()  { printf '%s\n' "$1"; }
fail() { printf '\n  \033[31mXX  %s\033[0m\n' "$1"; exit 1; }
good() { printf '  \033[32mOK  %s\033[0m\n' "$1"; }

# Answers come from the keyboard, not from the download piped into this script.
ask() { printf '%s ' "$1"; read -r REPLY < /dev/tty; }

# Install something with Homebrew, after asking.
need() {
  cmd="$1"; pkg="$2"; label="$3"
  if command -v "$cmd" >/dev/null 2>&1; then good "$label is installed"; return; fi
  if ! command -v brew >/dev/null 2>&1; then
    fail "$label isn't installed, and neither is Homebrew. Install Homebrew from https://brew.sh, then run this again."
  fi
  ask "$label isn't installed. Install it now with Homebrew? (y/n)"
  [ "$REPLY" = "y" ] || fail "Stopped. Install $label, then run this again."
  brew install $pkg || fail "Homebrew couldn't install $label. Try: brew install $pkg"
  good "$label installed"
}

say ""
say "Bexmedia repo setup (Mac)"
say "Checking this Mac has what the setup script needs."
say ""

if ! command -v git >/dev/null 2>&1; then
  fail "Git isn't installed. Run: xcode-select --install   Then run this again."
fi
good "Git is installed"
need pwsh "--cask powershell" "PowerShell"
need gh gh "The GitHub CLI"

# Hand over to the same setup script Windows uses.
exec pwsh -NoProfile -Command "irm '$SCRIPT_URL' | iex" < /dev/tty
