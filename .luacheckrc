std = "lua51"
max_line_length = false
exclude_files = { "tests/**", "tools/**", ".release/**", ".lua/**", ".luarocks/**" }
-- Our own globals.
globals = { "QuestieJobsDone", "QuestieJobsDoneDB", "SLASH_QUESTIEJOBSDONE1", "SLASH_QUESTIEJOBSDONE2", "SlashCmdList" }
-- WoW API (checked against Blizzard's UI source by tools/verify_api.py) and host-addon globals (tools/host_api.py).
read_globals = { "C_QuestLog", "C_ChatInfo", "CreateFrame", "GetTime", "IsInGroup", "IsInRaid", "PlaySoundFile", "strtrim", "Questie", "LibStub" }
