-- Questie: Job's Done! Plays the peon's "Job's done!" (or another work-crew line) the moment Questie sees a quest's
-- objectives finished, with an opt-in "done!" line to your party. Uses Questie's public API
-- (Questie.API.RegisterOnReady / RegisterForQuestUpdates) and sounds already in the client. No addon messages.
local addonName, ns = ...

local JD = {}
ns.JD = JD
QuestieJobsDone = JD

JD.Voices = {
  jobsdone = { id = 558132, label = "Peon: Job's done!" },
  ready = { id = 558137, label = "Peon: Ready to work!" },
  peasant = { id = 558118, label = "Peasant: Ready to work." },
}
JD.VoiceOrder = { "jobsdone", "ready", "peasant" }

local defaults = { enabled = true, voice = "jobsdone", channel = "Master", partyPing = false, chatLine = true }
local db
local announced = {}   -- questId -> true once we spoke for it (until it is turned in or abandoned)
local lastPing = -math.huge
local lastSound = -math.huge

local function say(msg) print("|cffffd200Job's Done|r: " .. msg) end

local function questieAlsoPlays()
  -- Questie has its own (off by default) quest-complete sound; if it is on, we stay quiet so you don't hear two.
  local p = Questie and Questie.db and Questie.db.profile
  return type(p) == "table" and p.soundOnQuestComplete == true
end

function JD.Play(force)
  local v = JD.Voices[db.voice] or JD.Voices.jobsdone
  local now = GetTime()
  if not force and now - lastSound < 1 then return false end -- several quests finishing on one kill: one line
  lastSound = now
  local ok, willPlay = pcall(PlaySoundFile, v.id, db.channel)
  return ok and willPlay and true or false
end

local REASON = { UPDATED = 2, TURNED_IN = 3, ABANDONED = 4 }

function JD.OnQuestUpdate(questId, _, reason)
  if not db or type(questId) ~= "number" then return end
  if reason == REASON.TURNED_IN or reason == REASON.ABANDONED then announced[questId] = nil return end
  if reason ~= REASON.UPDATED or announced[questId] then return end
  if not C_QuestLog.IsComplete(questId) then return end
  announced[questId] = true
  local title = C_QuestLog.GetTitleForQuestID(questId) or ("quest " .. questId)
  if db.enabled and not questieAlsoPlays() then JD.Play() end
  if db.chatLine then say(title .. " - job's done! Go hand it in.") end
  if db.partyPing and IsInGroup() and not IsInRaid() then
    local now = GetTime()
    local locked = C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown()
    if not locked and now - lastPing >= 10 then
      lastPing = now
      C_ChatInfo.SendChatMessage(("Job's done: %s"):format(title), "PARTY")
    end
  end
end

-- Also offer the lines in LibSharedMedia, so Questie's own sound pickers (and BigWigs, DBM...) can use them.
local lsmDone = false
function JD.RegisterLSM()
  if lsmDone or type(LibStub) ~= "table" then return lsmDone end
  local LSM = LibStub("LibSharedMedia-3.0", true)
  if not LSM then return false end
  for _, key in ipairs(JD.VoiceOrder) do pcall(LSM.Register, LSM, "sound", "Job's Done: " .. JD.Voices[key].label, JD.Voices[key].id) end
  lsmDone = true
  return true
end

local hooked = false
function JD.Hook()
  if hooked then return true end
  local api = type(Questie) == "table" and Questie.API
  if type(api) ~= "table" or type(api.RegisterForQuestUpdates) ~= "function" then return false end
  local enums = api.Enums and api.Enums.QuestUpdateTriggerReason
  if type(enums) == "table" then
    REASON.UPDATED, REASON.TURNED_IN, REASON.ABANDONED = enums.QUEST_UPDATED or 2, enums.QUEST_TURNED_IN or 3, enums.QUEST_ABANDONED or 4
  end
  local ok = pcall(api.RegisterForQuestUpdates, JD.OnQuestUpdate)
  hooked = ok
  if ok and type(api.RegisterOnReady) == "function" then
    -- quests already complete at login count as announced, so we don't shout about old work
    pcall(api.RegisterOnReady, function()
      for i = 1, (C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetNumQuestLogEntries() or 0) do
        local info = C_QuestLog.GetInfo and C_QuestLog.GetInfo(i)
        if info and info.questID and not info.isHeader and C_QuestLog.IsComplete(info.questID) then announced[info.questID] = true end
      end
    end)
  end
  return ok
end

SLASH_QUESTIEJOBSDONE1 = "/jobsdone"
SLASH_QUESTIEJOBSDONE2 = "/jd"
SlashCmdList.QUESTIEJOBSDONE = function(msg)
  msg = strtrim((msg or ""):lower())
  if msg == "test" then JD.Play(true); say((JD.Voices[db.voice] or JD.Voices.jobsdone).label)
  elseif msg == "voice" then
    local i = 1
    for n, k in ipairs(JD.VoiceOrder) do if k == db.voice then i = n end end
    db.voice = JD.VoiceOrder[i % #JD.VoiceOrder + 1]
    say("voice: " .. JD.Voices[db.voice].label); JD.Play(true)
  elseif msg == "party" then db.partyPing = not db.partyPing; say(db.partyPing and "party line on (5-player groups, max one per 10 s)." or "party line off.")
  elseif msg == "mute" then db.enabled = not db.enabled; say(db.enabled and "sound on." or "sound muted.")
  elseif msg == "quiet" then db.chatLine = not db.chatLine; say(db.chatLine and "chat line on." or "chat line off.")
  else
    say("/jd test | /jd voice (cycle) | /jd party (opt-in party line) | /jd mute | /jd quiet")
    if not hooked then say("Questie isn't loaded, so nothing will play.") end
    if questieAlsoPlays() then say("Questie's own quest-complete sound is on, so this addon only does the chat/party lines.") end
  end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" and name == addonName then
    QuestieJobsDoneDB = QuestieJobsDoneDB or {}
    db = QuestieJobsDoneDB
    for k, v in pairs(defaults) do if db[k] == nil then db[k] = v end end
    JD.db = db
  elseif event == "PLAYER_LOGIN" then
    JD.Hook(); JD.RegisterLSM()
  end
end)
