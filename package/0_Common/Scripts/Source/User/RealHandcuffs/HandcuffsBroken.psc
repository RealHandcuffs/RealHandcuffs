;
; Script attached to a broken handcuffs instance.
;
Scriptname RealHandcuffs:HandcuffsBroken extends RealHandcuffs:HandcuffsBase

Armor Property DummyHandcuffsBroken Auto Const Mandatory

Bool _restoreFirstPersonCamera

;
; Override: Get the chance to reach an item in the inventory if the handcuffs are currently worn (0-100).
;
Int Function GetReachInventoryItemChance()
    Return 100
EndFunction

;
; Override: Get the chance to unlock the handcuffs with the key in the hand if they are currently worn (0-100).
;
Int Function GetUnlockWithKeyChance()
    Return 100
EndFunction

;
; Override: Get a 'priority' value that is used to resolve conflicts between restraints.
;
Int Function GetPriority()
    Return 0
EndFunction

;
; Override: Get the impact caused by waring the restraint.
;
String Function GetImpact()
    Return Library.NoImpact
EndFunction

;
; Override: Get the penalty applied to a bound actor who wants to pick a lock.
;
Int Function GetLockpickingPenalty()
    Return 0
EndFunction

;
; Override: Get a 'dummy' armor that can be used to visually represent the restraint.
;
Armor Function GetDummyObject()
    Return DummyHandcuffsBroken
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
    If (!Library.GetHandsBoundBehindBack(player) && !(target != player && Library.SoftDependencies.IsActorDeviousDevicesBound(player)))
        If (target == player)
            Bool showEquipInteraction = true
            If (HasKeyword(Library.Resources.TimedLock) && HasKeyword(Library.Resources.TimeDial))
                Int selection = Library.Resources.MsgBoxActivateHandcuffsWithTimedLock.Show(GetTimedLockDuration())
                While (selection == 0)
                    selection = Library.Resources.MsgBoxChangeTimedLockDuration.Show()
                    SetTimedLockDuration(selection+1)
                    selection = Library.Resources.MsgBoxActivateHandcuffsWithTimedLock.Show(GetTimedLockDuration())
                EndWhile
                If (selection == 2)
                    showEquipInteraction = false
                EndIf
            EndIf
            If (showEquipInteraction)
                Int selection = Library.Resources.MsgBoxSelfEquipHandcuffsBrokenPart1.Show()
                If (selection == 0)
                    SetDefaultParameters(player)
                    selection = Library.Resources.MsgBoxSelfEquipHandcuffsBrokenPart2.Show()
                    Tightness = selection
                    equipped = true
                EndIf
            EndIf
        Else
            If (Library.IsFemale(target))
                Library.Resources.MsgNpcLockHandcuffsBrokenFemale.Show()
            Else
                Library.Resources.MsgNpcLockHandcuffsBrokenMale.Show()
            EndIf
            SetDefaultParameters(target)
            equipped = true
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
    If (HasKeyword(Library.Resources.TimedLock))
        Float remainingTime = GetRemainingTimedLockTimer()
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Interacting with time-locked handcuffs, remaining time: " + remainingTime, Library.Settings)
        EndIf
        If (remainingTime <= 0)
            ; fallback code in case timed lock has failed or is delayed
            Library.ClearInteractionType()
            If (target == player)
                Library.Resources.MsgBoxSelfHandcuffsBrokenTimedLockUnlocks.Show()
            EndIf
            Return true
        EndIf
    EndIf
    Bool unequipped = false
    Form keyObject = GetKeyObject()
    If (target == player)
        If (keyObject != None && player.GetItemCount(keyObject) > 0)
            Library.Resources.MsgUnlockHandcuffsWithKey.Show()
            unequipped = true
        ElseIf (!UI.IsMenuOpen("ContainerMenu"))
            Return StartPlayerUnequipInteraction() ; interaction may continue, don't clear interaction type
        EndIf
    ElseIf (Library.GetHandsBoundBehindBack(player) || Library.SoftDependencies.IsActorDeviousDevicesBound(player))
        Library.Resources.MsgBondsPreventUnlockingOfHandcuffs.Show()
    Else
        If (HasKeyword(Library.Resources.TimedLock))
            If (Library.IsFemale(target))
                Library.Resources.MsgBoxNpcUnlockHandcuffsTimedLockFemale.Show()
            Else
                Library.Resources.MsgBoxNpcUnlockHandcuffsTimedLockMale.Show()
            EndIf
        ElseIf (keyObject != None && player.GetItemCount(keyObject) > 0)
            Library.Resources.MsgUnlockHandcuffsWithKey.Show()
            unequipped = true
        Else
            If (Library.HasPlayerLockpickingSkill())
                Int selection
                If (Library.IsFemale(target))
                    selection = Library.Resources.MsgBoxNpcUnlockHandcuffsBrokenNoKeyFemale.Show()
                Else
                    selection = Library.Resources.MsgBoxNpcUnlockHandcuffsBrokenNoKeyMale.Show()
                EndIf
                If (selection == 0)
                    unequipped = Library.RunPlayerLockpickInteraction()
                EndIf
            Else
                If (Library.IsFemale(target))
                    Library.Resources.MsgBoxNpcUnlockHandcuffsBrokenNoKeyFemaleLPSkillNotHighEnough.Show()
                Else
                    Library.Resources.MsgBoxNpcUnlockHandcuffsBrokenNoKeyMaleLPSkillNotHighEnough.Show()
                EndIf
            EndIf
        EndIf
    EndIf
    Library.ClearInteractionType()
    Return unequipped
EndFunction

;
; Override: Open the restraint using the timed lock. This function is called when the timed lock runs out.
;
Function OpenTimedLock()
    If (HasKeyword(Library.Resources.Locked))
        StopTimedLockTimer() ; may do nothing
        Actor player = Game.GetPlayer()
        If (GetContainer() == player && Library.GetOrCreateActorToken(player).IsApplied(Self))
            Library.Resources.MsgBoxSelfHandcuffsBrokenTimedLockUnlocks.Show()
        EndIf
        ForceUnequip()
    EndIf
EndFunction

;
; Start the player unequip interaction.
;
Bool Function StartPlayerUnequipInteraction()
    If (Library.GetInteractionType() != Library.InteractionTypePlayer) ; not expected but check to be sure
        Library.ClearInteractionType()
        Return false
    EndIf
    Int selection
    If (Tightness == 2)
        selection = Library.Resources.MsgBoxSelfHandcuffsBrokenRatherLoose.Show()
    ElseIf (Tightness == 1)
        selection = Library.Resources.MsgBoxSelfHandcuffsBrokenQuiteTight.Show()
    Else
        selection = Library.Resources.MsgBoxSelfHandcuffsBrokenVeryTight.Show()
    EndIf
    If (selection == 0)
        PlayStruggleAnimation(StruggleToEscape)
        Return false ; interaction continues, don't clear interaction type
    ElseIf (selection == 1)
        Return PlayerStartInvestigateLock() ; interaction may continue, don't clear interaction type
    ElseIf (selection == 3)
        Tightness -= 1
    EndIf
    Library.ClearInteractionType()
    Return false
EndFunction

;
; Play the struggle animation and call a timer after it has finished.
;
Function PlayStruggleAnimation(Int timer)
    If (UI.IsMenuOpen("PipboyMenu"))
        UI.CloseMenu("PipboyMenu")
        Utility.Wait(0.4)
    EndIf
    _restoreFirstPersonCamera = false;
    If (Game.GetPlayer().GetAnimationVariableBool("IsFirstPerson"))
        Game.ForceThirdPerson()
        _restoreFirstPersonCamera = true
        Utility.Wait(0.1)
    EndIf
    Game.GetPlayer().PlayIdle(Library.Resources.LockedBraceletsStruggle)
    If (timer > 0)
        StartTimer(5, timer)
    Else
        StartTimer(5, RestoreFirstPersonCamera)
    EndIf
EndFunction

;
; Handle the result of the 'struggle to escape' unequip subinteraction.
;
Function PlayerAfterStruggleToEscape()
    If (Library.GetInteractionType() != Library.InteractionTypePlayer) ; not expected but check to be sure
        Library.ClearInteractionType()
        Return
    EndIf
    If (Tightness == 2)
        RealHandcuffs:Log.Info("Player struggled out of handcuffs (auto-success).", Library.Settings)
        Library.Resources.MsgSlipOutOfHandcuffs.Show()
        ForceUnequip()
    ElseIf (Tightness == 1)
        Int chance = GetStruggleOutOfHandcuffsChance()
        Int d100 = Utility.RandomInt(1, 100)
        If (d100 <= chance)
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Player struggled out of handcuffs (" + d100 + "&lt;=" + chance + ").", Library.Settings)
            EndIf
            Library.Resources.MsgSlipOutOfHandcuffs.Show()
            ForceUnequip()
        Else
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Player failed to struggle out of handcuffs (" + d100 + "&gt;" + chance + ").", Library.Settings)
            EndIf
            Int selection = Library.Resources.MsgBoxStruggleFailToEscapeBrokenHandcuffsQuiteTight.Show()
            If (selection == 0)
                PlayStruggleAnimation(StruggleFeebly)
                Return ; interaction continues, don't clear interaction type
            EndIf
        EndIf
    Else
        RealHandcuffs:Log.Info("Player failed to struggle out of handcuffs (auto-failure).", Library.Settings)
        Int selection = Library.Resources.MsgBoxStruggleFailToEscapeBrokenHandcuffsVeryTight.Show()
        If (selection == 0)
            PlayStruggleAnimation(StruggleToEscape)
            Return ; interaction continues, don't clear interaction type
        EndIf
    EndIf
    Library.ClearInteractionType()
EndFunction

;
; Start the 'investigate the lock' subinteraction.
;
Bool Function PlayerStartInvestigateLock()
    ; the target of this interaction can be either the player or a door
    Int interactionType = Library.GetInteractionType()
    If (interactionType != Library.InteractionTypePlayer) ; not expected but check to be sure
        Library.ClearInteractionType()
        Return false
    EndIf
    Bool success = false
    Actor player = Game.GetPlayer()
    ActorToken token = Library.GetOrCreateActorToken(player)
    Form keyObject
    If (interactionType == Library.InteractionTypePlayer)
        keyObject = GetKeyObject()
    Else
        keyObject = Library.GetInteractionTarget().GetKey()
    EndIf
    If (HasKeyword(Library.Resources.TimedLock))
        Library.Resources.MsgBoxSelfHandcuffsBrokenTimedLock.Show()
    ElseIf (keyObject != None && Player.GetItemCount(keyObject) == 1)
        Int selection = Library.Resources.MsgBoxSelfHandcuffsBrokenKeyInInventory.Show()
        If (selection == 0)
            ForceUnequip()
            success = true
        EndIf
    ElseIf (!Library.HasPlayerLockpickingSkill())
        Library.Resources.MsgBoxSelfHandcuffsBrokenNoKeyLockpickingSkillNotHighEnough.Show()
    ElseIf (player.GetItemCount(Library.Resources.BobbyPin) == 0)
        Library.Resources.MsgBoxSelfHandcuffsBrokenNoKeyNoBobbyPins.Show()
    Else
        Int selection = Library.Resources.MsgBoxSelfHandcuffsBrokenNoKeyBobbyPinsInInventory.Show()
        If (selection == 0)
            Bool unlocked = Library.RunPlayerLockpickInteraction()
            If (unlocked)
                ForceUnequip()
                success = true
            EndIf
        EndIf
    EndIf
    Library.ClearInteractionType()
    Return success
EndFunction