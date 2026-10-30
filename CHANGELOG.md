# Changelog

## 1.1.0
- Never plays over another of Kenny's voice addons or a BigWigs countdown.
- The 'Job's done!' sound shared with Wipe & Win Lines appears only once in LibSharedMedia.
- `/jd debug` checks your setup: client version, every game API the addon needs, and which of Kenny's other addons it is working with.
- A loud chat warning if this client is missing an API the addon needs, instead of failing silently.
- English text now lives in `Locales/enUS.lua`, ready for translations.
- Shared code (KennyShared) is identical in every addon of the family and checked in CI, along with every Blizzard API call (against the Forever UI source) and every DBM/BigWigs/Questie API call (against their source).

## 1.0.0 (first release)
- First release. Peon 'Job's done!' (or Peon/Peasant 'Ready to work') when Questie reports a quest's objectives complete, once per quest, via Questie.API.RegisterForQuestUpdates.
- Stays quiet when Questie's own quest-complete sound is on, ignores quests already complete at login, and adds its lines to LibSharedMedia.
- Optional party line (5-player groups, 10 s throttle). Game version: WoW: Forever 1.60.1 (Interface 16001).
