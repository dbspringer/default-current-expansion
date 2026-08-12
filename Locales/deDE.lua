if GetLocale() ~= "deDE" then return end
-- Auto-translated — pull requests with improved translations are welcome!
local L = DCE_L

-- Options panel
L.ADDON_TITLE = "Standard: Aktuelle Erweiterung"
L.ADDON_SUBTITLE = "Wendet automatisch Filter für Auktionshaus und Handwerksaufträge an"
L.OPT_SECTION_CEO = "Nur aktuelle Erweiterung"
L.OPT_SECTION_USABLE = "Nur verwendbare Gegenstände"
L.OPT_AUCTION_HOUSE = "Auktionshaus"
L.OPT_CRAFTING_ORDERS = "Handwerksaufträge"
L.VERSION_LABEL = "Version %s | Sprache: %s"

-- Toggle messages
L.MSG_AH_TOGGLE = "Nur aktuelle Erweiterung (Auktionshaus) %s"
L.MSG_CO_TOGGLE = "Nur aktuelle Erweiterung (Handwerksaufträge) %s"
L.MSG_USABLE_TOGGLE = "Nur verwendbare Gegenstände %s"
L.MSG_USABLE_AH_TOGGLE = "Nur verwendbare Gegenstände (Auktionshaus) %s"
L.MSG_USABLE_CO_TOGGLE = "Nur verwendbare Gegenstände (Handwerksaufträge) %s"
L.ENABLED = "aktiviert"
L.DISABLED = "deaktiviert"

-- Slash command help
L.HELP_HEADER = "Befehle:"
L.HELP_OPT = "/dce opt - Optionsmenü öffnen"
L.HELP_AH = "/dce ah - Nur aktuelle Erweiterung (Auktionshaus) umschalten"
L.HELP_CO = "/dce co - Nur aktuelle Erweiterung (Handwerksaufträge) umschalten"
L.HELP_USABLE = "/dce usable - Nur verwendbare Gegenstände umschalten"
L.HELP_STATUS = "/dce status - Aktuelle Einstellungen anzeigen"

-- Status
L.STATUS_HEADER = "Aktuelle Einstellungen:"
L.STATUS_CEO_AH = "  Nur aktuelle Erweiterung (AH): %s"
L.STATUS_CEO_CO = "  Nur aktuelle Erweiterung (HA): %s"
L.STATUS_USABLE_AH = "  Nur verwendbare Gegenstände (AH): %s"
L.STATUS_USABLE_CO = "  Nur verwendbare Gegenstände (HA): %s"
L.YES = "Ja"
L.NO = "Nein"

-- Errors
L.MSG_UNKNOWN_CMD = "Unbekannter Befehl. /dce help für Optionen eingeben"
