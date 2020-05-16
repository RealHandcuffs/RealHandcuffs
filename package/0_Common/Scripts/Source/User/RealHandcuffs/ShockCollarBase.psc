;
; Abstract base class for all shock collars.
;
Scriptname RealHandcuffs:ShockCollarBase extends RealHandcuffs:RestraintBase

RealHandcuffs:ShockCollarTerminalData Property TerminalData Auto Const Mandatory

FormList Property ShockCollarTerminatedSceneQuests Auto Const Mandatory
Projectile Property ExplosiveCollarProjectile Auto Const Mandatory
Sound Property MineTickLoop Auto Const Mandatory

Int _triggerMode = 0
Int _accessCode = -1
Float _tortureModeFrequency = 0.0
Float _tortureModeTargetTimestamp = 0.0
Float _clearTerminalLockoutTimestamp = 0.0
Float _lastSignalTimestampRealTime = 0.0
Int _currentSignalCount = 0
Int _currentPlaybackId = 0
Float _lastTimeTriggeredRealTime = 0.0
Bool _playerSleeping = False

;
; Set the firmware of the collar. Returns true if the mod was changed.
; Note that doing this on shock collars that are currently worn by an NPC will not fully work,
; you will need to unequip and requip them.
;
Bool Function SetFirmwareMod(ObjectMod firmwareMod)
    Return ReplaceMod(Library.Resources.FirmwareTag, firmwareMod)
EndFunction

;
; Set the shock module of the collar. Returns true if the mod was changed.
; Note that doing this on shock collars that are currently worn by an NPC will not fully work,
; you will need to unequip and requip them.
;
Bool Function SetShockModuleMod(ObjectMod shockModuleMod)
    Return ReplaceMod(Library.Resources.ShockModuleTag, shockModuleMod)
EndFunction

;
; Override: Get the item slots.
;
Int[] Function GetSlots()
    Int[] slots = new Int[1]
    slots[0] = 50
    Return slots
EndFunction

;
; Override: Get the impact caused by waring the restraint.
;
String Function GetImpact()
    Return Library.RemoteTriggerEffect
EndFunction

;
; Override: Get the level of the lock.
;
Int Function GetLockLevel()
    Return 254 ; inaccessible
EndFunction

;
; Override: Run the interaction when the restraint is equipped by player action
;
Bool Function EquipInteraction(Actor target)
    If (HasKeyword(Library.BlockPlayerEquipUnequip) || target.HasKeyword(Library.BlockPlayerEquipUnequip))
        Return false
    EndIf
    Actor player = Game.GetPlayer()
    Int interactionType = Library.InteractionTypeNpc
    If (target == player)
        interactionType = Library.InteractionTypePlayer
    EndIf
    If (!Library.TrySetInteractionType(interactionType, target, GetLockLevel()))
        Return false
    EndIf
    Bool equipped = false
    Bool showTerminal = false;
    If (Library.GetHandsBoundBehindBack(player) || Library.SoftDependencies.IsActorDeviousDevicesBound(player))
        Library.Resources.MsgBondsPreventManipulationOfShockCollar.Show()
    ElseIf (target == player)
        Int selection = Library.Resources.MsgBoxSelfEquipRobcoShockCollarPart1.Show()
        If (selection == 0)
            ScheduleShowTerminalOnPipboyInteraction(false, false)
             ; interaction continues, don't clear interaction type
        ElseIf (selection == 1)
            selection = Library.Resources.MsgBoxSelfEquipRobcoShockCollarPart2.Show()
            equipped = (selection == 0)
        EndIf
    Else
        Int selection
        If (Library.IsFemale(target))
            selection = Library.Resources.MsgBoxNpcEquipRobcoShockCollarFemale.Show()
        Else
            selection = Library.Resources.MsgBoxNpcEquipRobcoShockCollarMale.Show()
        EndIf
        equipped = (selection == 1 || selection == 2)
        If (selection == 0 || selection == 2)
            ScheduleShowTerminalOnPipboyInteraction(false, true)
            Return equipped ; interaction continues, don't clear interaction type
        EndIf
    EndIf
    Library.ClearInteractionType()
    Return equipped
EndFunction

;
; Override: Run the interaction when the restraint is unequipped by player action
;
Bool Function UnequipInteraction(Actor target)
    If (HasKeyword(Library.BlockPlayerEquipUnequip) || target.HasKeyword(Library.BlockPlayerEquipUnequip))
        Return false
    EndIf
    Actor player = Game.GetPlayer()
    Int lockpickingPenalty = 0
    Int interactionType = Library.InteractionTypeNpc
    If (target == player)
        lockpickingPenalty = GetLockpickingPenalty()
        interactionType = Library.InteractionTypePlayer
    EndIf
    If (!Library.TrySetInteractionType(interactionType, target, GetLockLevel() + lockpickingPenalty))
        Return false
    EndIf
    If (Library.GetHandsBoundBehindBack(player) || Library.SoftDependencies.IsActorDeviousDevicesBound(player))
        Library.Resources.MsgBondsPreventManipulationOfShockCollar.Show()
    ElseIf (target == player)
        If (!UI.IsMenuOpen("ContainerMenu"))
            Int selection = Library.Resources.MsgBoxSelfRobcoShockCollarEquipped.Show()
            If (selection == 0)
                ScheduleShowTerminalOnPipboyInteraction(false, false)
                Return false ; interaction continues, don't clear interaction type
            EndIf
        EndIf
    Else
        Int selection
        If (Library.IsFemale(target))
            selection = Library.Resources.MsgBoxNpcRobcoShockCollarEquippedFemale.Show()
        Else
            selection = Library.Resources.MsgBoxNpcRobcoShockCollarEquippedMale.Show()
        EndIf
        If (selection == 0)
            ScheduleShowTerminalOnPipboyInteraction(GetContainer() == Game.GetPlayer(), true)
            Return false ; interaction continues, don't clear interaction type
        EndIf
    EndIf
    Library.ClearInteractionType()
    Return false
EndFunction

;
; Set internal state after the restraint has been equipped and applied.
;
Function SetStateAfterEquip(Actor target, Bool interactive)
    CancelTimer(DoTrigger) ; may do nothing
    If (_currentPlaybackId > 0)
        Sound.StopInstance(_currentPlaybackId)
        _currentPlaybackId = 0
    EndIf
    _currentSignalCount = 0
    AddKeyword(Library.Resources.Locked)
    Float frequency = GetTortureModeFrequency()
    If (frequency > 0)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Starting torture mode for " + RealHandcuffs:Log.FormIdAsString(target) + " " + target.GetDisplayName() + ", frequency: " + frequency, Library.Settings)
        EndIf
        _tortureModeTargetTimestamp = Utility.GetCurrentGameTime() + frequency / 24
        StartTimerGameTime(frequency, TortureTrigger)
        If (target == Game.GetPlayer())
            RegisterForPlayerSleep()
        EndIf
    EndIf
EndFunction

;
; Set internal state after the restraint has been unequipped and unapplied.
;
Function SetStateAfterUnequip(Actor target, Bool interactive)
    CancelTimer(DoTrigger) ; may do nothing
    If (_tortureModeTargetTimestamp > 0.0)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Stopping torture mode for " + RealHandcuffs:Log.FormIdAsString(target) + " " + target.GetDisplayName() + ".", Library.Settings)
        EndIf
        CancelTimerGameTime(TortureTrigger)
        If (target == Game.GetPlayer())
            UnregisterForPlayerSleep()
        EndIf
        _tortureModeTargetTimestamp = 0.0
    EndIf
    If (_currentPlaybackId > 0)
        Sound.StopInstance(_currentPlaybackId)
        _currentPlaybackId = 0
    EndIf
    _currentSignalCount = 0
    ResetKeyword(Library.Resources.Locked)
EndFunction

;
; Override: Refresh data after the game has been loaded.
;
Function RefreshOnGameLoad(Bool upgrade)
    _lastSignalTimestampRealTime = 0.0
    _currentSignalCount = 0
    _lastTimeTriggeredRealTime = 0.0
EndFunction

;
; Override: Run the interaction when the restraint prevented the player from interacting with a furniture or similar object.
;
Function ActivateFurniturePreventedInteraction(ObjectReference furnitureRef, Bool shouldBeAllowed)
    Library.Resources.MsgFrequentShocksPreventSleeping.Show()
EndFunction

;
; Override: Called for some restraints that can be triggered, e.g. by a remote trigger being fired in the vicinity.
;
Function Trigger(Actor target, Bool force)
    If (_currentPlaybackId == -1)
        Return ; ignore all further signals
    EndIf
    If (force)
        If (_currentPlaybackId > 0)
            CancelTimer(DoTrigger)
            Sound.StopInstance(_currentPlaybackId)
        EndIf
        _currentPlaybackId = -1
        Var[] kArgs = new Var[1]
        kArgs[0] = target
        CallFunctionNoWait("ForceTriggerInternal", kArgs)
        Return
    EndIf
    Float currentRealTime = Utility.GetCurrentRealTime()
    If ((currentRealTime - _lastSignalTimestampRealTime) <= 0.5)
        _currentSignalCount += 1 ; count signals if the gap is not more than 0.5 seconds
    Else
        _currentSignalCount = 1
    EndIf
    _lastSignalTimestampRealTime = currentRealTime
    Int expectedNumberOfSignals = GetTriggerMode()
    If (expectedNumberOfSignals == 0 || _currentSignalCount == expectedNumberOfSignals)
        If (_currentPlaybackId == 0 && (currentRealTime - _lastTimeTriggeredRealTime) > 1) ; use a dead time of one second after triggering
            ObjectReference soundTarget = target
            If (soundTarget == None)
                soundTarget = GetContainer()
                If (soundTarget == None)
                    soundTarget = Self
                EndIf
            EndIf
            soundTarget.WaitFor3DLoad()
            _currentPlaybackId = MineTickLoop.Play(soundTarget)
            If (target != None && target.GetSleepState() != 0 && !target.IsInScene())
                ; force temporary wakeup
                Library.StartDummyScene(target)
            EndIf
            StartTimer(0.5, DoTrigger)
        EndIf
    ElseIf (_currentSignalCount > expectedNumberOfSignals)
        If (_currentPlaybackId > 0)
            CancelTimer(DoTrigger)
            Sound.StopInstance(_currentPlaybackId)
            _currentPlaybackId = 0
        EndIf
    EndIf
EndFunction

;
; Override: Handle death of the wearer of the restraint.
;
Function HandleWearerDied(Actor akActor)
    If (HasKeyword(Library.Resources.Explosive)) ; keep explosive shock collars active on corpses
        If (!IsBoundGameObjectAvailable())
            ; workaround, death will often cause end of persistence even though variables are still pointing at the object
            Drop(true)
            akActor.AddItem(Self, 1, true)
            akActor.EquipItem(GetBaseObject())
        EndIf
        ObjectReference last = akActor
        ObjectReference linked = akActor.GetLinkedRef(Library.Resources.LinkedRemoteTriggerObject)
        While (linked != None)
            last = linked
            linked = last.GetLinkedRef(Library.Resources.LinkedRemoteTriggerObject)
        EndWhile
        last.SetLinkedRef(Self, Library.Resources.LinkedRemoteTriggerObject)
        akActor.AddKeyword(Library.Resources.RemoteTriggerEffect) ; in case ActorToken has already removed it
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Set up remote trigger effect on corpse of " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName() + ".", Library.Settings)
        EndIf
    EndIf
EndFunction

;
; React on token collar moving between containers.
;
Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
    If (HasKeyword(Library.Resources.Explosive))
        If (akOldContainer != None && akOldContainer != GetContainer())
            ; remove explosive effect from akOldContainer if it was added by this collar
            ObjectReference last = akOldContainer
            ObjectReference linked = akOldContainer.GetLinkedRef(Library.Resources.LinkedRemoteTriggerObject)
            While (linked != None)
                If (linked == Self)
                    If (Library.Settings.InfoLoggingEnabled)
                        RealHandcuffs:Log.Info("Removing " + RealHandcuffs:Log.FormIdAsString(Self) + " " + Self.GetDisplayName() + " from remote trigger efect chain.", Library.Settings)
                    EndIf
                    linked = linked.GetLinkedRef(Library.Resources.LinkedRemoteTriggerObject)
                    last.SetLinkedRef(linked, Library.Resources.LinkedRemoteTriggerObject)
                    If (last == akOldContainer && linked == None)
                        If (Library.Settings.InfoLoggingEnabled)
                            RealHandcuffs:Log.Info("Removing trigger effect from container " + RealHandcuffs:Log.FormIdAsString(akOldContainer) + " " + akOldContainer.GetDisplayName() + ".", Library.Settings)
                        EndIf
                        akOldContainer.ResetKeyword(Library.Resources.RemoteTriggerEffect)
                    EndIf
                    Return
                Else
                    last = linked
                    linked = last.GetLinkedRef(Library.Resources.LinkedRemoteTriggerObject)
                EndIf
            EndWhile
            ; if player is moving collar to a corpse or armor rack, give them the possibility to booby-trap the corpse/armor rack
            If (UI.IsMenuOpen("ContainerMenu") && akOldContainer == Game.GetPlayer())
                Actor corpse = akNewContainer as Actor
                If (corpse != None && (corpse.IsDead() || Library.SoftDependencies.IsArmorRack(corpse)) && !corpse.IsEquipped(GetBaseObject()) && !corpse.IsDismembered("Head1"))
                    last = corpse
                    linked = corpse.GetLinkedRef(Library.Resources.LinkedRemoteTriggerObject)
                    While (linked != None)
                        RealHandcuffs:RestraintBase existingCollar = linked as RealHandcuffs:ShockCollarBase
                        If (existingCollar != None)
                            Return ; already booby-trapped with another collar
                        EndIf
                        last = linked
                        linked = last.GetLinkedRef(Library.Resources.LinkedRemoteTriggerObject)
                    EndWhile
                    Message boobyTrapMessage = Library.Resources.MsgBoxBoobyTrapCorpse
                    If (Library.SoftDependencies.IsArmorRack(corpse))
                        boobyTrapMessage = Library.Resources.MsgBoxBoobyTrapArmorRack
                    EndIf
                    If (boobyTrapMessage.Show() == 0)
                        If (!IsBoundGameObjectAvailable())
                            ; workaround
                            Drop(true)
                            corpse.AddItem(Self, 1, true)
                        EndIf
                        corpse.EquipItem(Self.GetBaseObject())
                        last.SetLinkedRef(Self, Library.Resources.LinkedRemoteTriggerObject)
                        If (linked == None)
                            corpse.AddKeyword(Library.Resources.RemoteTriggerEffect)
                        EndIf
                        KickContainerUI(corpse)
                        If (Library.Settings.InfoLoggingEnabled)
                            RealHandcuffs:Log.Info("Player booby-trapping corpse " + RealHandcuffs:Log.FormIdAsString(corpse) + " " + corpse.GetDisplayName() + ".", Library.Settings)
                        EndIf
                    EndIf
                EndIf
            EndIf
        EndIf
    EndIf
EndEvent

;
; Internal function used for force-triggering.
;
Function ForceTriggerInternal(Actor target)
    ObjectReference soundTarget = target
    If (soundTarget == None)
        soundTarget = GetContainer()
        If (soundTarget == None)
            soundTarget = Self
        EndIf
    EndIf
    soundTarget.WaitFor3DLoad()
    Int playbackId = MineTickLoop.Play(soundTarget) ; do not use _currentPlaybackId as it is set to -1
    If (target.GetSleepState() != 0 && !target.IsInScene())
        ; force temporary wakeup
        Library.StartDummyScene(target)
    EndIf
    Utility.Wait(0.5)
    Sound.StopInstance(playbackId)
    TriggerInternal(target)
EndFunction

;
; Internal function doing the actual triggering.
;
Function TriggerInternal(Actor target)
    _lastTimeTriggeredRealTime = Utility.GetCurrentRealTime()
    Bool collarIsWorn
    If (target == None || target.IsDead() || Library.SoftDependencies.IsArmorRack(target))
        ObjectReference myContainer = GetContainer()
        If (myContainer != None)
            RealHandcuffs:Log.Info("Triggering shock collar inside " + RealHandcuffs:Log.FormIdAsString(myContainer) + " " + myContainer.GetDisplayName() + ".", Library.Settings)
        Else
            RealHandcuffs:Log.Info("Triggering loose shock collar " + RealHandcuffs:Log.FormIdAsString(Self) + " " + GetDisplayName() + ".", Library.Settings)
        EndIf
        collarIsWorn = false
    Else
        RealHandcuffs:ActorToken token = Library.TryGetActorToken(target)
        collarIsWorn = token != None && token.IsApplied(Self)
        If (collarIsWorn)
            Scene currentScene = target.GetCurrentScene()
            If (currentScene != None && ShockCollarTerminatedSceneQuests.HasForm(currentScene.GetOwningQuest()))
                Library.StartDummyScene(target)
            EndIf
        EndIf
        If (Library.Settings.InfoLoggingEnabled)
            If (collarIsWorn)
                RealHandcuffs:Log.Info("Triggering shock collar of " + RealHandcuffs:Log.FormIdAsString(target) + " " + target.GetDisplayName() + ".", Library.Settings);
            Else
                RealHandcuffs:Log.Info("Triggering shock after bad manipulation from " + RealHandcuffs:Log.FormIdAsString(target) + " " + target.GetDisplayName() + ".", Library.Settings)
            EndIf
        EndIf
        Var[] kArgs = new Var[2]
        kArgs[0] = target
        kArgs[1] = Self
        Library.SendCustomEvent("OnRestraintTriggered", kArgs)
    EndIf
    If (HasKeyword(Library.Resources.Explosive))
        ; do not stop playback, Explode() will keep it playing a moment and then stop it
        If (collarIsWorn)
            Explode(target)
        Else
            Explode(None)
        EndIf
        _currentPlaybackId = 0
    Else
        If (_currentPlaybackId > 0)
            Sound.StopInstance(_currentPlaybackId)
        EndIf
        If (target != None)
            _currentPlaybackId = 0 ; also reset if it was -1
            If (HasKeyword(Library.Resources.DefaultShock))
                Library.ZapWithDefaultShock(target)
            ElseIf (HasKeyword(Library.Resources.ThrobbingShock))
                Library.ZapWithThrobbingShock(target)
            Else
                RealHandcuffs:Log.Error("Unknown shock module detected.", Library.Settings)
            EndIf
        Else
            RealHandcuffs:Log.Warning("Unable to trigger shock collar without target.", Library.Settings)
        EndIf
    EndIf
EndFunction

;
; Get the object to use for the exploded collar.
;
MiscObject Function GetExplodedCollar()
    Return None
EndFunction

;
; Explode the collar, destroying it in the process and killing its wearer.
; This function will block until the explosion has triggered.
;
Function Explode(Actor target)
    If (target == None)
        Actor livingActor = GetContainer() as Actor
        If (livingActor != None && !livingActor.IsDead() && !Library.SoftDependencies.IsArmorRack(livingActor) && !library.GetHandsBoundBehindBack(livingActor))
            Drop(false)
        EndIf
    ElseIf (!target.IsDead() && !Library.SoftDependencies.IsArmorRack(target))
        ;If (target.IsInPowerArmor())
        ;    target.SwitchToPowerArmor(None)
        ;EndIf
        ObjectReference currentFurniture = target.GetFurnitureReference()
        If (currentFurniture != None)
            WorkshopObjectScript woFurniture = currentFurniture as WorkshopObjectScript
            If (woFurniture == None || !woFurniture.bWork24Hours)
                target.PlayIdleAction(Library.Resources.ActionInteractionExitQuick)
            EndIf
        EndIf
    EndIf
    ; stop tick sound if it is still playing
    If (_currentPlaybackId >= 0)
        Sound.StopInstance(_currentPlaybackId)
        _currentPlaybackId = -1
    EndIf
    ; check if we need to kill a target
    If (target != None)
        ActorToken token = Library.TryGetActorToken(target)
        If (token == None || !token.IsApplied(Self))
            target = None ; assume target has dropped collar in the meantime
        Else
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Killing " + RealHandcuffs:Log.FormIdAsString(target) + " " + target.GetDisplayName() + " with explosive collar.", Library.Settings);
            EndIf
            token.UnapplyRestraint(Self)
        EndIf
    EndIf
    ; place a disabled object at the location of the explosion
    ObjectReference explodedCollar = None
    MiscObject explodedCollarMiscObject = GetExplodedCollar()
    If (target == None)
        ObjectReference explodedCollarLocation = GetContainer()
        If (explodedCollarLocation == None)
            explodedCollarLocation = Self
        EndIf
        If (explodedCollarMiscObject == None)
            If ((explodedCollarLocation as Actor) != None)
                explodedCollar = explodedCollarLocation.PlaceAtNode("Neck", Library.Resources.BobbyPin, 1, false, true, true, false)
            Else
                explodedCollar = explodedCollarLocation.PlaceAtMe(Library.Resources.BobbyPin, 1, false, true, true)
            EndIf
        Else
            If ((explodedCollarLocation as Actor) != None)
                explodedCollar = explodedCollarLocation.PlaceAtNode("Neck", explodedCollarMiscObject, 1, false, true, false, false)
            Else
                explodedCollar = explodedCollarLocation.PlaceAtMe(explodedCollarMiscObject, 1, false, true, false)
            EndIf
        EndIf
    Else
        If (explodedCollarMiscObject == None)
            explodedCollar = target.PlaceAtNode("Neck", Library.Resources.BobbyPin, 1, false, true, true, false)
        Else
            explodedCollar = target.PlaceAtNode("Neck", explodedCollarMiscObject, 1, false, true, true, false)
        EndIf
    EndIf
    ; explode the collar
    ObjectReference kaboom = explodedCollar.PlaceAtMe(ExplosiveCollarProjectile, 1, false, true, true)
    kaboom.EnableNoWait()
    If (explodedCollarMiscObject == None)
        explodedCollar.Delete()
    Else
        explodedCollar.SetPosition(explodedCollar.X, explodedCollar.Y, explodedCollar.Z + 3) ; move it up a bit to make it fly away in the explosion
        explodedCollar.EnableNoWait()
    EndIf
    If (target == None)
        Actor targetCorpse = GetContainer() as Actor
        If (targetCorpse != None && (targetCorpse.IsDead() || Library.SoftDependencies.IsArmorRack(targetCorpse)))
            targetCorpse.Dismember("Head1", targetCorpse.IsDead(), true, false)
        EndIf
    Else
        If (target.IsEssential())
            target.SetEssential(false) ; to make dismember more reliable
        EndIf
        target.Dismember("Head1", true, true, false)
        target.KillEssential()
    EndIf
    ; destroy the collar
    If (GetContainer() != None)
        Drop(true)
    EndIf
    DisableNoWait()
    Delete()
EndFunction

;
; Get the penalty applied to a collared actor who wants to pick the lock of the collar.
;
Int Function GetLockpickingPenalty()
    Return 25
EndFunction

;
; Schedule the terminal on the pipboy from a interaction, giving time to end the interaction first.
;
Function ScheduleShowTerminalOnPipboyInteraction(Bool moveToPlayerIfUnequipped, Bool openActorInventoryWhenFinished)
    Int timerId = ShowTerminalOnPipboyInteraction
    If (moveToPlayerIfUnequipped)
        timerId = ShowTerminalOnPipboyInteractionMoveToPlayerIfUnequipped
        If (openActorInventoryWhenFinished)
            timerId = ShowTerminalOnPipboyInteractionMoveToPlayerIfUnequippedOpenActorInventoryWhenFinished
        EndIf
    ElseIf (openActorInventoryWhenFinished)
        timerId = ShowTerminalOnPipboyInteractionOpenActorInventoryWhenFinished
    EndIf
    If (UI.IsMenuOpen("PipboyMenu"))
        UI.CloseMenu("PipboyMenu")
        StartTimer(0.8, timerId)
    ElseIf (UI.IsMenuOpen("ContainerMenu"))
        UI.CloseMenu("ContainerMenu")
        StartTimer(0.8, timerId)
    Else
        StartTimer(0.1, timerId)
    EndIf
EndFunction

;
; Show the terminal for the shock collar on the pipboy.
; This function will block until the pipboy closes. 
; Returns 1 if the collar was unequipped as a result, 2 if the collar will trigger as a result, 0 otherwise
;
Int Function ShowTerminalOnPipboy()
    ; copy shock collar data to terminal data
    TerminalData.Reset()
    If (HasKeyword(Library.Resources.MarkTwoFirmware))
        TerminalData.Flavor = TerminalData.MarkTwoFirmware
    ElseIf (HasKeyword(Library.Resources.MarkThreeFirmware))
        TerminalData.Flavor = TerminalData.MarkThreeFirmware
    ElseIf (HasKeyword(Library.Resources.HackedFirmware))
        TerminalData.Flavor = TerminalData.HackedFirmware
    Else
        RealHandcuffs:Log.Error("Unknown firmware detected.", Library.Settings)
    EndIf
    TerminalData.SetupPin(GetNumberOfAccessCodeDigits(), GetAccessCode(), ActionOnFailedAccessCodeEntry)
    Float lockoutTime = GetRemainingTerminalLockoutTime()
    If (lockoutTime > 0)
        TerminalData.RemainingLockoutTime = lockoutTime
        TerminalData.PinInputState = TerminalData.PinInputFailed
    EndIf
    Actor target = SearchCurrentTarget()
    If (target != None)
        TerminalData.CollarEnabled = true
    EndIf
    If (HasElectronicLock())
        If (target != None)
            TerminalData.ElectronicLockState = TerminalData.ElectronicLockLocked
        Else
            TerminalData.ElectronicLockState = TerminalData.ElectronicLockUnlocked
        EndIf
    Else
        TerminalData.ElectronicLockState = TerminalData.NoElectronicLock
    EndIf
    Int supportedTriggerModes = GetSupportedTriggerModes()
    If (supportedTriggerModes > 0)
        TerminalData.SupportedTriggerModes = supportedTriggerModes
        TerminalData.TriggerMode = GetTriggerMode()
    EndIf
    If (GetSupportsTortureMode())
        TerminalData.SupportsTortureMode = True
        TerminalData.TortureModeFrequency = GetTortureModeFrequency()
    EndIf
    ; close PipboyMenu/ContainerMenu if they are open
    If (UI.IsMenuOpen("PipboyMenu"))
        UI.CloseMenu("PipboyMenu")
        Utility.Wait(0.8)
    ElseIf (UI.IsMenuOpen("ContainerMenu"))
        UI.CloseMenu("ContainerMenu")
        Utility.Wait(0.8)
    EndIf
    Bool restoreThirdPersonCamera = false
    Actor player = Game.GetPlayer()
    If (!player.GetAnimationVariableBool("IsFirstPerson"))
        Game.ForceFirstPerson()
        restoreThirdPersonCamera = true
        Utility.Wait(0.1)
    EndIf
    If (Library.Settings.InfoLoggingEnabled)
        If (target == None)
            RealHandcuffs:Log.Info("Opening shock collar terminal.", Library.Settings)
        Else
            RealHandcuffs:Log.Info("Opening shock collar terminal for " + RealHandcuffs:Log.FormIdAsString(target) + " " + target.GetDisplayName() + ".", Library.Settings)
        EndIf
    EndIf
    ; show the terminal on pipboy
    Int waitCount = 0
    While (waitCount < 36 && !UI.IsMenuOpen("TerminalMenu"))
        If (target != None && target.IsDoingFavor())
            target.SetDoingFavor(false, false)
        EndIf
        If (UI.IsMenuOpen("DialogueMenu"))
            UI.CloseMenu("DialogueMenu")
        EndIf
        Int interactionType = Library.GetInteractionType()
        ObjectReference interactionTarget = Library.GetInteractionTarget()
        Int interactionLockLevel = Library.GetInteractionLockLevel()
        If (interactionType != 0)
            Library.ClearInteractionType()
        EndIf
        If ((waitCount % 12) == 0)
            GetTerminal().ShowOnPipboy()
        EndIf
        Utility.WaitMenuMode(0.1)
        waitCount += 1
    EndWhile
    If (UI.IsMenuOpen("TerminalMenu"))
        Utility.Wait(0.1)
        RealHandcuffs:Log.Info("Shock collar terminal closed.", Library.Settings)
    Else
        RealHandcuffs:Log.Warning("Unable to show terminal on pipboy.", Library.Settings)
    EndIf
    If (restoreThirdPersonCamera)
        Game.ForceThirdPerson()
    EndIf
    ; copy terminal data to shock collar
    If (TerminalData.RemainingLockoutTime > 0)
        StartTerminalLockout(TerminalData.RemainingLockoutTime)
    Else
        ClearTerminalLockout()
    EndIf
    If (TerminalData.PinInputState == TerminalData.PinInputSucceeded)
        SetAccessCode(TerminalData.StoredPin)
        ActionOnFailedAccessCodeEntry = TerminalData.WrongPinEnteredAction
        SetTriggerMode(TerminalData.TriggerMode)
        If (target != None && TerminalData.ElectronicLockState == TerminalData.ElectronicLockUnlocked)
            ForceUnequip()
            Return 1
        EndIf
        If (TerminalData.RestartTortureMode)
            SetTortureModeFrequency(TerminalData.TortureModeFrequency)
            RestartTortureMode(target)
            Return 2
        EndIf
    EndIf
    If (TerminalData.TriggerShock)
        If (target == None)
            Trigger(player, true)
        Else
            Trigger(target, true)
        EndIf
        Return 2
    EndIf
    Return 0
EndFunction

;
; Get the terminal for this shock collar.
;
Terminal Function GetTerminal()
    RealHandcuffs:Log.Error("Missing GetTerminal override in subclass.", Library.Settings)
    Return None
EndFunction

;
; Get the number of supported access code digits.
;
Int Function GetNumberOfAccessCodeDigits()
    Return 0
EndFunction

;
; Get the current access code (-1 for none).
;
Int Function GetAccessCode()
    If (_accessCode >= 0)
        Int numberOfDigits = GetNumberOfAccessCodeDigits()
        If (numberOfDigits > 0)
            Int maxValuePlusOne = 10
            While (numberOfDigits > 1)
                maxValuePlusOne *= 10
                numberOfDigits -= 1
            EndWhile
            Return _accessCode % maxValuePlusOne
        EndIf
    EndIf
    Return -1
EndFunction

;
; Set the current access code (-1 for none).
;
Function SetAccessCode(Int accessCode)
    _accessCode = accessCode
EndFunction

;
; Get or set the action to take on a failed access code entry.
; This must be one of the values in the ShockCollarTerminalData WrongPinEnteredAction group.
;
Int Property ActionOnFailedAccessCodeEntry = 0 Auto

;
; Set the terminal into lockout mode for the specified time.
;
Function StartTerminalLockout(Float durationHours)
    _clearTerminalLockoutTimestamp = Utility.GetCurrentGameTime() + durationHours / 24.0
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Set lockout to finish in " + durationHours + " hours.", Library.Settings)
    EndIf
EndFunction

;
; Get how many hours of terminal lockout mode are remaining; zero or less if lockout is not active.
;
Float Function GetRemainingTerminalLockoutTime()
    Return (_clearTerminalLockoutTimestamp - Utility.GetCurrentGameTime()) * 24.0
EndFunction

;
; Force-clear terminal lockout mode.
;
Function ClearTerminalLockout()
    _clearTerminalLockoutTimestamp = 0.0
EndFunction

;
; Get whether this shock collar has a electronic lock.
;
Bool Function HasElectronicLock()
    Return HasKeyword(Library.Resources.FirmwareControlledLock)
EndFunction

;
; Get the supporte trigger modes.
; This must be one of the values in the ShockCollarTerminalData SupportedTriggerModes group.
;
Int Function GetSupportedTriggerModes()
    Return TerminalData.SimpleTrigger
EndFunction

;
; Get the current trigger mode.
;
Int Function GetTriggerMode()
    Int supportedTriggerModes = GetSupportedTriggerModes()
    If (supportedTriggerModes == TerminalData.SimpleSignalTriggerOnly)
        Return 0
    ElseIf (supportedTriggerModes == TerminalData.SimpleSingleDoubleSignalTrigger)
        Return Math.Max(0, Math.Min(2, _triggerMode)) as Int
    ElseIf (supportedTriggerModes  == TerminalData.SimpleSingleDoubleTripleSignalTrigger)
        Return Math.Max(0, Math.Min(3, _triggerMode)) as Int
    Else
        RealHandcuffs:Log.Error("Detected unknown supported trigger modes.", Library.Settings)
        Return _triggerMode
    EndIf
EndFunction

;
; Set the current trigger mode.
;
Function SetTriggerMode(int triggerMode)
    _triggerMode = triggerMode
EndFunction

;
; Get the amount of temporary shock damage that triggering the collar will do.
;
Int Function GetTemporaryShockDamage()
    ; code smell: should find a better way than hardcoding the shock damage values here, but we need to know them such that we can catch up for the missed intervals
    If (HasKeyword(Library.Resources.DefaultShock))
        Return 70
    ElseIf (HasKeyword(Library.Resources.ThrobbingShock))
        Return 100
    EndIf
    Return 0
EndFunction

;
; Get whether torture mode is supported.
;
Bool Function GetSupportsTortureMode()
    Return False
EndFunction

;
; Get the torture mode frequency in hours.
;
Float Function GetTortureModeFrequency()
    If (!GetSupportsTortureMode())
        Return 0
    EndIf
    Return _tortureModeFrequency
EndFunction

;
; Set the torture mode frequency in hours.
;
Function SetTortureModeFrequency(Float frequency)
    _tortureModeFrequency = frequency
EndFunction

;
; Restart torture mode after setting frequency.
;
Function RestartTortureMode(Actor target)
    If (_tortureModeTargetTimestamp > 0.0)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Stopping torture mode for " + RealHandcuffs:Log.FormIdAsString(target) + " " + target.GetDisplayName() + ".", Library.Settings)
        EndIf
        CancelTimerGameTime(TortureTrigger)
        If (target == Game.GetPlayer())
            UnregisterForPlayerSleep()
        EndIf
        _tortureModeTargetTimestamp = 0.0
    EndIf
    Float frequency = GetTortureModeFrequency()
    If (frequency > 0 && target != None)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Starting torture mode for " + RealHandcuffs:Log.FormIdAsString(target) + " " + target.GetDisplayName() + ", frequency: " + frequency, Library.Settings)
        EndIf
        If (target != None)
            Trigger(target, true)
            _tortureModeTargetTimestamp = Utility.GetCurrentGameTime() + frequency / 24
            StartTimerGameTime(frequency, TortureTrigger)
            If (target == Game.GetPlayer())
                RegisterForPlayerSleep()
            EndIf
        EndIf
    EndIf
    RealHandcuffs:ActorToken token = Library.TryGetActorToken(target)
    If (token != None)
        token.ApplyStatefulEffects()
    EndIf
EndFunction

;
; Player sleep event for situations where player is in torture mode.
;
Event OnPlayerSleepStart(float afSleepStartTime, float afDesiredSleepEndTime, ObjectReference akBed)
    _playerSleeping = true
    If (_tortureModeTargetTimestamp > 0.0)
        Actor player = Game.GetPlayer()
        If (SearchCurrentTarget() != player)
            UnregisterForPlayerSleep() ; fallback code to prevent bugs if unequip was missed
            Return
        EndIf
        If (afDesiredSleepEndTime < _tortureModeTargetTimestamp)
            RealHandcuffs:Log.Info("Torture mode: Player starting to sleep but desiring to wake up before next shock.", Library.Settings)
        Else
            If (GetTortureModeFrequency() < 1)
                RealHandcuffs:Log.Info("Torture mode: Player starting to sleep, frequency is less than one hour, waking player.", Library.Settings)
                player.MoveTo(player, 0, 0, 0, true)
            Else
                Float hoursToNextShock = (_tortureModeTargetTimestamp - afSleepStartTime) * 24
                Int maxAllowedSleepTime = Math.Floor(hoursToNextShock)
                If (hoursToNextShock - (maxAllowedSleepTime as Float) >= 0.5) 
                    maxAllowedSleepTime += 1
                EndIf
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Torture mode: Player starting to sleep, allowing up to " + maxAllowedSleepTime + " hours of sleep.", Library.Settings)
                EndIf
                Float wakeTimestamp = afSleepStartTime + (maxAllowedSleepTime as Float) / 24.0
                CancelTimerGameTime(TortureTrigger)
                Bool playerSleepInterrupted = false
                While (Utility.GetCurrentGameTime() < wakeTimestamp && _playerSleeping)
                    Utility.WaitMenuMode(0.5)
                EndWhile
                If (_playerSleeping)
                    player.MoveTo(player, 0, 0, 0, true)
                    playerSleepInterrupted = true
                    RealHandcuffs:Log.Info("Torture mode: Interrupted player sleep.", Library.Settings)
                    Utility.Wait(1.0)
                EndIf
                If (GetTortureModeFrequency() > 0) ; fallback in case torture mode got disbled during sleep
                    If (playerSleepInterrupted || Utility.GetCurrentGameTime() >= _tortureModeTargetTimestamp)
                        RealHandcuffs:Log.Info("Torture mode: Restarting after player sleep.", Library.Settings)
                        RestartTortureMode(player)
                    Else
                        StartTimerGameTime((_tortureModeTargetTimestamp - Utility.GetCurrentGameTime()) * 24.0, TortureTrigger)
                    EndIf
                EndIf
            EndIf
        EndIf
    EndIf
EndEvent

;
; Player sleep event for situations where player is in torture mode.
;
Event OnPlayerSleepStop(bool abInterrupted, ObjectReference akBed)
    _playerSleeping = false
EndEvent

;
; Group for timer events
;
Group Timers
    Int Property ShowTerminalOnPipboyInteraction = 1000 AutoReadOnly
    Int Property ShowTerminalOnPipboyInteractionMoveToPlayerIfUnequipped = 1001 AutoReadOnly
    Int Property DoTrigger = 1002 AutoReadOnly
    Int Property ShowTerminalOnPipboyInteractionOpenActorInventoryWhenFinished = 1003 AutoReadOnly
    Int Property ShowTerminalOnPipboyInteractionMoveToPlayerIfUnequippedOpenActorInventoryWhenFinished = 1004 AutoReadOnly
    Int Property TortureTrigger = 1005 AutoReadOnly
EndGroup

;
; Continue interactions on timer event.
;
Event OnTimer(int aiTimerID)
    If (aiTimerID == ShowTerminalOnPipboyInteraction || aiTimerID == ShowTerminalOnPipboyInteractionMoveToPlayerIfUnequipped || aiTimerID == ShowTerminalOnPipboyInteractionOpenActorInventoryWhenFinished || aiTimerID == ShowTerminalOnPipboyInteractionMoveToPlayerIfUnequippedOpenActorInventoryWhenFinished)
        Bool moveToPlayerIfUnequipped = (aiTimerID == ShowTerminalOnPipboyInteractionMoveToPlayerIfUnequipped || aiTimerID == ShowTerminalOnPipboyInteractionMoveToPlayerIfUnequippedOpenActorInventoryWhenFinished)
        Actor openActorInventoryWhenFinished = None
        If (aiTimerID == ShowTerminalOnPipboyInteractionOpenActorInventoryWhenFinished || aiTimerID == ShowTerminalOnPipboyInteractionMoveToPlayerIfUnequippedOpenActorInventoryWhenFinished)
            openActorInventoryWhenFinished = SearchCurrentTarget()
        EndIf
        Int terminalResult = ShowTerminalOnPipboy()
        If (terminalResult == 1 && moveToPlayerIfUnequipped)
            Drop(false)
            Game.GetPlayer().AddItem(Self, 1, false)
        EndIf
        If (terminalResult != 2 && openActorInventoryWhenFinished != None && openActorInventoryWhenFinished != Game.GetPlayer())
            Utility.Wait(0.5)
            Library.ClearInteractionType()
            openActorInventoryWhenFinished.OpenInventory()
        Else
            Library.ClearInteractionType()
        EndIf
    ElseIf (aiTimerID == DoTrigger)
        Actor akTarget = SearchCurrentTarget()
        If (akTarget == None)
            akTarget = GetContainer() as Actor
        EndIf
        TriggerInternal(akTarget)
    Else
        Parent.OnTimer(aiTimerID)
    EndIf
EndEvent

;
; Timer event for torture mode.
;
Event OnTimerGameTime(int aiTimerID)
    If (aiTimerID == TortureTrigger)
        Float frequency = GetTortureModeFrequency()
        Actor target = SearchCurrentTarget()
        If (frequency <= 0 || target == None) ; not expected but be defeinsive
            _tortureModeTargetTimestamp = 0.0
            UnregisterForPlayerSleep()
            Return
        EndIf
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Torture mode: Timer elapsed for victim " + RealHandcuffs:Log.FormIdAsString(target) + " " + target.GetDisplayName() + ".", Library.Settings)
        EndIf
        Float currentGameTime = Utility.GetCurrentGameTime()
        Float hoursToTargetTimestamp = (_tortureModeTargetTimestamp - currentGameTime) * 24
        If (hoursToTargetTimestamp < -0.0833)
            ; target time is over since more than five (game) minutes, skip ahead
            Int intervalsToSkip = Math.Ceiling(-hoursToTargetTimestamp / frequency)
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Torture mode: hoursToTargetTimestamp=" + hoursToTargetTimestamp + ", skipping ahead by " + intervalsToSkip + " intervals.", Library.Settings)
            EndIf
            If (Library.SoftDependencies.JBCompatibilityActive && Library.Settings.ShockCollarJBSubmissionWeight > 0.0 && (Library.SoftDependencies.IsSlave(target) || Library.SoftDependencies.IsEscapedSlave(target)))
                Float shockDamage = GetTemporaryShockDamage()
                Float submissionValue = RealHandcuffs:TemporaryShockDamageDecayEffect.CalculateShockHealthPercent(shockDamage) * Library.Settings.ShockCollarJBSubmissionWeight * 0.5
                submissionValue *= intervalsToSkip
                If (Library.SoftDependencies.IncrementJBSubmission(target, submissionValue))
                    If (Library.Settings.InfoLoggingEnabled)
                        RealHandcuffs:Log.Info("Torture mode: Incremented submission of " + RealHandcuffs:Log.FormIdAsString(target) + " " + target.GetDisplayName() + " by " + submissionValue + " for missed intervals.", Library.Settings)
                    EndIf
                Else
                    RealHandcuffs:Log.Info("Torture mode: Failed to increment submission.", Library.Settings)
                EndIf
            EndIf
            _tortureModeTargetTimestamp += frequency * (intervalsToSkip as Float) / 24.0
            hoursToTargetTimestamp += frequency * (intervalsToSkip as Float)
        EndIf
        If (Math.Abs(hoursToTargetTimestamp) < 0.0833)
            ; we are within five (game) minutes of target timestamp, trigger the collar
            If (target.GetParentCell().IsAttached())
                Trigger(target, true)
            ElseIf (Library.SoftDependencies.JBCompatibilityActive && Library.Settings.ShockCollarJBSubmissionWeight > 0.0 && (Library.SoftDependencies.IsSlave(target) || Library.SoftDependencies.IsEscapedSlave(target)))
                Float shockDamage = GetTemporaryShockDamage()
                Float submissionValue = RealHandcuffs:TemporaryShockDamageDecayEffect.CalculateShockHealthPercent(shockDamage) * Library.Settings.ShockCollarJBSubmissionWeight * 0.5
                If (Library.SoftDependencies.IncrementJBSubmission(target, submissionValue))
                    If (Library.Settings.InfoLoggingEnabled)
                        RealHandcuffs:Log.Info("Torture mode: Incremented submission of " + RealHandcuffs:Log.FormIdAsString(target) + " " + target.GetDisplayName() + " by " + submissionValue + ".", Library.Settings)
                    EndIf
                Else
                    RealHandcuffs:Log.Info("Torture mode: Failed to increment submission.", Library.Settings)
                EndIf
            EndIf
            _tortureModeTargetTimestamp += frequency / 24
            hoursToTargetTimestamp += frequency
        EndIf
        While (hoursToTargetTimestamp < 0) ; not expected but be defensive
            _tortureModeTargetTimestamp += frequency / 24
            hoursToTargetTimestamp += frequency
        EndWhile
        StartTimerGameTime(hoursToTargetTimestamp, TortureTrigger)
    Else
        Parent.OnTimerGameTime(aiTimerID)
    EndIf
EndEvent