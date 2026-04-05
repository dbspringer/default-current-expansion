-- Default Current Expansion
-- Automatically applies AH and Crafting Orders filters (Current Expansion Only, Usable Only)

local addonName = "DefaultCurrentExpansion"
local addon = {}
local L = DCE_L

-- Default settings
local defaults = {
	auctionHouse = true,
	craftingOrders = true,
	preserveFilterChanges = true,
	usableOnlyAH = false,
	usableOnlyCO = false,
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
	DefaultCurrentExpansionDB.usableOnly = nil
end

-- Print function for user messages
local function Print(...)
	print("|cff00ff00[Default Current Expansion]|r", ...)
end

-- User's manual filter overrides for this AH session, keyed by filter enum (nil = use addon setting)
local userFilterOverride = {}
-- What was last applied per filter, so the watcher can detect user changes
local lastAppliedFilterState = {}
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

		for _, filter in ipairs({
			Enum.AuctionHouseFilter.CurrentExpansionOnly,
			Enum.AuctionHouseFilter.UsableOnly,
		}) do
			local currentState = filterButton.filters[filter] and true or false
			if lastAppliedFilterState[filter] ~= nil and currentState ~= lastAppliedFilterState[filter] then
				userFilterOverride[filter] = currentState
			end
			lastAppliedFilterState[filter] = currentState
		end
	end)
end

-- Apply AH filters after a short delay (frames need time to initialize)
local function ApplyAuctionHouseFilter()
	C_Timer.After(0.1, function()
		if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
			local searchBar = AuctionHouseFrame.SearchBar
			if searchBar and searchBar:IsShown() and searchBar.FilterButton then
				local filterButton = searchBar.FilterButton

				if filterButton.filters then
					-- Apply Current Expansion Only filter (only if enabled for AH)
					if DefaultCurrentExpansionDB.auctionHouse then
						local ceoFilter = Enum.AuctionHouseFilter.CurrentExpansionOnly
						local ceoDesired
						if DefaultCurrentExpansionDB.preserveFilterChanges and userFilterOverride[ceoFilter] ~= nil then
							ceoDesired = userFilterOverride[ceoFilter]
						else
							ceoDesired = true
						end
						filterButton.filters[ceoFilter] = ceoDesired
						lastAppliedFilterState[ceoFilter] = ceoDesired
					end

					-- Apply Usable Only filter (only if enabled for AH)
					if DefaultCurrentExpansionDB.usableOnlyAH then
						local uoFilter = Enum.AuctionHouseFilter.UsableOnly
						local uoDesired
						if DefaultCurrentExpansionDB.preserveFilterChanges and userFilterOverride[uoFilter] ~= nil then
							uoDesired = userFilterOverride[uoFilter]
						else
							uoDesired = true
						end
						filterButton.filters[uoFilter] = uoDesired
						lastAppliedFilterState[uoFilter] = uoDesired
					end

					searchBar:UpdateClearFiltersButton()
					StartFilterWatcher()
				end
			end
		end
	end)
end

-- Auction House event handler
-- Hooks SetDisplayMode to catch tab switches (e.g. returning from Auctionator's Shopping tab)
local function OnAuctionHouseShow()
	userFilterOverride = {}
	lastAppliedFilterState = {}
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

					if filterDropdown.filters then
						if DefaultCurrentExpansionDB.craftingOrders then
							filterDropdown.filters[Enum.AuctionHouseFilter.CurrentExpansionOnly] = true
						end
						if DefaultCurrentExpansionDB.usableOnlyCO then
							filterDropdown.filters[Enum.AuctionHouseFilter.UsableOnly] = true
						end
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

	-- Preserve Filter Changes checkbox (top-level setting)
	local preserveCheckbox = CreateFrame("CheckButton", "DCE_PreserveCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
	preserveCheckbox:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
	preserveCheckbox.Text:SetText(L.OPT_PRESERVE_FILTER)
	preserveCheckbox:SetChecked(DefaultCurrentExpansionDB.preserveFilterChanges)
	preserveCheckbox:SetScript("OnClick", function(self)
		DefaultCurrentExpansionDB.preserveFilterChanges = self:GetChecked()
		Print(string.format(L.MSG_PRESERVE_TOGGLE, DefaultCurrentExpansionDB.preserveFilterChanges and L.ENABLED or L.DISABLED))
	end)

	-- Current Expansion Only section
	local ceoHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	ceoHeader:SetPoint("TOPLEFT", preserveCheckbox, "BOTTOMLEFT", 0, -16)
	ceoHeader:SetText(L.OPT_SECTION_CEO)

	local ceoAHCheckbox = CreateFrame("CheckButton", "DCE_CEOAHCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
	ceoAHCheckbox:SetPoint("TOPLEFT", ceoHeader, "BOTTOMLEFT", 16, -4)
	ceoAHCheckbox.Text:SetText(L.OPT_AUCTION_HOUSE)
	ceoAHCheckbox:SetChecked(DefaultCurrentExpansionDB.auctionHouse)
	ceoAHCheckbox:SetScript("OnClick", function(self)
		DefaultCurrentExpansionDB.auctionHouse = self:GetChecked()
		if not addon.ahFrame then
			addon:SetupAuctionHouse()
		end
		Print(string.format(L.MSG_AH_TOGGLE, DefaultCurrentExpansionDB.auctionHouse and L.ENABLED or L.DISABLED))
	end)

	local ceoCOCheckbox = CreateFrame("CheckButton", "DCE_CEOCOCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
	ceoCOCheckbox:SetPoint("TOPLEFT", ceoAHCheckbox, "BOTTOMLEFT", 0, -4)
	ceoCOCheckbox.Text:SetText(L.OPT_CRAFTING_ORDERS)
	ceoCOCheckbox:SetChecked(DefaultCurrentExpansionDB.craftingOrders)
	ceoCOCheckbox:SetScript("OnClick", function(self)
		DefaultCurrentExpansionDB.craftingOrders = self:GetChecked()
		if not addon.coFrame then
			addon:SetupCraftingOrders()
		end
		Print(string.format(L.MSG_CO_TOGGLE, DefaultCurrentExpansionDB.craftingOrders and L.ENABLED or L.DISABLED))
	end)

	-- Usable Items Only section
	local usableHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	usableHeader:SetPoint("TOPLEFT", ceoCOCheckbox, "BOTTOMLEFT", -16, -16)
	usableHeader:SetText(L.OPT_SECTION_USABLE)

	local usableAHCheckbox = CreateFrame("CheckButton", "DCE_UsableAHCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
	usableAHCheckbox:SetPoint("TOPLEFT", usableHeader, "BOTTOMLEFT", 16, -4)
	usableAHCheckbox.Text:SetText(L.OPT_AUCTION_HOUSE)
	usableAHCheckbox:SetChecked(DefaultCurrentExpansionDB.usableOnlyAH)
	usableAHCheckbox:SetScript("OnClick", function(self)
		DefaultCurrentExpansionDB.usableOnlyAH = self:GetChecked()
		Print(string.format(L.MSG_USABLE_AH_TOGGLE, DefaultCurrentExpansionDB.usableOnlyAH and L.ENABLED or L.DISABLED))
	end)

	local usableCOCheckbox = CreateFrame("CheckButton", "DCE_UsableCOCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
	usableCOCheckbox:SetPoint("TOPLEFT", usableAHCheckbox, "BOTTOMLEFT", 0, -4)
	usableCOCheckbox.Text:SetText(L.OPT_CRAFTING_ORDERS)
	usableCOCheckbox:SetChecked(DefaultCurrentExpansionDB.usableOnlyCO)
	usableCOCheckbox:SetScript("OnClick", function(self)
		DefaultCurrentExpansionDB.usableOnlyCO = self:GetChecked()
		Print(string.format(L.MSG_USABLE_CO_TOGGLE, DefaultCurrentExpansionDB.usableOnlyCO and L.ENABLED or L.DISABLED))
	end)

	-- Refresh checkbox states when panel is shown
	panel:SetScript("OnShow", function()
		preserveCheckbox:SetChecked(DefaultCurrentExpansionDB.preserveFilterChanges)
		ceoAHCheckbox:SetChecked(DefaultCurrentExpansionDB.auctionHouse)
		ceoCOCheckbox:SetChecked(DefaultCurrentExpansionDB.craftingOrders)
		usableAHCheckbox:SetChecked(DefaultCurrentExpansionDB.usableOnlyAH)
		usableCOCheckbox:SetChecked(DefaultCurrentExpansionDB.usableOnlyCO)
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
		Print(L.HELP_USABLE)
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
	elseif command == "usable" then
		DefaultCurrentExpansionDB.usableOnlyAH = not DefaultCurrentExpansionDB.usableOnlyAH
		DefaultCurrentExpansionDB.usableOnlyCO = not DefaultCurrentExpansionDB.usableOnlyCO
		Print(string.format(L.MSG_USABLE_TOGGLE, DefaultCurrentExpansionDB.usableOnlyAH and L.ENABLED or L.DISABLED))
	elseif command == "status" then
		Print(L.STATUS_HEADER)
		Print(string.format(L.STATUS_PRESERVE, DefaultCurrentExpansionDB.preserveFilterChanges and L.YES or L.NO))
		Print(string.format(L.STATUS_CEO_AH, DefaultCurrentExpansionDB.auctionHouse and L.YES or L.NO))
		Print(string.format(L.STATUS_CEO_CO, DefaultCurrentExpansionDB.craftingOrders and L.YES or L.NO))
		Print(string.format(L.STATUS_USABLE_AH, DefaultCurrentExpansionDB.usableOnlyAH and L.YES or L.NO))
		Print(string.format(L.STATUS_USABLE_CO, DefaultCurrentExpansionDB.usableOnlyCO and L.YES or L.NO))
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
