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

local function Print(...)
	print("|cff00ff00[Default Current Expansion]|r", ...)
end

-- Filter enum references (nil if Blizzard renames/removes them in a future patch)
local FILTER_CEO = Enum.AuctionHouseFilter and Enum.AuctionHouseFilter.CurrentExpansionOnly
local FILTER_USABLE = Enum.AuctionHouseFilter and Enum.AuctionHouseFilter.UsableOnly

-- User's manual filter overrides for this AH session, keyed by filter enum (absent key = use addon setting)
local userFilterOverride = {}
-- What was last applied per filter, so the watcher can detect user changes
local lastAppliedFilterState = {}
local filterWatcher = nil

local function CancelFilterWatcher()
	if filterWatcher then
		filterWatcher:Cancel()
		filterWatcher = nil
	end
end

-- Polls while Buy tab is shown to detect manual filter changes
local function StartFilterWatcher()
	CancelFilterWatcher()
	if not DefaultCurrentExpansionDB.preserveFilterChanges then return end

	-- Built once per watcher start; settings can't change while AH is open
	local watchedFilters = {}
	if FILTER_CEO and DefaultCurrentExpansionDB.auctionHouse then
		watchedFilters[#watchedFilters + 1] = FILTER_CEO
	end
	if FILTER_USABLE and DefaultCurrentExpansionDB.usableOnlyAH then
		watchedFilters[#watchedFilters + 1] = FILTER_USABLE
	end

	filterWatcher = C_Timer.NewTicker(0.2, function()
		if not AuctionHouseFrame or not AuctionHouseFrame:IsShown() then
			CancelFilterWatcher()
			return
		end
		local searchBar = AuctionHouseFrame.SearchBar
		if not searchBar or not searchBar:IsShown() then return end
		local filterButton = searchBar.FilterButton
		if not filterButton or not filterButton.filters then return end

		for _, filter in ipairs(watchedFilters) do
			local currentState = filterButton.filters[filter] and true or false
			if lastAppliedFilterState[filter] ~= nil and currentState ~= lastAppliedFilterState[filter] then
				userFilterOverride[filter] = currentState
			end
			lastAppliedFilterState[filter] = currentState
		end
	end)
end

local function ApplyOneFilter(filters, filterEnum)
	local desired
	if DefaultCurrentExpansionDB.preserveFilterChanges and userFilterOverride[filterEnum] ~= nil then
		desired = userFilterOverride[filterEnum]
	else
		desired = true
	end
	filters[filterEnum] = desired
	lastAppliedFilterState[filterEnum] = desired
end

-- Frames need 0.1s after AUCTION_HOUSE_SHOW to fully initialize
local function ApplyAuctionHouseFilter()
	C_Timer.After(0.1, function()
		if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
			local searchBar = AuctionHouseFrame.SearchBar
			if searchBar and searchBar:IsShown() and searchBar.FilterButton then
				local filterButton = searchBar.FilterButton

				if filterButton.filters then
					if FILTER_CEO and DefaultCurrentExpansionDB.auctionHouse then
						ApplyOneFilter(filterButton.filters, FILTER_CEO)
					end
					if FILTER_USABLE and DefaultCurrentExpansionDB.usableOnlyAH then
						ApplyOneFilter(filterButton.filters, FILTER_USABLE)
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

-- CO has no filter watcher — preserveFilterChanges only applies to the AH
local function OnCraftingOrdersShow()
	C_Timer.After(0.1, function()
		if ProfessionsCustomerOrdersFrame and ProfessionsCustomerOrdersFrame:IsShown() then
			local browseFrame = ProfessionsCustomerOrdersFrame.BrowseOrders
			if browseFrame and browseFrame.SearchBar then
				local searchBar = browseFrame.SearchBar

				if searchBar.FilterDropdown then
					local filterDropdown = searchBar.FilterDropdown

					if filterDropdown.filters then
						if FILTER_CEO and DefaultCurrentExpansionDB.craftingOrders then
							filterDropdown.filters[FILTER_CEO] = true
						end
						if FILTER_USABLE and DefaultCurrentExpansionDB.usableOnlyCO then
							filterDropdown.filters[FILTER_USABLE] = true
						end
						filterDropdown:ValidateResetState()
					end
				end
			end
		end
	end)
end

function addon:SetupAuctionHouse()
	if not self.ahFrame then
		self.ahFrame = CreateFrame("Frame", "DCE_AuctionHouseEventFrame")
		self.ahFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
		self.ahFrame:SetScript("OnEvent", OnAuctionHouseShow)
	end
end

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
	ceoAHCheckbox:SetPoint("TOPLEFT", ceoHeader, "BOTTOMLEFT", 0, -8)
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
	usableHeader:SetPoint("TOPLEFT", ceoCOCheckbox, "BOTTOMLEFT", 0, -16)
	usableHeader:SetText(L.OPT_SECTION_USABLE)

	local usableAHCheckbox = CreateFrame("CheckButton", "DCE_UsableAHCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
	usableAHCheckbox:SetPoint("TOPLEFT", usableHeader, "BOTTOMLEFT", 0, -8)
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
		-- If either surface is on, turn both off; otherwise turn both on
		local newState = not (DefaultCurrentExpansionDB.usableOnlyAH or DefaultCurrentExpansionDB.usableOnlyCO)
		DefaultCurrentExpansionDB.usableOnlyAH = newState
		DefaultCurrentExpansionDB.usableOnlyCO = newState
		Print(string.format(L.MSG_USABLE_TOGGLE, newState and L.ENABLED or L.DISABLED))
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
