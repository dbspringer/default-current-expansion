# Default Current Expansion

Auto-enables AH and Crafting Orders filters ("Current Expansion Only" and "Usable Only") when opening those UIs. Each filter has independent per-surface (AH/CO) toggles. That is the entire scope — no search results, tooltips, pricing, or other AH/CO behavior is modified.

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
- For each enabled filter (`FILTER_CEO` if `auctionHouse` is on, `FILTER_USABLE` if `usableOnlyAH` is on):
  - If `preserveFilterChanges` is on and user has manually changed that filter, uses `userFilterOverride[filter]`
  - Otherwise sets the filter to `true`
  - Writes into `g_auctionHouseFilters.filters[filterEnum]` (12.1.0+; Clear Filters replaces that table wholesale, so it is re-resolved on every use via `GetAuctionHouseFilters()` and never cached)
- Starts a 0.2s ticker (`StartFilterWatcher`) that polls only the actively managed filters for user changes
- Note: `UpdateClearFiltersButton()` was intentionally removed to prevent taint propagation (see issue #10)
- The `SetDisplayMode` hook skips Auctionator's empty-table `SetDisplayMode({})` calls via `next(displayMode) ~= nil`

**Crafting Orders** (`CRAFTINGORDERS_SHOW_CUSTOMER`):
- 0.1s delay → for each enabled filter (`FILTER_CEO` if `craftingOrders` is on, `FILTER_USABLE` if `usableOnlyCO` is on), writes `true` into the corresponding slot in `ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.FilterDropdown.filters`
- Note: `ValidateResetState()` was intentionally removed to prevent taint propagation (see issue #10)

The 0.1s delay exists because Blizzard frames are not fully initialized on the event fire. Do not remove it.

### Saved Variables

`DefaultCurrentExpansionDB` (account-wide) — see the `defaults` table at the top of `DefaultCurrentExpansion.lua` for keys and default values.

### Options Panel

Registered via `Settings.RegisterCanvasLayoutCategory` (modern Settings API). Uses `InterfaceOptionsCheckButtonTemplate` for checkboxes. Accessible at ESC → Settings → AddOns → Default Current Expansion.

## Constraints

### Target Version
- **Retail only** (Interface 120100, Midnight era)
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

1. **AH filter path**: `g_auctionHouseFilters.filters` — a saved-variable global owned by Blizzard_AuctionHouseUI (`## SavedVariablesPerCharacter`). Before 12.1.0 this lived at `AuctionHouseFrame.SearchBar.FilterButton.filters`; that field no longer exists. `AuctionHouseFrame.SearchBar` is still used, but only as the Buy-tab gate
2. **CO filter path**: `ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.FilterDropdown.filters`
3. **Enum values**: `Enum.AuctionHouseFilter.CurrentExpansionOnly` and `Enum.AuctionHouseFilter.UsableOnly` — could be renamed or removed (hoisted to `FILTER_CEO`/`FILTER_USABLE` locals with nil guards)
4. **UI update calls**: `UpdateClearFiltersButton()` and `ValidateResetState()` were removed to prevent taint propagation — calling Blizzard frame methods from addon code taints the frame hierarchy (see issue #10). Do not re-add them.
   - Since 12.1.0 the AH filters table is no longer reset on every AH open (`SearchBar:OnShow` used to call `FilterButton:Reset()`, which allocated a fresh untainted table each time). The addon's taint on `g_auctionHouseFilters.filters` now survives the whole session, until the user clicks Clear Filters. Unavoidable — writing that table is the addon's purpose — but it makes #10-style `ADDON_ACTION_FORBIDDEN` reports more likely. Watch for them.
5. **SetDisplayMode hook**: If Blizzard renames/removes this method, the hook silently stops (filter still applies on initial open, just not on tab switch)

## Release Process

1. Update version in `DefaultCurrentExpansion.toc` (`## Version:`)
2. Update `CHANGELOG.md`
3. Commit, tag with `v<version>` (e.g., `git tag v1.2.1`), and push
4. Run `./export.sh ~/Desktop` to create `DefaultCurrentExpansion.<version>.zip`
5. Upload manually to CurseForge (project ID 1409180)

## References

- [Warcraft Wiki (API docs)](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API) — primary API reference
- [Blizzard FrameXML on GitHub](https://github.com/Gethe/wow-ui-source) — Gethe's mirror of retail FrameXML, use to verify frame hierarchy
- [Patch 12.0.0 API Changes](https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes) — check after major patches for breaking changes to frame hierarchy
- [CurseForge project page](https://www.curseforge.com/wow/addons/default-current-expansion) — published addon
