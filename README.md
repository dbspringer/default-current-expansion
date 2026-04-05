# Default Current Expansion

A World of Warcraft addon that automatically selects "Current Expansion Only" filter in the Auction House and Crafting Orders interfaces.

## Features

- Automatically applies "Current Expansion Only" filter when opening the Auction House and when browsing Crafting Orders
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
- **Auction House filtering** - Enable/disable AH filter automation
- **Crafting Orders filtering** - Enable/disable CO filter automation
- **Preserve filter changes** - Remember manual filter changes within an AH session

### Slash Commands

- `/dce help` - Display all available commands
- `/dce opt` - Open the options panel
- `/dce ah` - Toggle Auction House filtering
- `/dce co` - Toggle Crafting Orders filtering
- `/dce preserve` - Toggle preserve filter changes
- `/dce status` - Show current settings

### First Time Setup

After installation, simply:
1. Open the Auction House or Crafting Orders interface
2. The addon will automatically set the filter to "Current Expansion Only"
3. Type `/dce status` to verify the addon is working

## Configuration

**Disabling the Addon:**
- To completely disable the addon, uncheck it in the AddOns menu at character select
- To disable individual features (AH or CO only), use the options panel (`/dce opt`) or slash commands (`/dce ah` or `/dce co`)

## Compatibility

- **Current Version:** Retail WoW 12.0.0+ (Midnight)
- **Not compatible with:** Classic WoW, Classic Era, or Cataclysm Classic

## Contributing

Contributions are welcome! If you find issues with the UI frame paths or have improvements, please submit a pull request or open an issue.

## License

See [LICENSE](LICENSE) file for details
