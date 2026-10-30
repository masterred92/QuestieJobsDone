std = "lua51"
max_line_length = false
exclude_files = { "tests/**", "tools/**", ".release/**", ".lua/**", ".luarocks/**", "wow-ui/**", "index/**", "hosts/**" }
-- Our own globals.
globals = { "QuestieJobsDone", "QuestieJobsDoneDB", "SLASH_QUESTIEJOBSDONE1", "SLASH_QUESTIEJOBSDONE2", "SlashCmdList" }
-- WoW API (checked against Blizzard's UI source by tools/verify_api.py) and host-addon globals (tools/host_api.py).
read_globals = { "C_QuestLog", "C_ChatInfo", "CreateFrame", "GetTime", "IsInGroup", "IsInRaid", "PlaySoundFile", "strtrim", "Questie", "LibStub",
  -- used by the shared KennyShared library (Libs/KennyShared)
  "C_AddOns", "C_AuctionHouse", "C_Container", "C_Item", "C_RestrictedActions", "C_Timer", "Enum", "GameTooltip", "GetBuildInfo", "GetLocale", "GetMoney", "GetMoneyString", "GetRealZoneText", "GetRealmName", "GetSubZoneText", "ItemRefTooltip", "NUM_BAG_SLOTS", "NUM_TOTAL_EQUIPPED_BAG_SLOTS", "TooltipDataProcessor", "UIParent", "UnitAffectingCombat", "UnitFactionGroup", "date", "issecretvalue", "time" }
