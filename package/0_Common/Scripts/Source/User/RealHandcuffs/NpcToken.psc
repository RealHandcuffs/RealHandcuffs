;
;
; The ActorToken implementation for NPCs.
;
Scriptname RealHandcuffs:NpcToken extends RealHandcuffs:ActorToken

ActorValue Property HC_IsCompanionInNeedOfHealing Auto Const Mandatory
Keyword Property AnimFlavorFahrenheit Auto Const Mandatory
Keyword Property TeammateReadyWeapon_DO Auto Const Mandatory

FormList Property BoundHandsGenericFurnitureList Auto Const Mandatory
FormList Property BoundHandsBlacklistedSceneQuests Auto Const Mandatory
Furniture Property TemporaryWaitMarker Auto Const Mandatory
Keyword Property ActivateWithBoundHands Auto Const Mandatory
Keyword Property BoundHands Auto Const Mandatory
Keyword Property NoPackage Auto Const Mandatory
Keyword Property FurnitureTypePowerArmor Auto Const Mandatory
Keyword Property CanDoCommandFlagRemoved Auto Const Mandatory
Keyword Property PlayerTeammateFlagRemoved Auto Const Mandatory
Keyword Property Stay Auto Const Mandatory
Keyword Property WorkshopSandboxLocation Auto Const Mandatory
Package Property CommandModeActivateOverride Auto Const Mandatory
Package Property CommandModeTravelOverride Auto Const Mandatory
Spell Property BadAtSwimming Auto Const Mandatory
WorkshopParentScript Property WorkshopParent Auto Const Mandatory

Int Property CommandInspect = 5 AutoReadOnly
Int Property CommandRetrieve = 6 AutoReadOnly
Int Property CommandStay = 7 AutoReadOnly
Int Property CommandWorkshopAssign = 10 AutoReadOnly

Bool _handsBoundBehindBack
Bool _hasRemoteTriggerRestraint
Bool _removedReadyWeaponKeyword
Bool _commandModePackagesOverridden
Int _currentCommand
ObjectReference _commandTarget

Form[] _preventUnequipAllBug
Float _lastKickAiTimestamp
Float _lastInitializeMtGraphTimestamp

;
; Override: Get whether the hands of the actor are currently bound behind their back.
;
Bool Function GetHandsBoundBehindBack()
    Return _handsBoundBehindBack
EndFunction

;
; Override: Get whether firing a remote trigger in the vicinity will cause some effect.
;
Bool Function GetRemoteTriggerEffect()
    Return _hasRemoteTriggerRestraint
EndFunction

;
; Initialize the actor token after creation
;
Function Initialize(Actor myTarget)
    Parent.Initialize(myTarget)
    RegisterForRemoteEvent(myTarget, "OnCommandModeEnter")
    RegisterForRemoteEvent(myTarget, "OnCommandModeGiveCommand")
    RegisterForRemoteEvent(myTarget, "OnCommandModeCompleteCommand")
    RegisterForRemoteEvent(myTarget, "OnCommandModeExit")
    RegisterForRemoteEvent(myTarget, "OnDeath")
    RegisterForRemoteEvent(myTarget, "OnLoad")
    RegisterForRemoteEvent(myTarget, "OnUnload") 
    RegisterForRemoteEvent(myTarget, "OnWorkshopNPCTransfer")
    WorkshopNpcScript workshopNpc = myTarget as WorkshopNpcScript
    If (workshopNpc != None)
        RegisterForCustomEvent(WorkshopParent, "WorkshopActorAssignedToWork")
        RegisterForCustomEvent(WorkshopParent, "WorkshopActorUnassigned")
        StartTimer(2, UpdateWorkshopSandboxLocation)
    EndIf
    If (Library.SoftDependencies.AdvancedAnimationFrameworkAvailable && myTarget.GetActorBase() == Library.SoftDependencies.AAF_Doppelganger)
        myTarget.AddKeyword(NoPackage) ; permanently add the NoPackage keyword to AAF doppelganger
    EndIf
    StartTimer(15, DestroyNpcToken) ; sometimes tokens are created just to observe events on a NPC, they may end up not necessary
EndFunction

;
; Override: Uninitialize the actor token before destruction.
;
Function Uninitialize()
    CancelTimer(StartCheckingWeapon) ; may do nothing but that is fine
    CancelTimer(WaitForConsciousness) ; may do nothing but that is fine
    CancelTimer(CheckConsistency) ; may do nothing but that is fine
    CancelTimer(DestroyNpcToken) ; may do nothing but that is fine
    CancelTimer(UpdateWorkshopSandboxLocation) ; may do nothing but that is fine
    CancelTimer(CheckForVertibirdRideEnd) ; may do nothing but that is fine
    CancelTimer(EquipRestraintsWhenEnabled) ; may do nothing but that is fine
    If (_preventUnequipAllBug != None)
        CancelTimer(ReequipItemsAffectedByUnequipAllBug)
        _preventUnequipAllBug = None
    EndIf
    If (Target != None)
        If (Target.IsBoundGameObjectAvailable() && IsInHoldingCell())
            RemoveFromHoldingCell()
        EndIf
        WorkshopNpcScript workshopNpc = Target as WorkshopNpcScript
        If (workshopNpc != None)
            UnregisterForCustomEvent(WorkshopParent, "WorkshopActorAssignedToWork")
            UnregisterForCustomEvent(WorkshopParent, "WorkshopActorUnassigned")
            If (Target.IsBoundGameObjectAvailable())
                Target.SetLinkedRef(None, WorkshopSandboxLocation)
            EndIf
        EndIf
        UnregisterForRemoteEvent(Target, "OnCommandModeEnter")
        UnregisterForRemoteEvent(Target, "OnCommandModeGiveCommand")
        UnregisterForRemoteEvent(Target, "OnCommandModeCompleteCommand")
        UnregisterForRemoteEvent(Target, "OnCommandModeExit")
        UnregisterForRemoteEvent(Target, "OnDeath")
        UnregisterForRemoteEvent(Target, "OnLoad")
        UnregisterForRemoteEvent(Target, "OnUnload")
        UnregisterForRemoteEvent(Target, "OnWorkshopNPCTransfer")
        If (Library.RestrainedNpcs.Find(Target) >= 0)
            Library.RestrainedNpcs.RemoveRef(Target)
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Removed from restrained NPCs [" + Library.RestrainedNpcs.GetCount() + "]: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
            EndIf
        EndIf
    EndIf
    Parent.Uninitialize()
EndFunction

;
; Ocerride: Check if the token is in a good state.
;
Bool Function CheckConsistency(Actor expectedTarget)
    CancelTimer(CheckConsistency) ; may do nothing
    Return Parent.CheckConsistency(expectedTarget)
EndFunction

;
; Override: Refresh data after the game has been loaded.
;
Function RefreshOnGameLoad(Bool upgrade)
    Bool isInHoldingCell = IsInHoldingCell()
    If (isInHoldingCell)
        Actor owner = Target.GetLinkedRef(Library.Resources.LinkedOwnerSpecial) as Actor
        ObjectReference vertibird = Target.GetLinkedRef(Library.Resources.LinkedVertibird)
        If (owner != None && vertibird != None && !IsRidingVertibird(owner, vertibird))
            RemoveFromHoldingCell() ; fallback in case the timer did somehow not work
            isInHoldingCell = false
        EndIf
    EndIf
    Actor npcTarget = Target
    RealHandcuffs:WaitMarkerBase waitMarker = None
    Bool hasTemporaryWaitMarker = false
    Bool temporaryWaitMarkerDisablePoseInteraction = false
    String temporaryWaitMarkerAnimation = ""
    Bool enableAI = false
    If (npcTarget != None && upgrade)
        enableAI = npcTarget.IsAIEnabled()
        If (enableAI)
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Disabling AI: " + RealHandcuffs:Log.FormIdAsString(npcTarget) + " " + npcTarget.GetDisplayName(), Library.Settings)
            EndIf
            npcTarget.EnableAI(false, false)
        EndIf
        CancelTimer(UpdateWorkshopSandboxLocation) ; may do nothing but that is fine
        waitMarker = npcTarget.GetLinkedRef(Library.Resources.WaitMarkerLink) as RealHandcuffs:WaitMarkerBase
        If (waitMarker != None && waitMarker.GetRegisteredActor() == npcTarget)
            If ((waitMarker as RealHandcuffs:TemporaryWaitMarker) != None && GetParentCell() == waitMarker.GetParentCell())
                hasTemporaryWaitMarker = true
                temporaryWaitMarkerAnimation = waitMarker.Animation
                temporaryWaitMarkerDisablePoseInteraction = waitMarker.DisablePoseInteraction
                If (!isInHoldingCell)
                    npcTarget.MoveTo(waitMarker) ; workaround to ensure position stays correct after wait marker has been deleted and recreated
                EndIf
                waitMarker = None
            EndIf
        EndIf
    EndIf
    Parent.RefreshOnGameLoad(upgrade)
    If (Target != None) ; use Target, not npcTarget, in case RefreshOnGameLoad has made chances
        If (_preventUnequipAllBug != None) ; should never be true unless we have some bugs
            CancelTimer(ReequipItemsAffectedByUnequipAllBug)
            _preventUnequipAllBug = None
        EndIf
        Float realTime = Utility.GetCurrentRealTime()
        If (_lastKickAiTimestamp > realTime)
            _lastKickAiTimestamp = 0
        EndIf
        If (_lastInitializeMtGraphTimestamp > realTime)
            _lastInitializeMtGraphTimestamp = 0
        EndIf
        If (Restraints.Length == 0 || Target.IsDead())
            ; fallback for cleanup only, should not be necessary in theory
            StartTimer(15, DestroyNpcToken) ; wait before destroying to prevent destroying and creating tokens too often
        EndIf
        If (upgrade)
            If (waitMarker != None && waitMarker.IsEnabled() && waitMarker.GetRegisteredActor() == None)
                ; try to restore the link to the wait marker
                RealHandcuffs:WaitMarkerBase newWaitMarker = Target.GetLinkedRef(Library.Resources.WaitMarkerLink) as RealHandcuffs:WaitMarkerBase
                If (newWaitMarker != None && newWaitMarker.GetRegisteredActor() == Target)
                    newWaitMarker.Unregister(Target)
                    newWaitMarker = None
                EndIf
                If (newWaitMarker == None)
                    WorkshopObjectScript workshopObject = (waitMarker as ObjectReference) as WorkshopObjectScript
                    If (workshopObject != None && workshopObject.workshopID >= 0 && workshopObject.GetActorRefOwner() == Target)
                        AssignToWorkshop(workshopObject.workshopID, workshopObject) ; also refresh assignment in case it is broken
                    EndIf
                    waitMarker.Register(Target)
                EndIf
            EndIf
            If (hasTemporaryWaitMarker && !isInHoldingCell)
                ; try to restore temporary wait marker
                waitMarker = Target.GetLinkedRef(Library.Resources.WaitMarkerLink) as RealHandcuffs:WaitMarkerBase
                If (waitMarker != None && waitMarker.GetRegisteredActor() == Target)
                    waitMarker.DisablePoseInteraction = temporaryWaitMarkerDisablePoseInteraction
                    Var[] akArgs = new Var[2]
                    akArgs[0] = Target
                    akArgs[1] = temporaryWaitMarkerAnimation
                    waitMarker.CallFunctionNoWait("ChangeAnimation", akArgs)
                Else
                    TryCreateTemporaryWaitMarker(temporaryWaitMarkerAnimation, temporaryWaitMarkerDisablePoseInteraction)
                EndIf
            EndIf
            WorkshopNpcScript workshopNpc = Target as WorkshopNpcScript
            If (workshopNpc != None)
                StartTimer(2, UpdateWorkshopSandboxLocation)
            EndIf
            If (Library.SoftDependencies.AdvancedAnimationFrameworkAvailable && Target.GetActorBase() == Library.SoftDependencies.AAF_Doppelganger)
                Target.AddKeyword(NoPackage) ; permanently add the NoPackage keyword to AAF doppelganger
            EndIf
        EndIf
    EndIf
    If (npcTarget != None && upgrade && enableAI) ; use npcTarget to make sure that EnableAI is done even if RefreshOnGameLoad has made changes
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Enabling AI: " + RealHandcuffs:Log.FormIdAsString(npcTarget) + " " + npcTarget.GetDisplayName(), Library.Settings)
        EndIf
        npcTarget.EnableAI(true, false)
    EndIf
EndFunction

;
; Override: Refresh all static event registrations that don't depend on equipped restraints.
;
Function RefreshEventRegistrations()
    WorkshopNpcScript workshopNpc = Target as WorkshopNpcScript
    If (workshopNpc != None)
        UnregisterForCustomEvent(WorkshopParent, "WorkshopActorAssignedToWork")
        UnregisterForCustomEvent(WorkshopParent, "WorkshopActorUnassigned")
    EndIf
    UnregisterForRemoteEvent(Target, "OnCommandModeEnter")
    UnregisterForRemoteEvent(Target, "OnCommandModeGiveCommand")
    UnregisterForRemoteEvent(Target, "OnCommandModeCompleteCommand")
    UnregisterForRemoteEvent(Target, "OnCommandModeExit")
    UnregisterForRemoteEvent(Target, "OnDeath")
    UnregisterForRemoteEvent(Target, "OnLoad")
    UnregisterForRemoteEvent(Target, "OnUnload")
    UnregisterForRemoteEvent(Target, "OnWorkshopNPCTransfer")
    Parent.RefreshEventRegistrations()
    RegisterForRemoteEvent(Target, "OnCommandModeEnter")
    RegisterForRemoteEvent(Target, "OnCommandModeGiveCommand")
    RegisterForRemoteEvent(Target, "OnCommandModeCompleteCommand")
    RegisterForRemoteEvent(Target, "OnCommandModeExit")
    RegisterForRemoteEvent(Target, "OnDeath")
    RegisterForRemoteEvent(Target, "OnLoad")
    RegisterForRemoteEvent(Target, "OnUnload") 
    RegisterForRemoteEvent(Target, "OnWorkshopNPCTransfer")
    If (workshopNpc != None)
        RegisterForCustomEvent(WorkshopParent, "WorkshopActorAssignedToWork")
        RegisterForCustomEvent(WorkshopParent, "WorkshopActorUnassigned")
        If (Target.GetLinkedRef(WorkshopSandboxLocation) == None)
            CancelTimer(UpdateWorkshopSandboxLocation) ; may do nothing but that is fine
            StartTimer(2, UpdateWorkshopSandboxLocation)
        EndIf
    EndIf
EndFunction

;
; Override: Apply a restraint to the actor and update all effects and animations.
;
Function ApplyRestraint(RealHandcuffs:RestraintBase restraint)
    CancelTimer(CheckConsistency) ; may do nothing but that is fine
    CancelTimer(DestroyNpcToken) ; may do nothing but that is fine
    Parent.ApplyRestraint(restraint)
    If (Restraints.Length > 0)
        If (Library.RestrainedNpcs.Find(Target) < 0)
            Library.RestrainedNpcs.AddRef(Target)
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Added to restrained NPCs [" + Library.RestrainedNpcs.GetCount() + "]: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
            EndIf
        EndIf
    Else
        StartTimer(15, DestroyNpcToken) ; wait before destroying to prevent destroying and creating tokens too often
    EndIf
    StartTimer(2, CheckConsistency) ; fallback code to help catch problems
EndFunction

;
; Override: Unapply a restraint and update all effects and animations.
;
Function UnapplyRestraint(RealHandcuffs:RestraintBase restraint)
    CancelTimer(CheckConsistency) ; may do nothing but that is fine
    Parent.UnapplyRestraint(restraint)
    If (Restraints.Length == 0 && Library.RestrainedNpcs.Find(Target) >= 0)
        Library.RestrainedNpcs.RemoveRef(Target)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Removed from restrained NPCs [" + Library.RestrainedNpcs.GetCount() + "]: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
        EndIf
        StartTimer(15, DestroyNpcToken) ; wait before destroying to prevent destroying and creating tokens too often
    EndIf
    StartTimer(2, CheckConsistency) ; fallback code to help catch problems
EndFunction

;
; Override: Apply effects to the actor.
;
Function ApplyEffects(Bool forceRefresh, RealHandcuffs:RestraintBase handsBoundBehindBackRestraint, RealHandcuffs:RestraintBase[] remoteTriggerRestraints)
    Bool handsBoundBehindBack = handsBoundBehindBackRestraint != None
    Bool hasRemoteTriggerRestraint = remoteTriggerRestraints != None && remoteTriggerRestraints.Length > 0
    If (!forceRefresh && handsBoundBehindBack == _handsBoundBehindBack && hasRemoteTriggerRestraint == _hasRemoteTriggerRestraint)
        ; nothing to do
        Return
    EndIf
    Actor player = Game.GetPlayer()
    If (forceRefresh || (_handsBoundBehindBack && !handsBoundBehindBack))
        If (_handsBoundBehindBack && Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Removing hands bound behind back impact from: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
        EndIf
        _handsBoundBehindBack = false
        ; stop checking for drawing weapons
        CancelTimer(StartCheckingWeapon) ; may do nothing but that is fine
        CancelTimer(WaitForConsciousness) ; may do nothing but that is fine
        UnregisterForAnimationEvent(Target, "weaponDraw") ; may do nothing, too
        ; remove 'bound hands' keyword
        Target.ResetKeyword(BoundHands)
        ; restore TeammateReadyWeapon_DO keyword if necessary
        If (_removedReadyWeaponKeyword)
            Target.ResetKeyword(TeammateReadyWeapon_DO)
            _removedReadyWeaponKeyword = false
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Reset ready weapon keyword: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
            EndIf
        EndIf
        ; unregister from combat state changed event and undo changes made by the event
        UnregisterForRemoteEvent(Target, "OnCombatStateChanged")
        UnregisterForRemoteEvent(player, "OnCombatStateChanged")
        If (Target.HasKeyword(CanDoCommandFlagRemoved))
            CancelTimer(RestoreCanDoCommandFlag) ; may do nothing but that is fine
            CancelTimer(WaitForCombatEnd) ; may do nothing, too
            Target.SetCanDoCommand(true)
            Target.ResetKeyword(CanDoCommandFlagRemoved)
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Restored can do command flag: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
            EndIf
        EndIf
        CancelTimer(StopCombatWithPlayer) ; may do nothing but that is fine
        UnregisterForAllHitEvents() ; may do nothing but that is fine
        ; remove bad at swimming ability
        Target.RemoveSpell(BadAtSwimming)
        ; unregister furniture sit event
        UnregisterForRemoteEvent(Target, "OnSit")
        ; unregister from player teleport and from player entering vertibird
        UnregisterForPlayerTeleport()
        UnregisterForRemoteEvent(Game.GetPlayer(), "OnPlayerEnterVertibird")
        ; revert changes made to current behavior by commands
        If (_commandModePackagesOverridden)
            Library.RestoreCommandModeActivatePackage()
            Library.RestoreCommandModeTravelPackage()
            _commandModePackagesOverridden = false
        EndIf
        RevertCurrentCommandChanges()
        ; restore player teammate flag if necessary
        If (HasKeyword(PlayerTeammateFlagRemoved))
            Target.SetCanDoCommand(false)
            Target.SetPlayerTeammate(true, true, true)
            Target.ResetKeyword(PlayerTeammateFlagRemoved)
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Restored teammate flag: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
            EndIf
        EndIf
    EndIf
    If ((forceRefresh || !_handsBoundBehindBack) && handsBoundBehindBack)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Applying hands bound behind back impact on: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
        EndIf
        _handsBoundBehindBack = true
        ; add 'bound hands' keyword; this will apply the mod's no combat packages on the Library.RestrainedNpcs RefCollectionAlias
        Target.AddKeyword(BoundHands)
        ; prevent player teammates from drawing weapons when player does
        If (Target.HasKeyword(TeammateReadyWeapon_DO))
            Target.RemoveKeyword(TeammateReadyWeapon_DO)
            _removedReadyWeaponKeyword = true
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Removed ready weapon keyword: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
            EndIf
        EndIf
        ; register for combat state changed event, additional logic is in there
        RegisterForRemoteEvent(Target, "OnCombatStateChanged")
        RegisterForRemoteEvent(player, "OnCombatStateChanged")
        If (Target.GetCombatState() > 0)
            If (Target.IsPlayerTeammate())
                Target.AddKeyword(PlayerTeammateFlagRemoved)
                Target.SetPlayerTeammate(false, false, true)
                Target.SetCanDoCommand(true)
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Removed teammate flag: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
                EndIf
            EndIf
            HandleCombatStateChanged(Target, Target.GetCombatTarget(), Target.GetCombatState())
        EndIf
        If (player.GetCombatState() > 0)
            If (Target.IsPlayerTeammate())
                Target.AddKeyword(PlayerTeammateFlagRemoved)
                Target.SetPlayerTeammate(false, false, true)
                Target.SetCanDoCommand(true)
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Removed teammate flag: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
                EndIf
            EndIf
            HandleCombatStateChanged(player, player.GetCombatTarget(), player.GetCombatState())
        EndIf
        ; add bad at swimming ability
        Target.AddSpell(BadAtSwimming, false)
        ; register for furniture sit event, used to kick npcs out of furniture including power armor
        RegisterForRemoteEvent(Target, "OnSit")
        If (Target.IsInPowerArmor())
            Target.SwitchToPowerArmor(None)
        Else
            ObjectReference currentFurniture = Target.GetFurnitureReference()
            If (currentFurniture != None && !currentFurniture.HasKeyword(ActivateWithBoundHands) && !BoundHandsGenericFurnitureList.HasForm(currentFurniture.GetBaseObject()))
                Target.PlayIdleAction(Library.Resources.ActionInteractionExitQuick) ; kick out of furniture
            EndIf
        EndIf
        ; register for player teleport and for player entering vertibird
        RegisterForPlayerTeleport()
        RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerEnterVertibird")
        ; apply changes to behavior for current command
        If (Target.IsDoingFavor())
            Library.OverrideCommandModeActivatePackage(CommandModeActivateOverride)
            Library.OverrideCommandModeTravelPackage(CommandModeTravelOverride)
            _commandModePackagesOverridden = true
        EndIf
        ApplyCurrentCommandChanges()
        ; pull player teammates out of combat to prevent twitching around with the weapon in their hands
        If ((Target.IsPlayerTeammate() || Target.HasKeyword(PlayerTeammateFlagRemoved)) && Target.GetCombatState() > 0)
            Target.StopCombat()
        EndIf
        ; pull npcs out of blacklisted scenes
        Scene currentScene = Target.GetCurrentScene()
        If (currentScene != None && BoundHandsBlacklistedSceneQuests.HasForm(currentScene.GetOwningQuest()))
            Library.RunDummyScene(target)
        EndIf
        ; start checking for drawn weapons
        If (Library.SoftDependencies.IsKnockedOut(Target) || Target.IsBleedingOut())
            StartTimer(3, WaitForConsciousness)
        Else
            StartTimer(3, StartCheckingWeapon) ; give the NPC some time to stow their weapon
        EndIf
    EndIf
    If (forceRefresh || (_hasRemoteTriggerRestraint && !hasRemoteTriggerRestraint))
        If (_hasRemoteTriggerRestraint && Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Removing remote trigger effect impact from: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
        EndIf
        _hasRemoteTriggerRestraint = false
        If (Target.GetLinkedRef(Library.Resources.LinkedRemoteTriggerObject) == None)
            Target.ResetKeyword(Library.Resources.RemoteTriggerEffect)
        Else
            RealHandcuffs:Log.Info("Keeping RemoteTriggerEffect keyword because of linked refs.", Library.Settings)
        EndIf
    EndIf
    If ((forceRefresh || !_hasRemoteTriggerRestraint) && hasRemoteTriggerRestraint)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Applying remote trigger effect impact on: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
        EndIf
        _hasRemoteTriggerRestraint = true
        Target.AddKeyword(Library.Resources.RemoteTriggerEffect)
    EndIf
    ApplyStatefulEffects()
    Target.EvaluatePackage(true)
EndFunction

;
; Override: Kick the animations subsystem to trigger the changed animations.
;
Function KickAnimationSubsystem()
    ; switch around animation flavors to make the game realize that animation keywords changed
    Target.ChangeAnimFlavor(AnimFlavorFahrenheit)
    Target.ChangeAnimFlavor()
EndFunction

;
; Override: Tell the token to equip restraints that are not equipped once the actor is enabled.
;
Function EquipRestraintsWhenEnabled()
    If (Target.Is3DLoaded())
        StartTimer(3, EquipRestraintsWhenEnabled)
    EndIf
EndFunction

;
; When adding an item to a NPC by script directly after it has been unequipped and removed,
; a engine bug is triggered, causing the NPC to unequip all items. This function triggers a (bad)
; workaround to requip them again.
;
Function PreventUnequipAllBug()
    If (_preventUnequipAllBug == None)
        Form[] preventUnequipAllBug = new Form[0]
        _preventUnequipAllBug = preventUnequipAllBug
        Form skin = LL_FourPlay.GetActorBaseSkinForm(Target)
        Int index = 0
        While (index < 32) 
            Actor:WornItem worn = Target.GetWornItem(index, false)
            If (worn != None && ((worn.Item as Armor) != None || (worn.Item as Weapon) != None) && preventUnequipAllBug.Find(worn.Item, 0) < 0)
                If (worn.Item == skin)
                    preventUnequipAllBug.Insert(worn.Item, 0) ; make sure skin is equipped as first item
                Else
                    preventUnequipAllBug.Add(worn.Item)
                EndIf
            EndIf
            index += 1
        EndWhile
        StartTimer(0.1, ReequipItemsAffectedByUnequipAllBug)
    EndIf
EndFunction

;
; Event handler for death of the actor.
;
Event Actor.OnDeath(Actor sender, Actor akKiller)
    ; destroy the token, it is no longer required
    Actor oldTarget = Target
    oldTarget.SetLinkedRef(None, Library.LinkedActorToken)
    If (IsBoundGameObjectAvailable())    
        Actor clone = GetLinkedRef(Library.Resources.ClonedTarget) as Actor
        If (clone != None)
            RealHandcuffs:Log.Info("Moving restaints from " + RealHandcuffs:Log.FormIdAsString(oldTarget) + " " + oldTarget.GetDisplayName() + " to clone " + RealHandcuffs:Log.FormIdAsString(clone) + " " + clone.GetDisplayName(), Library.Settings)
            RealHandcuffs:ActorToken token = Library.TryGetActorToken(clone)
            If (token != None)
                token.RefreshEffectsAndAnimations(true, None)  ; they might be wrong because of parallel events from JB's inventory transfer function
            EndIf
            Int index = 0
            While (index < Restraints.Length)
                RealHandcuffs:RestraintBase restraint = Restraints[index]
                If (restraint.GetContainer() != clone)
                    restraint.Drop(true)
                    clone.AddItem(restraint, 1, true)
                EndIf
                restraint.ForceEquip(false, false)
                index += 1
            EndWhile
            SetLinkedRef(None, Library.Resources.ClonedTarget)
            clone.ResetKeyword(Library.Resources.FreshlyCloned)
        Else
            Int index = 0
            While (index < Restraints.Length)
                Restraints[index].HandleWearerDied(sender)
                index += 1
            EndWhile
        EndIf
    EndIf
    Uninitialize()
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Destroyed token for " + RealHandcuffs:Log.FormIdAsString(oldTarget) + " " + oldTarget.GetDisplayName(), Library.Settings)
    EndIf
EndEvent

;
; Event handler for unload of the actor.
;
Event ObjectReference.OnUnload(ObjectReference sender)
    CancelTimer(EquipRestraintsWhenEnabled) ; may do nothing but that is fine
    ; destoy the token if actor is deleted
    Actor oldTarget = Target
    If (oldTarget.IsDeleted())
        Uninitialize()
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Destroyed token for " + RealHandcuffs:Log.FormIdAsString(oldTarget) + " " + oldTarget.GetDisplayName(), Library.Settings)
        EndIf
    EndIf
EndEvent

;
; Event handler for 3D of actor loaded
;
Event ObjectReference.OnLoad(ObjectReference sender)
    If (_handsBoundBehindBack)
        RegisterForAnimationEvent(Target, "weaponDraw") ; restore animation event after it was lost/could not be registered
    EndIf
    Int index = 0
    While (index < Restraints.Length)
        RealHandcuffs:RestraintBase restraint = Restraints[index]
        If (!Target.IsEquipped(restraint.GetBaseObject()))
            If (!Target.IsEnabled())
                StartTimer(3, EquipRestraintsWhenEnabled)
                Return
            EndIf
            restraint.ForceEquip()
        EndIf
        index += 1
    EndWhile
EndEvent

;
; Try to assign the actor to a workshop
;
Bool Function AssignToWorkshop(int workshopId, WorkshopObjectScript assignToObject = None)
    If (workshopId < 0)
        Return false
    EndIf
    WorkshopScript workshop = WorkshopParent.GetWorkshop(workshopId)
    WorkShopNPCScript workshopNpc = Target as WorkShopNPCScript
    If (workshop == None || workshopNpc == None)
        Return false
    EndIf
    Library.SoftDependencies.SlaveRelax(Target) ; will do nothing if not a slave
    FollowersScript followers = FollowersScript.GetScript()
    If (Target.GetFactionRank(followers.CurrentCompanionFaction) >= 0)
        RealHandcuffs:Log.Info("Dismissing " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + ".", Library.Settings)
        CompanionActorScript companion = Target as CompanionActorScript
        If (companion != None)
            companion.SetLinkedRef(workshop, followers.workshopItemKeyword)
        EndIf
        followers.DismissCompanion(Target, false, false)
        If (Target.GetFactionRank(followers.CurrentCompanionFaction) >= 0)
            RealHandcuffs:Log.Info("Unable to dismiss " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + " using FollowersScript, trying workaround.", Library.Settings)
            Target.DisallowCompanion(true)
            Target.AllowCompanion(false, false)
        EndIf
        If (Target.GetFactionRank(followers.CurrentCompanionFaction) >= 0)
            RealHandcuffs:Log.Warning("Unable to dismiss " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + ", not assigning to workshop.", Library.Settings)
            Return false
        EndIf
    EndIf
    If (assignToObject == None)
        WorkshopParent.AddActorToWorkshopPUBLIC(workshopNpc, workshop, false)
    Else
        WorkshopParent.AddActorToWorkshopPUBLIC(workshopNpc, workshop, true)
        WorkshopParent.AssignActorToObjectPUBLIC(workshopNpc, assignToObject, true)
    EndIf
    RealHandcuffs:Log.Info("Transferred " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + " to new workshop at " + workshop.myLocation.GetName() + ".", Library.Settings)
    StartTimer(2, UpdateWorkshopSandboxLocation)
    Return true
EndFunction

;
; Event handler for actor transfered to workshop.
;
Event ObjectReference.OnWorkshopNPCTransfer(ObjectReference sender, Location akNewWorkshop, Keyword akActionKW)
    WorkshopNpcScript workshopNpc = Target as WorkshopNpcScript
    Bool assignedToFurniture = false
    If (workshopNpc != None && akNewWorkshop != None)
        WorkshopScript workshop = WorkshopParent.GetWorkshopFromLocation(akNewWorkshop)
        If (workshop != None)
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Transferred " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + " to new workshop at " + akNewWorkshop.GetName() + ".", Library.Settings)
            EndIf
            CancelTimer(UpdateWorkshopSandboxLocation) ; may do nothing but that is fine
            RealHandcuffs:WaitMarkerBase waitMarker = Target.GetLinkedRef(Library.Resources.WaitMarkerLink) as RealHandcuffs:WaitMarkerBase
            If (waitMarker != None)
                WorkshopObjectScript workshopObject = (waitMarker as ObjectReference) as WorkshopObjectScript ; both scripts are attached to the same object
                If (workshopObject != None && workshopObject.workshopId == workshop.GetWorkshopID())
                    ; current wait marker is workshopObject in the new workshop, assign to it
                    assignedToFurniture = true
                    If (workshopObject.GetActorRefOwner() != workshopNpc)
                        WorkshopParent.AssignActorToObjectPUBLIC(workshopNpc, workshopObject, true)
                    EndIf
                Else
                    ; current wait marker is not workshop object or not in the correct workshop, unregister
                    waitMarker.Unregister(Target)
                EndIf
            EndIf
            StartTimer(2, UpdateWorkshopSandboxLocation)
        EndIf
    EndIf
    If (!assignedToFurniture)
        ; cycle the AI to force a package switch, even if the final package will be the same
        Target.AddKeyword(Library.Resources.CycleAi)
        Target.EvaluatePackage(true)
    EndIf
EndEvent

;
; Event handler for assigned to workship work item event.
;
Event WorkshopParentScript.WorkshopActorAssignedToWork(WorkshopParentScript akSender, Var[] akArgs)
    WorkshopObjectScript workshopObject = akArgs[0] as WorkshopObjectScript
    ObjectReference currentSandboxLocation = Target.GetLinkedRef(WorkshopSandboxLocation)
    If (workshopObject != currentSandboxLocation && workshopObject.GetAssignedActor() == Target)
        HandleAssignedToWorkObject(workshopObject)
    EndIf
EndEvent

;
; Event handler for unassigned from workship work item event.
;
Event WorkshopParentScript.WorkshopActorUnassigned(WorkshopParentScript akSender, Var[] akArgs)
    ObjectReference currentSandboxLocation = Target.GetLinkedRef(WorkshopSandboxLocation)
    If (currentSandboxLocation != None)
        WorkshopObjectScript workshopObject = akArgs[0] as WorkshopObjectScript
        If (workshopObject == currentSandboxLocation && workshopObject.GetAssignedActor() != Target)
            HandleUnassignedFromWorkObject(workshopObject)
        EndIf
    EndIf
EndEvent

;
; Handle the NPC being assigned to a work object.
;
Function HandleAssignedToWorkObject(WorkshopObjectScript workshopObject)
    CancelTimer(UpdateWorkshopSandboxLocation) ; may do nothing but that is fine
    StartTimer(2, UpdateWorkshopSandboxLocation)
EndFunction

;
; Handle the NPC being unassigned from a work object.
;
Function HandleUnassignedFromWorkObject(WorkshopObjectScript workshopObject)
    If (Target.GetLinkedRef(WorkshopSandboxLocation) == workshopObject)
        Target.SetLinkedRef(None, WorkshopSandboxLocation)
        CancelTimer(UpdateWorkshopSandboxLocation) ; may do nothing but that is fine
        StartTimer(2, UpdateWorkshopSandboxLocation)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Cleared workshop sandbox location for " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + ".", Library.Settings)
        EndIf
    EndIf
EndFunction

;
; Update the workshop sandbox location. Return true if it was changed, false if it stayed the same.
;
Bool Function UpdateWorkshopSandboxLocation(WorkshopScript workshop)
    WorkshopObjectScript currentSandboxLocation = Target.GetLinkedRef(WorkshopSandboxLocation) as WorkshopObjectScript
    WorkshopObjectScript newSandboxLocation = None
    Int newSandboxLocationPriority = -1
    ObjectReference[] ownedResourceObjects = workshop.GetWorkshopOwnedObjects(Target)
    Int currentIndex = 0
    While (currentIndex < ownedResourceObjects.Length)
        WorkshopObjectScript resourceObject = ownedResourceObjects[currentIndex] as WorkshopObjectScript
        If (resourceObject != None && resourceObject.WorkshopParent != None)
            Int priority = 0
            If (resourceObject.IsBed())
                priority += 1
            ElseIf (resourceObject.RequiresActor())
                ; prefer objects that require an actor and are not bed (i.e. work objects)
                priority += 2
            EndIf
            If (resourceObject.bWork24Hours)
                ; greatly prefer objects that demand 24-hour work
                priority += 4
            EndIf
            If (priority > newSandboxLocationPriority)
                newSandboxLocation = resourceObject
                newSandboxLocationPriority = priority
            EndIf
        EndIf
        currentIndex += 1
    EndWhile
    If (newSandboxLocation == currentSandboxLocation)
        Return false
    EndIf
    Target.SetLinkedRef(newSandboxLocation, WorkshopSandboxLocation)
    Target.EvaluatePackage(true)
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Updated workshop sandbox location for " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + ".", Library.Settings)
    EndIf
    If (Target.GetLinkedRef(Library.Resources.WaitMarkerLink) == None)
        ; cycle the AI to force a package switch, even if the final package will be the same
        ; do not cycle if currently in a wait marker, it is not necessary and cycling will break the animation
        Target.AddKeyword(Library.Resources.CycleAi)
        Target.EvaluatePackage(true)
    EndIf
    Return true
EndFunction

;
; Event handler for combat state changed event.
;
Event Actor.OnCombatStateChanged(Actor akSender, Actor akTarget, int aeCombatState)
    HandleCombatStateChanged(akSender, akTarget, aeCombatState)
EndEvent

;
; Combat state changed handler, extracted as a function such that we can call it from ApplyEffects.
;
Function HandleCombatStateChanged(Actor akSender, Actor akTarget, int aeCombatState)
    If (_handsBoundBehindBack)
        Actor player = Game.GetPlayer()
        If (aeCombatState > 0)
            If (Target.HasKeyword(CanDoCommandFlagRemoved))
                CancelTimer(RestoreCanDoCommandFlag) ; may do nothing but that is fine
                StartTimer(10, WaitForCombatEnd) ; backup in case we do not get both OnCombatStateChanged events when combat finally ends
            ElseIf (Target.IsPlayerTeammate() || Target.HasKeyword(PlayerTeammateFlagRemoved))
                ; The "can do command" flag causes serious issues with bound combat, so remove it during combat.
                ; Replace it with a keyword such that we can recognize that we removed the flag.
                Target.AddKeyword(CanDoCommandFlagRemoved)
                Target.SetCanDoCommand(false)
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Removed can do command flag: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
                EndIf
                StartTimer(10, WaitForCombatEnd) ; backup in case we do not get both OnCombatStateChanged events when combat finally ends
            EndIf
            ; try to stop combat with player as teammate if not hit by player after 5 seconds
            If (Target.HasKeyword(CanDoCommandFlagRemoved) && akSender == Target && akTarget == player)
                RegisterForHitEvent(Target, player, None, None, -1, -1, -1, -1, true)            
                StartTimer(5, StopCombatWithPlayer)
            EndIf
        ElseIf (player.GetCombatState() == 0 && Target.GetCombatState() == 0)
            ; require that both the player and the bound npc are out of combat before restoring the can do command flag
            ; add the flag in a timer to prevent frequent changes when rapidly switching in/out of combat
            If (Target.HasKeyword(CanDoCommandFlagRemoved))
                CancelTimer(WaitForCombatEnd) ; may do nothing but that is fine
                StartTimer(1, RestoreCanDoCommandFlag) ; will also restore PlayerTeammate flag if necessary
            ElseIf (Target.HasKeyword(PlayerTeammateFlagRemoved) && !Target.HasKeyword(Stay)) ; not expected but handle it
                Target.ResetKeyword(PlayerTeammateFlagRemoved)
                Target.SetCanDoCommand(false)
                Target.SetPlayerTeammate(true, true, true)
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Restored teammate flag: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
                EndIf
            EndIf
        EndIf
    EndIf
EndFunction

;
; Event handler for being hit.
;
Event OnHit(ObjectReference akTarget, ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked, string apMaterial)
    If (_handsBoundBehindBack)
        If (akAggressor == Game.GetPlayer())
            RegisterForHitEvent(Target, Game.GetPlayer(), None, None, -1, -1, -1, -1, true)            
            CancelTimer(StopCombatWithPlayer)
            StartTimer(5, StopCombatWithPlayer)
        EndIf
    EndIf
EndEvent

;
; Event handler for entering furniture.
;
Event Actor.OnSit(Actor sender, ObjectReference akFurniture)
    If (_handsBoundBehindBack)
        If (akFurniture.HasKeyword(FurnitureTypePowerArmor))
            Target.SwitchToPowerArmor(None)
        ElseIf (!akFurniture.HasKeyword(ActivateWithBoundHands) && !BoundHandsGenericFurnitureList.HasForm(akFurniture.GetBaseObject()))
            Target.PlayIdleAction(Library.Resources.ActionInteractionExitQuick) ; kick out of furniture
        EndIf
    EndIf
EndEvent

;
; Event handler for start of command mode.
;
Event Actor.OnCommandModeEnter(Actor sender)
    If (_handsBoundBehindBack)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Starting bound command mode: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
        EndIf
        Library.OverrideCommandModeActivatePackage(CommandModeActivateOverride)
        Library.OverrideCommandModeTravelPackage(CommandModeTravelOverride)
        _commandModePackagesOverridden = true
        If (Target.HasKeyword(TeammateReadyWeapon_DO))
            ; most probably the keyword was added when the bound npc was turned into a follower, e.g. JB slave who was told to follow
            Target.RemoveKeyword(TeammateReadyWeapon_DO)
            _removedReadyWeaponKeyword = true
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Removed ready weapon keyword: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
            EndIf
        EndIf
    EndIf
EndEvent

;
; Event handler for player gives command.
;
Event Actor.OnCommandModeGiveCommand(Actor sender, int aeCommandType, ObjectReference akTarget)
    If (aeCommandType == 0)
        Return ; ignore "none" command
    EndIf
    If (akTarget == None)
        ; the game will repeat the last given command without target when activating command mode, ignore that
        Return
    EndIf
    If (_currentCommand != aeCommandType || _commandTarget != akTarget)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Updating current command for " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + ": " + aeCommandType + ", " + RealHandcuffs:Log.FormIdAsString(akTarget), Library.Settings)
        EndIf
        If (_handsBoundBehindBack)
            RevertCurrentCommandChanges()
        EndIf
        _currentCommand = aeCommandType
        _commandTarget = akTarget
        If (_handsBoundBehindBack)
            ApplyCurrentCommandChanges()
        EndIf
    EndIf
EndEvent

;
; Event handler called when items are added while 'inspect' or 'retrieve' commands are running.
; This is necessary because part of these commands is hardcoded and not run by a package that can be overridden,
; so instead we have to undo the effect
;
Event ObjectReference.OnItemAdded(ObjectReference sender, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    If (_handsBoundBehindBack && _currentCommand == CommandRetrieve && _commandTarget != None)
        If (akSourceContainer == _commandTarget)
            Target.RemoveItem(akBaseItem, aiItemCount, true, akSourceContainer)
        ElseIf (akSourceContainer == None && akItemReference == _commandTarget)
            akItemReference.Drop(true)
        EndIf
    EndIf
EndEvent

;
; Event handler for command completed.
;
Event Actor.OnCommandModeCompleteCommand(Actor sender, int aeCommandType, ObjectReference akTarget)
    Bool clearCurrentCommand = true
    If (_currentCommand == CommandInspect)
        If (_commandTarget != None && (_commandTarget.GetBaseObject() as Furniture) != None)
            clearCurrentCommand = false ; use furniture command will continue after completion as completion is only the sit down part
        EndIf
    EndIf
    If (clearCurrentCommand)
        If (_handsBoundBehindBack)
            RevertCurrentCommandChanges()
        EndIf
        _currentCommand = 0
        _commandTarget = None
    EndIf
EndEvent

;
; Apply changes for the current command.
;
Function ApplyCurrentCommandChanges()
    If (_currentCommand != 0)
        If (_currentCommand == CommandInspect)
            ; special command: follow the "inspected" NPC until a different command is given
            Actor targetActor = _commandTarget as Actor
            If (targetActor != None)
                Target.SetLinkedRef(targetActor, Library.LinkedOwner)
                Target.EvaluatePackage(true)
            EndIf
        ElseIf (_currentCommand == CommandRetrieve)
            RegisterForRemoteEvent(Target, "OnItemAdded")
            AddInventoryEventFilter(None)
        ElseIf (_currentCommand == CommandStay)
            ; create a temporary wait marker and register the NPC with the wait marker
            TryCreateTemporaryWaitMarker("", false)
            Target.AddKeyword(Stay)
            If (Target.IsPlayerTeammate())
                Target.AddKeyword(PlayerTeammateFlagRemoved)
                Target.SetPlayerTeammate(false, false, true)
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Removed teammate flag: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
                EndIf
                Target.SetCanDoCommand(true)
            EndIf
            Target.EvaluatePackage(true)
        EndIf
    EndIf
EndFunction

;
; Try to create a temporary wait marker for the target.
;
RealHandcuffs:TemporaryWaitMarker Function TryCreateTemporaryWaitMarker(String animation, Bool disablePoseInteraction)
    If ((Target.GetLinkedRef(Library.Resources.WaitMarkerLink) as RealHandcuffs:WaitMarkerBase) == None && !IsInHoldingCell())
        RealHandcuffs:TemporaryWaitMarker waitMarker = Target.PlaceAtMe(TemporaryWaitMarker, 1, false, true, false) as RealHandcuffs:TemporaryWaitMarker
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Created TemporaryWaitMarker " + RealHandcuffs:Log.FormIdAsString(waitMarker) + ".", Library.Settings)
        EndIf
        If (animation != "")
            waitMarker.Animation = animation
        EndIf
        If (disablePoseInteraction)
            waitMarker.DisablePoseInteraction = true
        EndIf
        If (Target.GetFurnitureReference() != None)
            Target.MoveTo(Target) ; kick out of furniture, express version
        EndIf
        If (!waitMarker.Register(Target))
            ; unable to establish link, not expected
            waitMarker.Delete()
            RealHandcuffs:Log.Warning("Unable to register " + RealHandcuffs:log.FormIdAsString(Target) + " " + Target.GetDisplayName() + " with TemporaryWaitMarker " + RealHandcuffs:Log.FormIdAsString(waitMarker) + ".", Library.Settings)
        Else
            waitMarker.TemporaryWaitMarkers.AddRef(waitMarker)
            waitMarker.EnableNoWait()
            Return waitMarker
        EndIf
    EndIf
    Return None
EndFunction

;
; Revert all changes made by the current command.
;
Function RevertCurrentCommandChanges()
    Bool evaluatePackage = false
    If (_currentCommand != 0)
        If (_currentCommand == CommandInspect)
            If (Target.GetLinkedRef(Library.LinkedOwner) == _commandTarget)
                Target.SetLinkedRef(None, Library.LinkedOwner)
                evaluatePackage = true
            EndIf
        ElseIf (_currentCommand == CommandRetrieve)
            RemoveAllInventoryEventFilters()
            UnregisterForRemoteEvent(Target, "OnItemAdded")
        ElseIf (_currentCommand == CommandStay)
            If (Target.HasKeyword(PlayerTeammateFlagRemoved))
                Target.ResetKeyword(PlayerTeammateFlagRemoved)
                Target.SetCanDoCommand(false)
                Target.SetPlayerTeammate(true, true, true)
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Restored teammate flag: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
                EndIf
            EndIf
            Target.ResetKeyword(Stay)
        EndIf
    EndIf
    ; do the check if assigned to a wait marker outside of the _currentCommand block
    ; it is possible that the NPC has been commanded to sit on a wait marker before getting bound, or assigned by a script
    RealHandcuffs:WaitMarkerBase waitMarker = Target.GetLinkedRef(Library.Resources.WaitMarkerLink) as RealHandcuffs:WaitMarkerBase
    If (waitMarker != None)
        waitMarker.Unregister(Target)
        evaluatePackage = true
    EndIf
    If (evaluatePackage)
        Target.EvaluatePackage(false)
    EndIf
EndFunction

;
; Event handler for player teleporting (fast travel, etc).
;
Event OnPlayerTeleport()
    RealHandcuffs:BoundHandsPackage boundHandsPackage = Target.GetCurrentPackage() as RealHandcuffs:BoundHandsPackage
    If (boundHandsPackage != None && !IsInHoldingCell())
        Actor followRoot = boundHandsPackage.GetFollowRoot(Target)
        If (followRoot != None)
            Utility.Wait(1) ; give the game time to move followers etc
            If (Target != None)
                Actor player = Game.GetPlayer()
                If (followRoot == player || followRoot.GetParentCell() == player.GetParentCell())
                    ; the follow root is the player of followed the player through the teleport, make sure the target follows, too
                    If (Target.GetParentCell() != followRoot.GetParentCell() || Target.GetDistance(followRoot) > 1024)
                        If (Library.Settings.InfoLoggingEnabled)
                            RealHandcuffs:Log.Info("Moving " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + " to " + RealHandcuffs:Log.FormIdAsString(followRoot) + " " + followRoot.GetDisplayName() + " after player teleport.", Library.Settings)
                        EndIf
                        Target.MoveTo(followRoot)
                    EndIf
                EndIf
            EndIf
        EndIf
    EndIf
EndEvent

;
; Event handler for player entering vertibird.
;
Event Actor.OnPlayerEnterVertibird(Actor sender, ObjectReference akVertibird)
    RealHandcuffs:BoundHandsPackage boundHandsPackage = Target.GetCurrentPackage() as RealHandcuffs:BoundHandsPackage
    If (boundHandsPackage != None)
        Actor followRoot = boundHandsPackage.GetFollowRoot(Target)
        If (followRoot != None)
            Bool isRidingVertibird = IsRidingVertibird(followRoot, akVertibird)
            Int waitCount = 0
            While (!isRidingVertibird && waitCount < 10) ; give the follow root some time to board in case it is a follower
                Utility.Wait(1.0)
                boundHandsPackage = Target.GetCurrentPackage() as RealHandcuffs:BoundHandsPackage
                If (boundHandsPackage == None)
                    Return
                EndIf
                followRoot = boundHandsPackage.GetFollowRoot(Target)
                If (followRoot == None)
                    Return
                EndIf
                isRidingVertibird = IsRidingVertibird(followRoot, akVertibird)
                waitCount += 1
            EndWhile
            If (isRidingVertibird && !IsInHoldingCell())
                If (akVertibird.CountRefsLinkedToMe(Library.Resources.LinkedVertibird) >= 3) ; 3 is hardcoded capacity of vertibird cargo compartment for now
                    RealHandcuffs:DebugWrapper.Notification("the cargo compartment of " + akVertibird.GetDisplayName() + " is full")
                Else
                    Target.SetLinkedRef(akVertibird, Library.Resources.LinkedVertibird) ; keep the race window small
                    RealHandcuffs:DebugWrapper.Notification(Target.GetDisplayName() + " locked up in cargo compartment of " + akVertibird.GetDisplayName())
                    MoveToHoldingCell(followRoot)
                    StartTimer(3, CheckForVertibirdRideEnd)
                EndIf
            EndIf
        EndIf
    EndIf
EndEvent

;
; A helper function checking if an actor is riding a vertibird.
;
Bool Function IsRidingVertibird(Actor akActor, ObjectReference akVertibird)
    Actor vertibirdActor = akVertibird as Actor
    If (vertibirdActor != None && vertibirdActor.IsBeingRiddenBy(akActor))
        Return true
    EndIf
    If (akActor.GetLinkedRef(Library.Resources.LinkedVertibird) == akVertibird)
        Return true
    EndIf
    Return false
EndFunction

;
; Temporarily move the NPC to the holding cell.
;
Function MoveToHoldingCell(ObjectReference owner)
    Target.EnableAI(false, false)
    Target.MoveTo(Library.Resources.HoldingCellMarker)
    Target.SetLinkedRef(owner, Library.Resources.LinkedOwnerSpecial)
    RealHandcuffs:Log.Info("Moved " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + " to holding cell.", Library.Settings)
EndFunction

;
; Check if the NPC is currently in the holding cell.
;
Bool Function IsInHoldingCell()
    Return Target.GetCurrentLocation() == Library.Resources.HoldingCell
EndFunction

;
; Remove the NPC from the holding cell.
;
Function RemoveFromHoldingCell()
    ObjectReference owner = Target.GetLinkedRef(Library.Resources.LinkedOwnerSpecial)
    If (owner == None) ; not expected  but handle it
        owner = Game.GetPlayer()
    EndIf
    ObjectReference vertibird = Target.GetLinkedRef(Library.Resources.LinkedVertibird)
    Float offsetX = 0
    Float offsetY = 0
    If (vertibird != None)
        Float deltaX = vertibird.X - owner.X
        Float deltaY = vertibird.Y - owner.Y
        Float deltaXY = Math.Sqrt(deltaX * deltaX + deltaY * deltaY)
        If (deltaXY > 1)
            Float factor = 112 / deltaXY ; heuristic: place NPC 112 units away from vertibird center
            offsetX = deltaX * factor
            offsetY = deltaY * factor
        EndIf
    EndIf
    Bool isInHoldingCell = IsInHoldingCell()
    Target.MoveTo(owner, offsetX, offsetY, 0, true)
    Target.MoveToNearestNavmeshLocation() ; for example to prevent falling to their death when landing on Prydwen
    Target.EnableAI(true, false)
    Target.EvaluatePackage(false)
    Target.SetLinkedRef(None, Library.Resources.LinkedOwnerSpecial)
    If (vertibird != None)
        Target.SetLinkedRef(None, Library.Resources.LinkedVertibird)
    EndIf
    If (isInHoldingCell)
        RealHandcuffs:Log.Info("Removed " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + " from holding cell.", Library.Settings)
    Else
        ; e.g. caused by mods that teleport followers who get too far away from the player without checking if their AI is enabled
        RealHandcuffs:Log.Info("Removed " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + " from holding cell (WARNING: was not in holding cell).", Library.Settings)
    EndIf
EndFunction

;
; Event handler for end of command mode.
;
Event Actor.OnCommandModeExit(Actor sender)
    If (_commandModePackagesOverridden)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Ending bound command mode: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
        EndIf
        Library.RestoreCommandModeActivatePackage()
        Library.RestoreCommandModeTravelPackage()
        _commandModePackagesOverridden = false
    EndIf
EndEvent

;
; Event handler for weapon draw animation event.
;
Event OnAnimationEvent(ObjectReference akSource, string asEventName)
    If (asEventName == "weaponDraw" && _handsBoundBehindBack)
        FixWeaponDrawn()
    EndIf
EndEvent

;
; Try to fix the condition that the NPC has the weapon drawn.
;
Function FixWeaponDrawn()
    If (Target.HasKeyword(TeammateReadyWeapon_DO))
        ; The keyword was added to the target since the handcuffs have been equipped, remove it again and cycle the AI.
        CancelTimer(WaitForConsciousness)
        CancelTimer(StartCheckingWeapon)
        UnregisterForAnimationEvent(Target, "weaponDraw")
        Target.RemoveKeyword(TeammateReadyWeapon_DO)
        _removedReadyWeaponKeyword = true
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Removed ready weapon keyword: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
        EndIf
        Target.AddKeyword(Library.Resources.CycleAi)
        Target.EvaluatePackage(true)
        If (Library.SoftDependencies.IsKnockedOut(Target) || Target.IsBleedingOut())
            StartTimer(3, WaitForConsciousness)
        Else
            StartTimer(3, StartCheckingWeapon) ; give the NPC some time to stow their weapon
        EndIf
    ElseIf (Library.SoftDependencies.IsKnockedOut(Target) || Target.IsBleedingOut())
        CancelTimer(WaitForConsciousness)
        CancelTimer(StartCheckingWeapon)
        UnregisterForAnimationEvent(Target, "weaponDraw")
        StartTimer(3, WaitForConsciousness)
    Else
        ; For some unknown reason NPCs sometimes get stuck with drawn weapon animations.
        ; It is hard to find a reliable way to solve this, currently the best way is to (re)initialize the MT graph.
        ; Only do this if we have not done it in the last thirty seconds
        Float realTime = Utility.GetCurrentRealTime()
        If ((_lastInitializeMtGraphTimestamp == 0 || (realTime - _lastInitializeMtGraphTimestamp) > 30) && !Library.SoftDependencies.IsInAafScene(Target))
            _lastInitializeMtGraphTimestamp = realTime
            CancelTimer(WaitForConsciousness)
            CancelTimer(StartCheckingWeapon)
            UnregisterForAnimationEvent(Target, "weaponDraw")
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Initializing MT graph: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
            EndIf
            Idle InitializeMTGraphInstant = Game.GetFormFromFile(0x080D4A, "Fallout4.esm") as Idle
            Target.PlayIdle(InitializeMTGraphInstant)
            StartTimer(3, StartCheckingWeapon)
        EndIf
    EndIf
EndFunction

;
; Event handler for actor equipped item.
;
Event Actor.OnItemEquipped(Actor sender, Form akBaseObject, ObjectReference akReference)
    Form[] preventUnequipAllBug = _preventUnequipAllBug
    If (preventUnequipAllBug != None && ((akBaseObject as Armor) != None || (akBaseObject as Weapon) != None))
        Int index = preventUnequipAllBug.Find(akBaseObject)
        If (index < 0)
            preventUnequipAllBug.Add(akBaseObject)
        EndIf
    EndIf
    Parent.HandleItemEquipped(akBaseObject, akReference)
EndEvent

;
; Event handler for actor unequipped item.
;
Function HandleItemUnequipped(Form akBaseObject, ObjectReference akReference)
    Form[] preventUnequipAllBug = _preventUnequipAllBug
    If (preventUnequipAllBug != None && UI.IsMenuOpen("ContainerMenu"))
        Int index = preventUnequipAllBug.Find(akBaseObject)
        If (index >= 0)
            preventUnequipAllBug.Remove(index)
         EndIf
    EndIf
    Parent.HandleItemUnequipped(akBaseObject, akReference)
EndFunction

;
; Event handler for actor changed away from bound hands package.
;
Function HandleBoundHandsPackageChanged()
    Package currentPackage = Target.GetCurrentPackage()
    If (_handsBoundBehindBack)
        ; do nothing if we just tried to regain control over the npc
        Float realTime = Utility.GetCurrentRealTime()
        If ((realTime - _lastKickAiTimestamp) > 1 && (currentPackage as RealHandcuffs:BoundHandsPackage) == None)
            ; moved away from a 'bound hands' package
            If (!Target.HasKeyword(NoPackage) && Target.HasKeyword(BoundHands) && Library.RestrainedNpcs.Find(Target) >= 0 && !Library.SoftDependencies.IsInAafScene(Target))
                ; but we expect such a package to be active
                _lastKickAiTimestamp = realTime
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Trying to regain control over " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + " (current package: " + RealHandcuffs:Log.FormIdAsString(Target.GetCurrentPackage()) + ")", Library.Settings)
                EndIf
                Scene currentScene = Target.GetCurrentScene()
                If (currentScene != None && BoundHandsBlacklistedSceneQuests.HasForm(currentScene.GetOwningQuest()))
                    Library.StartDummyScene(Target)
                Else
                    Library.RestrainedNpcs.RemoveRef(Target)
                    Library.RestrainedNpcs.AddRef(Target)
                    Target.EvaluatePackage(true)
                EndIf
            EndIf
        EndIf
    EndIf
EndFunction

;
; React on token moving between containers.
;
Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
    If ((!Uninitialized && !IsBoundGameObjectAvailable()) || Target == None || akNewContainer != Target)
        If (Library.SoftDependencies.IsActorCloneOf(akNewContainer as Actor, akOldContainer as Actor))
            RealHandcuffs:Log.Info("Deteced cloning operation, marking actor as clone.", Library.Settings)
            SetLinkedRef(akNewContainer, Library.Resources.ClonedTarget)
            akNewContainer.AddKeyword(Library.Resources.FreshlyCloned)
        Else
            CheckConsistency(Target)
        EndIf    
    EndIf
EndEvent

;
; Timer definitions.
;
Group Timers
    Int Property RestoreCanDoCommandFlag = 1000 AutoReadOnly
    Int Property StopCombatWithPlayer = 1001 AutoReadOnly
    Int Property ReequipItemsAffectedByUnequipAllBug = 1002 AutoReadOnly
    Int Property CheckConsistency = 1003 AutoReadOnly
    Int Property DestroyNpcToken = 1004 AutoReadOnly
    Int Property WaitForConsciousness = 1005 AutoReadOnly
    Int Property StartCheckingWeapon = 1006 AutoReadOnly
    Int Property WaitForCombatEnd = 1007 AutoReadOnly
    Int Property UpdateWorkshopSandboxLocation = 1008 AutoReadOnly
    Int Property CheckForVertibirdRideEnd = 1009 AutoReadOnly
    Int Property EquipRestraintsWhenEnabled = 1010 AutoReadOnly
EndGroup

;
; Timer event.
;
Event OnTimer(Int aiTimerID)
    If (aiTimerID == CheckConsistency)
        CheckConsistency(Target)
    ElseIf (Target == None)
        Return
    ElseIf (aiTimerID == RestoreCanDoCommandFlag)
        If (Target.HasKeyword(CanDoCommandFlagRemoved))
            Target.SetCanDoCommand(true)
            Target.ResetKeyword(CanDoCommandFlagRemoved)
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Restored can do command flag: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
            EndIf
            ; also restore PlayerTeammate flag if necessary, in addition to CanDoCommand flag
            If (Target.HasKeyword(PlayerTeammateFlagRemoved) && !Target.HasKeyword(Stay))
                Target.ResetKeyword(PlayerTeammateFlagRemoved)
                Target.SetCanDoCommand(false)
                Target.SetPlayerTeammate(true, true, true)
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Restored teammate flag: " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName(), Library.Settings)
                EndIf
            EndIf
        EndIf
    ElseIf (aiTimerID == StopCombatWithPlayer)
        If (_handsBoundBehindBack)
            UnregisterForAllHitEvents()
            Target.StopCombat()
        EndIf
    ElseIf (aiTimerID == ReequipItemsAffectedByUnequipAllBug)
        Form[] preventUnequipAllBug = _preventUnequipAllBug
        _preventUnequipAllBug = None
        Target.UnequipAll()
        Int index = 0
        While (index < preventUnequipAllBug.Length)
            Form item = preventUnequipAllBug[index]
            If (!Target.IsEquipped(item))
                Target.EquipItem(preventUnequipAllBug[index], item is RealHandcuffs:RestraintBase, true)
            EndIf
            index += 1
        EndWhile
    ElseIf (aiTimerID == DestroyNpcToken)
        If (Restraints.Length == 0 || Target.IsDead())
            Actor oldTarget = Target
            oldTarget.SetLinkedRef(None, Library.LinkedActorToken)
            Uninitialize()
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Destroyed token for: " + RealHandcuffs:Log.FormIdAsString(oldTarget) + " " + oldTarget.GetDisplayName(), Library.Settings)
            EndIf
        EndIf
    ElseIf (aiTimerID == WaitForConsciousness)
        If (_handsBoundBehindBack)
            If (Library.SoftDependencies.IsKnockedOut(Target) || Target.IsBleedingOut())
                StartTimer(3, WaitForConsciousness)
            Else
                StartTimer(3, StartCheckingWeapon) ; give the NPC some time to stow their weapon
            EndIf
        EndIf
    ElseIf (aiTimerID == StartCheckingWeapon)
        If (_handsBoundBehindBack)
            If (Library.SoftDependencies.IsKnockedOut(Target) || Target.IsBleedingOut())
                StartTimer(3, WaitForConsciousness)
            Else
                If (Target.WaitFor3DLoad())
                    RegisterForAnimationEvent(Target, "weaponDraw")
                EndIf
                If (Target.IsWeaponDrawn())
                    FixWeaponDrawn()
                EndIf
            EndIf
        EndIf
    ElseIf (aiTimerID == WaitForCombatEnd)
        If (Target.HasKeyword(CanDoCommandFlagRemoved))
            If (Target.GetCombatState() == 0 && Game.GetPlayer().GetCombatState() == 0)
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("WaitForCombatEnd " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + " detected end of combat.", Library.Settings)
                EndIf
                ; add the flag in a timer to prevent frequent changes when rapidly switching in/out of combat
                StartTimer(1, RestoreCanDoCommandFlag)
            Else
                StartTimer(10, WaitForCombatEnd)
            EndIf
        EndIf
    ElseIf (aiTimerID == UpdateWorkshopSandboxLocation)
        WorkshopNpcScript workshopNpc = Target as WorkshopNpcScript
        If (workshopNpc != None)
            Int workshopId = workshopNpc.GetWorkshopID()
            If (workshopId >= 0)
                WorkshopScript workshop = WorkshopParent.GetWorkshop(workshopId)
                If (workshop != None && workshopId == workshop.GetWorkshopID())
                    UpdateWorkshopSandboxLocation(workshop)
                EndIf
            EndIf
        EndIf
    ElseIf (aiTimerID == CheckForVertibirdRideEnd)
        Actor owner = Target.GetLinkedRef(Library.Resources.LinkedOwnerSpecial) as Actor
        ObjectReference vertibird = Target.GetLinkedRef(Library.Resources.LinkedVertibird)
        If (owner == None || vertibird == None || !IsRidingVertibird(owner, vertibird))
            If (vertibird == None) ; not expected but handle it
                RealHandcuffs:DebugWrapper.Notification(Target.GetDisplayName() + " released from cargo compartment of vertibird")
            Else
                RealHandcuffs:DebugWrapper.Notification(Target.GetDisplayName() + " released from cargo compartment of " + vertibird.GetDisplayName())
            EndIf
            RemoveFromHoldingCell()
        Else
            StartTimer(3, CheckForVertibirdRideEnd)
        EndIf
    ElseIf (aiTimerID == EquipRestraintsWhenEnabled)
RealHandcuffs:Log.Error("OnTimer: EquipRestraintsWhenEnabled " + RealHandcuffs:Log.FormIdAsString(Target), Library.Settings);TODO
        If (Target.Is3DLoaded())
            If (Target.IsEnabled())
                Int index = 0
                While (index < Restraints.Length)
                    RealHandcuffs:RestraintBase restraint = Restraints[index]
                    If (!Target.IsEquipped(restraint.GetBaseObject()))
                        restraint.ForceEquip()
                    EndIf
                    index += 1
                EndWhile
            Else
                StartTimer(3, EquipRestraintsWhenEnabled)
            EndIf
        EndIf
    Else
        Parent.OnTimer(aiTimerID)
    EndIf
EndEvent