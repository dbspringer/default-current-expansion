-- Default Current Expansion
-- Automatically selects "Current Expansion Only" filter in AH and Crafting Orders

local addonName = "DefaultCurrentExpansion"
local addon = {}

-- Default settings
local defaults = {
	auctionHouse = true,
	craftingOrders = true,
	debug = false
}

-- Initialize saved variables
function addon:InitDB()
	if not DefaultCurrentExpansionDB then
		DefaultCurrentExpansionDB = {}
	end

	-- Merge defaults with saved settings
	for k, v in pairs(defaults) do
		if DefaultCurrentExpansionDB[k] == nil then
			DefaultCurrentExpansionDB[k] = v
		end
	end
end

-- Debug print function
local function DebugPrint(...)
	if DefaultCurrentExpansionDB.debug then
		print("|cff00ff00[" .. addonName .. "]|r", ...)
	end
end

-- Print function for user messages
local function Print(...)
	print("|cff00ff00[Default Current Expansion]|r", ...)
end

-- Auction House filter automation
function addon:SetupAuctionHouse()
	-- Hook into the Auction House UI when it opens
	local function OnAuctionHouseShow()
		-- Wait a frame to ensure UI is fully loaded
		C_Timer.After(0.1, function()
			if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
				-- Access the SearchBar and FilterButton
				local searchBar = AuctionHouseFrame.SearchBar
				if searchBar and searchBar.FilterButton then
					local filterButton = searchBar.FilterButton

					-- Set the filter using the proper enum
					local filter = Enum.AuctionHouseFilter.CurrentExpansionOnly

					-- Set or clear the filter based on current setting
					if filterButton.filters then
						filterButton.filters[filter] = DefaultCurrentExpansionDB.auctionHouse
						if DefaultCurrentExpansionDB.auctionHouse then
							DebugPrint("Auction House filter set to current expansion")
						else
							DebugPrint("Auction House filter cleared")
						end
					else
						DebugPrint("Warning: FilterButton.filters not found")
					end
				else
					DebugPrint("Warning: SearchBar or FilterButton not found")
				end
			end
		end)
	end

	-- Register for Auction House events
	if not self.ahFrame then
		self.ahFrame = CreateFrame("Frame")
		self.ahFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
		self.ahFrame:SetScript("OnEvent", function(self, event, ...)
			if event == "AUCTION_HOUSE_SHOW" then
				OnAuctionHouseShow()
			end
		end)
		DebugPrint("Auction House automation enabled")
	end
end

-- Crafting Orders filter automation
function addon:SetupCraftingOrders()
	-- Hook into the Crafting Orders UI when it opens
	local function OnCraftingOrdersShow()
		C_Timer.After(0.1, function()
			if ProfessionsCustomerOrdersFrame and ProfessionsCustomerOrdersFrame:IsShown() then
				local browseFrame = ProfessionsCustomerOrdersFrame.BrowseOrders
				if browseFrame and browseFrame.SearchBar then
					local searchBar = browseFrame.SearchBar

					-- Access the FilterDropdown
					if searchBar.FilterDropdown then
						local filterDropdown = searchBar.FilterDropdown

						-- Set the filter using the proper enum
						local filter = Enum.AuctionHouseFilter.CurrentExpansionOnly

						-- Set or clear the filter based on current setting
						if filterDropdown.filters then
							filterDropdown.filters[filter] = DefaultCurrentExpansionDB.craftingOrders
							if DefaultCurrentExpansionDB.craftingOrders then
								DebugPrint("Crafting Orders filter set to current expansion")
							else
								DebugPrint("Crafting Orders filter cleared")
							end
						else
							DebugPrint("Warning: FilterDropdown.filters not found")
						end
					else
						DebugPrint("Warning: FilterDropdown not found on SearchBar")
					end
				else
					DebugPrint("Warning: BrowseOrders or SearchBar not found")
				end
			end
		end)
	end

	-- Monitor when the professions/crafting orders UI opens
	if not self.coFrame then
		self.coFrame = CreateFrame("Frame")
		self.coFrame:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")
		self.coFrame:SetScript("OnEvent", function(self, event, ...)
			if event == "CRAFTINGORDERS_SHOW_CUSTOMER" then
				OnCraftingOrdersShow()
			end
		end)
		DebugPrint("Crafting Orders automation enabled")
	end
end

-- Options Panel
function addon:CreateOptionsPanel()
	local panel = CreateFrame("Frame")
	panel.name = "Default Current Expansion"

	-- Title
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("Default Current Expansion")

	-- Subtitle
	local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetText("Automatically selects 'Current Expansion Only' filter")

	-- Auction House checkbox
	local ahCheckbox = CreateFrame("CheckButton", "DCE_AHCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
	ahCheckbox:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
	ahCheckbox.Text:SetText("Auction House filtering")
	ahCheckbox:SetChecked(DefaultCurrentExpansionDB.auctionHouse)
	ahCheckbox:SetScript("OnClick", function(self)
		DefaultCurrentExpansionDB.auctionHouse = self:GetChecked()
		-- Ensure the frame is set up if it doesn't exist yet
		if not addon.ahFrame then
			addon:SetupAuctionHouse()
		end
		if DefaultCurrentExpansionDB.auctionHouse then
			Print("Auction House filtering enabled")
		else
			Print("Auction House filtering disabled")
		end
	end)

	-- Crafting Orders checkbox
	local coCheckbox = CreateFrame("CheckButton", "DCE_COCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
	coCheckbox:SetPoint("TOPLEFT", ahCheckbox, "BOTTOMLEFT", 0, -8)
	coCheckbox.Text:SetText("Crafting Orders filtering")
	coCheckbox:SetChecked(DefaultCurrentExpansionDB.craftingOrders)
	coCheckbox:SetScript("OnClick", function(self)
		DefaultCurrentExpansionDB.craftingOrders = self:GetChecked()
		-- Ensure the frame is set up if it doesn't exist yet
		if not addon.coFrame then
			addon:SetupCraftingOrders()
		end
		if DefaultCurrentExpansionDB.craftingOrders then
			Print("Crafting Orders filtering enabled")
		else
			Print("Crafting Orders filtering disabled")
		end
	end)

	-- Version info
	local version = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	version:SetPoint("BOTTOMLEFT", 16, 16)
	version:SetText("Version 1.0.0")

	-- Register with Settings (new API for 10.0+)
	if Settings and Settings.RegisterCanvasLayoutCategory then
		local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
		Settings.RegisterAddOnCategory(category)
		addon.settingsCategory = category
	else
		-- Fallback for older versions
		InterfaceOptions_AddCategory(panel)
	end

	addon.optionsPanel = panel
	return panel
end

-- Slash command handler
local function SlashCommandHandler(msg)
	local command = msg:lower():trim()

	if command == "" or command == "help" then
		Print("Commands:")
		Print("/dce opt - Open options menu")
		Print("/dce ah - Toggle Auction House filtering")
		Print("/dce co - Toggle Crafting Orders filtering")
		Print("/dce debug - Toggle debug messages")
		Print("/dce status - Show current settings")
	elseif command == "opt" then
		-- Open the addon settings panel
		if Settings and Settings.OpenToCategory then
			-- Use the stored category for the new Settings API
			if addon.settingsCategory then
				Settings.OpenToCategory(addon.settingsCategory:GetID())
			else
				Settings.OpenToCategory("Default Current Expansion")
			end
		elseif InterfaceOptionsFrame_OpenToCategory then
			-- Fallback for older versions - need to call twice due to Blizzard bug
			InterfaceOptionsFrame_OpenToCategory(addon.optionsPanel)
			InterfaceOptionsFrame_OpenToCategory(addon.optionsPanel)
		end
	elseif command == "ah" then
		DefaultCurrentExpansionDB.auctionHouse = not DefaultCurrentExpansionDB.auctionHouse
		Print("Auction House filtering", DefaultCurrentExpansionDB.auctionHouse and "enabled" or "disabled")
		if DefaultCurrentExpansionDB.auctionHouse then
			addon:SetupAuctionHouse()
		end
	elseif command == "co" then
		DefaultCurrentExpansionDB.craftingOrders = not DefaultCurrentExpansionDB.craftingOrders
		Print("Crafting Orders filtering", DefaultCurrentExpansionDB.craftingOrders and "enabled" or "disabled")
		if DefaultCurrentExpansionDB.craftingOrders then
			addon:SetupCraftingOrders()
		end
	elseif command == "debug" then
		DefaultCurrentExpansionDB.debug = not DefaultCurrentExpansionDB.debug
		Print("Debug mode", DefaultCurrentExpansionDB.debug and "enabled" or "disabled")
	elseif command == "status" then
		Print("Current Settings:")
		Print("  Auction House:", DefaultCurrentExpansionDB.auctionHouse and "Yes" or "No")
		Print("  Crafting Orders:", DefaultCurrentExpansionDB.craftingOrders and "Yes" or "No")
		Print("  Debug:", DefaultCurrentExpansionDB.debug and "Yes" or "No")
	else
		Print("Unknown command. Type /dce help for options")
	end
end

-- Register slash commands
SLASH_DEFAULTCURRENTEXPANSION1 = "/dce"
SLASH_DEFAULTCURRENTEXPANSION2 = "/defaultcurrentexpansion"
SlashCmdList["DEFAULTCURRENTEXPANSION"] = SlashCommandHandler

-- Main initialization
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == addonName then
		addon:InitDB()
		addon:CreateOptionsPanel()
		DebugPrint("Addon loaded")
	elseif event == "PLAYER_LOGIN" then
		addon:SetupAuctionHouse()
		addon:SetupCraftingOrders()
	end
end)
