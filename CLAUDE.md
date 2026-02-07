# CLAUDE.md

## What This Addon Does

Default Current Expansion auto-enables the "Current Expansion Only" filter when opening the Auction House or Crafting Orders UI. That is the entire scope. It does not modify search results, item tooltips, pricing, or any other AH/CO behavior.

## Architecture

Single-file addon: `DefaultCurrentExpansion.lua`. No libraries, no XML, no embeds.

### Boot Sequence

1. `ADDON_LOADED` (arg1 == `"DefaultCurrentExpansion"`) → init saved variables, create options panel, register slash commands
2. `PLAYER_LOGIN` → create event listener frames for AH and CO

### Runtime Flow

- `AUCTION_HOUSE_SHOW` → install `hooksecurefunc` on `AuctionHouseFrame.SetDisplayMode` (once, to catch tab switches) → call `ApplyAuctionHouseFilter()`
- `ApplyAuctionHouseFilter()` → 0.1s delay via `C_Timer.After` → check `searchBar:IsShown()` (Buy tab only) → write `true` into `AuctionHouseFrame.SearchBar.FilterButton.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly]`, then call `searchBar:UpdateClearFiltersButton()`
- The `SetDisplayMode` hook also calls `ApplyAuctionHouseFilter()` on tab switches, but skips Auctionator's empty-table `SetDisplayMode({})` calls via `next(displayMode) ~= nil`
- `CRAFTINGORDERS_SHOW_CUSTOMER` → 0.1s delay → write `true` into `ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.FilterDropdown.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly]`, then call `filterDropdown:ValidateResetState()`

The 0.1s delay exists because Blizzard frames are not fully initialized on the event fire. Do not remove it.

### Named Frames

| Frame | Purpose |
|---|---|
| `DCE_MainEventFrame` | Listens for ADDON_LOADED and PLAYER_LOGIN |
| `DCE_AuctionHouseEventFrame` | Listens for AUCTION_HOUSE_SHOW |
| `DCE_CraftingOrdersEventFrame` | Listens for CRAFTINGORDERS_SHOW_CUSTOMER |

### Saved Variables

`DefaultCurrentExpansionDB` (account-wide), keys:

| Key | Type | Default | Purpose |
|---|---|---|---|
| `auctionHouse` | boolean | `true` | Toggle AH filter automation |
| `craftingOrders` | boolean | `true` | Toggle CO filter automation |
| `debug` | boolean | `false` | Print debug messages to chat |

### Slash Commands

`/dce` or `/defaultcurrentexpansion` with subcommands: `help`, `opt`, `ah`, `co`, `debug`, `status`.

### Options Panel

Registered via `Settings.RegisterCanvasLayoutCategory` (modern Settings API). Uses `InterfaceOptionsCheckButtonTemplate` for checkboxes. Accessible at ESC → Settings → AddOns → Default Current Expansion.

## File Map

| File | Role |
|---|---|
| `DefaultCurrentExpansion.toc` | Addon metadata, interface version, load order |
| `DefaultCurrentExpansion.lua` | All addon logic (single file) |
| `CHANGELOG.md` | Version history |
| `export.sh` | Local zip packaging (reads version from TOC) |
| `.pkgmeta` | BigWigsMods packager config for CurseForge releases |
| `.github/workflows/release.yml` | CI: tag push → BigWigsMods/packager@v2 → CurseForge upload |

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

These are the paths most likely to break on WoW patches:

1. **AH filter path**: `AuctionHouseFrame.SearchBar.FilterButton.filters` — if Blizzard restructures the AH frame hierarchy, this breaks silently (filter just doesn't apply)
2. **CO filter path**: `ProfessionsCustomerOrdersFrame.BrowseOrders.SearchBar.FilterDropdown.filters` — same risk
3. **Enum value**: `Enum.AuctionHouseFilter.CurrentExpansionOnly` — could be renamed or removed in a major patch
4. **UI update calls**: `UpdateClearFiltersButton()` and `ValidateResetState()` — internal Blizzard methods, not part of a stable API
5. **SetDisplayMode hook**: `AuctionHouseFrame.SetDisplayMode` — hooked via `hooksecurefunc` to detect tab switches; if Blizzard renames or removes this method, the hook silently stops firing (filter still applies on initial open, just not on tab switch)

When any of these break, the addon fails silently (no error, filter just isn't set). Enable `/dce debug` to see which path failed.

## Release Process

1. Update version in `DefaultCurrentExpansion.toc` (`## Version:`)
2. Update `CHANGELOG.md`
3. Commit and push
4. Tag with `v<version>` (e.g., `git tag v1.2.1`)
5. Push tag → GitHub Actions runs BigWigsMods/packager → uploads to CurseForge (project ID 1409180)

For local testing: `./export.sh ~/Desktop` creates a zip named `DefaultCurrentExpansion.<version>.zip`.

## References

- [Warcraft Wiki (API docs)](https://warcraft.wiki.gg/wiki/World_of_Warcraft_API) — primary API reference
- [Warcraft Wiki: Events](https://warcraft.wiki.gg/wiki/Events) — event names and payloads
- [Warcraft Wiki: AUCTION_HOUSE_SHOW](https://warcraft.wiki.gg/wiki/AUCTION_HOUSE_SHOW)
- [Blizzard FrameXML on GitHub](https://github.com/Gethe/wow-ui-source) — Gethe's mirror of retail FrameXML, use to verify frame hierarchy
- [BigWigsMods Packager](https://github.com/BigWigsMods/packager) — the CI packaging tool
- [CurseForge project page](https://www.curseforge.com/wow/addons/default-current-expansion) — published addon
