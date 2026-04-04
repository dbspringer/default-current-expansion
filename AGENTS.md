# Default Current Expansion

Auto-enables the "Current Expansion Only" filter when opening the Auction House or Crafting Orders UI. That is the entire scope — no search results, tooltips, pricing, or other AH/CO behavior is modified.

## Architecture

Core logic in `DefaultCurrentExpansion.lua` with locale files in `Locales/`. No libraries, no XML, no embeds.

### Localization

Global `DCE_L` table created in `Locales/enUS.lua` with all English strings. Non-English locale files guard with `GetLocale()` and override keys for their language. The main file references `local L = DCE_L`. Unoverridden keys fall back to English.

### Boot Sequence

1. File scope: slash commands (`/dce`, `/defaultcurrentexpansion`) are registered immediately
2. `ADDON_LOADED` → init saved variables (`defaults` table), create options panel
3. `PLAYER_LOGIN` → create AH and CO event listener frames

### Runtime Flow

**Auction House** (`AUCTION_HOUSE_SHOW`):
- Resets `userFilterOverride` and `lastAppliedFilterState`, cancels any active filter watcher
- Installs `hooksecurefunc` on `AuctionHouseFrame.SetDisplayMode` (once) to catch tab switches
- Calls `ApplyAuctionHouseFilter()` → 0.1s delay → checks `searchBar:IsShown()` (Buy tab only)
- Writes `desiredState` into `AuctionHouseFrame.SearchBar.FilterButton.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly]`:
  - If `preserveFilterChanges` is on and user has manually changed the filter, uses `userFilterOverride`
  - Otherwise uses `DefaultCurrentExpansionDB.auctionHouse`
- Calls `searchBar:UpdateClearFiltersButton()`, then starts a 0.2s ticker (`StartFilterWatcher`) that polls for user filter changes
- The `SetDisplayMode` hook skips Auctionator's empty-table `SetDisplayMode({})` calls via `next(displayMode) ~= nil`

**Crafting Orders** (`CRAFTINGORDERS_SHOW_CUSTOMER`):
- 0.1s delay → writes `DefaultCurrentExpansionDB.craftingOrders` into `ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.FilterDropdown.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly]`
- Calls `filterDropdown:ValidateResetState()`

The 0.1s delay exists because Blizzard frames are not fully initialized on the event fire. Do not remove it.

### Saved Variables

`DefaultCurrentExpansionDB` (account-wide) — see the `defaults` table at the top of `DefaultCurrentExpansion.lua` for keys and default values.

### Options Panel

Registered via `Settings.RegisterCanvasLayoutCategory` (modern Settings API). Uses `InterfaceOptionsCheckButtonTemplate` for checkboxes. Accessible at ESC → Settings → AddOns → Default Current Expansion.

## Constraints

### Target Version
- **Retail only** (Interface 120000 / 120001, Midnight era)
- Not compatible with Classic, Classic Era, or Cataclysm Classic
- Lua 5.1 (WoW's embedded runtime)

### Do

- Keep the addon as a single `.lua` file unless there is a strong reason to split
- Use `local` for all variables and functions except the saved variable table and slash command globals
- Prefix any new global names with `DCE_` to avoid namespace collisions
- Test that AH and CO frame paths still resolve after WoW patches — these are the most fragile parts
- Update the `## Interface:` line in the TOC when targeting a new game build
- Bump `## Version:` in the TOC for every release (export.sh and the options panel read it dynamically)
- Use `C_Timer.After` for any timing-sensitive UI manipulation

### Do Not

- Add features outside AH/CO filter defaulting — scope is intentionally narrow
- Require or bundle external libraries (Ace3, LibStub, etc.)
- Hook or replace Blizzard functions — the addon writes directly to filter state, it does not detour anything
- Use `securecall` or modify protected frames — the filter tables are not protected
- `hooksecurefunc` is acceptable for *observing* Blizzard method calls (e.g. tab switches) but never for altering their behavior
- Add Classic/Era support without a separate TOC and gated code paths
- Remove the `C_Timer.After(0.1, ...)` delay without verifying the frame is fully initialized at event fire time
- Commit AI-related files (CLAUDE.local.md, .claude/, etc.) — they are in `.gitignore` and `.pkgmeta` ignore list

## Fragile Areas

These paths are most likely to break on WoW patches (failures are silent — no error, filter just isn't set):

1. **AH filter path**: `AuctionHouseFrame.SearchBar.FilterButton.filters`
2. **CO filter path**: `ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.FilterDropdown.filters`
3. **Enum value**: `Enum.AuctionHouseFilter.CurrentExpansionOnly` — could be renamed or removed
4. **UI update calls**: `UpdateClearFiltersButton()` and `ValidateResetState()` — internal Blizzard methods, not a stable API
5. **SetDisplayMode hook**: If Blizzard renames/removes this method, the hook silently stops (filter still applies on initial open, just not on tab switch)

## Release Process

1. Update version in `DefaultCurrentExpansion.toc` (`## Version:`)
2. Update `CHANGELOG.md`
3. Commit and push
4. Tag with `v<version>` (e.g., `git tag v1.2.1`)
5. Push tag → GitHub Actions runs BigWigsMods/packager → uploads to CurseForge (project ID 1409180)

For local testing: `./export.sh ~/Desktop` creates a zip named `DefaultCurrentExpansion.<version>.zip`.

## References

- [Warcraft Wiki (API docs)](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API) — primary API reference
- [Blizzard FrameXML on GitHub](https://github.com/Gethe/wow-ui-source) — Gethe's mirror of retail FrameXML, use to verify frame hierarchy
- [Patch 12.0.0 API Changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes) — check after major patches for breaking changes to frame hierarchy
- [CurseForge project page](https://www.curseforge.com/wow/addons/default-current-expansion) — published addon
