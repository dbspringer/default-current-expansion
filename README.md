# Default Current Expansion

A World of Warcraft addon that automatically applies filters in the Auction House and Crafting Orders interfaces.

## Features

- Automatically applies "Current Expansion Only" filter when opening the Auction House and when browsing Crafting Orders
- Optionally applies "Usable Only" filter for the Auction House and Crafting Orders
- Each filter has independent per-surface (AH/CO) toggles
- Compatible with retail WoW 12.0.0+ (Midnight)

## Installation

1. Download or clone this repository
2. Copy the `default-current-expansion` folder to your WoW AddOns directory:
   - Windows: `C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\`
   - Mac: `/Applications/World of Warcraft/_retail_/Interface/AddOns/`
3. Restart World of Warcraft or reload UI with `/reload`
4. The addon will be enabled by default

## Usage

The addon works automatically once enabled. You can customize its behavior using the options panel or slash commands:

### Options Panel

Access the options panel via:
- In-game: ESC → Settings → AddOns → Default Current Expansion
- Slash command: `/dce opt`

The options panel allows you to toggle:
- **Preserve filter changes** - Remember manual filter changes within an AH session
- **Current Expansion Only** - Enable/disable per surface (Auction House, Crafting Orders)
- **Usable Items Only** - Enable/disable per surface (Auction House, Crafting Orders)

### Slash Commands

- `/dce help` - Display all available commands
- `/dce opt` - Open the options panel
- `/dce ah` - Toggle Current Expansion Only (Auction House)
- `/dce co` - Toggle Current Expansion Only (Crafting Orders)
- `/dce usable` - Toggle Usable Items Only (both surfaces)
- `/dce preserve` - Toggle preserve filter changes
- `/dce status` - Show current settings

### First Time Setup

After installation, simply:
1. Open the Auction House or Crafting Orders interface
2. The addon will automatically set the "Current Expansion Only" filter (enabled by default)
3. To also enable "Usable Items Only", use `/dce usable` or the options panel
4. Type `/dce status` to verify the addon is working

## Configuration

**Disabling the Addon:**
- To completely disable the addon, uncheck it in the AddOns menu at character select
- To disable individual filters per surface, use the options panel (`/dce opt`) or slash commands (`/dce ah`, `/dce co`, `/dce usable`)

## Compatibility

- **Current Version:** Retail WoW 12.0.0+ (Midnight)
- **Not compatible with:** Classic WoW, Classic Era, or Cataclysm Classic

## Contributing

Contributions are welcome! If you find issues with the UI frame paths or have improvements, please submit a pull request or open an issue.

## License

See [LICENSE](LICENSE) file for details
