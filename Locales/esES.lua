if GetLocale() ~= "esES" and GetLocale() ~= "esMX" then return end
-- Auto-translated — pull requests with improved translations are welcome!
local L = DCE_L

-- Options panel
L.ADDON_TITLE = "Expansión actual por defecto"
L.ADDON_SUBTITLE = "Aplica automáticamente filtros de casa de subastas y pedidos de fabricación"
L.OPT_PRESERVE_FILTER = "Conservar cambios de filtro"
L.OPT_SECTION_CEO = "Solo expansión actual"
L.OPT_SECTION_USABLE = "Solo objetos utilizables"
L.OPT_AUCTION_HOUSE = "Casa de subastas"
L.OPT_CRAFTING_ORDERS = "Pedidos de fabricación"
L.VERSION_LABEL = "Versión %s | Idioma: %s"

-- Toggle messages
L.MSG_AH_TOGGLE = "Solo expansión actual (Casa de subastas) %s"
L.MSG_CO_TOGGLE = "Solo expansión actual (Pedidos de fabricación) %s"
L.MSG_PRESERVE_TOGGLE = "Conservar cambios de filtro %s"
L.MSG_USABLE_TOGGLE = "Solo objetos utilizables %s"
L.MSG_USABLE_AH_TOGGLE = "Solo objetos utilizables (Casa de subastas) %s"
L.MSG_USABLE_CO_TOGGLE = "Solo objetos utilizables (Pedidos de fabricación) %s"
L.ENABLED = "activado"
L.DISABLED = "desactivado"

-- Slash command help
L.HELP_HEADER = "Comandos:"
L.HELP_OPT = "/dce opt - Abrir menú de opciones"
L.HELP_AH = "/dce ah - Alternar solo expansión actual (Casa de subastas)"
L.HELP_CO = "/dce co - Alternar solo expansión actual (Pedidos de fabricación)"
L.HELP_PRESERVE = "/dce preserve - Alternar conservar cambios de filtro"
L.HELP_USABLE = "/dce usable - Alternar solo objetos utilizables"
L.HELP_STATUS = "/dce status - Mostrar configuración actual"

-- Status
L.STATUS_HEADER = "Configuración actual:"
L.STATUS_PRESERVE = "  Conservar cambios de filtro: %s"
L.STATUS_CEO_AH = "  Solo expansión actual (CS): %s"
L.STATUS_CEO_CO = "  Solo expansión actual (PF): %s"
L.STATUS_USABLE_AH = "  Solo objetos utilizables (CS): %s"
L.STATUS_USABLE_CO = "  Solo objetos utilizables (PF): %s"
L.YES = "Sí"
L.NO = "No"

-- Errors
L.MSG_UNKNOWN_CMD = "Comando desconocido. Escribe /dce help para ver opciones"
