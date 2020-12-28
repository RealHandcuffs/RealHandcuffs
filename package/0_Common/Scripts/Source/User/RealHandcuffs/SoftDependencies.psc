;
; Script to handle soft dependencies.
;
Scriptname RealHandcuffs:SoftDependencies extends Quest

RealHandcuffs:Library Property Library Auto Const Mandatory
RefCollectionAlias Property KnockoutActors Auto Const Mandatory
FormList Property BoundHandsGenericFurnitureList Auto Const Mandatory
ActorValue Property Paralysis Auto Const Mandatory
Keyword Property ActorTypeChild Auto Const Mandatory
Keyword Property ActorTypeNPC Auto Const Mandatory
Keyword Property ActorTypeRobot Auto Const Mandatory
Keyword Property ActorTypeSuperMutant Auto Const Mandatory
Keyword Property ActorTypeSynth Auto Const Mandatory
Keyword Property VanillaShockCollarTriggering Auto Const Mandatory
Sound Property MineTickLoop Auto Const Mandatory

;
; Group for names of soft dependency plugins.
;
Group Plugins
    String Property DLCNukaWorld               = "DLCNukaWorld.esm" AutoReadOnly
    String Property DLCworkshop01              = "DLCworkshop01.esm" AutoReadOnly
    String Property DLCworkshop02              = "DLCworkshop02.esm" AutoReadOnly
    String Property DLCworkshop03              = "DLCworkshop03.esm" AutoReadOnly
    String Property TortureDevices             = "TortureDevices.esm" AutoReadOnly
    String Property DeviousDevices             = "Devious Devices.esm" AutoReadOnly
    String Property JustBusiness               = "Just Business.esp" AutoReadOnly
    String Property KnockoutFramework          = "Knockout Framework.esm" AutoReadOnly
    String Property AdvancedAnimationFramework = "AAF.esm" AutoReadOnly
    String Property SSConqueror                = "SimSettlements_XPAC_Conqueror.esp" AutoReadOnly
    String Property CanarySaveFileMonitor      = "CanarySaveFileMonitor.esl" AutoReadOnly
    String Property WorkshopFramework          = "WorkshopFramework.esm" AutoReadOnly
    String Property PipPad                     = "PIP-Pad.esp" AutoReadOnly
    String Property CrimeAndPunishment         = "Flashy_CrimeAndPunishment.esp" AutoReadOnly
EndGroup

;
; Group for bools set to true if soft dependency plugin is available.
;
Group AvailablePlugins
    Bool Property DLCNukaWorldAvailable Auto
    Bool Property DLCworkshop01Available Auto
    Bool Property DLCworkshop02Available Auto
    Bool Property DLCworkshop03Available Auto
    Bool Property TortureDevicesAvailable Auto
    Bool Property DeviousDevicesAvailable Auto
    Bool Property JustBusinessAvailable Auto
    Bool Property KnockoutFrameworkAvailable Auto
    Bool Property AdvancedAnimationFrameworkAvailable Auto
    Bool Property SSConquerorAvailable Auto
    Bool Property WorkshopFrameworkAvailable Auto
    Bool Property PipPadAvailable Auto
    Bool Property CrimeAndPunishmentAvailable Auto
EndGroup

;
; Group for names of compatibility plugins.
;
Group CompatibilityPlugins
   String Property RealHandcuffsAWKCRCompatibility       = "RealHandcuffs_AWKCR_Compatibility.esp" AutoReadOnly
   String Property RealHandcuffsDDCompatibility          = "RealHandcuffs_DD_Compatibility.esp" AutoReadOnly
   String Property RealHandcuffsDDServitronCompatibility = "RealHandcuffs_DD_Servitron_Compatibility.esp" AutoReadOnly
   String Property RealHandcuffsJBCompatibility          = "RealHandcuffs_JB_Compatibility.esp" AutoReadOnly
   String Property RealHandcuffsServitronCompatibility   = "RealHandcuffs_Servitron_Compatibility.esp" AutoReadOnly
   String Property RealHandcuffsSSConquerorCompatibility = "RealHandcuffs_SS_CQ_Compatibility.esp" AutoReadOnly
EndGroup

;
; Group for bools set to true if compatibility plugins are active.
;
Group ActiveCompatibilityPlugins
    Bool Property DDCompatibilityActive Auto
    Bool Property JBCompatibilityActive Auto
    Bool Property ServitronCompatibilityActive Auto
    Bool Property SSConquerorCompatibilityActive Auto
EndGroup

;
; Group for forms of compatibility plugins
;
Group CompatibilityPluginForms
    Bool Property DDCompatibilityUseDDSlots Auto
    Topic Property DDCompatibilityFemaleGaggedPain Auto
    Topic Property DDCompatibilityFemaleGaggedExhausted Auto
    Quest Property JBCompatibilityMainQuest Auto
EndGroup

;
; A flag that is true while the soft dependencies are being loaded
;
Bool Property SoftDependenciesLoading Auto

;
; Forms used from Nuka-World
;
Group NukaWorld
    Armor Property ShockCollar Auto
    FormList Property DLC04VoicesDialogueRaider Auto
    Topic Property DLC04GenericHitGroup Auto
    Topic Property DLC04GenericDeathGroup Auto
    Topic Property DLC04GenericBleedoutGroup Auto
    FormList Property DLC04SettlementNPCVoices Auto
    Topic Property DLC04SettlementDeathGroup Auto
EndGroup

;
; Forms used from Contraptions Workshop
;
Group DLCworkshop02
    Race Property DLC05ArmorRackRace Auto
EndGroup

;
; Forms used from Devious Devices
;
Group DeviousDevices
    Keyword Property DD_kw_ItemType_WristCuffs Auto
    Keyword Property DD_kw_ItemSubType_Straitjacket Auto
    Keyword Property DD_kw_ItemType_Gag Auto
EndGroup

;
; Forms used from Just Business
;
Group JustBusiness
    Quest Property JBSlaveQuest Auto
    Faction Property JBSlaveFaction Auto
    Faction Property JBEscapeSlaveFaction Auto
    MagicEffect Property JBMarkEffect Auto
    Spell Property JBMarkSpell Auto
    ActorValue Property JBIsSubmissive Auto
EndGroup

;
; Forms used from Knockout Framework
;
Group KnockoutFramework
    ScriptObject Property KnockoutFrameworkManagerQuestMainScript Auto
    Keyword Property KFKnockedOutKeyword Auto
    Keyword Property KFActorCantBeKnockedOutKeyword Auto
    Perk Property KFIncomingMonitoringPerk Auto
EndGroup

;
; Forms used from Advanced Animation Framework
;
Group AdvancedAnimationFramework
    Keyword Property AAF_ActorBusy Auto
    ActorBase Property AAF_Doppelganger Auto
EndGroup

;
; Forms used from Sim Settlements Conqueror
;
Group SSConqueror
    FormList Property kgConq_RaiderGangVoiceList Auto
    Topic Property kgConq_Dialogue_Raiders_Hit Auto
    Topic Property kgConq_Dialogue_Raiders_Death Auto
    Topic Property kgConq_Dialogue_Raiders_Bleedout Auto
EndGroup

;
; Property used by Canary Save File Monitor
;
Group CanarySaveFileMonitor
    Int Property iSaveFileMonitor Auto Hidden ; Do not mess with ever - this is used by Canary to track data loss
EndGroup

;
; Forms used from Workshop Framework
;
Group WorkshopFramework
    GlobalVariable Property WSFW_AlternateActivation_Workshop Auto
EndGroup

;
; Forms used from Crime And Punishment
;
Group CrimeAndPunishment
    Keyword Property RSEII_SurrenderToPlayer Auto
    Keyword Property RSEII_PrisonerSettler Auto
    Keyword Property RSEII_EscapedPrisoner Auto
EndGroup

;
; Refresh the third party dependencies when the game is loaded.
;
Function RefreshOnGameLoad()
    DLCNukaWorldAvailable = GetDLCNukaWorldForms()
    If (DLCNukaWorldAvailable)
        AddToBoundHandsGenericFurnitureList(0x015AA0, DLCNukaWorld)  ; Nuka-World Radio Transmitter
    EndIf
    DLCworkshop01Available = AddToBoundHandsGenericFurnitureList(0x000C03, DLCworkshop01) ; Decontamination Arch
    DLCworkshop02Available = GetDLCworkshop02Forms()
    DLCworkshop03Available = AddToBoundHandsGenericFurnitureList(0x0042B7, DLCworkshop03) ; Vault 88 Radio Beacon
    TortureDevicesAvailable = Game.IsPluginInstalled(TortureDevices)
    DeviousDevicesAvailable = GetDeviousDevicesForms()
    JustBusinessAvailable = GetJustBusinessForms()
    KnockoutFrameworkAvailable = GetKnockoutFrameworkForms()
    AdvancedAnimationFrameworkAvailable = GetAdvancedAnimationFrameworkForms()
    SSConquerorAvailable = GetSSConquerorForms()
    Bool CanarySaveFileMonitorAvailable = CheckForCanary()
    WorkshopFrameworkAvailable = GetWorkshopFrameworkForms()
    CrimeAndPunishmentAvailable = GetCrimeAndPunishmentForms()
    PipPadAvailable = GetPipPadForms()
    SoftDependenciesLoading = false
    If (Library.Settings.InfoLoggingEnabled)
       String list = ""
        If (DLCNukaWorldAvailable)
            list = AddToList(list, DLCNukaWorld)
        EndIf
        If (DLCworkshop01Available)
            list = AddToList(list, DLCworkshop01)
        EndIf
        If (DLCworkshop02Available)
            list = AddToList(list, DLCworkshop02)
        EndIf
        If (DLCworkshop03Available)
            list = AddToList(list, DLCworkshop03)
        EndIf
        If (TortureDevicesAvailable)
            list = AddToList(list, TortureDevices)
        EndIf
        If (DeviousDevicesAvailable)
            list = AddToList(list, DeviousDevices)
        EndIf
        If (JustBusinessAvailable)
            list = AddToList(list, JustBusiness)
        EndIf
        If (KnockoutFrameworkAvailable)
            list = AddToList(list, KnockoutFramework)
        EndIf
        If (AdvancedAnimationFrameworkAvailable)
            list = AddToList(list, AdvancedAnimationFramework)
        EndIf
        If (SSConquerorAvailable)
            list = AddToList(list, SSConqueror)
        EndIf
        If (CanarySaveFileMonitorAvailable)
            list = AddToList(list, CanarySaveFileMonitor)
        EndIf
        If (WorkshopFrameworkAvailable)
            list = AddToList(list, WorkshopFramework)
        EndIf
        If (PipPadAvailable)
            list = AddToList(list, PipPad)
        EndIf
        If (CrimeAndPunishmentAvailable)
            list = AddToList(list, CrimeAndPunishment)
        EndIf
        RealHandcuffs:Log.Info("Available soft dependencies: " + list, Library.Settings)
    EndIf
    Bool awkcrPluginActive = Game.IsPluginInstalled(RealHandcuffsAWKCRCompatibility)
    Bool ddPluginActive = Game.IsPluginInstalled(RealHandcuffsDDCompatibility)
    Bool ddServitronPluginActive = Game.IsPluginInstalled(RealHandcuffsDDServitronCompatibility)
    Bool jbPluginActive = Game.IsPluginInstalled(RealHandcuffsJBCompatibility)
    Bool servitronPluginActive = Game.IsPluginInstalled(RealHandcuffsServitronCompatibility)
    Bool ssConquerorCompatibilityPluginActive = Game.IsPluginInstalled(RealHandcuffsSSConquerorCompatibility)
    DDCompatibilityActive = ddPluginActive || ddServitronPluginActive
    If (ddPluginActive)
        DDCompatibilityUseDDSlots = (Game.GetFormFromFile(0x000809, RealHandcuffsDDCompatibility) as GlobalVariable).GetValueInt() != 1
        DDCompatibilityFemaleGaggedPain = Game.GetFormFromFile(0x000804, RealHandcuffsDDCompatibility) as Topic
        DDCompatibilityFemaleGaggedExhausted = Game.GetFormFromFile(0x000806, RealHandcuffsDDCompatibility) as Topic
    ElseIf (ddServitronPluginActive)
        DDCompatibilityUseDDSlots = (Game.GetFormFromFile(0x000809, RealHandcuffsDDServitronCompatibility) as GlobalVariable).GetValueInt() != 1
        DDCompatibilityFemaleGaggedPain = Game.GetFormFromFile(0x000804, RealHandcuffsDDServitronCompatibility) as Topic
        DDCompatibilityFemaleGaggedExhausted = Game.GetFormFromFile(0x000806, RealHandcuffsDDServitronCompatibility) as Topic
    Else
        DDCompatibilityUseDDSlots = false
        DDCompatibilityFemaleGaggedPain = None
        DDCompatibilityFemaleGaggedExhausted = None
    EndIf
    JBCompatibilityActive = jbPluginActive
    If (jbPluginActive)
        JBCompatibilityMainQuest = Game.GetFormFromFile(0x00080D, RealHandcuffsJBCompatibility) as Quest
    Else
        JBCompatibilityMainQuest = None
    EndIf
    ServitronCompatibilityActive = servitronPluginActive || ddServitronPluginActive
    SSConquerorCompatibilityActive = ssConquerorCompatibilityPluginActive
    If (Library.Settings.InfoLoggingEnabled)
        String list = ""
        If (awkcrPluginActive)
            list = AddToList(list, RealHandcuffsAWKCRCompatibility)
        EndIf
        If (ddPluginActive)
            list = AddToList(list, RealHandcuffsDDCompatibility)
        EndIf
        If (ddServitronPluginActive)
            list = AddToList(list, RealHandcuffsDDServitronCompatibility)
        EndIf
        If (jbPluginActive)
            list = AddToList(list, RealHandcuffsJBCompatibility)
        EndIf
        If (servitronPluginActive)
            list = AddToList(list, RealHandcuffsServitronCompatibility)
        EndIf
        If (SSConquerorCompatibilityPluginActive)
            list = AddToList(list, RealHandcuffsSSConquerorCompatibility)
        EndIf
        RealHandcuffs:Log.Info("Loaded compatibility plugins: " + list, Library.Settings)
    EndIf
EndFunction

;
; Add a form to the list of 'generic furniture' that can be used with bound hands.
;
Bool Function AddToBoundHandsGenericFurnitureList(int aiFormID, string asFilename)
    Form formToAdd = Game.GetFormFromFile(aiFormID, asFilename)
    If (formToAdd == None)
        Return false
    ElseIf (!BoundHandsGenericFurnitureList.HasForm(formToAdd))
        BoundHandsGenericFurnitureList.AddForm(formToAdd)
    EndIf
    Return true
EndFunction

;
; Get the forms used from Nuka-World
;
Bool Function GetDLCNukaWorldForms()
    ShockCollar = Game.GetFormFromFile(0x029AFA, DLCNukaWorld) as Armor
    If (ShockCollar == None)
        DLC04VoicesDialogueRaider = None
        DLC04GenericHitGroup = None
        DLC04GenericDeathGroup = None
        DLC04GenericBleedoutGroup = None
        Return false
    EndIf
    DLC04VoicesDialogueRaider = Game.GetFormFromFile(0x009697, DLCNukaWorld) as FormList
    DLC04GenericHitGroup = Game.GetFormFromFile(0x009699, DLCNukaWorld) as Topic
    DLC04GenericDeathGroup = Game.GetFormFromFile(0x00969b, DLCNukaWorld) as Topic
    DLC04GenericBleedoutGroup = Game.GetFormFromFile(0x009636, DLCNukaWorld) as Topic
    DLC04SettlementNPCVoices = Game.GetFormFromFile(0x028837, DLCNukaWorld) as FormList
    DLC04SettlementDeathGroup = Game.GetFormFromFile(0x028821, DLCNukaWorld) as Topic
    Return DLC04VoicesDialogueRaider != None && DLC04GenericHitGroup != None && DLC04GenericDeathGroup != None && DLC04GenericBleedoutGroup != None && DLC04SettlementNPCVoices != None && DLC04SettlementDeathGroup != None
EndFunction

;
; Get the forms used from Contraptions Workshop
;
Bool Function GetDLCworkshop02Forms()
    DLC05ArmorRackRace = Game.GetFormFromFile(0x0008AB, DLCworkshop02) as Race
    If (DLC05ArmorRackRace == None)
        Return false
    EndIf
    Return AddToBoundHandsGenericFurnitureList(0x000B39, DLCworkshop02) ; Conduit Switch
EndFunction

;
; Get the forms used from Devious Devices
;
Bool Function GetDeviousDevicesForms()
    DD_kw_ItemType_WristCuffs = Game.GetFormFromFile(0x01196C, DeviousDevices) as Keyword
    If (DD_kw_ItemType_WristCuffs == None)
        DD_kw_ItemSubType_Straitjacket = None
        DD_kw_ItemType_Gag = None
        Return false
    EndIf
    DD_kw_ItemSubType_Straitjacket = Game.GetFormFromFile(0x051BCF, DeviousDevices) as Keyword
    DD_kw_ItemType_Gag = Game.GetFormFromFile(0x015DE9, DeviousDevices) as Keyword
    Return DD_kw_ItemSubType_Straitjacket != None && DD_kw_ItemType_Gag != None
EndFunction

;
; Get the forms used from Just Business
;
Bool Function GetJustBusinessForms()
    JBSlaveQuest = Game.GetFormFromFile(0x0150D9, JustBusiness) as Quest
    If (JBSlaveQuest == None)
        JBSlaveFaction = None
        JBEscapeSlaveFaction = None
        JBMarkEffect = None
        JBMarkSpell = None
        JBIsSubmissive = None
        Return false
    EndIf
    JBSlaveFaction = Game.GetFormFromFile(0x018357, JustBusiness) as Faction
    JBEscapeSlaveFaction = Game.GetFormFromFile(0x03F961, JustBusiness) as Faction
    JBMarkEffect = Game.GetFormFromFile(0x00dd2f, JustBusiness) as MagicEffect
    JBMarkSpell = Game.GetFormFromFile(0x00e4ca, JustBusiness) as Spell
    JBIsSubmissive = Game.GetFormFromFile(0x03D7C6, JustBusiness) as ActorValue
    Return JBSlaveFaction != None && JBEscapeSlaveFaction != None && JBMarkEffect != None && JBMarkSpell != None && JBIsSubmissive != None
EndFunction

;
; Get the forms used from Knockout Framework
;
Bool Function GetKnockoutFrameworkForms()
    Quest knockoutFrameworkMainQuest = Game.GetFormFromFile(0x000F99, KnockoutFramework) as Quest
    If (knockoutFrameworkMainQuest == None)
        KnockoutFrameworkManagerQuestMainScript = None
        KFKnockedOutKeyword = None
        KFActorCantBeKnockedOutKeyword = None
        KFIncomingMonitoringPerk = None
        Return false
    EndIf
    KnockoutFrameworkManagerQuestMainScript = knockoutFrameworkMainQuest.CastAs("KFManagerQuestMainScript")
    KFKnockedOutKeyword = Game.GetFormFromFile(0x001ED5, KnockoutFramework) as Keyword
    KFActorCantBeKnockedOutKeyword = Game.GetFormFromFile(0x00AF8B, KnockoutFramework) as Keyword
    KFIncomingMonitoringPerk = Game.GetFormFromFile(0x000F9B, KnockoutFramework) as Perk
    Return KnockoutFrameworkManagerQuestMainScript != None && KFKnockedOutKeyword != None && KFActorCantBeKnockedOutKeyword != None && KFIncomingMonitoringPerk != None
EndFunction

;
; Get the forms used from Advanced Animation Framework
;
Bool Function GetAdvancedAnimationFrameworkForms()
    Quest aafMainQuest = Game.GetFormFromFile(0x000F99, AdvancedAnimationFramework) as Quest
    If (aafMainQuest == None)
        AAF_ActorBusy = None
        AAF_Doppelganger = None
        Return False
    EndIf
    ScriptObject aafApi = aafMainQuest.CastAs("AAF:AAF_API")
    AAF_ActorBusy = aafApi.GetPropertyValue("AAF_ActorBusy") as Keyword
    ScriptObject aafMainQuestScript = aafMainQuest.CastAs("AAF:AAF_MainQuestScript")
    AAF_Doppelganger = aafMainQuestScript.GetPropertyValue("AAF_Doppelganger") as ActorBase
    Return aafApi != None && AAF_ActorBusy != None && aafMainQuestScript != None && AAF_Doppelganger != None
EndFunction

;
; Get the forms used from Sim Settlements Conqueror
;
Bool Function GetSSConquerorForms()
    kgConq_RaiderGangVoiceList = Game.GetFormFromFile(0x00de11, SSConqueror) as FormList
    If (kgConq_RaiderGangVoiceList == None)
        kgConq_Dialogue_Raiders_Hit = None
        kgConq_Dialogue_Raiders_Death = None
        kgConq_Dialogue_Raiders_Bleedout = None
        Return false
    EndIf
    kgConq_Dialogue_Raiders_Hit = Game.GetFormFromFile(0x00f6d7, SSConqueror) as Topic
    kgConq_Dialogue_Raiders_Death = Game.GetFormFromFile(0x00f6e6, SSConqueror) as Topic
    kgConq_Dialogue_Raiders_Bleedout = Game.GetFormFromFile(0x00f6e8, SSConqueror) as Topic
    Return kgConq_Dialogue_Raiders_Hit != None && kgConq_Dialogue_Raiders_Death != None && kgConq_Dialogue_Raiders_Bleedout != None
EndFunction

;
; Check for save file canary.
;
Bool Function CheckForCanary()
    If (!Game.IsPluginInstalled(CanarySaveFileMonitor))
        Return false
    EndIf
    Var[] kArgs = new Var[2]
    kArgs[0] = Self as Quest
    kArgs[1] = "RealHandcuffs:SoftDependencies" ; must be the same as the script name!
    Utility.CallGlobalFunction("Canary:API", "MonitorForDataLoss", kArgs)
    Return true
EndFunction

;
; Get the forms used from Workshop Framework
;
Bool Function GetWorkshopFrameworkForms()
    WSFW_AlternateActivation_Workshop = Game.GetFormFromFile(0x015132, WorkshopFramework) as GlobalVariable
    Return WSFW_AlternateActivation_Workshop != None
EndFunction

;
; Get the forms used from Crime And Punishment
;
Bool Function GetCrimeAndPunishmentForms()
    RSEII_SurrenderToPlayer = Game.GetFormFromFile(0x00DD5E, CrimeAndPunishment) as Keyword
    If (RSEII_SurrenderToPlayer == None)
        RSEII_PrisonerSettler = None
        Return False
    EndIf
    RSEII_PrisonerSettler = Game.GetFormFromFile(0x02CE47, CrimeAndPunishment) as Keyword
    RSEII_EscapedPrisoner = Game.GetFormFromFile(0x020062, CrimeAndPunishment) as Keyword
    Return RSEII_PrisonerSettler != None && RSEII_EscapedPrisoner != None
EndFunction

;
; Get the forms used from Pip Pad
;
Bool Function GetPipPadForms()
    Return Game.IsPluginInstalled(PipPad)
EndFunction

;
; Add a string to a comma-separated list.
;
String Function AddToList(String list, String item)
    If (list == "")
        Return item
    EndIf
    Return list + ", " + item
EndFunction

;
; Check if an actor is wearing a vanilla shock collar.
;
Bool Function IsWearingVanillaShockCollar(Actor akActor)
    Return ShockCollar != None && akActor.IsEquipped(ShockCollar)
EndFunction

;
; Trigger the vanilla shock collar of an actor.
; This function will take several seconds and block until the whole sequence is over.
; Use IsWearingVanillaShockCollar to check if the actor is wearing a vanilla shock collar before calling it.
;
Function TriggerVanillaShockCollar(Actor akActor)
    If (akActor == None || !akActor.GetParentCell().IsAttached() || akActor.HasKeyword(VanillaShockCollarTriggering))
        Return
    EndIf
    akActor.AddKeyword(VanillaShockCollarTriggering) ; prevent further triggering while this function is running
    akActor.WaitFor3DLoad()
    Int playbackId = MineTickLoop.Play(akActor)
    If (akActor.GetSleepState() != 0 && !akActor.IsInScene())
        ; force temporary wakeup
        Library.StartDummyScene(akActor)
    Else
        ObjectReference currentFurniture = akActor.GetFurnitureReference()
        If (currentFurniture != None)
            WorkshopObjectScript woFurniture = currentFurniture as WorkshopObjectScript
            If (woFurniture == None || !woFurniture.bWork24Hours)
                akActor.PlayIdleAction(Library.Resources.ActionInteractionExitQuick)
            EndIf
        EndIf
    EndIf
    Utility.Wait(0.5) ; beep for half a second
    Sound.StopInstance(playbackId)
    RealHandcuffs:Log.Info("Triggering vanilla shock collar of " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName() + ".", Library.Settings);    
    Library.ZapWithDefaultShock(akActor)
    Utility.Wait(1.0) ; use a dead time of one second after triggering
    akActor.ResetKeyword(VanillaShockCollarTriggering)
EndFunction

;
; Check if an actor is an armor rack instead of a real actor.
;
Bool Function IsArmorRack(Actor akActor)
    Return DLC05ArmorRackRace != None && akActor.GetRace() == DLC05ArmorRackRace
EndFunction

;
; Check if a actor is bound using a devious device.
;
Bool Function IsActorDeviousDevicesBound(Actor target)
    If (DeviousDevicesAvailable)
        If (target.WornHasKeyword(DD_kw_ItemSubType_Straitjacket))
            ; target bound by Devious Devices Straitjacket
            Return true
        EndIf
        If (target.WornHasKeyword(DD_kw_ItemType_WristCuffs))
            ; target bound by either Devious Devices wristcuffs, or wearing Handcuffs with DD compatibility plugin enabled
            If (DDCompatibilityActive)
                RealHandcuffs:RestraintBase[] restraints = Library.GetWornRestraints(target)
                Int index = 0
                While (index < restraints.Length)
                    If (restraints[index].HasKeyword(DD_kw_ItemType_WristCuffs))
                        ; target bound using RealHandcuffs
                        Return false
                    EndIf
                    index += 1
                EndWhile
            EndIf
            ; target bound by Devious Devices wristcuffs
            Return true
        EndIf
    EndIf
    Return False
EndFunction

;
; Check if a actor is gagged using a devious device.
;
Bool Function IsDeviousDevicesGagged(Actor target)
    Return DeviousDevicesAvailable && target.WornHasKeyword(DD_kw_ItemType_Gag)
EndFunction

;
; Check if an actor is in a AAF scene.
;
Bool Function IsInAafScene(Actor target)
    Return AdvancedAnimationFrameworkAvailable && target.HasKeyword(AAF_ActorBusy)
EndFunction

;
; Check if an actor is a Just Business slave.
;
Bool Function IsJBSlave(Actor target)
    Return JustBusinessAvailable && target.IsInFaction(JBSlaveFaction)
EndFunction

;
; Check if an actor is an escaped Just Business slave.
;
Bool Function IsEscapedJBSlave(Actor target)
    Return JustBusinessAvailable && target.IsInFaction(JBEscapeSlaveFaction)
EndFunction

;
; Check if an actor can be enslaved using Just Business functionality.
;
Bool Function CanBeJustBusinessEnslaved(Actor target)
    Return JustBusinessAvailable && (target.HasMagicEffect(JBMarkEffect) || IsValidJBMarkSpellVictim(target))
EndFunction

;
; Enslave an actor using Just Business functionality.
;
Bool Function JustBusinessEnslave(Actor target)
    If (!CanBeJustBusinessEnslaved(target))
        Return False
    EndIf
    If (!target.HasMagicEffect(JBMarkEffect) && !target.IsBleedingOut())
        target.PlayIdleAction(Library.Resources.ActionBleedoutStart) ; send into "bleedout" because the cloning process can take a long time
    EndIf
    Var[] kArgs = new Var[2]
    kArgs[0] = target
    kArgs[1] = false
    JBSlaveQuest.CallFunction("CreateClone", kArgs)
EndFunction

;
; Try to make a slave follow like a follower.
;
Bool Function SlaveFollow(Actor target)
    If (JustBusinessAvailable && target.IsInFaction(JBSlaveFaction))
        ScriptObject jbSlaveNpcScript = target.CastAs("JB:JBSlaveNPCScript")
        If (jbSlaveNpcScript != None)
            jbSlaveNpcScript.CallFunction("SlaveFollow", new Var[0])
            Return true
        EndIf
    EndIf
    Return false
EndFunction

;
; Try to make a slave stop following.
;
Bool Function SlaveRelax(Actor target)
    If (JustBusinessAvailable && target.IsInFaction(JBSlaveFaction))
        ScriptObject jbSlaveNpcScript = target.CastAs("JB:JBSlaveNPCScript")
        If (jbSlaveNpcScript != None)
            jbSlaveNpcScript.CallFunction("SlaveRelax", new Var[0])
            Return true
        EndIf
    EndIf
    Return false
EndFunction

;
; Check if an actor is a valid victim for the JBMarkSpell.
;
Bool Function IsValidJBMarkSpellVictim(Actor target)
    Form actorTypeTarget = target
    If (CrimeAndPunishmentAvailable)
        If (target.HasKeyword(RSEII_PrisonerSettler))
            Return false ; don't convert Crime And Punishment prisoners to Just Business Slaves
        EndIf
        If (target.HasKeyword(RSEII_SurrenderToPlayer))
            actorTypeTarget = target.GetRace() ; Crime And Punishment temporarily clears keywords on surrendered actors, check them on the race instead
        EndIf
    EndIf
    Return JustBusinessAvailable && !target.HasKeyword(VanillaShockCollarTriggering) && target != Game.GetPlayer() && !target.IsDead() && !IsArmorRack(target) && !actorTypeTarget.HasKeyword(ActorTypeRobot) && !actorTypeTarget.HasKeyword(ActorTypeChild) && (actorTypeTarget.HasKeyword(ActorTypeNPC) || actorTypeTarget.HasKeyword(ActorTypeSuperMutant) || actorTypeTarget.HasKeyword(ActorTypeSynth)) && !target.IsInFaction(JBSlaveFaction) && !target.HasMagicEffect(JBMarkEffect)
EndFunction

;
; Increase the JB Submission value of a slave (0 to 100).
;
Bool Function IncrementJBSubmission(Actor target, Float value)
    If (JustBusinessAvailable)
        ScriptObject jbSlaveNpcScript = target.CastAs("JB:JBSlaveNPCScript")
        If (jbSlaveNpcScript != None)
            Var[] kArgs = new Var[2]
            kArgs[0] = JBIsSubmissive
            kArgs[1] = value
            jbSlaveNpcScript.CallFunction("ChangeSlaveSkillValue", kArgs)
            Return true
        EndIf
    EndIf
    Return false
EndFunction

;
; Check if an actor is a Crime And Punishment prisoner.
;
Bool Function IsCAPPrisoner(Actor target)
    Return CrimeAndPunishmentAvailable && target.HasKeyword(RSEII_PrisonerSettler)
EndFunction

;
; Check if an actor is an escaped Crime And Punishment prisoner.
;
Bool Function IsEscapedCAPPrisoner(Actor target)
    Return CrimeAndPunishmentAvailable && target.HasKeyword(RSEII_EscapedPrisoner)
EndFunction

;
; Check if a actor is a clone of another actor.
;
Bool Function IsActorCloneOf(Actor maybeClone, Actor source)
    If (source != None && maybeClone != None && source != maybeClone) 
        If (JustBusinessAvailable && maybeClone.IsInFaction(JBSlaveFaction))
            ; the code to detect JB clones is somewhat heuristic
            Var[] kSource = new Var[1]
            kSource[0] = source
            ActorBase sourceActorBase = JBSlaveQuest.CallFunction("GetSlaveBase", kSource) as ActorBase
            Var[] kMaybeClone = new Var[1]
            kMaybeClone[0] = maybeClone
            ActorBase targetActorBase = JBSlaveQuest.CallFunction("GetSlaveBase", kMaybeClone) as ActorBase
            If (sourceActorBase != None && targetActorBase != None && sourceActorBase.GetFormID() == targetActorBase.GetFormID())
                Return true
            EndIf
        EndIf
    EndIf
    Return false
EndFunction

;
; Check if KnockoutActor will use the knockout framework for an actor or the fallback implementation.
;
Bool Function WillUseKnockoutFramework(Actor target)
    If (target != None && KnockoutFrameworkAvailable && target.HasPerk(KFIncomingMonitoringPerk) && !target.HasKeyword(KFActorCantBeKnockedOutKeyword))
        String kfState = KnockoutFrameworkManagerQuestMainScript.CallFunction("GetState", new Var[0]) as String
        Return kfState == ""
    EndIf
    Return false
EndFunction

;
; Knock out an actor.
;
Bool Function KnockoutActor(Actor target)
    If (target == None || IsKnockedOut(target))
        Return False
    EndIf
    If (WillUseKnockoutFramework(target))
        Var[] kArgs = new Var[4]
        kArgs[0] = target
        kArgs[1] = None
        kArgs[2] = 0
        kArgs[3] = true
        KnockoutFrameworkManagerQuestMainScript.CallFunction("KnockOutActor", kArgs)
        Return true
    EndIf
    KnockOutActors.AddRef(target)
    target.SetUnconscious(true)
    target.SetValue(Paralysis, 1)
    target.PushActorAway(target, 0) ; ragdoll effect
    Return true
EndFunction

;
; Check if a actor is knocked out
;
Bool Function IsKnockedOut(Actor target)
    If (target == None)
        Return false
    EndIf
    If (KnockoutFrameworkAvailable && target.HasKeyword(KFKnockedOutKeyword))
        Return true
    EndIf
    Return KnockOutActors.Find(target) >= 0
EndFunction

;
; Wake a knocked-out actor.
;
Bool Function WakeKnockedOutActor(Actor target)
    If (target == None)
        Return false
    EndIf
    If (KnockoutFrameworkAvailable && target.HasKeyword(KFKnockedOutKeyword))
        Var[] kArgs = new Var[4]
        kArgs[0] = target
        kArgs[1] = -1
        kArgs[2] = None
        kArgs[3] = true
        KnockoutFrameworkManagerQuestMainScript.CallFunction("WakeKnockedOutActor", kArgs)
        Return true
    EndIf
    If (KnockOutActors.Find(target) < 0)
        Return false
    EndIf
    KnockOutActors.RemoveRef(target)
    target.SetUnconscious(false)
    target.SetValue(Paralysis, 0)
    Return true
EndFunction
