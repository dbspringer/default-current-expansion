if GetLocale() ~= "deDE" then return end
-- Auto-translated — pull requests with improved translations are welcome!
local L = DCE_L

-- Options panel
L.ADDON_TITLE = "Standard: Aktuelle Erweiterung"
L.ADDON_SUBTITLE = "Wählt automatisch den Filter 'Nur aktuelle Erweiterung'"
L.OPT_AUCTION_HOUSE = "Auktionshaus-Filterung"
L.OPT_CRAFTING_ORDERS = "Handwerksaufträge-Filterung"
L.OPT_PRESERVE_FILTER = "Filteränderungen beibehalten"
L.OPT_USABLE_ONLY = "Nur verwendbare Gegenstände"
L.VERSION_LABEL = "Version %s | Sprache: %s"

-- Toggle messages
L.MSG_AH_TOGGLE = "Auktionshaus-Filterung %s"
L.MSG_CO_TOGGLE = "Handwerksaufträge-Filterung %s"
L.MSG_PRESERVE_TOGGLE = "Filteränderungen beibehalten %s"
L.MSG_USABLE_TOGGLE = "Nur verwendbare Gegenstände %s"
L.ENABLED = "aktiviert"
L.DISABLED = "deaktiviert"

-- Slash command help
L.HELP_HEADER = "Befehle:"
L.HELP_OPT = "/dce opt - Optionsmenü öffnen"
L.HELP_AH = "/dce ah - Auktionshaus-Filterung umschalten"
L.HELP_CO = "/dce co - Handwerksaufträge-Filterung umschalten"
L.HELP_PRESERVE = "/dce preserve - Filteränderungen beibehalten umschalten"
L.HELP_USABLE = "/dce usable - Nur verwendbare Gegenstände umschalten"
L.HELP_STATUS = "/dce status - Aktuelle Einstellungen anzeigen"

-- Status
L.STATUS_HEADER = "Aktuelle Einstellungen:"
L.STATUS_AH = "  Auktionshaus: %s"
L.STATUS_CO = "  Handwerksaufträge: %s"
L.STATUS_PRESERVE = "  Filteränderungen beibehalten: %s"
L.STATUS_USABLE = "  Nur verwendbare Gegenstände: %s"
L.YES = "Ja"
L.NO = "Nein"

-- Errors
L.MSG_UNKNOWN_CMD = "Unbekannter Befehl. /dce help für Optionen eingeben"
