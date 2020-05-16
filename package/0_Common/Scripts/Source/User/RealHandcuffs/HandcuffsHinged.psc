;
; Script attached to a hinged handcuffs instance.
;
Scriptname RealHandcuffs:HandcuffsHinged extends RealHandcuffs:HandcuffsBase

Armor Property DummyHandcuffsHinged Auto Const Mandatory
ObjectMod Property ModArmsCuffedBehindBackHinged Auto Const Mandatory

;
; If the lock is facing away from the hands, the hands of victim cannot reach the lock.
;
Bool Property LockFacingAwayFromHands Auto

;
; Override: Get a 'dummy' armor that can be used to visually represent the restraint.
;
Armor Function GetDummyObject()
    Return DummyHandcuffsHinged
EndFunction


;
; Replace the mods of this instance by cloning mods from another restraint.
;
Function CloneModsFrom(RealHandcuffs:RestraintBase otherRestraint)
    Parent.CloneModsFrom(otherRestraint)
    SetPoseMod(ModArmsCuffedBehindBackHinged)
EndFunction

;
; Override: Break the handcuffs. This will delete the instance on success.
;
Bool Function BreakHandcuffs()
    AttachMod(Library.Converter.ModRemoveHinges, 0)
    Return Library.Converter.ConvertRestraint(Self)
EndFunction

;
; Override: Get the chance to struggle out the handcuffs if they are currently worn (0-100).
;
Int Function GetStruggleOutOfHandcuffsChance()
    If (Tightness == 2)
        Return 100
    ElseIf (Tightness == 1)
        Int chance = Library.Settings.HandcuffsOnBackStruggleChance * (100 - Library.Settings.HingedHandcuffsStrugglePenalty) / 100
        If (chance == 0 && Library.Settings.HandcuffsOnBackStruggleChance > 0)
            chance = 1
        EndIf
        Return chance
    Else
        Return 0
    EndIf
EndFunction

;
; Override: Get the chance to reach an item in the inventory if the handcuffs are currently worn (0-100).
;
Int Function GetReachInventoryItemChance()
    Int chance = Library.Settings.HandcuffsOnBackReachItemChance * (100 - Library.Settings.HingedHandcuffsStrugglePenalty) / 100
    If (chance == 0 && Library.Settings.HandcuffsOnBackReachItemChance > 0)
        chance = 1
    EndIf
    Return chance
EndFunction

;
; Override: Get the chance to unlock the handcuffs with the key in the hand if they are currently worn (0-100).
;
Int Function GetUnlockWithKeyChance()
    If (LockFacingAwayFromHands)
        Return 0
    EndIf
    Return Library.Settings.HandcuffsOnBackUnlockChance
EndFunction

;
; Override: Set the default parameters for restraints that can be equipped in different ways.
;
Function SetDefaultParameters(Actor target)
    Parent.SetDefaultParameters(target)
    LockFacingAwayFromHands = true
EndFunction

; Copy the parameters for restraints that can be equipped in different ways from another restraint.
; This is called automatically when a restraint is applied as replacement for another restraint.
;
Function CopyParametersFrom(RealHandcuffs:RestraintBase restraint)
    Parent.CopyParametersFrom(restraint)
    RealHandcuffs:HandcuffsHinged handcuffs = restraint as RealHandcuffs:HandcuffsHinged
    If (handcuffs != None)
        LockFacingAwayFromHands = handcuffs.LockFacingAwayFromHands
    EndIf
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
    Bool equipped = false
    If (target == player && !HasKeyword(Library.Resources.TimedLock)) ; no reason to choose facing for timed locks
        If (Library.GetHandsBoundBehindBack(player) || !Library.TrySetInteractionType(interactionType, target, GetLockLevel()))
            Return false
        EndIf
        Bool showEquipInteraction = true
        If (showEquipInteraction)
            Int selection = Library.Resources.MsgBoxSelfEquipHandcuffsHingedOnBackPart1.Show()
            If (selection < 2)
                SetDefaultParameters(player)
                LockFacingAwayFromHands = selection == 0
                Tightness = 2 ; use "rather loose" for now, will be updated in EquipPartTwo
                equipped = true
                StartTimer(1.0, EquipPartTwo)
            EndIf
        EndIf
        Library.ClearInteractionType()
    Else
        equipped = Parent.EquipInteraction(target)
    EndIf
    Return equipped
EndFunction

;
; Override: Start the player cut handcuffs with tools interaction.
;
Bool Function StartPlayerUseToolsInteraction(ObjectReference workshopRef)
    If (Library.GetInteractionType() != Library.InteractionTypePlayer) ; not expected but check to be sure
        Library.ClearInteractionType()
        Return false
    EndIf
    Int selection = Library.Resources.MsgBoxSelfHandcuffsOnBackUseWorkshopTools.Show()
    If (selection == 0)
        selection = Library.Resources.MsgBoxSelfHandcuffsHingedOnBackCutWithWorkshopTools.Show()
        If (selection == 0)
            Actor player = Game.GetPlayer()
            Int chance = (player.GetValue(Game.GetAgilityAV()) * 7) as Int
            Int d100 = Utility.RandomInt(1, 100)
            If (d100 <= chance)
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Player cut handcuffs (" + d100 + "&lt;=" + chance + ").", Library.Settings)
                EndIf
                Library.Resources.MsgBoxSelfHandcuffsHingedOnBackCutWithWorkshopToolsSuccess.Show()
            Else
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Player cut handcuffs but got hurt (" + d100 + "&gt;" + chance + ").", Library.Settings)
                EndIf
                Library.Resources.MsgBoxSelfHandcuffsHingedOnBackCutWithWorkshopToolsSuccessHurt.Show()
                ; reduce health by 30% of max health
                Float baseHealth = player.GetBaseValue(Game.GetHealthAV())
                player.DamageValue(Game.GetHealthAV(), baseHealth * 0.3)
                ; cripple one of the arms
                ActorValue armCondition = None
                If (Utility.RandomInt(0, 1) == 0)
                    armCondition = Library.Resources.LeftAttackCondition
                Else
                    armCondition = Library.Resources.RightAttackCondition
                EndIf
                player.DamageValue(armCondition, player.GetValue(armCondition))
            EndIf
            Library.ClearInteractionType()
            Return true
        EndIf
    EndIf
    Library.ClearInteractionType()
    Return false
EndFunction

;
; Override: Start the player unequip interaction.
;
Bool Function StartPlayerUnequipInteraction()
    If (Library.GetInteractionType() != Library.InteractionTypePlayer) ; not expected but check to be sure
        Library.ClearInteractionType()
        Return false
    EndIf
    Int selection
    If (Tightness == 2)
        selection = Library.Resources.MsgBoxSelfHandcuffsHingedOnBackRatherLoose.Show()
    ElseIf (Tightness == 1)
        selection = Library.Resources.MsgBoxSelfHandcuffsHingedOnBackQuiteTight.Show()
    Else
        selection = Library.Resources.MsgBoxSelfHandcuffsHingedOnBackVeryTight.Show()
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
; Overide Start the 'investigate the lock' subinteraction.
;
Bool Function PlayerStartInvestigateLock()
    ; the target of this interaction can be either the player or a door
    Int interactionType = Library.GetInteractionType()
    If (interactionType == Library.InteractionTypePlayer && !HasKeyword(Library.Resources.TimedLock) && LockFacingAwayFromHands)
        Library.Resources.MsgBoxSelfHandcuffsHingedOnBackCannotReachLock.Show()
        Library.ClearInteractionType()
        Return false
    EndIf
    Return Parent.PlayerStartInvestigateLock()
EndFunction

;
; Override: Set internal state after the restraint has been equipped and applied.
;
Function SetStateAfterEquip(Actor target, Bool interactive)
    CancelTimer(EquipAfterPoseModChange)
    Parent.SetStateAfterEquip(target, interactive)
    ObjectMod poseMod = ModArmsCuffedBehindBackHinged
    If (SetPoseMod(poseMod))
        ActorToken token = Library.TryGetActorToken(target)
        If (token != None)
            token.RefreshEffectsAndAnimations(false, None)
        EndIf
        If (target != Game.GetPlayer())
            StartTimer(0.1, UnequipAfterPoseModChange)
        EndIf
    EndIf
EndFunction

;
; Override: Set internal state after the restraint has been unequipped and unapplied.
;
Function SetStateAfterUnequip(Actor target, Bool interactive)
    CancelTimer(UnequipAfterPoseModChange)
    Parent.SetStateAfterUnequip(target, interactive)
EndFunction

;
; Group for timer events
;
Group Timers
    Int Property UnequipAfterPoseModChange = 2000 AutoReadOnly
    Int Property EquipAfterPoseModChange = 2001 AutoReadOnly
EndGroup

;
; Continue equip interaction.
;
Event OnTimer(int aiTimerID)
    If (aiTimerID == UnequipAfterPoseModChange)
        Actor target = GetContainer() as Actor
        Form baseObject = GetBaseObject()
        If (target != None && target.IsEquipped(baseObject))
            target.UnequipItem(baseObject, false, true) ; should get reverted
        EndIf
        StartTimer(0.1, EquipAfterPoseModChange) ; in case it did not get reverted
    ElseIf (aiTimerID == EquipAfterPoseModChange)
        Actor target = GetContainer() as Actor
        Form baseObject = GetBaseObject()
        If (target != None && !target.IsEquipped(baseObject))
            ForceEquip(target)
        EndIf
    Else
        Parent.OnTimer(aiTimerID)
    EndIf
EndEvent