# CLAUDE.md

This file provides context and guidelines for AI assistants working on this project.

## Project Overview

**Project Name:** default-current-expansion
**Type:** World of Warcraft Addon
**Primary Language:** Lua
**Purpose:** Automatically selects the "Current Expansion Only" filter for inventory/items

## Project Goals

This addon helps players by automating the selection of the "Current Expansion Only" filter, streamlining inventory management and reducing repetitive UI interactions.

## Technical Context

### World of Warcraft Addon Architecture
- This is a WoW addon written in Lua using the WoW API
- Addons use event-driven architecture with callbacks
- Primary focus: Inventory/Items systems
- UI interactions may involve frames and widgets

### Key WoW API Systems Used
- **Inventory/Items API**: Bags, items, equipment, filtering
- **Events/Callbacks**: Responding to inventory and UI events
- **UI Frames**: Potential interaction with item filtering UI elements

## Development Priorities

1. **Code Quality**: Write clean, maintainable, and well-structured Lua code
2. **Performance**: Minimize performance impact on the game client
   - Avoid excessive event handlers
   - Be mindful of frame rate impact
   - Cache data when appropriate

## Coding Standards

### Lua Conventions for WoW Addons
- Follow standard WoW addon Lua conventions
- Use PascalCase for addon-specific global functions
- Use camelCase for local functions and variables
- Prefix addon-specific globals with addon name to avoid conflicts
- Use local variables whenever possible for performance

### Code Organization
- Keep event handlers lightweight
- Separate UI code from logic where possible
- Comment complex WoW API interactions
- Document any non-obvious behavior or workarounds

### WoW-Specific Best Practices
- Always unregister events when they're no longer needed
- Use secure templates for action-related UI when required
- Test across different UI scales and resolutions
- Consider compatibility with popular UI addons

## Project Structure

Standard WoW addon structure:
- `.toc` file: Addon metadata and file load order
- `.lua` files: Addon logic and functionality
- `.xml` files (optional): UI frame definitions

## Testing Considerations

- Test in-game with various inventory states
- Verify behavior with empty and full bags
- Test with different character types/levels
- Check for taint issues with protected functions
- Verify memory usage remains reasonable

## Common Pitfalls to Avoid

1. **Taint**: Be careful not to taint protected Blizzard UI elements
2. **Performance**: Avoid running heavy operations on frequent events
3. **Memory Leaks**: Clean up references and unregister unused events
4. **Global Namespace Pollution**: Minimize global variables
5. **Event Spam**: Throttle or debounce high-frequency events if needed

## Helpful Context for AI Assistants

- WoW uses Lua 5.1 with some modifications
- The WoW API changes between expansions; assume current retail version unless specified
- Many standard Lua libraries are not available (io, os, etc.)
- Focus on using WoW's provided API functions
- When in doubt about API usage, mention that testing in-game is required

## Questions to Ask

When working on this addon, consider asking:
- Which WoW expansion/version is this targeting? (Retail, Classic, etc.)
- Are there specific UI addons this needs to be compatible with?
- Should this work in combat, or only out of combat?
- Are there specific inventory views this should affect? (bags, bank, vendor, etc.)

## Additional Resources

- WoW API Documentation: https://warcraft.wiki.gg/
- Addon development guides and community forums
- CurseForge/WoWInterface for addon distribution

## Notes

This is an automation helper addon focused on improving quality of life for players managing inventory across expansions. Keep the scope focused and the implementation lightweight.
