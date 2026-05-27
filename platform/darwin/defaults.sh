#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# @file platform/darwin/defaults.sh
# @description macOS system preferences (sensible defaults)
# @since 1.0.0
# @version 1.0.0
# @see https://macos-defaults.com
#
# Run on demand via: dotfiles defaults
# Requires logout/restart for some settings to take effect.
# ═══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

source "${DOTFILES_DIR}/lib/core/logger.sh"

Logger::info "Applying macOS defaults..."

# ───────────────────────────────────────────────────────────────────────────────
# General UI
# ───────────────────────────────────────────────────────────────────────────────

# Dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Disable automatic capitalization, period substitution, smart quotes/dashes
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# ───────────────────────────────────────────────────────────────────────────────
# Keyboard & Input
# ───────────────────────────────────────────────────────────────────────────────

# Fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Full keyboard access for all controls (Tab in dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# ───────────────────────────────────────────────────────────────────────────────
# Trackpad & Mouse
# ───────────────────────────────────────────────────────────────────────────────

# Trackpad: enable tap to click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Trackpad: three-finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true

# ───────────────────────────────────────────────────────────────────────────────
# Finder
# ───────────────────────────────────────────────────────────────────────────────

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show path bar and status bar
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# Default to list view
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Disable warning when changing file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Search current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Avoid creating .DS_Store files on network/USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# ───────────────────────────────────────────────────────────────────────────────
# Dock
# ───────────────────────────────────────────────────────────────────────────────

# Set icon size
defaults write com.apple.dock tilesize -int 48

# Auto-hide dock
defaults write com.apple.dock autohide -bool true

# Remove auto-hide delay
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.3

# Don't show recent apps
defaults write com.apple.dock show-recents -bool false

# Minimize windows into application icon
defaults write com.apple.dock minimize-to-application -bool true

# ───────────────────────────────────────────────────────────────────────────────
# Safari & WebKit
# ───────────────────────────────────────────────────────────────────────────────

# Show full URL in address bar
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Enable developer menu and Web Inspector
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true

# ───────────────────────────────────────────────────────────────────────────────
# Terminal & iTerm2
# ───────────────────────────────────────────────────────────────────────────────

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# ───────────────────────────────────────────────────────────────────────────────
# Activity Monitor
# ───────────────────────────────────────────────────────────────────────────────

# Show all processes
defaults write com.apple.ActivityMonitor ShowCategory -int 0

# Sort by CPU usage
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

# ───────────────────────────────────────────────────────────────────────────────
# Screenshots
# ───────────────────────────────────────────────────────────────────────────────

# Save screenshots to ~/Pictures/Screenshots
mkdir -p "${HOME}/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "${HOME}/Pictures/Screenshots"

# Save in PNG format
defaults write com.apple.screencapture type -string "png"

# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

# ───────────────────────────────────────────────────────────────────────────────
# Restart affected apps
# ───────────────────────────────────────────────────────────────────────────────
Logger::info "Restarting affected applications..."
for app in "Finder" "Dock" "SystemUIServer"; do
    killall "${app}" 2>/dev/null || true
done

Logger::success "macOS defaults applied (some changes require logout)"
