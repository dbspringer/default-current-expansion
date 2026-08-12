-- Default Current Expansion
-- Automatically applies AH and Crafting Orders filters (Current Expansion Only, Usable Only)

local addonName = "DefaultCurrentExpansion"
local addon = {}
local L = DCE_L

-- Default settings
local defaults = {
	auctionHouse = true,
	craftingOrders = true,
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

	-- Which AH filters this addon set for THIS character. Blizzard's g_auctionHouseFilters is
	-- per-character, so ownership has to be too: the account-wide settings above say what the
	-- player wants, this says what we actually did here.
	if not DefaultCurrentExpansionCharDB then
		DefaultCurrentExpansionCharDB = {}
	end
	DefaultCurrentExpansionCharDB.owned = DefaultCurrentExpansionCharDB.owned or {}

	-- Clean up removed keys from existing saved variables
	DefaultCurrentExpansionDB.debug = nil
	DefaultCurrentExpansionDB.usableOnly = nil
	DefaultCurrentExpansionDB.preserveFilterChanges = nil
	DefaultCurrentExpansionDB.pendingRelease = nil
end

local function Print(...)
	print("|cff00ff00[Default Current Expansion]|r", ...)
end

-- Filter enum references (nil if Blizzard renames/removes them in a future patch)
local FILTER_CEO = Enum.AuctionHouseFilter and Enum.AuctionHouseFilter.CurrentExpansionOnly
local FILTER_USABLE = Enum.AuctionHouseFilter and Enum.AuctionHouseFilter.UsableOnly

-- 12.1.0 moved AH filter state out of the FilterButton and into this saved variable.
-- Clear Filters replaces the whole table, so resolve it on every use — never cache.
local function GetAuctionHouseFilters()
	return g_auctionHouseFilters and g_auctionHouseFilters.filters
end

-- Brings one filter in line with its setting, tracking what we set on this character.
-- 12.1.0 persists AH filters, so a filter we turned on stays on after its option is turned
-- off; we hand it back. A filter the player ticked themselves is never ours to clear.
local function SyncAuctionHouseFilter(filters, filterEnum, wanted)
	if not filterEnum then return end

	local owned = DefaultCurrentExpansionCharDB.owned
	if wanted then
		-- Claim it only if we are the ones switching it on. A filter that is already true
		-- belongs to the player, and claiming it would let a later toggle-off delete their
		-- choice. An existing claim survives, since this branch never clears one.
		if not filters[filterEnum] then
			owned[filterEnum] = true
		end
		filters[filterEnum] = true
	elseif owned[filterEnum] then
		filters[filterEnum] = false
		owned[filterEnum] = nil
	end
end

-- Called when an AH option is turned off. If the AH UI hasn't loaded yet (it is
-- LoadOnDemand) ownership stays recorded and the next AH open syncs it instead.
local function ReleaseAuctionHouseFilter(filterEnum)
	local filters = GetAuctionHouseFilters()
	if filters then
		SyncAuctionHouseFilter(filters, filterEnum, false)
	end
end

-- Reaching the Buy tab is what we care about, not every tab switch. Applying once per AH
-- visit leaves a manual untick alone for the rest of that visit, which the game now keeps.
local appliedThisVisit = false

-- Frames need 0.1s after AUCTION_HOUSE_SHOW to fully initialize
local function ApplyAuctionHouseFilter()
	C_Timer.After(0.1, function()
		if appliedThisVisit then return end

		if AuctionHouseFrame and AuctionHouseFrame:IsShown() then
			local searchBar = AuctionHouseFrame.SearchBar
			if searchBar and searchBar:IsShown() then
				local filters = GetAuctionHouseFilters()

				if filters then
					appliedThisVisit = true

					SyncAuctionHouseFilter(filters, FILTER_CEO, DefaultCurrentExpansionDB.auctionHouse)
					SyncAuctionHouseFilter(filters, FILTER_USABLE, DefaultCurrentExpansionDB.usableOnlyAH)
				end
			end
		end
	end)
end

-- Auction House event handler
-- Hooks SetDisplayMode so the filter still applies when another addon (e.g. Auctionator)
-- opens the AH on its own tab. The Buy search bar is hidden at AUCTION_HOUSE_SHOW in that
-- case, so without this the filter is never written at all and 12.1.0's persistence has
-- nothing to preserve. Re-applying on tab switch is no longer needed; reaching Buy is.
local function OnAuctionHouseShow()
	appliedThisVisit = false

	if AuctionHouseFrame and not AuctionHouseFrame.DCE_displayModeHooked then
		hooksecurefunc(AuctionHouseFrame, "SetDisplayMode", function(_, displayMode)
			-- Auctionator calls SetDisplayMode({}) for its own tabs; skip those
			if displayMode and next(displayMode) ~= nil then
				ApplyAuctionHouseFilter()
			end
		end)
		AuctionHouseFrame.DCE_displayModeHooked = true
	end

	ApplyAuctionHouseFilter()
end

-- CO needs no release: unlike the AH, it still resets its filters to defaults on open
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

	-- Current Expansion Only section
	local ceoHeader = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	ceoHeader:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -16)
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
		if not DefaultCurrentExpansionDB.auctionHouse then
			ReleaseAuctionHouseFilter(FILTER_CEO)
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
		if not DefaultCurrentExpansionDB.usableOnlyAH then
			ReleaseAuctionHouseFilter(FILTER_USABLE)
		end
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
		Print(L.HELP_USABLE)
		Print(L.HELP_STATUS)
	elseif command == "ah" then
		DefaultCurrentExpansionDB.auctionHouse = not DefaultCurrentExpansionDB.auctionHouse
		Print(string.format(L.MSG_AH_TOGGLE, DefaultCurrentExpansionDB.auctionHouse and L.ENABLED or L.DISABLED))
		if DefaultCurrentExpansionDB.auctionHouse then
			addon:SetupAuctionHouse()
		else
			ReleaseAuctionHouseFilter(FILTER_CEO)
		end
	elseif command == "co" then
		DefaultCurrentExpansionDB.craftingOrders = not DefaultCurrentExpansionDB.craftingOrders
		Print(string.format(L.MSG_CO_TOGGLE, DefaultCurrentExpansionDB.craftingOrders and L.ENABLED or L.DISABLED))
		if DefaultCurrentExpansionDB.craftingOrders then
			addon:SetupCraftingOrders()
		end
	elseif command == "usable" then
		-- If either surface is on, turn both off; otherwise turn both on
		local newState = not (DefaultCurrentExpansionDB.usableOnlyAH or DefaultCurrentExpansionDB.usableOnlyCO)
		DefaultCurrentExpansionDB.usableOnlyAH = newState
		DefaultCurrentExpansionDB.usableOnlyCO = newState
		if not newState then
			ReleaseAuctionHouseFilter(FILTER_USABLE)
		end
		Print(string.format(L.MSG_USABLE_TOGGLE, newState and L.ENABLED or L.DISABLED))
	elseif command == "status" then
		Print(L.STATUS_HEADER)
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
