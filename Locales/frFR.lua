if GetLocale() ~= "frFR" then return end
-- Auto-translated — pull requests with improved translations are welcome!
local L = DCE_L

-- Options panel
L.ADDON_TITLE = "Extension actuelle par défaut"
L.ADDON_SUBTITLE = "Sélectionne automatiquement le filtre 'Extension actuelle uniquement'"
L.OPT_AUCTION_HOUSE = "Filtrage de l'hôtel des ventes"
L.OPT_CRAFTING_ORDERS = "Filtrage des commandes d'artisanat"
L.OPT_PRESERVE_FILTER = "Conserver les modifications de filtre"
L.OPT_USABLE_ONLY = "Objets utilisables uniquement"
L.VERSION_LABEL = "Version %s | Langue : %s"

-- Toggle messages
L.MSG_AH_TOGGLE = "Filtrage de l'hôtel des ventes %s"
L.MSG_CO_TOGGLE = "Filtrage des commandes d'artisanat %s"
L.MSG_PRESERVE_TOGGLE = "Conserver les modifications de filtre %s"
L.MSG_USABLE_TOGGLE = "Objets utilisables uniquement %s"
L.ENABLED = "activé"
L.DISABLED = "désactivé"

-- Slash command help
L.HELP_HEADER = "Commandes :"
L.HELP_OPT = "/dce opt - Ouvrir le menu des options"
L.HELP_AH = "/dce ah - Basculer le filtrage de l'hôtel des ventes"
L.HELP_CO = "/dce co - Basculer le filtrage des commandes d'artisanat"
L.HELP_PRESERVE = "/dce preserve - Basculer la conservation des modifications de filtre"
L.HELP_USABLE = "/dce usable - Basculer objets utilisables uniquement"
L.HELP_STATUS = "/dce status - Afficher les paramètres actuels"

-- Status
L.STATUS_HEADER = "Paramètres actuels :"
L.STATUS_AH = "  Hôtel des ventes : %s"
L.STATUS_CO = "  Commandes d'artisanat : %s"
L.STATUS_PRESERVE = "  Conserver les modifications de filtre : %s"
L.STATUS_USABLE = "  Objets utilisables uniquement : %s"
L.YES = "Oui"
L.NO = "Non"

-- Errors
L.MSG_UNKNOWN_CMD = "Commande inconnue. Tapez /dce help pour les options"
