-- Default Current Expansion
-- Automatically selects "Current Expansion Only" filter in AH and Crafting Orders

local addonName = "DefaultCurrentExpansion"
local addon = {}
local L = DCE_L

-- Default settings
local defaults = {
	auctionHouse = true,
	craftingOrders = true,
	preserveFilterChanges = true,
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

	-- Clean up removed keys from existing saved variables
	DefaultCurrentExpansionDB.debug = nil
end

-- Print function for user messages
local function Print(...)
	print("|cff00ff00[Default Current Expansion]|r", ...)
end

-- User's manual filter override for this AH session (nil = use addon setting)
local userFilterOverride = nil
-- What was last applied, so the watcher can detect user changes
local lastAppliedFilterState = nil
-- Ticker that watches for user filter changes
local filterWatcher = nil

-- Cancel any active filter watcher
local function CancelFilterWatcher()
	if filterWatcher then
		filterWatcher:Cancel()
		filterWatcher = nil
	end
end

-- Start watching for user filter changes (polls while Buy tab is shown)
local function StartFilterWatcher()
	CancelFilterWatcher()
	if not DefaultCurrentExpansionDB.preserveFilterChanges then return end

	filterWatcher = C_Timer.NewTicker(0.2, function()
		if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then
			CancelFilterWatcher()
			return
		end
		local searchBar = AuctionHouseFrame.SearchBar
		if not searchBar or not searchBar:IsShown() then return end
		local filterButton = searchBar.FilterButton
		if not filterButton or not filterButton.filters then return end

		local filter = Enum.AuctionHouseFilter.CurrentExpansionOnly
		local currentState = filterButton.filters[filter] and true or false
		if currentState ~= lastAppliedFilterState then
			userFilterOverride = currentState
			lastAppliedFilterState = currentState
		end
	end)
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
					-- Use user's override if preserve mode is on, otherwise use addon setting
					local desiredState
					if DefaultCurrentExpansionDB.preserveFilterChanges and userFilterOverride ~= nil then
						desiredState = userFilterOverride
					else
						desiredState = DefaultCurrentExpansionDB.auctionHouse
					end
					filterButton.filters[filter] = desiredState
					searchBar:UpdateClearFiltersButton()
					lastAppliedFilterState = desiredState
					StartFilterWatcher()
				end
			end
		end
	end)
end

-- Auction House event handler
-- Hooks SetDisplayMode to catch tab switches (e.g. returning from Auctionator's Shopping tab)
local function OnAuctionHouseShow()
	userFilterOverride = nil
	lastAppliedFilterState = nil
	CancelFilterWatcher()
	if AuctionHouseFrame and not AuctionHouseFrame.DCE_displayModeHooked then
		hooksecurefunc(AuctionHouseFrame, "SetDisplayMode", function(_, displayMode)
			if displayMode and next(displayMode) ~= nil then
				CancelFilterWatcher()
				ApplyAuctionHouseFilter()
			end
		end)
		AuctionHouseFrame.DCE_displayModeHooked = true
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
					end
				end
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
	end
end

-- Crafting Orders filter automation
function addon:SetupCraftingOrders()
	if not self.coFrame then
		self.coFrame = CreateFrame("Frame", "DCE_CraftingOrdersEventFrame")
		self.coFrame:RegisterEvent("CRAFTINGORDERS_SHOW_CUSTOMER")
		self.coFrame:SetScript("OnEvent", OnCraftingOrdersShow)
	end
end

-- Options Panel
function addon:CreateOptionsPanel()
	local panel = CreateFrame("Frame")
	panel.name = L.ADDON_TITLE

	-- Title
	local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(L.ADDON_TITLE)

	-- Subtitle
	local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	subtitle:SetText(L.ADDON_SUBTITLE)

	-- Auction House checkbox
	local ahCheckbox = CreateFrame("CheckButton", "DCE_AHCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
	ahCheckbox:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
	ahCheckbox.Text:SetText(L.OPT_AUCTION_HOUSE)
	ahCheckbox:SetChecked(DefaultCurrentExpansionDB.auctionHouse)
	ahCheckbox:SetScript("OnClick", function(self)
		DefaultCurrentExpansionDB.auctionHouse = self:GetChecked()
		-- Ensure the frame is set up if it doesn't exist yet
		if not addon.ahFrame then
			addon:SetupAuctionHouse()
		end
		Print(string.format(L.MSG_AH_TOGGLE, DefaultCurrentExpansionDB.auctionHouse and L.ENABLED or L.DISABLED))
	end)

	-- Crafting Orders checkbox
	local coCheckbox = CreateFrame("CheckButton", "DCE_COCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
	coCheckbox:SetPoint("TOPLEFT", ahCheckbox, "BOTTOMLEFT", 0, -8)
	coCheckbox.Text:SetText(L.OPT_CRAFTING_ORDERS)
	coCheckbox:SetChecked(DefaultCurrentExpansionDB.craftingOrders)
	coCheckbox:SetScript("OnClick", function(self)
		DefaultCurrentExpansionDB.craftingOrders = self:GetChecked()
		-- Ensure the frame is set up if it doesn't exist yet
		if not addon.coFrame then
			addon:SetupCraftingOrders()
		end
		Print(string.format(L.MSG_CO_TOGGLE, DefaultCurrentExpansionDB.craftingOrders and L.ENABLED or L.DISABLED))
	end)

	-- Preserve Filter Changes checkbox
	local preserveCheckbox = CreateFrame("CheckButton", "DCE_PreserveCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
	preserveCheckbox:SetPoint("TOPLEFT", coCheckbox, "BOTTOMLEFT", 0, -8)
	preserveCheckbox.Text:SetText(L.OPT_PRESERVE_FILTER)
	preserveCheckbox:SetChecked(DefaultCurrentExpansionDB.preserveFilterChanges)
	preserveCheckbox:SetScript("OnClick", function(self)
		DefaultCurrentExpansionDB.preserveFilterChanges = self:GetChecked()
		Print(string.format(L.MSG_PRESERVE_TOGGLE, DefaultCurrentExpansionDB.preserveFilterChanges and L.ENABLED or L.DISABLED))
	end)

	-- Refresh checkbox states when panel is shown
	panel:SetScript("OnShow", function()
		ahCheckbox:SetChecked(DefaultCurrentExpansionDB.auctionHouse)
		coCheckbox:SetChecked(DefaultCurrentExpansionDB.craftingOrders)
		preserveCheckbox:SetChecked(DefaultCurrentExpansionDB.preserveFilterChanges)
	end)

	-- Version info
	local version = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	version:SetPoint("BOTTOMLEFT", 16, 16)
	version:SetText(string.format(L.VERSION_LABEL, C_AddOns.GetAddOnMetadata(addonName, "Version"), GetLocale()))

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

	if command == "" or command == "opt" then
		if addon.settingsCategory then
			Settings.OpenToCategory(addon.settingsCategory:GetID())
		end
	elseif command == "help" then
		Print(L.HELP_HEADER)
		Print(L.HELP_OPT)
		Print(L.HELP_AH)
		Print(L.HELP_CO)
		Print(L.HELP_PRESERVE)
		Print(L.HELP_STATUS)
	elseif command == "ah" then
		DefaultCurrentExpansionDB.auctionHouse = not DefaultCurrentExpansionDB.auctionHouse
		Print(string.format(L.MSG_AH_TOGGLE, DefaultCurrentExpansionDB.auctionHouse and L.ENABLED or L.DISABLED))
		if DefaultCurrentExpansionDB.auctionHouse then
			addon:SetupAuctionHouse()
		end
	elseif command == "co" then
		DefaultCurrentExpansionDB.craftingOrders = not DefaultCurrentExpansionDB.craftingOrders
		Print(string.format(L.MSG_CO_TOGGLE, DefaultCurrentExpansionDB.craftingOrders and L.ENABLED or L.DISABLED))
		if DefaultCurrentExpansionDB.craftingOrders then
			addon:SetupCraftingOrders()
		end
	elseif command == "preserve" then
		DefaultCurrentExpansionDB.preserveFilterChanges = not DefaultCurrentExpansionDB.preserveFilterChanges
		Print(string.format(L.MSG_PRESERVE_TOGGLE, DefaultCurrentExpansionDB.preserveFilterChanges and L.ENABLED or L.DISABLED))
	elseif command == "status" then
		Print(L.STATUS_HEADER)
		Print(string.format(L.STATUS_AH, DefaultCurrentExpansionDB.auctionHouse and L.YES or L.NO))
		Print(string.format(L.STATUS_CO, DefaultCurrentExpansionDB.craftingOrders and L.YES or L.NO))
		Print(string.format(L.STATUS_PRESERVE, DefaultCurrentExpansionDB.preserveFilterChanges and L.YES or L.NO))
	else
		Print(L.MSG_UNKNOWN_CMD)
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
		eventFrame:UnregisterEvent("ADDON_LOADED")
	elseif event == "PLAYER_LOGIN" then
		addon:SetupAuctionHouse()
		addon:SetupCraftingOrders()
		eventFrame:UnregisterEvent("PLAYER_LOGIN")
	end
end)
