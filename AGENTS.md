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
- Installs `hooksecurefunc` on `AuctionHouseFrame.SetDisplayMode` (once) so the Buy tab is caught even when the AH opens elsewhere — see the note below
- Calls `ApplyAuctionHouseFilter()` → 0.1s delay → returns early if `appliedThisVisit`, then checks `searchBar:IsShown()` (Buy tab only)
- Writes `true` into `g_auctionHouseFilters.filters[filterEnum]` for each enabled filter (`FILTER_CEO` if `auctionHouse` is on, `FILTER_USABLE` if `usableOnlyAH` is on). Clear Filters replaces that table wholesale, so it is re-resolved on every use via `GetAuctionHouseFilters()` and never cached
- Note: `UpdateClearFiltersButton()` was intentionally removed to prevent taint propagation (see issue #10)

**Why the `SetDisplayMode` hook stays** — it does two unrelated jobs, and only one became obsolete in 12.1.0. Re-applying the filter after a tab switch is no longer needed, because `AuctionHouseSearchBarMixin:OnShow` now only resets the search text and the game keeps filter state across tabs by itself. But *reaching* the Buy tab still matters: when another addon (e.g. Auctionator) opens the AH on its own tab, `SearchBar` is hidden at `AUCTION_HOUSE_SHOW`, `ApplyAuctionHouseFilter()` bails, and nothing else would ever retry. Persistence only preserves a write that already happened, so dropping the hook silently reintroduces the bug fixed in 1.3.0. The hook observes only (`hooksecurefunc`, no behavior altered) and skips Auctionator's empty-table `SetDisplayMode({})` calls via `next(displayMode) ~= nil`. `AuctionHouseFrame.DCE_displayModeHooked` keeps it from stacking across `/reload`.

The apply is gated to **once per AH visit** by the `appliedThisVisit` upvalue, reset in `OnAuctionHouseShow`. Reaching Buy is what matters; re-applying on every later tab switch would undo a manual untick that the game would otherwise have kept. That gate is also what replaces `preserveFilterChanges`, which had no second job and was removed: `userFilterOverride` was cleared on every AH open, so it only ever protected tab switches within a single visit. A side effect worth knowing: clicking Clear Filters mid-visit leaves the filters cleared until the next AH open, which matches what the player just asked for.

**The addon sets the box; it never unsets it.** This is the design decision most likely to look like a bug, so it is worth stating plainly.

The options are named for automation: "Current Expansion Only (Auction House)" means *automatically tick this filter when the AH opens*. Turning it off means we stop ticking it. It does not mean we untick it. Before 12.1.0 the difference was invisible, because Blizzard reset the filters on every open, so "we stopped setting it" and "it ended up off" were the same outcome. 12.1.0 made filters persist, which pulled those apart.

An earlier revision of this work did release filters on toggle-off, and every problem it caused came from needing to know whether the addon or the player had set a given filter — a distinction the player cannot see and never asked us to track. It cost a per-character saved variable, an ownership acquisition rule, and hooks on `ToggleFilter` and `Reset`, and still had gaps. The clinching argument is that uninstalling is how most people stop using an addon, and no release logic can run then, so the machinery only ever covered disable-but-keep-installed.

What happens instead: disable an option and the box stays as it is. The player unticks it once from the AH's own filter dropdown, which the game then remembers. That is the same single click any other filter takes, and the affordance is native and visible.

The one rule that follows: **never write `false` into `g_auctionHouseFilters.filters`.** If a future change needs to, it needs ownership tracking again, and the history above is why that is more expensive than it looks.

**Crafting Orders** (`CRAFTINGORDERS_SHOW_CUSTOMER`):
- 0.1s delay → for each enabled filter (`FILTER_CEO` if `craftingOrders` is on, `FILTER_USABLE` if `usableOnlyCO` is on), writes `true` into the corresponding slot in `ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.FilterDropdown.filters`
- Note: `ValidateResetState()` was intentionally removed to prevent taint propagation (see issue #10)

The 0.1s delay exists because Blizzard frames are not fully initialized on the event fire. Do not remove it.

### Saved Variables

`DefaultCurrentExpansionDB` (`## SavedVariables`, account-wide) — see the `defaults` table at the top of `DefaultCurrentExpansion.lua` for keys and default values.

The AH filters themselves live in Blizzard's `g_auctionHouseFilters`, which is `SavedVariablesPerCharacter`. The addon reads and writes that table but stores nothing of its own per character, because it never needs to remember what it did — see the note above on why it only ever sets the box.

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
5. **SetDisplayMode hook**: if Blizzard renames or removes this method the hook silently stops, and the filter is then never applied at all for AH visits that start on a non-Buy tab (Auctionator and similar). Do not remove it on the grounds that 12.1.0 persists filters across tabs — that reasoning covers only half of what it does; see the Runtime Flow note above
6. **Filter persistence**: the AH now keeps filters across tab switches and sessions, while CO still resets to `AUCTION_HOUSE_DEFAULT_FILTERS` on open — which is why CO applies on every visit and the AH applies once. If Blizzard ever gives CO the same treatment, `OnCraftingOrdersShow` should gain a once-per-visit gate like the AH has, not a release path

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
