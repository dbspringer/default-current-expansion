# Changelog

All notable changes to this project will be documented in this file.

## [1.2.1] - 2025-01-28

### Added
- Export script for creating distributable zip files

## [1.2.0] - 2025-01-27

### Added
- Crafting Orders filter UI feedback with ValidateResetState call
- Options panel checkbox refresh on show
- Named event frames for easier debugging

### Changed
- Use dynamic version from TOC metadata
- Hoist event handlers to module level for efficiency
- Remove deprecated InterfaceOptions API fallbacks (12.0+ only)
- Remove redundant event checks in single-event handlers

### Fixed
- Potential nil error in DebugPrint before InitDB

## [1.1.0] - 2025-01-24

### Changed
- Updated interface support for WoW 12.0.1 (Midnight)
- Improved Auction House filter UI feedback with UpdateClearFiltersButton call

## [1.0.0] - 2025-01-19

### Added
- Initial release
- Automatic "Current Expansion Only" filter for Auction House
- Automatic "Current Expansion Only" filter for Crafting Orders
- In-game options panel (ESC → Interface → AddOns → Default Current Expansion)
- Slash commands for configuration (`/dce`)
- Individual toggles for AH and CO filtering
- Debug mode for troubleshooting
- Support for retail WoW 11.0.7 (The War Within)
- Support for upcoming WoW 12.0.0 (Midnight)

### Features
- Dynamic filter state checking - filters update immediately when settings change
- Saved variables to persist settings between sessions
- Lightweight event-driven architecture
- Minimal performance impact
