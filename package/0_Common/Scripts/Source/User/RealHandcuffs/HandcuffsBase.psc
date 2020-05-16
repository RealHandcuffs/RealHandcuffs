;
; Abstract base class for all handcuffs.
;
Scriptname RealHandcuffs:HandcuffsBase extends RealHandcuffs:RestraintBase

;
; 0: very thight, 1: quite tight, 2: rather loose
;
Int Property Tightness Auto
Float _lastPickUpItemTimestamp
Bool _restoreFirstPersonCamera

;
; Set the lock mod of the handcuffs. Returns true if the mod was changed.
; Note that doing this on handcuffs that are currently worn by an NPC will not fully work,
; you will need to unequip and requip them.
;
Bool Function SetLockMod(ObjectMod lockMod)
    If (!ReplaceMod(Library.Resources.LockTag, lockMod))
        Return false
    EndIf
    StopTimedLockTimer() ; may do nothing
    If (HasKeyword(Library.Resources.TimedLock) && SearchCurrentTarget() != None)
        ; start timed lock timer after replacing lock with timed lock
        StartTimedLockTimer(GetTimedLockDuration())
    EndIf
    Return true
EndFunction

;
; Set the pose mod of the handcuffs. Returns true if the mod was changed.
; Note that doing this on handcuffs that are currently worn by an NPC will not fully work,
; you will need to unequip and requip them.
;
Bool Function SetPoseMod(ObjectMod poseMod)
    Return ReplaceMod(Library.Resources.PoseTag, poseMod)
EndFunction

;
; Replace the mods of this instance by cloning mods from another restraint.
;
Function CloneModsFrom(RealHandcuffs:RestraintBase otherRestraint)
    ObjectMod[] mods = otherRestraint.GetAllMods()
    Int index = 0
    While (index < mods.Length)
        If (Library.IsAddingKeyword(mods[index], Library.Resources.LockTag))
            ReplaceMod(Library.Resources.LockTag, mods[index])
            If (HasKeyword(Library.Resources.TimedLock) && HasKeyword(Library.Resources.TimeDial))
                SetTimedLockDuration(otherRestraint.GetTimedLockDuration())
            EndIf
        EndIf
        index += 1
    EndWhile
EndFunction

;
; Get the chance to struggle out the handcuffs if they are currently worn (0-100).
;
Int Function GetStruggleOutOfHandcuffsChance()
    If (Tightness == 2)
        Return 100
    ElseIf (Tightness == 1)
        Return Library.Settings.HandcuffsOnBackStruggleChance
    Else
        Return 0
    EndIf
EndFunction

;
; Get the chance to reach an item in the inventory if the handcuffs are currently worn (0-100).
;
Int Function GetReachInventoryItemChance()
    Return Library.Settings.HandcuffsOnBackReachItemChance
EndFunction

;
; Get the chance to unlock the handcuffs with the key in the hand if they are currently worn (0-100).
;
Int Function GetUnlockWithKeyChance()
    Return Library.Settings.HandcuffsOnBackUnlockChance
EndFunction

;
; Break the handcuffs. This will delete the instance on success.
;
Bool Function BreakHandcuffs()
    Return false 
EndFunction

;
; Override: Get the MT animation for the arms when the restraing is being worn.
;
Keyword Function GetMtAnimationForArms()
    If (GetImpact() != Library.HandsBoundBehindBack)
        Return None
    EndIf
    ; the animation keyword is added by a pose mod, so search for a mod that adds:
    ; - first the "PoseTag" keyword (tagging the mod as a pose mod)
    ; - then another keyword, return that keyword
    ; the order is important; if there are further keywords, they will be ignored
    ObjectMod[] mods = GetAllMods()
    Int index = 0
    While (index < mods.Length)
        ObjectMod mod = mods[index]
        ObjectMod:PropertyModifier[] modifiers = mod.GetPropertyModifiers()
        Int modifierIndex = 0
        Bool isPoseMod = false
        While (modifierIndex < modifiers.length)
            ObjectMod:PropertyModifier modifier = modifiers[modifierIndex]
            If (modifier.operator == mod.Modifier_Operator_Add)
                Keyword kw = modifier.object as Keyword
                If (kw == Library.Resources.PoseTag)
                    isPoseMod = true
                ElseIf (isPoseMod && kw != None)
                    Return kw ; return the first keyword after the PoseTag keyword
                EndIf
            EndIf
            modifierIndex += 1
        EndWhile
        index += 1
    EndWhile
    RealHandcuffs:Log.Warning("Unable to find MT animation keyword for " + GetDisplayName() + " " + RealHandcuffs:Log.FormIdAsString(Self) + "." , Library.Settings)
    Return None    
EndFunction

;
; Override: Set the default parameters for restraints that can be equipped in different ways.
;
Function SetDefaultParameters(Actor target)
    Tightness = 0
    If (target != None)
        ActorToken token = Library.TryGetActorToken(target)
        If (token != None)
            token.ItemInHand = None
        EndIf
    EndIf
EndFunction

; Copy the parameters for restraints that can be equipped in different ways from another restraint.
; This is called automatically when a restraint is applied as replacement for another restraint.
;
Function CopyParametersFrom(RealHandcuffs:RestraintBase restraint)
    RealHandcuffs:HandcuffsBase handcuffs = restraint as RealHandcuffs:HandcuffsBase
    If (handcuffs != None)
        If (HasKeyword(Library.Resources.TimedLock))
            Float remainingTimedLockTimer = restraint.GetRemainingTimedLockTimer()
            If (remainingTimedLockTimer > 0)
                StartTimedLockTimer(remainingTimedLockTimer)
            EndIf
        EndIf
        Tightness = handcuffs.Tightness
    EndIf
EndFunction

;
; Override: Get a 'priority' value that is used to resolve conflicts between restraints.
;
Int Function GetPriority()
    Return 100
EndFunction

;
; Override: Get the item slots.
;
Int[] Function GetSlots()
    If (Library.SoftDependencies.DDCompatibilityActive)
        Int[] slots = new Int[2]
        slots[0] = 37
        slots[1] = 38
        Return slots
    Else
        Int[] slots = new Int[1]
        slots[0] = 54
        Return slots
    EndIf
EndFunction

;
; Override: Get the impact caused by waring the restraint.
;
String Function GetImpact()
    Return Library.HandsBoundBehindBack
EndFunction

;
; Override: Get the key that will unlock the restraint.
;
Form Function GetKeyObject()
    If (HasKeyword(Library.Resources.EasyLock))
        Return Library.Converter.HandcuffsKey
    EndIf
    If (HasKeyword(Library.Resources.HighSecurityLock))
        Return Library.Converter.HighSecurityHandcuffsKey
    EndIf
    Return None
EndFunction

;
; Override: Get the level of the lock.
;
Int Function GetLockLevel()
    If (HasKeyword(Library.Resources.EasyLock))
        Return Library.Settings.HandcuffsLockLevel
    EndIf
    If (HasKeyword(Library.Resources.HighSecurityLock))
        Return Library.Settings.HandcuffsLockLevelHighSecurity
    EndIf
    Return 254 ; inaccessible
EndFunction

;
; Get the penalty applied to a bound actor who wants to pick a lock.
;
Int Function GetLockpickingPenalty()
    Return Library.Settings.HandcuffsOnBackLockpickingPenality
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
                Int selection = Library.Resources.MsgBoxSelfEquipHandcuffsOnBackPart1.Show()
                If (selection == 0)
                    SetDefaultParameters(player)
                    Tightness = 2 ; use "rather loose" for now, will be updated in EquipPartTwo
                    equipped = true
                    StartTimer(1.0, EquipPartTwo)
                EndIf
            EndIf
        Else
            If (Library.IsFemale(target))
                Library.Resources.MsgNpcLockHandcuffsOnBackFemale.Show()
            Else
                Library.Resources.MsgNpcLockHandcuffsOnBackMale.Show()
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
                Library.Resources.MsgBoxSelfHandcuffsOnBackTimedLockUnlocks.Show()
            EndIf
            Return true
        EndIf
    EndIf
    Bool unequipped = false
    If (target == player)
        If (!UI.IsMenuOpen("ContainerMenu"))
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
        Else
            Form keyObject = GetKeyObject()
            If (keyObject != None && player.GetItemCount(keyObject) > 0)
                Library.Resources.MsgUnlockHandcuffsWithKey.Show()
                unequipped = true
            Else
                If (Library.HasPlayerLockpickingSkill())
                    Int selection
                    If (Library.IsFemale(target))
                        selection = Library.Resources.MsgBoxNpcUnlockHandcuffsNoKeyFemale.Show()
                    Else
                        selection = Library.Resources.MsgBoxNpcUnlockHandcuffsNoKeyMale.Show()
                    EndIf
                    If (selection == 0)
                        unequipped = Library.RunPlayerLockpickInteraction()
                    EndIf
                Else
                    If (Library.IsFemale(target))
                        Library.Resources.MsgBoxNpcUnlockHandcuffsNoKeyFemaleLockpickingSkillNotHighEnough.Show()
                    Else
                        Library.Resources.MsgBoxNpcUnlockHandcuffsNoKeyMaleLockpickingSkillNotHighEnough.Show()
                    EndIf
                EndIf
            EndIf
        EndIf
    EndIf
    Library.ClearInteractionType()
    Return unequipped
EndFunction

;
; Override: Set internal state after the restraint has been equipped and applied.
;
Function SetStateAfterEquip(Actor target, Bool interactive)
    AddKeyword(Library.Resources.Locked)
    If (HasKeyword(Library.Resources.TimedLock) && GetRemainingTimedLockTimer() <= 0) ; only start timer if not already running
        StartTimedLockTimer(GetTimedLockDuration())
    EndIf
EndFunction

;
; Override: Refresh data after the game has been loaded.
;
Function RefreshOnGameLoad(Bool upgrade)
    _lastPickUpItemTimestamp = 0
    _restoreFirstPersonCamera = false
    If (HasKeyword(Library.Resources.Locked) && HasKeyword(Library.Resources.TimedLock))
        ; fallback code on game load in case timed lock has failed or is delayed
        Float remainingTimedLockHours = GetRemainingTimedLockTimer()
        If (remainingTimedLockHours <= 0)
            OpenTimedLock()
        EndIf
    EndIf
EndFunction

;
; Override: Set internal state after the restraint has been unequipped and unapplied.
;
Function SetStateAfterUnequip(Actor target, Bool interactive)
    ResetKeyword(Library.Resources.Locked)
    StopTimedLockTimer() ; may do nothing
EndFunction

;
; Override: Run the interaction when the restraint prevented player access to the pipboy.
;
Function PipboyPreventedInteraction()
    ; pressing pipboy key (usually tab) will start unequip interaction
    If (HasKeyword(Library.BlockPlayerEquipUnequip) || Game.GetPlayer().HasKeyword(Library.BlockPlayerEquipUnequip))
        Return
    EndIf
    If (Library.TrySetInteractionType(Library.InteractionTypePlayer, Game.GetPlayer(), GetLockLevel() + GetLockpickingPenalty()))
        If (HasKeyword(Library.Resources.TimedLock))
            Float remainingTime = GetRemainingTimedLockTimer()
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Interacting with time-locked handcuffs, remaining time: " + remainingTime, Library.Settings)
            EndIf
            If (remainingTime <= 0)
                ; fallback code in case timed lock has failed or is delayed
                OpenTimedLock()
                Return
            EndIf
        EndIf
        StartPlayerUnequipInteraction()
    EndIf
EndFunction

;
; Override: Run the interaction when the restraint prevented the player from interacting with a door.
;
Function OpenDoorPreventedInteraction(ObjectReference doorRef, Int lockDifficulty)
    If (lockDifficulty > 0)
        If (!Library.TrySetInteractionType(Library.InteractionTypeDoor, doorRef, lockDifficulty + GetLockpickingPenalty()))
            Return
        EndIf
        PlayerStartInvestigateLock() ; interaction may continue, don't clear interaction type
    EndIf
EndFunction

;
;
; Override: Run the interaction when the restraint prevented the player from interacting with a container (including corpses).
;
Function OpenContainerPreventedInteraction(ObjectReference containerRef, Int lockDifficulty)
    If (lockDifficulty > 0)
        If (!Library.TrySetInteractionType(Library.InteractionTypeContainer, containerRef, lockDifficulty + GetLockpickingPenalty()))
            Return
        EndIf
        PlayerStartInvestigateLock() ; interaction may continue, don't clear interaction type
    EndIf
EndFunction

;
; Override: Run the interaction when the restraint prevented the player from picking up an item.
;
Function TakeItemPreventedInteraction(ObjectReference itemRef, bool shouldBeAllowed)
    If (!Library.TrySetInteractionType(Library.InteractionTypeObject, itemRef))
        Return
    EndIf
    ; only show message box if not picking up and dropping items for at least 30 seconds real time
    ; this is to prevent annoying the player with too many message boxes
    Bool showMessageBox = Utility.GetCurrentRealTime() - _lastPickUpItemTimestamp >= 30
    If (shouldBeAllowed)
        ActorToken token = Library.GetOrCreateActorToken(Game.GetPlayer())
        Bool pickUp = true
        If (token.ItemInHand == None)
            If (showMessageBox)
                pickUp = Library.Resources.MsgBoxSelfHandcuffsOnBackPickUpItemAllowed.Show() == 0
            EndIf
        Else
            pickUp = Library.Resources.MsgBoxSelfHandcuffsOnBackPickUpHandsNotEmpty.Show() == 0
        EndIf
        ; let base class handle the actual logic
        If (pickUp)
            Parent.TakeItemPreventedInteraction(itemRef, shouldBeAllowed)
        EndIf
        _lastPickUpItemTimestamp = Utility.GetCurrentRealTime()
    ElseIf (showMessageBox)
        Library.Resources.MsgBoxSelfHandcuffsOnBackPickUpItemNotAllowed.Show()
    EndIf
    _lastPickUpItemTimestamp = Utility.GetCurrentRealTime()
    Library.ClearInteractionType()
EndFunction

;
; Override: Run the interaction when the restraint prevented the player from taking an item from a container.
;
Function TakeItemFromContainerPreventedInteraction(Form baseItem, ObjectReference originalContainer, ObjectReference temporaryContainer, Bool shouldBeAllowed)
    ; do not start interaction, there is already one running
    Bool showMessageBox = Utility.GetCurrentRealTime() - _lastPickUpItemTimestamp >= 30
    If (shouldBeAllowed)
        ActorToken token = Library.GetOrCreateActorToken(Game.GetPlayer())
        Bool takeItem = true
        If (token.ItemInHand == None)
            If (showMessageBox)
                takeItem = Library.Resources.MsgBoxSelfHandcuffsOnBackTakeItemFromContainerAllowed.Show() == 0
            EndIf
        Else
            takeItem = Library.Resources.MsgBoxSelfHandcuffsOnBackTakeItemFromContainerHandsNotEmpty.Show() == 0
        EndIf
        ; let base class handle the actual logic
        If (takeItem)
            Parent.TakeItemFromContainerPreventedInteraction(baseItem, originalContainer, temporaryContainer, shouldBeAllowed)
        EndIf
    ElseIf (showMessageBox)
        Library.Resources.MsgBoxSelfHandcuffsOnBackTakeItemFromContainerNotAllowed.Show()
    EndIf
    _lastPickUpItemTimestamp = Utility.GetCurrentRealTime()
EndFunction

;
; Override: Run the interaction when the restraint prevented the player from putting an item from a container.
;
Function PutItemIntoContainerPreventedInteraction(Form baseItem, ObjectReference originalContainer, ObjectReference temporaryContainer, Bool shouldBeAllowed)
    ; do not start interaction, there is already one running
    Bool showMessageBox = Utility.GetCurrentRealTime() - _lastPickUpItemTimestamp >= 30
    If (shouldBeAllowed)
        ActorToken token = Library.GetOrCreateActorToken(Game.GetPlayer())
        If (baseItem == token.ItemInHand)
            If (Library.Resources.MsgBoxSelfHandcuffsOnBackPutItemIntoContainerAllowed.Show() == 0)
                Parent.PutItemIntoContainerPreventedInteraction(baseItem, originalContainer, temporaryContainer, shouldBeAllowed)
            EndIf
        ElseIf (showMessageBox)
            Library.Resources.MsgBoxSelfHandcuffsOnBackPutItemIntoContainerNotAllowed.Show()
        EndIf
    ElseIf (showMessageBox)
        Library.Resources.MsgBoxSelfHandcuffsOnBackPutItemIntoContainerNotAllowed.Show()
    EndIf
    _lastPickUpItemTimestamp = Utility.GetCurrentRealTime()
EndFunction

;
; Override: Run the interaction when the player uses workshop tools to get free from a restraint.
;
Function UseToolsInteraction(ObjectReference containerRef)
    ; check if player is allowed to use workhop tools to free themselves
    Actor player = Game.GetPlayer()
    If (HasKeyword(Library.BlockPlayerEquipUnequip) || player.HasKeyword(Library.BlockPlayerEquipUnequip))
        Return
    EndIf
    If (player.GetCombatState() != 0)
        Library.Resources.CantUseInCombatMessage.Show()
        Return
    EndIf
    WorkshopScript workshop = containerRef as WorkshopScript
    If (workshop != None)
        workshop.CheckOwnership()
        If (!workshop.OwnedByPlayer)
            Return
        EndIf
    EndIf
    ; yes, start interaction
    If (Library.TrySetInteractionType(Library.InteractionTypePlayer, player, GetLockLevel() + GetLockpickingPenalty()))
        If (StartPlayerUseToolsInteraction(containerRef))
            BreakHandcuffs()
        EndIf
    EndIf
EndFunction

;
; Override: Start the player cut handcuffs with tools interaction.
;
Bool Function StartPlayerUseToolsInteraction(ObjectReference workshopRef)
    RealHandcuffs:Log.Error("Missing override: StartPlayerUseToolsInteraction()", Library.Settings)
    Library.ClearInteractionType()
    Return false
EndFunction

;
; Override: Run the interaction when the player eats an item.
;
Function EatItemInteraction(ObjectReference itemRef)
    If (Library.Resources.MsgBoxSelfHandcuffsOnBackEatItem.Show() == 0)
        Parent.EatItemInteraction(itemRef)
    EndIf
EndFunction

;
; Override: Run the interaction when the player drinks from open water.
;
Function DrinkOpenWaterInteraction(ObjectReference itemRef)
    If (Library.Resources.MsgBoxSelfHandcuffsOnBackDrinkOpenWater.Show() == 0)
        Parent.DrinkOpenWaterInteraction(itemRef)
    EndIf
EndFunction

;
; Override: Open the restraint using the timed lock. This function is called when the timed lock runs out.
;
Function OpenTimedLock()
    If (HasKeyword(Library.Resources.Locked))
        StopTimedLockTimer() ; may do nothing
        Actor player = Game.GetPlayer()
        If (GetContainer() == player && Library.GetOrCreateActorToken(player).IsApplied(Self))
            Library.Resources.MsgBoxSelfHandcuffsOnBackTimedLockUnlocks.Show()
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
        selection = Library.Resources.MsgBoxSelfHandcuffsOnBackRatherLoose.Show()
    ElseIf (Tightness == 1)
        selection = Library.Resources.MsgBoxSelfHandcuffsOnBackQuiteTight.Show()
    Else
        selection = Library.Resources.MsgBoxSelfHandcuffsOnBackVeryTight.Show()
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
    Game.GetPlayer().PlayIdle(Library.Resources.HandcuffsOnBackStruggle)
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
            Int selection = Library.Resources.MsgBoxStruggleFailToEscapeQuiteTight.Show()
            If (selection == 0)
                PlayStruggleAnimation(StruggleFeebly)
                Return ; interaction continues, don't clear interaction type
            EndIf
        EndIf
    Else
        RealHandcuffs:Log.Info("Player failed to struggle out of handcuffs (auto-failure).", Library.Settings)
        Int selection = Library.Resources.MsgBoxStruggleFailToEscapeVeryTight.Show()
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
    ; the target of this interaction can be either the player, a container or a door
    Int interactionType = Library.GetInteractionType()
    If (interactionType != Library.InteractionTypePlayer && interactionType != Library.InteractionTypeContainer && interactionType != Library.InteractionTypeDoor) ; not expected but check to be sure
        Library.ClearInteractionType()
        Return False
    EndIf
    Actor player = Game.GetPlayer()
    ActorToken token = Library.GetOrCreateActorToken(player)
    Form keyObject
    If (interactionType == Library.InteractionTypePlayer)
        keyObject = GetKeyObject()
    Else
        keyObject = Library.GetInteractionTarget().GetKey()
    EndIf
    If (interactionType == Library.InteractionTypePlayer && HasKeyword(Library.Resources.TimedLock))
        Library.Resources.MsgBoxSelfHandcuffsOnBackTimedLock.Show()
    ElseIf (keyObject != None && token.ItemInHand == keyObject)
        Int selection
        If (interactionType == Library.InteractionTypePlayer)
            selection = Library.Resources.MsgBoxSelfHandcuffsOnBackKeyInHand.Show()
            If (selection == 0)
                PlayStruggleAnimation(StruggleToUnlock)
                Return False ; interaction continues, don't clear interaction type
            EndIf
        Else
            selection = Library.Resources.MsgBoxSelfHandcuffsOnBackKeyInHandEasyToReach.Show()
            If (selection == 0)
                Library.GetInteractionTarget().Unlock()
            EndIf
        EndIf
        If (selection == 2)
            player.DropObject(token.ItemInHand, 1)
            token.ItemInHand = None
        EndIf
    ElseIf (token.ItemInHand == Library.Resources.BobbyPin && (interactionType != Library.InteractionTypePlayer || GetUnlockWithKeyChance() > 0) && Library.HasPlayerLockpickingSkill())
        Int selection = Library.Resources.MsgBoxSelfHandcuffsOnBackBobbyPinInHand.Show() % 3
        If (selection == 0)
            Int bobbyPinCount = player.GetItemCount(Library.Resources.BobbyPin)
            player.RemoveItem(Library.Resources.BobbyPin, bobbyPinCount - 1, true)
            Bool unlocked = Library.RunPlayerLockpickInteraction()
            If (Player.GetItemCount(Library.Resources.BobbyPin) == 0)
                token.ItemInHand = None
            EndIf
            player.AddItem(Library.Resources.BobbyPin, bobbyPinCount - 1, true)
            If (unlocked)
                If (interactionType == Library.InteractionTypePlayer)
                    ForceUnequip()
                Else
                    Library.GetInteractionTarget().Unlock()
                EndIf
            EndIf
        ElseIf (selection == 2)
            player.DropObject(token.ItemInHand, 1)
            token.ItemInHand = None
        EndIf
    ElseIf (keyObject == None || Player.GetItemCount(keyObject) == 0)
        If (Library.GetInteractionLockLevel() > 100)
            Library.Resources.MsgBoxSelfHandcuffsOnBackNoKeyLockTooDifficult.Show()
        ElseIf (!Library.HasPlayerLockpickingSkill())
            Library.Resources.MsgBoxSelfHandcuffsOnBackNoKeyLockpickingSkillNotHighEnough.Show()
        ElseIf (player.GetItemCount(Library.Resources.BobbyPin) == 0)
            Library.Resources.MsgBoxSelfHandcuffsOnBackNoKeyNoBobbyPins.Show()
        Else
            Int selection
            If (token.ItemInHand == None)
                selection = Library.Resources.MsgBoxSelfHandcuffsOnBackNoKeyBobbyPinsInInventory.Show()
            Else
                selection = Library.Resources.MsgBoxSelfHandcuffsOnBackNoKeyBobbyPinsInInventoryHandsNotEmpty.Show()
            EndIf
            If (selection == 0)
                If (token.ItemInHand != None)
                    Player.DropObject(Token.ItemInHand, 1)
                    token.ItemInHand = None
                EndIf
                PlayStruggleAnimation(StruggleToReachBobbyPin)
                Return False; interaction continues, don't clear interaction type
            EndIf
        EndIf
    Else
        Int selection
        If (token.ItemInHand == None)
            selection = Library.Resources.MsgBoxSelfHandcuffsOnBackKeyInInventory.Show()
        Else
            selection = Library.Resources.MsgBoxSelfHandcuffsOnBackKeyInInventoryHandsNotEmpty.Show()
        EndIf
        If (selection == 0)
            If (token.ItemInHand != None)
                Player.DropObject(Token.ItemInHand, 1)
                token.ItemInHand = None
            EndIf
            PlayStruggleAnimation(StruggleToReachKey)
            Return False ; interaction continues, don't clear interaction type
        EndIf
    EndIf
    Library.ClearInteractionType()
    Return False
EndFunction

;
; Handle the result of the 'struggle to reach key' subinteraction.
;
Function PlayerAfterStruggleToReachKey()
    ; the target of this interaction can be either the player or a door
    Int interactionType = Library.GetInteractionType()
    If (interactionType != Library.InteractionTypePlayer && interactionType != Library.InteractionTypeContainer && interactionType != Library.InteractionTypeDoor) ; not expected but check to be sure
        Library.ClearInteractionType()
        Return
    EndIf
    Actor player = Game.GetPlayer()
    Form keyObject;
    If (interactionType == Library.InteractionTypePlayer)
        keyObject = GetKeyObject()
    Else
        keyObject = Library.GetInteractionTarget().GetKey()
    EndIf
    Bool hasKey = keyObject != None && player.GetItemCount(keyObject) > 0 ; should always be true but check to be sure
    ActorToken token = Library.GetOrCreateActorToken(player)
    If (hasKey)
        Int chance = GetReachInventoryItemChance()
        Int d100 = Utility.RandomInt(1, 100)
        If (d100 <= chance)
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Player reached key (" + d100 + "&lt;=" + chance + ").", Library.Settings)
            EndIf
            If (token.ItemInHand != None && token.ItemInHand != keyObject)
                player.DropObject(token.ItemInHand, 1)
            EndIf
            token.ItemInHand = keyObject
            PlayerStartInvestigateLock()
            Return ; interaction may continue, don't clear interaction type
        Else
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Player failed to reach key (" + d100 + "&gt;" + chance + ").", Library.Settings)
            EndIf
        EndIf
    EndIf
    Int selection = Library.Resources.MsgBoxStruggleFailToReachKey.Show()
    If (selection == 0)
        PlayStruggleAnimation(StruggleToReachKey)
        Return ; interaction continues, don't clear interaction type
    EndIf
    Library.ClearInteractionType()
EndFunction

;
; Handle the result of the 'struggle to reach bobby pin' subinteraction.
;
Function PlayerAfterStruggleToReachBobbyPin()
    ; the target of this interaction can be either the player or a door
    Int interactionType = Library.GetInteractionType()
    If (interactionType != Library.InteractionTypePlayer && interactionType != Library.InteractionTypeContainer && interactionType != Library.InteractionTypeDoor) ; not expected but check to be sure
        Library.ClearInteractionType()
        Return
    EndIf
    Actor player = Game.GetPlayer()
    Bool hasBobbyPin = player.GetItemCount(Library.Resources.BobbyPin) > 0 ; should always be true but check to be sure
    ActorToken token = Library.GetOrCreateActorToken(player)
    If (hasBobbyPin)
        Int chance = GetReachInventoryItemChance()
        Int d100 = Utility.RandomInt(1, 100)
        If (d100 <= chance)
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Player reached bobby pin (" + d100 + "&lt;=" + chance + ").", Library.Settings)
            EndIf
            If (token.ItemInHand != None && token.ItemInHand != Library.Resources.BobbyPin)
                player.DropObject(token.ItemInHand, 1)
            EndIf
            token.ItemInHand = Library.Resources.BobbyPin
            PlayerStartInvestigateLock()
            Return ; interaction continues, don't clear interaction type
        Else
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Player failed to reach bobby pin (" + d100 + "&gt;" + chance + ").", Library.Settings)
            EndIf
        EndIf
    EndIf
    Int selection = Library.Resources.MsgBoxStruggleFailToReachBobbyPin.Show()
    If (selection == 0)
        PlayStruggleAnimation(StruggleToReachBobbyPin)
        Return ; interaction continues, don't clear interaction type
    EndIf
    Library.ClearInteractionType()
EndFunction

;
; Handle the result of the 'struggle to unlock' subinteraction.
;
Function PlayerAfterStruggleToUnlock()
    If (Library.GetInteractionType() != Library.InteractionTypePlayer) ; not expected but check to be sure
        Library.ClearInteractionType()
        Return
    EndIf
    Actor player = Game.GetPlayer()
    Form keyObject = GetKeyObject()
    ActorToken token = Library.GetOrCreateActorToken(player)
    If (keyObject == None || token.ItemInHand != keyObject) ; really not expected but check to be sure
        PlayerStartInvestigateLock()
        Return ; interaction continues, don't clear interaction type
    EndIf
    Int chance = GetUnlockWithKeyChance()
    Int d100 = Utility.RandomInt(1, 100)
    If (d100 <= chance)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Player unlocked handcuffs (" + d100 + "&lt;=" + chance + ").", Library.Settings)
        EndIf
        Library.Resources.MsgUnlockHandcuffsWithKey.Show()
        ForceUnequip()
    Else
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Player failed to unlock handcuffs (" + d100 + "&gt;" + chance + ").", Library.Settings)
        EndIf
        Int selection = Library.Resources.MsgBoxStruggleFailToUnlock.Show()
        If (selection == 0)
            PlayStruggleAnimation(StruggleToUnlock)
            Return ; interaction continues, don't clear interaction type
        ElseIf (selection == 2)
            player.DropObject(keyObject, 1)
            token.ItemInHand = None
        EndIf
    EndIf
    Library.ClearInteractionType()
EndFunction

;
; Group for timer events
;
Group Timers
    Int Property EquipPartTwo = 1000 AutoReadOnly
    Int Property StruggleToEscape = 1001 AutoReadOnly
    Int Property StruggleFeebly = 1002 AutoReadOnly
    Int Property StruggleToReachKey = 1003 AutoReadOnly
    Int Property StruggleToReachBobbyPin = 1004 AutoReadOnly
    Int Property StruggleToUnlock = 1005 AutoReadOnly
    Int Property RestoreFirstPersonCamera = 1006 AutoReadOnly
EndGroup

;
; Continue interactions on timer event.
;
Event OnTimer(int aiTimerID)
    If (_restoreFirstPersonCamera)
        Game.ForceFirstPerson()
        _restoreFirstPersonCamera = false
        Utility.Wait(0.1)
    EndIf
    If (aiTimerID == EquipPartTwo)
        Tightness = Library.Resources.MsgBoxSelfEquipHandcuffsOnBackPart2.Show()
    ElseIf (aiTimerID == StruggleToEscape || aiTimerID == StruggleFeebly)
        PlayerAfterStruggleToEscape()
    ElseIf (aiTimerID == StruggleToReachKey)
        PlayerAfterStruggleToReachKey()
    ElseIf (aiTimerID == StruggleToReachBobbyPin)
        PlayerAfterStruggleToReachBobbyPin()
    ElseIf (aiTimerID == StruggleToUnlock)
        PlayerAfterStruggleToUnlock()
    ElseIf (aiTimerID == RestoreFirstPersonCamera)
        ; do nothing, camera was restored above
    Else
        Parent.OnTimer(aiTimerID)
    EndIf
EndEvent