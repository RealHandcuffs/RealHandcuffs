;
; A script handling settings for the mod.
;
Scriptname RealHandcuffs:Settings extends Quest

RealHandcuffs:Library Property Library Auto Const Mandatory
RealHandcuffs:McmInteraction Property McmInteraction Auto Const Mandatory
RealHandcuffs:McmHotkeysQuest Property McmHotkeysQuest Auto Const Mandatory
GlobalVariable Property IsLiteEdition Auto Const Mandatory

;
; The edition, "Standard" or "Lite".
;
String Property Edition
    String Function Get()
        If (IsLiteEdition.GetValueInt() != 0)
            Return "Lite"
        EndIf
        Return "Standard"
    EndFunction
EndProperty

;
; Group for settings that are calculated automatically, often from other settings.
;
Group Derived
    Bool Property UseMCMSettings Auto
    Bool Property AutoConvertHandcuffs
        Bool Function Get()
            Return !Disabled && IsLiteEdition.GetValueInt() == 0
        EndFunction
    EndProperty
    Bool Property IntegrateHandcuffsInVanillaScenes
        Bool Function Get()
            Return !Disabled && AddHandcuffsToVanillaScenes && IsLiteEdition.GetValueInt() == 0
        EndFunction
    EndProperty
    Bool Property SettingsUnlocked Auto
    Bool Property SettingsLocked Auto ; both SettingsUnlocked and SettingsLocked must be auto properties for MCM to work
EndGroup

;
; Group for general settings.
;
Group General
    Bool Property HardcoreMode Auto
EndGroup

;
; Group for settings that control behavior of handcuffs.
;
Group Handcuffs
    Int Property HandcuffsOnBackStruggleChance Auto
    Int Property HandcuffsOnBackReachItemChance Auto
    Int Property HandcuffsOnBackUnlockChance Auto
    Int Property HandcuffsOnBackLockpickingPenality Auto ; number of 25-point steps
    Int Property HandcuffsOnBackPose Auto                ; 0: Real Handcuffs, 1: Torture Devices
    Int Property HingedHandcuffsStrugglePenalty Auto
    Int Property HandcuffsLockLevel Auto                 ; 25, 50, 75, 100
    Int Property HandcuffsLockLevelHighSecurity Auto     ; 25, 50, 75, 100
    Bool Property AutoAssignPrisonerMatUsers Auto
EndGroup

;
; Group for settings that control behavior of shock collars.
;
Group ShockCollars
    Int Property ShockLethality Auto                    ; 0: potentially lethal, 1: only for non-essential actors, 2: always non-lethal
    Int Property PipboyTerminalMode Auto                ; 0: auto-select, 1: open pip-boy directly, 2: use holodisk manually
EndGroup

;
; Group for settings that control integration with vanilla or other mods.
;
Group Integration
    Bool Property AddHandcuffsToVanillaScenes Auto
    Bool Property AddCollarsToJBSlaves Auto
    Float Property ShockCollarJBSubmissionWeight Auto   ; 0.0 to 3.0
    Int Property CastJBMarkSpellOnTaserVictims Auto     ; 0: yes, 1: only when causing exhaustion, 2: no
    Int Property JBEnslaveByEquippingCollar Auto        ; 0: always, 1: ask for confirmation, 2: never
EndGroup

;
; Group for hotkey settings.
; Most hotkeys are managed by MCM directly.
;
Group Hotkey
    Bool Property ShowPoseAction ; property forwarded to McmHotkeysQuest
        Bool Function Get()
            Return McmHotkeysQuest.ShowPoseActivation
        EndFunction
        Function Set(Bool value)
            McmHotkeysQuest.ShowPoseActivation = value
        EndFunction
    EndProperty
    Bool Property EnableQuickInventoryInteraction ; property forwarded to McmHotkeysQuest
        Bool Function Get()
            Return McmHotkeysQuest.EnableQuickInventoryInteraction
        EndFunction
        Function Set(Bool value)
            McmHotkeysQuest.EnableQuickInventoryInteraction = value
        EndFunction
    EndProperty
EndGroup

;
; Group for debug settings.
;
Group Debug
    Bool Property ShowDebugSettings Auto
    Bool Property Disabled Auto
    Int Property LogLevelPapyrus Auto
    Int Property LogLevelNotificationArea Auto
EndGroup

;
; Check if any kind of info logging is enabled, either to papyrus or to notification area.
;
Bool Property InfoLoggingEnabled
    Bool Function Get()
        Return LogLevelPapyrus <= 0 || LogLevelNotificationArea <= 0
    EndFunction
EndProperty

;
; Apply new general settings. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged, the caller has to call FireSettingsChangedEvent if true was returned!
;
Bool Function ApplyGeneralSettings(Bool newHardcoreMode)
    Bool changed = false
    If (SettingsUnlocked && HardcoreMode != newHardcoreMode)
        HardcoreMode = newHardcoreMode
        changed = true
    EndIf
    Bool newSettingsUnlocked = Disabled || !HardcoreMode || Library.GetWornRestraints(Game.GetPlayer()).Length == 0
    If (SettingsUnlocked != newSettingsUnlocked)
        SettingsUnlocked = newSettingsUnlocked
        SettingsLocked = !newSettingsUnlocked
        If (SettingsLocked)
            RealHandcuffs:Log.Info("Hardcore mode enabled, locking settings.", Self)
        Else
            RealHandcuffs:Log.Info("Hardcore mode disabled, unlocking settings.", Self)
            If (SettingsUnlocked && UseMCMSettings)
                StartTimer(0.1, 1) ; load settings from MCM when they get unlocked
            EndIf
        EndIf
    EndIf
    Return changed
EndFunction

;
; Apply new handcuffs settings. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged, the caller has to call FireSettingsChangedEvent if true was returned!
; 
Bool Function ApplyHandcuffsSettings(Int newHandcuffsOnBackStruggleChance, Int newHandcuffsOnBackReachItemChance, Int newHandcuffsOnBackUnlockChance, Int newHandcuffsOnBackLockpickingPenality, Int newHandcuffsOnBackPose, Int newHingedHandcuffsStrugglePenalty, Int newHandcuffsLockLevel, Int newHandcuffsLockLevelHighSecurity, Bool newAutoAssignPrisonerMatUsers)
    Bool changed = false
    If (SettingsUnlocked && HandcuffsOnBackStruggleChance != newHandcuffsOnBackStruggleChance)
        HandcuffsOnBackStruggleChance = newHandcuffsOnBackStruggleChance
        changed = true
    EndIf
    If (SettingsUnlocked && HandcuffsOnBackReachItemChance != newHandcuffsOnBackReachItemChance)
        HandcuffsOnBackReachItemChance = newHandcuffsOnBackReachItemChance
        changed = true
    EndIf
    If (SettingsUnlocked && HandcuffsOnBackUnlockChance != newHandcuffsOnBackUnlockChance)
        HandcuffsOnBackUnlockChance = newHandcuffsOnBackUnlockChance
        changed = true
    EndIf
    If (SettingsUnlocked && HandcuffsOnBackLockpickingPenality != newHandcuffsOnBackLockpickingPenality)
        HandcuffsOnBackLockpickingPenality = newHandcuffsOnBackLockpickingPenality
        changed = true
    EndIf
    If (SettingsUnlocked && newHandcuffsOnBackPose != HandcuffsOnBackPose)
        HandcuffsOnBackPose = newHandcuffsOnBackPose
        changed = true
    EndIf
    If (SettingsUnlocked && newHingedHandcuffsStrugglePenalty != HingedHandcuffsStrugglePenalty)
        HingedHandcuffsStrugglePenalty = newHingedHandcuffsStrugglePenalty
        changed = true
    EndIf
    If (SettingsUnlocked && HandcuffsLockLevel != newHandcuffsLockLevel)
        HandcuffsLockLevel = newHandcuffsLockLevel
        changed = true
    EndIf
    If (SettingsUnlocked && HandcuffsLockLevelHighSecurity != newHandcuffsLockLevelHighSecurity)
        HandcuffsLockLevelHighSecurity = newHandcuffsLockLevelHighSecurity
        changed = true
    EndIf
    If (SettingsUnlocked && AutoAssignPrisonerMatUsers != newAutoAssignPrisonerMatUsers)
        AutoAssignPrisonerMatUsers = newAutoAssignPrisonerMatUsers
        changed = true
    EndIf
    Return changed
EndFunction

;
; Apply new shock collar settings. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged, the caller has to call FireSettingsChangedEvent if true was returned!
; 
Bool Function ApplyShockCollarSettings(Int newShockLethality, Int newPipboyTerminalMode)
    Bool changed = false
    If (SettingsUnlocked && ShockLethality != newShockLethality)
        ShockLethality = newShockLethality
        changed = true
    EndIf
    If (SettingsUnlocked && PipboyTerminalMode != newPipboyTerminalMode)
        PipboyTerminalMode = newPipboyTerminalMode
        changed = true
    EndIf
    Return changed
EndFunction

;
; Apply new integration settings. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged, the caller has to call FireSettingsChangedEvent if true was returned!
; 
Bool Function ApplyIntegrationSettings(Bool newAddHandcuffsToVanillaScenes, Bool newAddCollarsToJBSlaves, Float newShockCollarJBSubmissionWeight, Int newCastJBMarkSpellOnTaserVictims, Int newJBEnslaveByEquippingCollar)
    ; do not test for SettingsUnlocked, these settings can be changed at any time
    Bool changed = false
    If (AddHandcuffsToVanillaScenes != newAddHandcuffsToVanillaScenes)
        AddHandcuffsToVanillaScenes = newAddHandcuffsToVanillaScenes
        changed = true
    EndIf
    If (AddCollarsToJBSlaves != newAddCollarsToJBSlaves)
        AddCollarsToJBSlaves = newAddCollarsToJBSlaves
        changed = true
    EndIf
    If (ShockCollarJBSubmissionWeight != newShockCollarJBSubmissionWeight)
        ShockCollarJBSubmissionWeight = newShockCollarJBSubmissionWeight
        changed = true
    EndIf
    If (CastJBMarkSpellOnTaserVictims != newCastJBMarkSpellOnTaserVictims)
        CastJBMarkSpellOnTaserVictims = newCastJBMarkSpellOnTaserVictims
        changed = true
    EndIf
    If (JBEnslaveByEquippingCollar != newJBEnslaveByEquippingCollar)
        JBEnslaveByEquippingCollar = newJBEnslaveByEquippingCollar
        changed = true
    EndIf
    Return changed
EndFunction

;
; Apply new hotkey settings. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged, the caller has to call FireSettingsChangedEvent if true was returned!
; 
Bool Function ApplyHotkeySettings(Bool newShowPoseAction, bool newEnableQuickInventoryInteraction)
    Bool changed = false
    If (ShowPoseAction != newShowPoseAction)
        ShowPoseAction = newShowPoseAction
        changed = true
    EndIf
    If (EnableQuickInventoryInteraction != newEnableQuickInventoryInteraction)
        EnableQuickInventoryInteraction = newEnableQuickInventoryInteraction
        changed = true
    EndIf
    Return changed
EndFunction

;
; Apply new debug settings. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged, the caller has to call FireSettingsChangedEvent if true was returned!
; 
Bool Function ApplyDebugSettings(Bool newShowDebugSettings, Bool newDisabled, Int newLogLevelPapyrus, Int newLogLevelNotificationArea)
    Bool changed = false
    If (ShowDebugSettings != newShowDebugSettings)
        ShowDebugSettings = newShowDebugSettings
        changed = true
    EndIf
    If (SettingsUnlocked && Disabled != newDisabled)
        Disabled = newDisabled
        changed = true
    EndIf
    If (LogLevelPapyrus != newLogLevelPapyrus)
        LogLevelPapyrus = newLogLevelPapyrus
        changed = true
    EndIf
    If (LogLevelNotificationArea != newLogLevelNotificationArea)
        LogLevelNotificationArea = newLogLevelNotificationArea
        changed = true
    EndIf
    Bool newSettingsUnlocked = Disabled || !HardcoreMode || Library.GetWornRestraints(Game.GetPlayer()).Length == 0
    If (SettingsUnlocked != newSettingsUnlocked)
        SettingsUnlocked = newSettingsUnlocked
        SettingsLocked = !newSettingsUnlocked
        If (SettingsLocked)
            RealHandcuffs:Log.Info("Mod enabled, locking settings.", Self)
        Else
            RealHandcuffs:Log.Info("Mod disabled, unlocking settings.", Self)
            If (SettingsUnlocked && UseMCMSettings)
                StartTimer(0.1, 1) ; load settings from MCM when they get unlocked
            EndIf
        EndIf
    EndIf
    Return changed
EndFunction
    
;
; Set all general settings back to default. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged event, the caller has to call FireSettingsChangedEvent if true was returned!
;
Bool Function RestoreDefaultGeneralSettings()
    Bool defHardcoreMode = false
    Bool changed = ApplyGeneralSettings(defHardcoreMode)
    If (changed)
        RealHandcuffs:Log.Info("Default general settings restored.", Self)
    EndIf
    If (UseMCMSettings && SaveMcmGeneralSettings())
        MCM.RefreshMenu()
    EndIf
    Return changed
EndFunction

;
; Set all handcuffs settings back to default. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged event, the caller has to call FireSettingsChangedEvent if true was returned!
;
Bool Function RestoreDefaultHandcuffsSettings()
    Int defHandcuffsOnBackStruggleChance      = 15
    Int defHandcuffsOnBackReachItemChance     = 25
    Int defHandcuffsOnBackUnlockChance        = 35
    Int defHandcuffsOnBackLockpickingPenality = 50
    Int defHandcuffsOnBackPose                =  0
    Int defHingedHandcuffsStrugglePenalty     = 33
    Int defHandcuffsLockLevel                 = 25
    Int defHandcuffsLockLevelHighSecurity     = 75
    Bool defAutoAssignPrisonerMatUsers        = true
    Bool changed = ApplyHandcuffsSettings(defHandcuffsOnBackStruggleChance, defHandcuffsOnBackReachItemChance, defHandcuffsOnBackUnlockChance, defHandcuffsOnBackLockpickingPenality, defHandcuffsOnBackPose, defHingedHandcuffsStrugglePenalty, defHandcuffsLockLevel, defHandcuffsLockLevelHighSecurity, defAutoAssignPrisonerMatUsers)
    If (changed)
        RealHandcuffs:Log.Info("Default handcuffs settings restored.", Self)
    EndIf
    If (UseMCMSettings && SaveMcmHandcuffsSettings())
        MCM.RefreshMenu()
    EndIf
    Return changed
EndFunction

;
; Set all shock collar settings back to default. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged event, the caller has to call FireSettingsChangedEvent if true was returned!
;
Bool Function RestoreDefaultShockCollarSettings()
    Int defShockLethality = 0
    Int defPipboyTerminalMode = 0
    Bool changed = ApplyShockCollarSettings(defShockLethality, defPipboyTerminalMode)
    If (changed)
        RealHandcuffs:Log.Info("Default shock collar settings restored.", Self)
    EndIf
    If (UseMCMSettings && SaveMcmShockCollarSettings())
        MCM.RefreshMenu()
    EndIf
    Return changed
EndFunction

;
; Set all integration1 settings back to default. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged event, the caller has to call FireSettingsChangedEvent if true was returned!
;
Bool Function RestoreDefaultIntegrationSettings()
    Bool defAddHandcuffsToVanillaScenes = true
    Bool defAddCollarsToJBSlaves = true
    Float defShockCollarJBSubmissionWeight = 1.0
    Int defCastJBMarkSpellOnTaserVictims = 1
    Int defJBEnslaveByEquippingCollar = 1
    Bool changed = ApplyIntegrationSettings(defAddHandcuffsToVanillaScenes, defAddCollarsToJBSlaves, defShockCollarJBSubmissionWeight, defCastJBMarkSpellOnTaserVictims, defJBEnslaveByEquippingCollar)
    If (changed)
        RealHandcuffs:Log.Info("Default integration settings restored.", Self)
    EndIf
    If (UseMCMSettings && SaveMcmIntegrationSettings())
        MCM.RefreshMenu()
    EndIf
    Return changed
EndFunction

;
; Set all hotkey settings back to default. Returns true if any settings have been modified.
;
Bool Function RestoreDefaultHotkeySettings()
    Bool defShowPoseAction = true
    Bool defEnableQuickInventoryInteraction = false
    Bool changed = ApplyHotkeySettings(defShowPoseAction, defEnableQuickInventoryInteraction)
    If (changed)
        RealHandcuffs:Log.Info("Default hotkey settings restored.", Self)
    EndIf
    If (UseMCMSettings && SaveMcmHotkeySettings())
        MCM.RefreshMenu()
    EndIf
    Return changed
EndFunction

;
; Set all debug settings back to default. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged event, the caller has to call FireSettingsChangedEvent if true was returned!
;
Bool Function RestoreDefaultDebugSettings()
    Bool defShowDebugSettings       = false
    Bool defDisabled                = false
    Int defLogLevelPapyrus          = 1 ; 0: info, 1: warning, 2: error
    Int defLogLevelNotificationArea = 1 ; 0: info, 1: warning, 2: error
    Bool changed = ApplyDebugSettings(defShowDebugSettings, defDisabled, defLogLevelPapyrus, defLogLevelNotificationArea)
    If (changed)
        RealHandcuffs:Log.Info("Default debug settings restored.", Self)
    EndIf
    If (UseMCMSettings && SaveMcmDebugSettings())
        MCM.RefreshMenu()
    EndIf
    Return changed
EndFunction

;
; Load all general settings from MCM. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged event, the caller has to call FireSettingsChangedEvent if true was returned!
;
Bool Function LoadMcmGeneralSettings()
    Bool mcmHardcoreMode = MCM.GetModSettingBool("RealHandcuffs", "bHardcoreMode:General")
    If (ApplyGeneralSettings(mcmHardcoreMode))
        RealHandcuffs:Log.Info("General settings changed from MCM.", Self)
        Return true
    EndIf
    Return false
EndFunction

;
; Load all handcuffs settings from MCM. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged event, the caller has to call FireSettingsChangedEvent if true was returned!
;
Bool Function LoadMcmHandcuffsSettings()
    Int mcmHandcuffsOnBackStruggleChance      = MCM.GetModSettingInt("RealHandcuffs", "iStruggleChance:Handcuffs")
    Int mcmHandcuffsOnBackReachItemChance     = MCM.GetModSettingInt("RealHandcuffs", "iReachItemChanceOnBack:Handcuffs")
    Int mcmHandcuffsOnBackUnlockChance        = MCM.GetModSettingInt("RealHandcuffs", "iUnlockChanceOnBack:Handcuffs")
    Int mcmHandcuffsOnBackLockpickingPenality = (MCM.GetModSettingInt("RealHandcuffs", "iLockpickingPenaltyHandsOnBack:Handcuffs") + 1) * 25
    Int mcmHandcuffsOnBackPose                = MCM.GetModSettingInt("RealHandcuffs", "iHandsOnBackPose:Handcuffs")
    Int mcmHingedHandcuffsStrugglePenalty     = MCM.GetModSettingInt("RealHandcuffs", "iHingedHandcuffsStrugglePenalty:Handcuffs")
    Int defHandcuffsLockLevel                 = 25
    Int defHandcuffsLockLevelHighSecurity     = 75
    Bool mcmAutoAssignPrisonerMatUsers        = MCM.GetModSettingBool("RealHandcuffs", "bAutoAssignPrisonerMatUsers:Handcuffs")
    If (ApplyHandcuffsSettings(mcmHandcuffsOnBackStruggleChance, mcmHandcuffsOnBackReachItemChance, mcmHandcuffsOnBackUnlockChance, mcmHandcuffsOnBackLockpickingPenality, mcmHandcuffsOnBackPose, mcmHingedHandcuffsStrugglePenalty, defHandcuffsLockLevel, defHandcuffsLockLevelHighSecurity, mcmAutoAssignPrisonerMatUsers))
        RealHandcuffs:Log.Info("Handcuffs settings changed from MCM.", Self)
        Return true
    EndIf
    Return False
EndFunction

;
; Load all shock collar settings from MCM. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged event, the caller has to call FireSettingsChangedEvent if true was returned!
;
Bool Function LoadMcmShockCollarSettings()
    Int mcmShockLethality = MCM.GetModSettingInt("RealHandcuffs", "iShockLethality:ShockCollars")
    Int mcmPipboyTerminalMode = MCM.GetModSettingInt("RealHandcuffs", "iPipboyTerminalMode:ShockCollars")
    If (ApplyShockCollarSettings(mcmShockLethality, mcmPipboyTerminalMode))
        RealHandcuffs:Log.Info("Shock collar settings changed from MCM.", Self)
        Return true
    EndIf
    Return false
EndFunction

;
; Load all integration settings from MCM. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged event, the caller has to call FireSettingsChangedEvent if true was returned!
;
Bool Function LoadMcmIntegrationSettings()
    Bool mcmAddHandcuffsToVanillaScenes = MCM.GetModSettingBool("RealHandcuffs", "bAddHandcuffsToVanillaScenes:Handcuffs")
    Bool mcmAddCollarsToJBSlaves = MCM.GetModSettingBool("RealHandcuffs", "bAddCollarsToJBSlaves:ShockCollars")
    Float mcmShockCollarJBSubmissionWeight = MCM.GetModSettingFloat("RealHandcuffs", "fShockCollarJBSubmissionWeight:ShockCollars")
    Int mcmCastJBMarkSpellOnTaserVictims = MCM.GetModSettingInt("RealHandcuffs", "iCastJBMarkSpellOnTaserVictims:ShockCollars")
    Int mcmJBEnslaveByEquippingCollar = MCM.GetModSettingInt("RealHandcuffs","iJBEnslaveByEquippingCollar:ShockCollars")
    If (ApplyIntegrationSettings(mcmAddHandcuffsToVanillaScenes, mcmAddCollarsToJBSlaves, mcmShockCollarJBSubmissionWeight, mcmCastJBMarkSpellOnTaserVictims, mcmJBEnslaveByEquippingCollar))
        RealHandcuffs:Log.Info("Integration settings changed from MCM.", Self)
        Return true
    EndIf
    Return false
EndFunction

;
; Load all hotkey settings from MCM. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged event, the caller has to call FireSettingsChangedEvent if true was returned!
;
Bool Function LoadMcmHotkeySettings()
    Bool mcmShowPoseAction = MCM.GetModSettingBool("RealHandcuffs", "bShowPoseAction:Hotkeys")
    Bool mcmEnableQuickInventoryInteraction = MCM.GetModSettingBool("RealHandcuffs", "bEnableQuickInventoryInteraction:Hotkeys")
    If (ApplyHotkeySettings(mcmShowPoseAction, mcmEnableQuickInventoryInteraction))
        RealHandcuffs:Log.Info("Hotkey settings changed from MCM.", Self)
        Return true
    EndIf
    Return false
EndFunction

;
; Load all debug settings from MCM. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged event, the caller has to call FireSettingsChangedEvent if true was returned!
;
Bool Function LoadMcmDebugSettings()
    Bool mcmShowDebugSettings       = MCM.GetModSettingBool("RealHandcuffs", "bShowDebugSettings:Debug")
    Bool mcmDisabled                = MCM.GetModSettingBool("RealHandcuffs", "bDisabled:Debug")
    Int mcmLogLevelPapyrus          = MCM.GetModSettingInt("RealHandcuffs", "iLogLevelPapyrus:Debug")
    Int mcmLogLevelNotificationArea = MCM.GetModSettingInt("RealHandcuffs", "iLogLevelNotificationArea:Debug")
    If (ApplyDebugSettings(mcmShowDebugSettings, mcmDisabled, mcmLogLevelPapyrus, mcmLogLevelNotificationArea))
        RealHandcuffs:Log.Info("Debug settings changed from MCM.", Self)
        Return true
    EndIf
    Return false
EndFunction

;
; Save all debug settings to MCM. Returns true if any MCM settings have been updated.
;
Bool Function SaveMcmGeneralSettings()
    Bool changed = false
    If (SettingsUnlocked && MCM.GetModSettingBool("RealHandcuffs", "bHardcoreMode:General") != HardcoreMode)
        MCM.SetModSettingBool("RealHandcuffs", "bHardcoreMode:General", HardcoreMode)
        changed = true
    EndIf
    Return changed
EndFunction

;
; Save all handcuffs settings to MCM. Returns true if any MCM settings have been updated.
;
Bool Function SaveMcmHandcuffsSettings()
    Bool changed = false
    If (SettingsUnlocked && MCM.GetModSettingInt("RealHandcuffs", "iStruggleChance:Handcuffs") != HandcuffsOnBackStruggleChance)
        MCM.SetModSettingInt("RealHandcuffs", "iStruggleChance:Handcuffs", HandcuffsOnBackStruggleChance)
        changed = true
    EndIf
    If (SettingsUnlocked && MCM.GetModSettingInt("RealHandcuffs", "iReachItemChanceOnBack:Handcuffs") != HandcuffsOnBackReachItemChance)
        MCM.SetModSettingInt("RealHandcuffs", "iReachItemChanceOnBack:Handcuffs", HandcuffsOnBackReachItemChance)
        changed = true
    EndIf
    If (SettingsUnlocked && MCM.GetModSettingInt("RealHandcuffs", "iUnlockChanceOnBack:Handcuffs") != HandcuffsOnBackUnlockChance)
        MCM.SetModSettingInt("RealHandcuffs", "iUnlockChanceOnBack:Handcuffs", HandcuffsOnBackUnlockChance)
        changed = true
    EndIf
    Int lockpickinPenaltyHandsOnBackMcmValue = (HandcuffsOnBackLockpickingPenality / 25) - 1
    If (SettingsUnlocked && MCM.GetModSettingInt("RealHandcuffs", "iLockpickingPenaltyHandsOnBack:Handcuffs")!= lockpickinPenaltyHandsOnBackMcmValue)
        MCM.SetModSettingInt("RealHandcuffs", "iLockpickingPenaltyHandsOnBack:Handcuffs", lockpickinPenaltyHandsOnBackMcmValue)
        changed = true
    EndIf
    If (SettingsUnlocked && MCM.GetModSettingInt("RealHandcuffs", "iHandsOnBackPose:Handcuffs") != HandcuffsOnBackPose)
        MCM.SetModSettingInt("RealHandcuffs", "iHandsOnBackPose:Handcuffs", HandcuffsOnBackPose)
        changed = true
    EndIf
    If (SettingsUnlocked && MCM.GetModSettingInt("RealHandcuffs", "iHingedHandcuffsStrugglePenalty:Handcuffs") != HingedHandcuffsStrugglePenalty)
        MCM.SetModSettingInt("RealHandcuffs", "iHingedHandcuffsStrugglePenalty:Handcuffs", HingedHandcuffsStrugglePenalty)
        changed = true
    EndIf
    If (SettingsUnlocked && MCM.GetModSettingBool("RealHandcuffs", "bAutoAssignPrisonerMatUsers:Handcuffs") != AutoAssignPrisonerMatUsers)
        MCM.SetModSettingBool("RealHandcuffs", "bAutoAssignPrisonerMatUsers:Handcuffs", AutoAssignPrisonerMatUsers)
        changed = true
    EndIf
    Return changed
EndFunction

;
; Save all shock collar settings to MCM. Returns true if any MCM settings have been updated.
;
Bool Function SaveMcmShockCollarSettings()
    Bool changed = false
    If (SettingsUnlocked && MCM.GetModSettingBool("RealHandcuffs", "iShockLethality:ShockCollars") != ShockLethality)
        MCM.SetModSettingInt("RealHandcuffs", "iShockLethality:ShockCollars", ShockLethality)
        changed = true
    EndIf
    If (SettingsUnlocked && MCM.GetModSettingInt("RealHandcuffs", "iPipboyTerminalMode:ShockCollars") != PipboyTerminalMode)
        MCM.SetModSettingInt("RealHandcuffs", "iPipboyTerminalMode:ShockCollars", PipboyTerminalMode)
        changed = true
    EndIf
    Return changed
EndFunction

;
; Save all integration settings to MCM. Returns true if any MCM settings have been updated.
;
Bool Function SaveMcmIntegrationSettings()
    ; do not test for SettingsUnlocked, these settings can be changed at any time
    Bool changed = false
    If (MCM.GetModSettingBool("RealHandcuffs", "bAddHandcuffsToVanillaScenes:Handcuffs") != AddHandcuffsToVanillaScenes)
        MCM.SetModSettingBool("RealHandcuffs", "bAddHandcuffsToVanillaScenes:Handcuffs", AddHandcuffsToVanillaScenes)
        changed = true
    EndIf
    If (MCM.GetModSettingBool("RealHandcuffs", "bAddCollarsToJBSlaves:ShockCollars") != AddCollarsToJBSlaves)
        MCM.SetModSettingBool("RealHandcuffs", "bAddCollarsToJBSlaves:ShockCollars", AddCollarsToJBSlaves)
        changed = true
    EndIf
    If (MCM.GetModSettingFloat("RealHandcuffs", "fShockCollarJBSubmissionWeight:ShockCollars") != ShockCollarJBSubmissionWeight)
        MCM.SetModSettingFloat("RealHandcuffs", "fShockCollarJBSubmissionWeight:ShockCollars", ShockCollarJBSubmissionWeight)
        changed = true
    EndIf
    If (MCM.GetModSettingInt("RealHandcuffs", "iCastJBMarkSpellOnTaserVictims:ShockCollars") != CastJBMarkSpellOnTaserVictims)
        MCM.SetModSettingInt("RealHandcuffs", "iCastJBMarkSpellOnTaserVictims:ShockCollars", CastJBMarkSpellOnTaserVictims)
        changed = true
    EndIf
    If (MCM.GetModSettingInt("RealHandcuffs", "iJBEnslaveByEquippingCollar:ShockCollars") != JBEnslaveByEquippingCollar)
        MCM.SetModSettingInt("RealHandcuffs", "iJBEnslaveByEquippingCollar:ShockCollars", JBEnslaveByEquippingCollar)
        changed = true
    EndIf
    Return changed
EndFunction
    
;
; Save all hotkey settings to MCM. Returns true if any MCM settings have been updated.
;
Bool Function SaveMcmHotkeySettings()
    Bool changed = false
    If (MCM.GetModSettingBool("RealHandcuffs", "bShowPoseAction:Hotkeys") != ShowPoseAction)
        MCM.SetModSettingBool("RealHandcuffs", "bShowPoseAction:Hotkeys", ShowPoseAction)
        changed = true
    EndIf
    If (MCM.GetModSettingBool("RealHandcuffs", "bEnableQuickInventoryInteraction:Hotkeys") != EnableQuickInventoryInteraction)
        MCM.SetModSettingBool("RealHandcuffs", "bEnableQuickInventoryInteraction:Hotkeys", EnableQuickInventoryInteraction)
        changed = true
    EndIf
    Return changed
EndFunction

;
; Save all debug settings to MCM. Returns true if any MCM settings have been updated.
;
Bool Function SaveMcmDebugSettings()
    Bool changed = false
    If (MCM.GetModSettingBool("RealHandcuffs", "bShowDebugSettings:Debug") !=  ShowDebugSettings)
        MCM.SetModSettingBool("RealHandcuffs", "bShowDebugSettings:Debug", ShowDebugSettings)
        changed = true
    EndIf
    If (SettingsUnlocked && MCM.GetModSettingBool("RealHandcuffs", "bDisabled:Debug") != Disabled)
        MCM.SetModSettingBool("RealHandcuffs", "bDisabled:Debug", Disabled)
        changed = true
    EndIf
    If (MCM.GetModSettingInt("RealHandcuffs", "iLogLevelPapyrus:Debug") != LogLevelPapyrus)
        MCM.SetModSettingInt("RealHandcuffs", "iLogLevelPapyrus:Debug", LogLevelPapyrus)
        changed = true
    EndIf
    If (MCM.GetModSettingInt("RealHandcuffs", "iLogLevelNotificationArea:Debug") != LogLevelNotificationArea)
        MCM.SetModSettingInt("RealHandcuffs", "iLogLevelNotificationArea:Debug", LogLevelNotificationArea)
        changed = true
    EndIf
    Return changed
EndFunction

;
; Set all settings back to default. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged event, the caller has to call FireSettingsChangedEvent if true was returned!
;
Bool Function RestoreDefaultSettings()
    RealHandcuffs:Log.Info("Restoring default settings.", Self)
    Bool settingsChanged = RestoreDefaultDebugSettings() ; restore debug settings before all other settings because of log settings
    If (RestoreDefaultHandcuffsSettings())
        settingsChanged = true
    EndIf
    If (RestoreDefaultShockCollarSettings())
        settingsChanged = true
    EndIf
    If (RestoreDefaultIntegrationSettings())
        settingsChanged = true
    EndIf
    If (RestoreDefaultHotkeySettings())
        settingsChanged = true
    EndIf
    If (RestoreDefaultGeneralSettings()) ; restore general settings after all other settings because of hardcore mode setting
        settingsChanged = true
    EndIf
    Return settingsChanged
EndFunction

;
; Load all settings from MCM. Returns true if any settings have been modified.
; This will not fire OnSettingsChanged event, the caller has to call FireSettingsChangedEvent if true was returned!
;
Bool Function LoadMcmSettings()
    RealHandcuffs:Log.Info("Loading MCM settings.", Self)
    Bool settingsChanged = LoadMcmDebugSettings() ; load debug settings before all other settings because of log settings
    If (LoadMcmHandcuffsSettings())
        settingsChanged = true
    EndIf
    If (LoadMcmShockCollarSettings())
        settingsChanged = true
    EndIf
    If (LoadMcmIntegrationSettings())
        settingsChanged = true
    EndIf
    If (LoadMcmHotkeySettings())
        settingsChanged = true
    EndIf
    If (LoadMcmGeneralSettings()) ; load general settings after all other settings because of hardcore mode setting
        settingsChanged = true
    EndIf
    Return settingsChanged
EndFunction

;
; Refresh all settings after loading the game and fire OnSettingsChanged if something changed.
;
Function Refresh()
    If (SettingsUnlocked == SettingsLocked) ; true directly after starting the game
        SettingsUnlocked = !SettingsLocked
    EndIf
    RegisterForCustomEvent(Library, "OnRestraintApplied")    
    RegisterForCustomEvent(Library, "OnRestraintUnapplied")    
    UnregisterForExternalEvent("OnMCMSettingChange|RealHandcuffs")
    McmInteraction.UnregisterForMcmEvents()
    If (MCM.IsInstalled() && MCM.GetVersionCode() >= 6)
        RealHandcuffs:Log.Info("Using MCM for settings.", Self)
        UseMCMSettings = true
        RegisterForExternalEvent("OnMCMSettingChange|RealHandcuffs", "OnMCMSettingChange")
        McmInteraction.RegisterForMcmEvents()
        If (LoadMcmSettings())
            FireSettingsChangedEvent()
        EndIf
    Else
        RealHandcuffs:Log.Info("MCM not installed or too old, using default settings.", Self)
        UseMCMSettings = false
        If (RestoreDefaultSettings())
            FireSettingsChangedEvent()
        EndIf
    EndIf
EndFunction

;
; Handler called when restraints are applied.
;
Event RealHandcuffs:Library.OnRestraintApplied(Library akSender, Var[] akArgs)
    Actor player = Game.GetPlayer()
    If ((akArgs[0] as Actor) == player)
        OnPlayerRestraintsChanged(Library.GetWornRestraints(player))
    EndIf
EndEvent
 
;
; Handler called when restraints are unapplied.
;
Event RealHandcuffs:Library.OnRestraintUnapplied(Library akSender, Var[] akArgs)
    Actor player = Game.GetPlayer()
    If ((akArgs[0] as Actor) == Game.GetPlayer())
        OnPlayerRestraintsChanged(Library.GetWornRestraints(player))
    EndIf
EndEvent

;
; Handler called when player restraints change.
;
Function OnPlayerRestraintsChanged(RealHandcuffs:RestraintBase[] restraints)
    Bool newSettingsUnlocked = Disabled || !HardcoreMode || restraints.Length == 0
    If (SettingsUnlocked != newSettingsUnlocked)
        SettingsUnlocked = newSettingsUnlocked
        SettingsLocked = !newSettingsUnlocked
        If (SettingsLocked)
            RealHandcuffs:Log.Info("Player restrained, locking settings.", Self)
        Else
            RealHandcuffs:Log.Info("Player no longer restrained, unlocking settings.", Self)
            If (SettingsUnlocked && UseMCMSettings)
                StartTimer(0.1, 1) ; load settings from MCM when they get unlocked
            EndIf
        EndIf
    EndIf
EndFunction

;
; Event called by MCM when settings change.
;
Function OnMCMSettingChange(string modName, string id)
    If (modName == "RealHandcuffs")
        CancelTimer(1) ; may do nothing but that is fine
        StartTimer(0.1, 1)
    EndIf
EndFunction

;
; Timer event.
;
Event OnTimer(Int aiTimerID)
    If (aiTimerID == 1)
        ; One or multiple MCM settings changed, load the settings.
        If (LoadMcmSettings())
            FireSettingsChangedEvent()
        EndIf
    EndIf
EndEvent

;
; Fire OnSettingsChanged.
;
Function FireSettingsChangedEvent()
    Var[] kargs = new Var[0]
    SendCustomEvent("OnSettingsChanged", kargs)
EndFunction

;
; A event that is fired after any settings have changed.
;
CustomEvent OnSettingsChanged