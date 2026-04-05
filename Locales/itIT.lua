if GetLocale() ~= "itIT" then return end
-- Auto-translated — pull requests with improved translations are welcome!
local L = DCE_L

-- Options panel
L.ADDON_TITLE = "Espansione corrente predefinita"
L.ADDON_SUBTITLE = "Applica automaticamente i filtri della casa d'aste e degli ordini di creazione"
L.OPT_PRESERVE_FILTER = "Conserva modifiche filtro"
L.OPT_SECTION_CEO = "Solo espansione corrente"
L.OPT_SECTION_USABLE = "Solo oggetti utilizzabili"
L.OPT_AUCTION_HOUSE = "Casa d'aste"
L.OPT_CRAFTING_ORDERS = "Ordini di creazione"
L.VERSION_LABEL = "Versione %s | Lingua: %s"

-- Toggle messages
L.MSG_AH_TOGGLE = "Solo espansione corrente (Casa d'aste) %s"
L.MSG_CO_TOGGLE = "Solo espansione corrente (Ordini di creazione) %s"
L.MSG_PRESERVE_TOGGLE = "Conserva modifiche filtro %s"
L.MSG_USABLE_TOGGLE = "Solo oggetti utilizzabili %s"
L.MSG_USABLE_AH_TOGGLE = "Solo oggetti utilizzabili (Casa d'aste) %s"
L.MSG_USABLE_CO_TOGGLE = "Solo oggetti utilizzabili (Ordini di creazione) %s"
L.ENABLED = "attivato"
L.DISABLED = "disattivato"

-- Slash command help
L.HELP_HEADER = "Comandi:"
L.HELP_OPT = "/dce opt - Apri il menu opzioni"
L.HELP_AH = "/dce ah - Attiva/disattiva solo espansione corrente (Casa d'aste)"
L.HELP_CO = "/dce co - Attiva/disattiva solo espansione corrente (Ordini di creazione)"
L.HELP_PRESERVE = "/dce preserve - Attiva/disattiva conserva modifiche filtro"
L.HELP_USABLE = "/dce usable - Attiva/disattiva solo oggetti utilizzabili"
L.HELP_STATUS = "/dce status - Mostra impostazioni attuali"

-- Status
L.STATUS_HEADER = "Impostazioni attuali:"
L.STATUS_PRESERVE = "  Conserva modifiche filtro: %s"
L.STATUS_CEO_AH = "  Solo espansione corrente (CA): %s"
L.STATUS_CEO_CO = "  Solo espansione corrente (OC): %s"
L.STATUS_USABLE_AH = "  Solo oggetti utilizzabili (CA): %s"
L.STATUS_USABLE_CO = "  Solo oggetti utilizzabili (OC): %s"
L.YES = "Sì"
L.NO = "No"

-- Errors
L.MSG_UNKNOWN_CMD = "Comando sconosciuto. Digita /dce help per le opzioni"
