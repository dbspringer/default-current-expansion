if GetLocale() ~= "frFR" then return end
-- Auto-translated — pull requests with improved translations are welcome!
local L = DCE_L

-- Options panel
L.ADDON_TITLE = "Extension actuelle par défaut"
L.ADDON_SUBTITLE = "Applique automatiquement les filtres de l'hôtel des ventes et des commandes d'artisanat"
L.OPT_PRESERVE_FILTER = "Conserver les modifications de filtre"
L.OPT_SECTION_CEO = "Extension actuelle uniquement"
L.OPT_SECTION_USABLE = "Objets utilisables uniquement"
L.OPT_AUCTION_HOUSE = "Hôtel des ventes"
L.OPT_CRAFTING_ORDERS = "Commandes d'artisanat"
L.VERSION_LABEL = "Version %s | Langue : %s"

-- Toggle messages
L.MSG_AH_TOGGLE = "Extension actuelle uniquement (Hôtel des ventes) %s"
L.MSG_CO_TOGGLE = "Extension actuelle uniquement (Commandes d'artisanat) %s"
L.MSG_PRESERVE_TOGGLE = "Conserver les modifications de filtre %s"
L.MSG_USABLE_TOGGLE = "Objets utilisables uniquement %s"
L.MSG_USABLE_AH_TOGGLE = "Objets utilisables uniquement (Hôtel des ventes) %s"
L.MSG_USABLE_CO_TOGGLE = "Objets utilisables uniquement (Commandes d'artisanat) %s"
L.ENABLED = "activé"
L.DISABLED = "désactivé"

-- Slash command help
L.HELP_HEADER = "Commandes :"
L.HELP_OPT = "/dce opt - Ouvrir le menu des options"
L.HELP_AH = "/dce ah - Basculer extension actuelle uniquement (Hôtel des ventes)"
L.HELP_CO = "/dce co - Basculer extension actuelle uniquement (Commandes d'artisanat)"
L.HELP_PRESERVE = "/dce preserve - Basculer la conservation des modifications de filtre"
L.HELP_USABLE = "/dce usable - Basculer objets utilisables uniquement"
L.HELP_STATUS = "/dce status - Afficher les paramètres actuels"

-- Status
L.STATUS_HEADER = "Paramètres actuels :"
L.STATUS_PRESERVE = "  Conserver les modifications de filtre : %s"
L.STATUS_CEO_AH = "  Extension actuelle uniquement (HV) : %s"
L.STATUS_CEO_CO = "  Extension actuelle uniquement (CA) : %s"
L.STATUS_USABLE_AH = "  Objets utilisables uniquement (HV) : %s"
L.STATUS_USABLE_CO = "  Objets utilisables uniquement (CA) : %s"
L.YES = "Oui"
L.NO = "Non"

-- Errors
L.MSG_UNKNOWN_CMD = "Commande inconnue. Tapez /dce help pour les options"
