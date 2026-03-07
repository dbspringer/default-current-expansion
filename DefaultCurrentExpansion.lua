-- Default Current Expansion
-- Automatically selects "Current Expansion Only" filter in AH and Crafting Orders

local addonName = "DefaultCurrentExpansion"
local addon = {}

-- Default settings
local defaults = {
	auctionHouse = true,
	craftingOrders = true,
	applyOnOpenOnly = false,
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
	if DefaultCurrentExpansionDB and DefaultCurrentExpansionDB.debug then
		print("|cff00ff00[" .. addonName .. "]|r", ...)
	end
end

-- Print function for user messages
local function Print(...)
	print("|cff00ff00[Default Current Expansion]|r", ...)
end

-- Apply AH filter after a short delay (frames need time to initialize)
local function ApplyAuctionHouseFilter()
	C_Timer.After(0.1, function()
		if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
			local searchBar = AuctionHouseFrame.SearchBar
			if searchBar and searchBar:IsShown() and searchBar.FilterButton then
				local filterButton = searchBar.FilterButton
				local filter = Enum.AuctionHouseFilter.CurrentExpansionOnly

				if filterButton.filters then
					filterButton.filters[filter] = DefaultCurrentExpansionDB.auctionHouse
					searchBar:UpdateClearFiltersButton()
					ahFilterAppliedThisSession = true
					if DefaultCurrentExpansionDB.auctionHouse then
						DebugPrint("Auction House filter set to current expansion")
					else
						DebugPrint("Auction House filter cleared")
					end
				else
					DebugPrint("Warning: FilterButton.filters not found")
				end
			else
				DebugPrint("Buy tab not active, skipping filter")
			end
		end
	end)
end

-- Tracks whether the AH filter has been successfully applied this session (reset on each AH open)
local ahFilterAppliedThisSession = false

-- Auction House event handler
-- Hooks SetDisplayMode to catch tab switches (e.g. returning from Auctionator's Shopping tab)
local displayModeHooked = false

local function OnAuctionHouseShow()
	ahFilterAppliedThisSession = false
	if not displayModeHooked and AuctionHouseFrame then
		hooksecurefunc(AuctionHouseFrame, "SetDisplayMode", function(_, displayMode)
			if displayMode and next(displayMode) ~= nil then
				if DefaultCurrentExpansionDB.applyOnOpenOnly and ahFilterAppliedThisSession then
					DebugPrint("applyOnOpenOnly active, skipping tab-switch re-apply")
					return
				end
				DebugPrint("Tab switch detected, re-applying filter")
				ApplyAuctionHouseFilter()
			end
		end)
		displayModeHooked = true
		DebugPrint("SetDisplayMode hook installed")
	end

	ApplyAuctionHouseFilter()
end

-- Crafting Orders event handler
local function OnCraftingOrdersShow()
	C_Timer.After(0.1, function()
		if ProfessionsCustomerOrdersFrame and ProfessionsCustomerOrdersFrame:IsShown() then
			local browseFrame = ProfessionsCustomerOrdersFrame.BrowseOrders
			if browseFrame and browseFrame.SearchBar then
				local searchBar = browseFrame.SearchBar

				if searchBar.FilterDropdown then
					local filterDropdown = searchBar.FilterDropdown
					local filter = Enum.AuctionHouseFilter.CurrentExpansionOnly

					if filterDropdown.filters then
						filterDropdown.filters[filter] = DefaultCurrentExpansionDB.craftingOrders
						filterDropdown:ValidateResetState()
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

-- Auction House filter automation
function addon:SetupAuctionHouse()
	if not self.ahFrame then
		self.ahFrame = CreateFrame("Frame", "DCE_AuctionHouseEventFrame")
		self.ahFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
		self.ahFrame:SetScript("OnEvent", OnAuctionHouseShow)
		DebugPrint("Auction House automation enabled")
	end
end

-- Crafting Orders filter automation
function addon:SetupCraftingOrders()
	if not self.coFrame then
		self.coFrame = CreateFrame("Frame", "DCE_CraftingOrdersEventFrame")
		self.coFrame:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")
		self.coFrame:SetScript("OnEvent", OnCraftingOrdersShow)
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

	-- Apply On Open Only checkbox
	local openOnlyCheckbox = CreateFrame("CheckButton", "DCE_OpenOnlyCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
	openOnlyCheckbox:SetPoint("TOPLEFT", coCheckbox, "BOTTOMLEFT", 0, -8)
	openOnlyCheckbox.Text:SetText("Apply only when Auction House opens")
	openOnlyCheckbox:SetChecked(DefaultCurrentExpansionDB.applyOnOpenOnly)
	openOnlyCheckbox:SetScript("OnClick", function(self)
		DefaultCurrentExpansionDB.applyOnOpenOnly = self:GetChecked()
		if DefaultCurrentExpansionDB.applyOnOpenOnly then
			Print("Apply on open only enabled")
		else
			Print("Apply on open only disabled")
		end
	end)

	-- Refresh checkbox states when panel is shown
	panel:SetScript("OnShow", function()
		ahCheckbox:SetChecked(DefaultCurrentExpansionDB.auctionHouse)
		coCheckbox:SetChecked(DefaultCurrentExpansionDB.craftingOrders)
		openOnlyCheckbox:SetChecked(DefaultCurrentExpansionDB.applyOnOpenOnly)
	end)

	-- Version info
	local version = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	version:SetPoint("BOTTOMLEFT", 16, 16)
	version:SetText("Version " .. C_AddOns.GetAddOnMetadata(addonName, "Version"))

	-- Register with Settings
	local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
	Settings.RegisterAddOnCategory(category)
	addon.settingsCategory = category

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
		Print("/dce openonly - Toggle apply on open only")
		Print("/dce debug - Toggle debug messages")
		Print("/dce status - Show current settings")
	elseif command == "opt" then
		-- Open the addon settings panel
		Settings.OpenToCategory(addon.settingsCategory:GetID())
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
	elseif command == "openonly" then
		DefaultCurrentExpansionDB.applyOnOpenOnly = not DefaultCurrentExpansionDB.applyOnOpenOnly
		Print("Apply on open only", DefaultCurrentExpansionDB.applyOnOpenOnly and "enabled" or "disabled")
	elseif command == "debug" then
		DefaultCurrentExpansionDB.debug = not DefaultCurrentExpansionDB.debug
		Print("Debug mode", DefaultCurrentExpansionDB.debug and "enabled" or "disabled")
	elseif command == "status" then
		Print("Current Settings:")
		Print("  Auction House:", DefaultCurrentExpansionDB.auctionHouse and "Yes" or "No")
		Print("  Crafting Orders:", DefaultCurrentExpansionDB.craftingOrders and "Yes" or "No")
		Print("  Apply On Open Only:", DefaultCurrentExpansionDB.applyOnOpenOnly and "Yes" or "No")
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
local eventFrame = CreateFrame("Frame", "DCE_MainEventFrame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" and arg1 == addonName then
		addon:InitDB()
		addon:CreateOptionsPanel()
		DebugPrint("Addon loaded")
	elseif event == "PLAYER_LOGIN" then
		addon:SetupAuctionHouse()
		addon:SetupCraftingOrders()
	end
end)
