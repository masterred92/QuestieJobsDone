package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
M.install()
local libs = M.installLDB()
local lsm = {}
libs["LibSharedMedia-3.0"] = { Register = function(_, t, k, v) lsm[#lsm + 1] = { t, k, v } end }
local complete, log = {}, { { questID = 100, isHeader = false } }
complete[100] = true -- already complete at login
C_QuestLog = { IsComplete = function(id) return complete[id] == true end,
  GetTitleForQuestID = function(id) return "The Lazy Peons " .. id end,
  GetNumQuestLogEntries = function() return #log end, GetInfo = function(i) return log[i] end }
local cbs, ready = {}, {}
Questie = { db = { profile = { soundOnQuestComplete = false } }, API = {
  Enums = { QuestUpdateTriggerReason = { QUEST_ACCEPTED = 1, QUEST_UPDATED = 2, QUEST_TURNED_IN = 3, QUEST_ABANDONED = 4 } },
  RegisterForQuestUpdates = function(f) cbs[#cbs + 1] = f end,
  RegisterOnReady = function(f) ready[#ready + 1] = f end } }
local function q(id, obj, reason) for _, f in ipairs(cbs) do f(id, obj, reason) end end

local ns = M.loadAddon(".", "QuestieJobsDone")
M.fire("PLAYER_LOGIN")
M.check(#cbs == 1, "registered with Questie.API.RegisterForQuestUpdates")
M.check(#lsm == 3 and lsm[1][3] == 558132, "lines offered in LibSharedMedia")
ready[1]()
q(100, 1, 2)
M.check(#M.sounds == 0, "quest complete before login stays quiet")
-- progress, not complete
q(200, 1, 2)
M.check(#M.sounds == 0, "unfinished quest: nothing")
complete[200] = true
q(200, 1, 2); q(200, 2, 2) -- Questie calls once per changed objective
M.check(#M.sounds == 1 and M.sounds[1][1] == 558132, "Job's done! once")
M.check(M.printed("The Lazy Peons 200 - job's done"), "chat line")
M.check(#M.chat == 0, "no party line unless opted in")
-- turned in then re-done (repeatable)
q(200, nil, 3); M.advance(2); q(200, 1, 2)
M.check(#M.sounds == 2, "repeatable quest speaks again after turn-in")
-- party ping opt-in, 5-player only, lockdown respected, throttled
ns.JD.db.partyPing = true; M.group.inGroup = true
complete[300] = true; M.advance(2); q(300, 1, 2)
M.check(#M.chat == 1 and M.chat[1][2] == "PARTY", "opt-in party line")
complete[301] = true; M.advance(2); q(301, 1, 2)
M.check(#M.chat == 1, "party line throttled to one per 10 s")
M.lockdown = true; complete[302] = true; M.advance(20); q(302, 1, 2); M.lockdown = false
M.check(#M.chat == 1, "no party line during chat lockdown")
M.group.inRaid = true; complete[303] = true; M.advance(20); q(303, 1, 2); M.group.inRaid = false
M.check(#M.chat == 1, "never in raids")
-- Questie's own sound on -> we don't double up
local before = #M.sounds
Questie.db.profile.soundOnQuestComplete = true
complete[400] = true; M.advance(2); q(400, 1, 2)
M.check(#M.sounds == before, "quiet when Questie's own quest sound is on")
Questie.db.profile.soundOnQuestComplete = false
M.slash("/jd", "voice")
M.check(ns.JD.db.voice == "ready" and M.sounds[#M.sounds][1] == 558137, "voice cycles and previews")
-- 1.1.0: never over another of our voice lines
KennyAddonsHub.MarkVoiceBusy(5)
local before = #M.sounds
QuestieJobsDone.Play()
M.check(#M.sounds == before, "waits while another voice line plays")
M.advance(6)
QuestieJobsDone.Play()
M.check(#M.sounds == before + 1, "plays once the line is over")
M.done("QuestieJobsDone")
