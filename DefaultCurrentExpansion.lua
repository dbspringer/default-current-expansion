-- Default Current Expansion
-- Automatically selects "Current Expansion Only" filter in AH and Crafting Orders

local addonName = "DefaultCurrentExpansion"
local addon = {}

-- Default settings
local defaults = {
	auctionHouse = true,
	craftingOrders = true,
	preserveFilterChanges = false,
	debug = false
}

-- Initialize saved variables
function addon:InitDB()
	if not DefaultCurrentExpansionDB then
		DefaultCurrentExpansionDB = {}
	end

	-- Migrate renamed saved variables
	if DefaultCurrentExpansionDB.applyOnOpenOnly ~= nil then
		DefaultCurrentExpansionDB.preserveFilterChanges = DefaultCurrentExpansionDB.applyOnOpenOnly
		DefaultCurrentExpansionDB.applyOnOpenOnly = nil
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
			DebugPrint("User changed filter to " .. tostring(currentState) .. ", will preserve on tab switch")
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
					DebugPrint("Auction House filter set to " .. tostring(desiredState))
				else
					DebugPrint("Warning: FilterButton.filters not found")
				end
			else
				DebugPrint("Buy tab not active, skipping filter")
			end
		end
	end)
end

-- Auction House event handler
-- Hooks SetDisplayMode to catch tab switches (e.g. returning from Auctionator's Shopping tab)
local displayModeHooked = false

local function OnAuctionHouseShow()
	userFilterOverride = nil
	lastAppliedFilterState = nil
	CancelFilterWatcher()
	if not displayModeHooked and AuctionHouseFrame then
		hooksecurefunc(AuctionHouseFrame, "SetDisplayMode", function(_, displayMode)
			if displayMode and next(displayMode) ~= nil then
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

	-- Preserve Filter Changes checkbox
	local preserveCheckbox = CreateFrame("CheckButton", "DCE_PreserveCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
	preserveCheckbox:SetPoint("TOPLEFT", coCheckbox, "BOTTOMLEFT", 0, -8)
	preserveCheckbox.Text:SetText("Preserve filter changes")
	preserveCheckbox:SetChecked(DefaultCurrentExpansionDB.preserveFilterChanges)
	preserveCheckbox:SetScript("OnClick", function(self)
		DefaultCurrentExpansionDB.preserveFilterChanges = self:GetChecked()
		if DefaultCurrentExpansionDB.preserveFilterChanges then
			Print("Preserve filter changes enabled")
		else
			Print("Preserve filter changes disabled")
		end
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
		Print("/dce preserve - Toggle preserve filter changes")
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
	elseif command == "preserve" then
		DefaultCurrentExpansionDB.preserveFilterChanges = not DefaultCurrentExpansionDB.preserveFilterChanges
		Print("Preserve filter changes", DefaultCurrentExpansionDB.preserveFilterChanges and "enabled" or "disabled")
	elseif command == "debug" then
		DefaultCurrentExpansionDB.debug = not DefaultCurrentExpansionDB.debug
		Print("Debug mode", DefaultCurrentExpansionDB.debug and "enabled" or "disabled")
	elseif command == "status" then
		Print("Current Settings:")
		Print("  Auction House:", DefaultCurrentExpansionDB.auctionHouse and "Yes" or "No")
		Print("  Crafting Orders:", DefaultCurrentExpansionDB.craftingOrders and "Yes" or "No")
		Print("  Preserve Filter Changes:", DefaultCurrentExpansionDB.preserveFilterChanges and "Yes" or "No")
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
