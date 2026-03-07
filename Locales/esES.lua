if GetLocale() ~= "esES" and GetLocale() ~= "esMX" then return end
-- Auto-translated — pull requests with improved translations are welcome!
local L = DCE_L

-- Options panel
L.ADDON_TITLE = "Expansión actual por defecto"
L.ADDON_SUBTITLE = "Selecciona automáticamente el filtro 'Solo expansión actual'"
L.OPT_AUCTION_HOUSE = "Filtrado de casa de subastas"
L.OPT_CRAFTING_ORDERS = "Filtrado de pedidos de fabricación"
L.OPT_PRESERVE_FILTER = "Conservar cambios de filtro"
L.VERSION_LABEL = "Versión %s | Idioma: %s"

-- Toggle messages
L.MSG_AH_TOGGLE = "Filtrado de casa de subastas %s"
L.MSG_CO_TOGGLE = "Filtrado de pedidos de fabricación %s"
L.MSG_PRESERVE_TOGGLE = "Conservar cambios de filtro %s"
L.ENABLED = "activado"
L.DISABLED = "desactivado"

-- Slash command help
L.HELP_HEADER = "Comandos:"
L.HELP_OPT = "/dce opt - Abrir menú de opciones"
L.HELP_AH = "/dce ah - Alternar filtrado de casa de subastas"
L.HELP_CO = "/dce co - Alternar filtrado de pedidos de fabricación"
L.HELP_PRESERVE = "/dce preserve - Alternar conservar cambios de filtro"
L.HELP_STATUS = "/dce status - Mostrar configuración actual"

-- Status
L.STATUS_HEADER = "Configuración actual:"
L.STATUS_AH = "  Casa de subastas: %s"
L.STATUS_CO = "  Pedidos de fabricación: %s"
L.STATUS_PRESERVE = "  Conservar cambios de filtro: %s"
L.YES = "Sí"
L.NO = "No"

-- Errors
L.MSG_UNKNOWN_CMD = "Comando desconocido. Escribe /dce help para ver opciones"
