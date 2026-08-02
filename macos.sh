#!/usr/bin/env bash
#
# macOS system preferences — the System Settings choices worth carrying to a
# new machine, applied via `defaults`. Run directly, or let install.sh do it.
#
# Idempotent: every write sets an absolute value, so re-running is a no-op.
# After changing a setting in System Settings that should sync, add its
# `defaults write` line here (find the key with `defaults read`).
set -euo pipefail

echo "Applying macOS defaults..."

# --- Dock ---
# Auto-hide, pinned to the right edge.
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock orientation -string "right"

# --- Trackpad ---
# Tracking speed: slider max (range 0–3).
defaults write NSGlobalDomain com.apple.trackpad.scaling -float 3

# --- Finder ---
# New windows open the home folder instead of Recents.
defaults write com.apple.finder NewWindowTarget -string "PfHm"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/"

# --- Keyboard shortcuts ---
# "Move focus to next window" = cmd+` (symbolic hotkey 27).
# parameters = [ASCII 96 = "`", key code 50, modifier flags 1048576 = cmd]
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 27 '
  <dict>
    <key>enabled</key><true/>
    <key>value</key>
    <dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array><integer>96</integer><integer>50</integer><integer>1048576</integer></array>
    </dict>
  </dict>'

# Spotlight search = cmd+space OFF (symbolic hotkey 64) so Raycast can own the
# shortcut (Raycast's own hotkey comes from its imported .rayconfig).
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '
  <dict>
    <key>enabled</key><false/>
    <key>value</key>
    <dict>
      <key>type</key><string>standard</string>
      <key>parameters</key>
      <array><integer>65535</integer><integer>49</integer><integer>1048576</integer></array>
    </dict>
  </dict>'

# --- Apply without logging out ---
# The Dock/Finder re-read their plists on launch; the preferences daemon needs a
# nudge before trackpad/hotkey changes are picked up (else they apply at next login).
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u 2>/dev/null ||
  echo "  note: trackpad/keyboard-shortcut changes take effect after logging out and back in"

echo "macOS defaults applied."
