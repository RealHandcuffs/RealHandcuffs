;
; Abstract base class for all restraints.
;
Scriptname RealHandcuffs:RestraintBase extends ObjectReference

;
; The library instance.
;
RealHandcuffs:Library Property Library Auto Const Mandatory

;
; A flag used to communicate conflicts and their resolution between instances.
;
Bool Property ConflictPending Auto

Float _unlockTimedLockTimestamp

;
; ---- Functions that can be overridden in subclasses. -----
;

;
; Set the default parameters for restraints that can be equipped in different ways.
; This is called automatically before applying a restraint when the restraint is equipped non-interactively.
;
Function SetDefaultParameters(Actor target)
EndFunction

; Copy the parameters for restraints that can be equipped in different ways from another restraint.
; This is called automatically when a restraint is applied as replacement for another restraint.
;
Function CopyParametersFrom(RealHandcuffs:RestraintBase restraint)
EndFunction

;
; Get a 'priority' value that is used to resolve conflicts between restraints.
; Higher numbers are more important, meaning that they can override lower numbers.
; The returned value must be constant and not change depending on the state of the restraint.
;
Int Function GetPriority()
    Return 0 ; default
EndFunction

;
; Get the impact caused by waring the restraint. The returned string must be from the Library's Impacts group.
; The returned value must be constant and not change while the restraint is applied.
; DEVELOPER NOTE: This (const-ness) may need to change in the future, but will require additional support
; in the token, most probably the restraint needs to call a function of the token.
;
String Function GetImpact()
    Return Library.NoImpact
EndFunction

;
; Get the MT animation for the arms when the restraing is being worn, or None if no such animation is applied.
; The returned value must be constant and not change while the restraint is applied.
;
Keyword Function GetMtAnimationForArms()
    Return None
EndFunction

;
; Check whether the MT animation for the arms can be changed.
;
Bool Function MtAnimationForArmsCanBeCycled()
    Return False
EndFunction

;
; Try to cycle the MT animation for the arms - use the actor as target who is wearing the restraint, None if not worn.
;
Function CycleMtAnimationForArms(Actor target)
EndFunction

;
; Get the key that will unlock the restraint; None if there is no key. Note that the signature is different than
; the one in GetKey(), as we want to allow droppable MiscItem objects and not just undroppable keys.
; The returned value can change, e.g. depending on mods installed in the restraint.
;
Form Function GetKeyObject()
    Return None
EndFunction

;
; Get the level of the lock; 0 if there is no lock.
; The returned value can change, e.g. depending on mods installed in the restraint.
;
Int Function GetLockLevel()
    Return 0
EndFunction

;
; Get a 'dummy' armor that can be used to visually represent the restraint.
;
Armor Function GetDummyObject()
    RealHandcuffs:Log.Error("Missing GetDummyObject override in subclass.", Library.Settings)
    Return None
EndFunction

;
; Run the interaction when the restraint is equipped by player action (i.e. the player can choose if and how
; to equip the restraint) and return true if the restraint should actually be equipped, false otherwise.
; This will not actually equip and apply the restraint, even if true is returned; use ForceEquip to do that.
;
Bool Function EquipInteraction(Actor target)
    If (HasKeyword(Library.BlockPlayerEquipUnequip) || target.HasKeyword(Library.BlockPlayerEquipUnequip))
        Return false
    EndIf
    Return true
EndFunction

;
; Run the interaction when the restraint is unequipped by player action and return true if the restraint should
; actually be unequipped, false otherwise. This will not actually unequip and unapply the restraint, even if
; true is returned; use ForceUnequip to do that.
;
Bool Function UnequipInteraction(Actor target)
    If (HasKeyword(Library.BlockPlayerEquipUnequip) || target.HasKeyword(Library.BlockPlayerEquipUnequip))
        Return false
    EndIf
    Return true
EndFunction

;
; Set internal state after the restraint has been equipped and applied.
;
Function SetStateAfterEquip(Actor target, Bool interactive)
    CancelTimer(UnequipAfterModChange)
EndFunction

;
; Set internal state after the restraint has been unequipped and unapplied.
;
Function SetStateAfterUnequip(Actor target, Bool interactive)
EndFunction

;
; Refresh data after the game has been loaded.
;
Function RefreshOnGameLoad(Bool upgrade)
EndFunction

;
; Run the interaction when the restraint prevented player access to the pipboy. This is only triggered if the
; restraint is applied to the player and prevents access to the pipboy.
;
Function PipboyPreventedInteraction()
EndFunction

;
; Run the interaction when the restraint prevented player access to a favorite item. This is only triggered if the
; restraint is applied to the player and prevents access to the favorites.
;
Function QuickkeyPreventedInteraction(Form favoriteItem)
EndFunction

;
; Run the interaction when the restraint prevented the player from interacting with a furniture or similar object. This
; is only triggered if the restraint is applied to the player and prevents access to (at least some) furnitures.
;
Function ActivateFurniturePreventedInteraction(ObjectReference furnitureRef, Bool shouldBeAllowed)
EndFunction

;
; Run the interaction when the restraint prevented the player from interacting with a container (including corpses). This is
; only triggered if the restraint is applied to the player and prevents access to (at least some) containers.
;
Function OpenContainerPreventedInteraction(ObjectReference containerRef, Int lockDifficulty)
EndFunction

;
; Run the interaction when the restraint prevented the player from interacting with a door. This is only triggered if the
; restraint is applied to the player and prevents access to (at least some) doors.
;
Function OpenDoorPreventedInteraction(ObjectReference doorRef, Int lockDifficulty)
EndFunction

;
; Run the interaction when the restraint prevented the player from picking pockets. This is only triggered if the restraint
; is applied to the player and prevents (at least some) pickpocketing events.
;
Function PickPocketsPreventedInteraction(ObjectReference ref, bool shouldBeAllowed)
EndFunction

;
; Run the interaction when the restraint prevented the player from disarming a mine or trap. This is only triggered if the
; restraint is applied to the player and prevents disarming (at least some) mines or traps.
;
Function DisarmTrapPreventedInteraction(ObjectReference trapRef, Bool shouldBeAllowed)
EndFunction

;
; Run the interaction when the restraint prevented the player from picking up an item. This is only triggered if the
; item is applied to the player and prevents access to loose items. The base implementation handles the logic correctly
; without showing any UI, so it can be called by override implementations.
;
Function TakeItemPreventedInteraction(ObjectReference itemRef, Bool shouldBeAllowed)
    If (shouldBeAllowed)
        Actor player = Game.GetPlayer()
        RealHandcuffs:ActorToken token = Library.GetOrCreateActorToken(player)
        If (token.ItemInHand != None)
            player.DropObject(token.ItemInHand, 1)
        EndIf
        Form baseObject = itemRef.GetBaseObject()
        ObjectReference invisibleContainer = player.PlaceAtMe(Library.Resources.InvisibleContainer, 1, false, true, true)
        invisibleContainer.AddItem(itemRef, 1, true) ; to "unpack" stacks of objects, keeping them packed causes issues
        Int stackSize = invisibleContainer.GetItemCount(baseObject)
        If (stackSize == 1)
            Player.AddItem(itemRef, 1)
        Else
            Player.AddItem(baseObject, 1)
            InvisibleContainer.DropObject(baseObject, stackSize - 1)
        EndIf
        invisibleContainer.Delete()
        token.ItemInHand = itemRef.GetBaseObject()
    EndIf
EndFunction

;
; Run the interaction when the restraint prevented the player from taking an item from a container. This is only triggered if the
; item is applied to the player and prevents taking items from containers. The base implementation handles the logic correctly
; without showing any UI, so it can be called by override implementations.
;
Function TakeItemFromContainerPreventedInteraction(Form baseObject, ObjectReference originalContainer, ObjectReference temporaryContainer, Bool shouldBeAllowed)
    If (shouldBeAllowed)
        Actor player = Game.GetPlayer()
        RealHandcuffs:ActorToken token = Library.GetOrCreateActorToken(player)
        If (token.ItemInHand != None)
            player.RemoveItem(token.ItemInHand, 1, false, originalContainer)
            originalContainer.AddItem(Library.Resources.BobbyPin, 1, true)
            originalContainer.RemoveItem(Library.Resources.BobbyPin, 1, true, None)
        EndIf
        temporaryContainer.RemoveItem(baseObject, 1, false, player)
        token.ItemInHand = baseObject
        player.AddItem(Library.Resources.BobbyPin, 1, true)
        player.RemoveItem(Library.Resources.BobbyPin, 1, true, None)
    EndIf
EndFunction

;
; Run the interaction when the restraint prevented the player from putting an item into a container. This is only triggered if the
; item is applied to the player and prevents putting items from containers. The base implementation handles the logic correctly
; without showing any UI, so it can be called by override implementations.
;
Function PutItemIntoContainerPreventedInteraction(Form baseObject, ObjectReference originalContainer, ObjectReference temporaryContainer, Bool shouldBeAllowed)
    If (shouldBeAllowed)
        Actor player = Game.GetPlayer()
        RealHandcuffs:ActorToken token = Library.GetOrCreateActorToken(player)
        If (token.ItemInHand == baseObject)
            temporaryContainer.RemoveItem(baseObject, 1, false, originalContainer)
            token.ItemInHand = None
            originalContainer.AddItem(Library.Resources.BobbyPin, 1, true)
            originalContainer.RemoveItem(Library.Resources.BobbyPin, 1, true, None)
        EndIf
    EndIf
EndFunction

;
; Run the interaction when the player uses workshop tools to get free from a restraint.
;
Function UseToolsInteraction(ObjectReference containerRef)
EndFunction

;
; Run the interaction when the player eats an item.
;
Function EatItemInteraction(ObjectReference itemRef)
    Actor player = Game.GetPlayer()
    Form baseObject = itemRef.GetBaseObject()
    player.AddItem(itemRef, 1, true)
    player.EquipItem(baseObject, false, true)
EndFunction

;
; Run the interaction when the player drinks from open water.
;
Function DrinkOpenWaterInteraction(ObjectReference itemRef)
    Actor player = Game.GetPlayer()
    Cell currentCell = player.GetParentCell()
    WaterType openWater = currentCell.GetWaterType()
    Spell consumeSpell = openWater.GetConsumeSpell()
    consumeSpell.Cast(player, player)
EndFunction

;
; Open the restraint using the timed lock. This function is called when the timed lock runs out.
;
Function OpenTimedLock()
EndFunction

;
; Called for some restraints that can be triggered, e.g. by a remote trigger being fired in the vicinity.
; When setting force to true, it forces activation even if the state of the restraint would normally prevent activation.
;
Function Trigger(Actor target, Bool force)
EndFunction

;
; ----- End of functions that can be overridden in subclasses
;

;
; Get the mod of the restraint for the specified mod tag.
;
ObjectMod Function GetMod(Keyword modTag)
    ObjectMod[] mods = GetAllMods()
    Int index = 0
    While (index < mods.Length)
        If (Library.IsAddingKeyword(mods[index], modTag))
            Return mods[index]
        EndIf
        index += 1
    EndWhile
    Return None
EndFunction

;
; Replace the mod of the restraint for the specified mod tag. Returns true if the mod was replaced.
; Note that doing this on restraints that are currently worn by an NPC will not fully work, you will
; need to unequip and requip them.
;
Bool Function ReplaceMod(Keyword modTag, ObjectMod mod)
    ObjectMod[] mods = GetAllMods()
    If (mods.Find(mod) < 0)
        Int index = 0
        While (index < mods.Length)
            If (Library.IsAddingKeyword(mods[index], modTag))
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Removing mod " + RealHandcuffs:Log.FormIdAsString(mods[index]) + " " + mods[index].GetName() + " from " + GetDisplayName() + ".", Library.Settings)
                EndIf
                RemoveMod(mods[index])
            EndIf
            index += 1
        EndWhile
        If (AttachMod(mod))
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Attached mod " + RealHandcuffs:Log.FormIdAsString(mod) + " " + mod.GetName() + " to " + GetDisplayName() + ".", Library.Settings)
            EndIf
            Return True
        Else
            RealHandcuffs:Log.Warning("Failed to attached mod " + RealHandcuffs:Log.FormIdAsString(mod) + " " + mod.GetName() + " to " + GetDisplayName() + ".", Library.Settings)
        EndIf
    EndIf
    Return False
EndFunction

;
; Get the duration of a time-locked restraint in hours; 0 if the restraint is not time-locked.
; The returned value can change, e.g. depending on mods installed in the restraint.
;
Int Function GetTimedLockDuration()
    If (HasKeyword(Library.Resources.TimedLock))
        If (HasKeyword(Library.Resources.LockTime1h))
            Return 1
        EndIf
        If (HasKeyword(Library.Resources.LockTime2h))
            Return 2
        EndIf
        If (HasKeyword(Library.Resources.LockTime3h))
            Return 3
        EndIf
        If (HasKeyword(Library.Resources.LockTime4h))
            Return 4
        EndIf
        If (HasKeyword(Library.Resources.LockTime5h))
            Return 5
        EndIf
        If (HasKeyword(Library.Resources.LockTime6h))
            Return 6
        EndIf
        If (HasKeyword(Library.Resources.LockTime7h))
            Return 7
        EndIf
        If (HasKeyword(Library.Resources.LockTime8h))
            Return 8
        EndIf
        If (HasKeyword(Library.Resources.LockTime9h))
            Return 9
        EndIf
        If (HasKeyword(Library.Resources.LockTime10h))
            Return 10
        EndIf
        If (HasKeyword(Library.Resources.LockTime11h))
            Return 11
        EndIf
        If (HasKeyword(Library.Resources.LockTime12h))
            Return 12
        EndIf
        Return 3 ; default
    EndIf
    Return 0
EndFunction

;
; Set the base duration of a time-locked restraint in hours (1-12, or anything else for default).
;
Function SetTimedLockDuration(Int hours)
    If (HasKeyword(Library.Resources.TimedLock))
        If (hours == 1)
            ReplaceMod(Library.Resources.LockTimeTag, Library.Resources.ModLockTime1h)
        ElseIf (hours == 2)
            ReplaceMod(Library.Resources.LockTimeTag, Library.Resources.ModLockTime2h)
        ElseIf (hours == 3)
            ReplaceMod(Library.Resources.LockTimeTag, Library.Resources.ModLockTime3h)
        ElseIf (hours == 4)
            ReplaceMod(Library.Resources.LockTimeTag, Library.Resources.ModLockTime4h)
        ElseIf (hours == 5)
            ReplaceMod(Library.Resources.LockTimeTag, Library.Resources.ModLockTime5h)
        ElseIf (hours == 6)
            ReplaceMod(Library.Resources.LockTimeTag, Library.Resources.ModLockTime6h)
        ElseIf (hours == 7)
            ReplaceMod(Library.Resources.LockTimeTag, Library.Resources.ModLockTime7h)
        ElseIf (hours == 8)
            ReplaceMod(Library.Resources.LockTimeTag, Library.Resources.ModLockTime8h)
        ElseIf (hours == 9)
            ReplaceMod(Library.Resources.LockTimeTag, Library.Resources.ModLockTime9h)
        ElseIf (hours == 10)
            ReplaceMod(Library.Resources.LockTimeTag, Library.Resources.ModLockTime10h)
        ElseIf (hours == 11)
            ReplaceMod(Library.Resources.LockTimeTag, Library.Resources.ModLockTime11h)
        ElseIf (hours == 12)
            ReplaceMod(Library.Resources.LockTimeTag, Library.Resources.ModLockTime12h)
        Else
            ReplaceMod(Library.Resources.LockTimeTag, Library.Resources.ModLockTime3h) ; default
        EndIf
    EndIf
EndFunction

;
; Start a timer that will unlock the restraint when it runs out.
;
Function StartTimedLockTimer(Float durationHours)
    _unlockTimedLockTimestamp = Utility.GetCurrentGameTime() + durationHours / 24.0
    StartTimerGameTime(durationHours, UnlockTimedLock)
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Set timer to unlock in " + durationHours + " hours.", Library.Settings)
    EndIf
EndFunction

;
; Get how many hours the timer that will unlock the restraint when it runs out still has to go.
;
Float Function GetRemainingTimedLockTimer()
    Return (_unlockTimedLockTimestamp - Utility.GetCurrentGameTime()) * 24.0
EndFunction

;
; Stop the timer that will unlock the restraint when it runs out.
;
Function StopTimedLockTimer()
    If (_unlockTimedLockTimestamp > 0.0)
        _unlockTimedLockTimestamp = 0.0
        CancelTimerGameTime(UnlockTimedLock)
    EndIf
EndFunction

;
; Search the current "target" of the restraint, the actor wearing the restraint (may be None).
; This can be rather slow and should ony be done if really necessary.
;
Actor Function SearchCurrentTarget()
    ActorToken token
    Actor containerActor = GetContainer() as Actor
    If (containerActor != None)
        token = Library.TryGetActorToken(containerActor)
        If (token != None && token.IsApplied(Self))
            Return containerActor
        EndIf
    EndIf
    Actor player = Game.GetPlayer()
    If (containerActor != player)
        token = Library.GetOrCreateActorToken(player)
        If (token.IsApplied(Self))
            Return player
        EndIf
    EndIf
    RefCollectionAlias restrained = Library.RestrainedNpcs
    Int index = 0
    While (index < restrained.GetCount())
        Actor akActor = restrained.GetAt(index) as Actor
        If (akActor != None)
            token = Library.TryGetActorToken(akActor)
            If (token != None && token.IsApplied(Self))
                Return akActor
            EndIf
        EndIf
        index += 1
    EndWhile
    Return None
EndFunction

; Force the restraint to be equipped and applied, bypassing any interactions.
; This requires that the restraint is in the inventory of an actor, otherwise it will fail.
; This should be preferred to just using Actor.EquipItem, as the latter might show interactions
; if for example the pipboy menu is currently active, or even fail to work.
;
Function ForceEquip(Bool unequipConflicting = false, Bool setDefaultParameters = true)
    Actor target = GetContainer() as Actor
    If (target != None)
        ; apply before equipping, this will bypass the interactions
        RealHandcuffs:ActorToken token = Library.GetOrCreateActorToken(target)
        If (token != None && !token.IsApplied(Self))
            RealHandcuffs:RestraintBase[] conflicts = token.GetConflictingRestraints(GetBaseObject().GetSlotMask())
            If (conflicts != None && conflicts.Length > 0)
                If (!unequipConflicting)
                    Return ; abort, slots are blocked by other restraints
                EndIf
                Int index = 0
                While (index < conflicts.Length)
                    conflicts[index].ForceUnequip()
                    index += 1
                EndWhile
            EndIf
            If (setDefaultParameters)
                SetDefaultParameters(target)
            EndIf
            token.ApplyRestraint(Self)
            SetStateAfterEquip(target, false)
        EndIf
        Form baseObject = GetBaseObject()
        If (!target.IsEquipped(baseObject) && !target.IsInPowerArmor())
            If (!target.IsEnabled())
                If (token != None)
                    token.EquipRestraintsWhenEnabled()
                EndIf
            Else
                Int count = target.GetItemCount(baseObject)
                If (count == 1)
                    target.EquipItem(baseObject, target != Game.GetPlayer(), true)
                Else
                    ; equipping can only be done by base object, so we need to take extra steps to make sure
                    ; that this reference is equipped and not another one if there are multiple in the inventory
                    ObjectReference invisibleContainer = target.PlaceAtMe(Library.Resources.InvisibleContainer, 1, false, true, true)
                    target.RemoveItem(baseObject, count, true, invisibleContainer)
                    target.AddItem(Self, 1, true)
                    target.EquipItem(baseObject, target != Game.GetPlayer(), true)
                    invisibleContainer.RemoveItem(baseObject, count - 1, true, target)
                    invisibleContainer.Delete()
                EndIf
            EndIf
        EndIf
    EndIf
EndFunction

;
; Force the restraint to be unequipped and unapplied, bypassing any interactions.
; This requires that the restraint is in the inventory of an actor, otherwise it will fail.
; This should be preferred to just using Actor.UnequipItem, as the latter might show interactions
; if for example the pipboy menu is currently active, or even fail to work.
;
Function ForceUnequip()
    Actor target = SearchCurrentTarget()
    If (target != None)
        ; unapply before unequipping, this will bypass the interactions
        RealHandcuffs:ActorToken token = Library.TryGetActorToken(target)
        If (token != None && token.IsApplied(Self))
            token.UnapplyRestraint(Self)
            SetStateAfterUnequip(target, false)
        EndIf
        Form baseObject = GetBaseObject()
        If (target.IsEquipped(baseObject) && target.IsEnabled())
            target.UnequipItem(baseObject, false, true)
        EndIf
    EndIf
EndFunction

;
; Note:
; Handling of equipping and unequipping are very complicated because the engine does not have events before equipping/unequipping.
; So instead we need to detect the equip/unequip after the fact, check if it is allowed, and revert if it is not allowed.
; We also get no information about the reason of the equip/unequip: Is it an action performed by the user, or a script,
; or something else? We use some heuristics to make an educated guess; guesses can be wrong though. Scripts should call
; the ForceEquip/ForceUnequip functions when putting items on actors in a non-interactive way, this will allow us to
; detect the situation.
;

;
; Handle equipping of restraint.
;
Event OnEquipped(Actor akActor)
    RealHandcuffs:ActorToken token = Library.GetOrCreateActorToken(akActor)
    If (token == None || token.IsApplied(Self))
        ; nothing to do, restraint is already applied or actor is dead
        Return
    EndIf
    Bool interactive = false
    If (!Library.Settings.Disabled && (Library.Settings.HardcoreMode || !UI.IsMenuOpen("Console")))
        Bool containerMenuOpen = UI.IsMenuOpen("ContainerMenu")
        RealHandcuffs:RestraintBase[] conflicts = token.GetConflictingRestraints(GetBaseObject().GetSlotMask())
        If (conflicts != None && conflicts.Length > 0)
            ; detected conflicting restraints that were bumped off, put them back on and abort
            Int index = 0
            While (index < conflicts.Length)
                conflicts[index].ConflictPending = true ; set the flag as quickly as possible
                index += 1
            EndWhile
            Form baseObject = GetBaseObject()
            If (akActor.IsEquipped(baseObject))
                akActor.UnequipItem(baseObject, false, true)
            EndIf
            index = 0
            While (index < conflicts.Length)
                conflicts[index].ForceEquip()
                index += 1
            EndWhile
            Utility.WaitMenuMode(0.1)
            index = 0
            While (index < conflicts.Length)
                conflicts[index].ConflictPending = false ; clear the flag only after allowing some time for updates
                index += 1
            EndWhile
            If (containerMenuOpen)
                KickContainerUI(akActor)
            EndIf
            Return
        EndIf
        If (akActor == Game.GetPlayer())
            If (UI.IsMenuOpen("PipboyMenu"))
                ; most probably player equipped restraint using pipboy menu
                interactive = true
            Else
                RealHandcuffs:PlayerToken playerToken = token as RealHandcuffs:PlayerToken
                Float lastQuickkeyTime = playerToken.LastQuickKeyRealTime
                If (lastQuickkeyTime > 0 && Utility.GetCurrentRealTime() - playerToken.LastQuickKeyRealTime <= 0.5)
                    Form lastQuickkeyItem = playerToken.LastQuickKeyItem as Form
                    Form baseObject = GetBaseObject()
                    If (lastQuickkeyItem == baseObject)
                        ; most probably player equipped restraint using quickkey
                        interactive = true
                    EndIf
                EndIf
            EndIf
        ElseIf (containerMenuOpen)
            ; most probably player equipped restraint on npc using container menu
            interactive = true
        EndIf
        If (interactive)
            ; the event may have caused an incompatible restraint from another mod to be bumped off
            ; wait a short moment and check if this restraint has been removed before starting the interaction
            Utility.WaitMenuMode(0.1)
            Form baseObject = GetBaseObject()
            If (!akActor.IsEquipped(baseObject) || !EquipInteraction(akActor))
                ; unequip and abort
                If (akActor.IsEquipped(baseObject))
                    akActor.UnequipItem(baseObject, false, true)
                EndIf
                If (UI.IsMenuOpen("ContainerMenu"))
                    KickContainerUI(akActor)
                EndIf
                Return
            EndIf
        EndIf
    EndIf
    ; the change was not reverted, apply restraint
    If (!interactive)
        ; generic equip operation, be wary and do an additional check
        Actor currentTarget = SearchCurrentTarget()
        If (currentTarget != None)
            If (Library.SoftDependencies.IsActorCloneOf(akActor, currentTarget))
                ; cloning operation in progress, do nothing for now
                Return
            Else
                ; something is wrong, try to fix things
                Drop(true)
                currentTarget.AddItem(Self, 1, true)
                ForceEquip(true, false)
                Return
            EndIf
        Else
            SetDefaultParameters(akActor)
        EndIf
    EndIf
    token.ApplyRestraint(Self)
    SetStateAfterEquip(akActor, interactive)
EndEvent

;
; Handle unequipping of restraint.
; We are not doing this in a OnUnequipped event handler because OnEquipped/OnUnequipped event handlers are not completely reliable.
; Instead we are listening on Actor.OnItemUnequipped in the actor token and calling HandleUnequipped from there.
;
Function HandleUnequipped(Actor akActor)
    RealHandcuffs:ActorToken token = Library.TryGetActorToken(akActor)
    If (token == None || !token.IsApplied(Self))
        ; nothing to do, restraint is not applied
        Return
    EndIf
    If (akActor.IsInPowerArmor())
        ; restraint was temporarily unequipped by the game because the wearer entered power armor, ignore
        ; waters are getting a bit muddy here though, there may be bugs hiding...
        Return
    EndIf
    Bool interactive = false
    If (!Library.Settings.Disabled && (Library.Settings.HardcoreMode || !UI.IsMenuOpen("Console")))
        Bool containerMenuOpen = UI.IsMenuOpen("ContainerMenu")
        If (akActor == Game.GetPlayer())
            If (UI.IsMenuOpen("PipboyMenu"))
                ; most probably player unequipped restraint using pipboy menu
                interactive = true
            ElseIf (containerMenuOpen)
                ; most probably player unequipped restraint using container menu
                interactive = true
            Else
                RealHandcuffs:PlayerToken playerToken = token as RealHandcuffs:PlayerToken
                Float lastQuickkeyTime = playerToken.LastQuickKeyRealTime
                If (lastQuickkeyTime > 0 && Utility.GetCurrentRealTime() - playerToken.LastQuickKeyRealTime <= 0.5)
                    Form lastQuickkeyItem = playerToken.LastQuickKeyItem
                    Form baseObject = GetBaseObject()
                    If (((lastQuickkeyItem as Armor) != None && (baseObject as Armor) != None) || (((lastQuickkeyItem as Weapon) != None && (baseObject as Weapon) != None)))
                        ; most probably player unequipped restraint by using quickkey to equip another item in the same slot
                        interactive = true
                    EndIf
                EndIf
            EndIf
        ElseIf (containerMenuOpen)
            ; most probably player unequipped restraint from npc using container menu
            interactive = true
        EndIf
        Bool revertChange
        If (interactive)
            ; the event may have been caused by the equipping of an incompatible device
            ; wait a short moment and check if the conflict flag is set before starting the interaction
            Utility.WaitMenuMode(0.1)
            Form baseObject = GetBaseObject()
            If (ConflictPending)
                Return
            EndIf
            revertChange = !UnequipInteraction(akActor)
            If (!revertChange && !token.IsApplied(Self))
                ; the interaction called ForceUnequip() so there is nothing left to do
                Return
            EndIf
        Else
            revertChange = true
        EndIf
        If (revertChange)
            ; reequip and abort
            If (!ConflictPending)
                ObjectReference cnt = GetContainer()
                If (cnt != akActor)
                    Actor cntActor = cnt as Actor
                    If (Library.SoftDependencies.IsActorCloneOf(cntActor, akActor))
                        ; cloning operation in progress, do nothing for now
                        Return
                    EndIf    
                    Actor player = Game.GetPlayer()
                    If (akActor != player)
                        NpcToken preventBugToken = token as NpcToken
                        preventBugToken.PreventUnequipAllBug()
                    EndIf
                    If (cntActor != None && cntActor != player)
                        NpcToken preventBugToken = Library.GetOrCreateActorToken(cntActor) as NpcToken
                        If (preventBugToken != None)
                            preventBugToken.PreventUnequipAllBug()
                        EndIf
                    EndIf
                    Drop(true)
                    akActor.AddItem(Self, 1, true)
                EndIf
                ForceEquip(true)
                If (UI.IsMenuOpen("ContainerMenu"))
                    KickContainerUI(akActor)
                    If (cnt != akActor)
                        KickContainerUI(cnt)
                    EndIf
                EndIf
                If (!interactive && Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Prevented generic unequip of restraint from " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName(), Library.Settings)
                EndIf
            EndIf
            Return
        EndIf
    EndIf
    ; the change was not reverted, unapply restraint
    token.UnapplyRestraint(Self)
    SetStateAfterUnequip(akActor, interactive)
EndFunction

;
; Handle death of the wearer of the restraint.
;
Function HandleWearerDied(Actor akActor)
EndFunction

;
; Kick the container ui to force a refresh. The UI will not always update automatically if items are added/removed/equipped/unequipped by script.
;
Function KickContainerUI(ObjectReference cnt)
    cnt.AddItem(Library.Resources.BobbyPin, 1, true)
    cnt.RemoveItem(Library.Resources.BobbyPin, 1, true, None)
EndFunction

;
; Group for timer events
;
Group Timers
    Int Property UnlockTimedLock = 1 AutoReadOnly
    Int Property UnequipAfterModChange = 2 AutoReadOnly
    Int Property EquipAfterModChange = 3 AutoReadOnly
EndGroup

;
; Event for timed locks.
;
Event OnTimerGameTime(int aiTimerID)
    If (aiTimerID == UnlockTimedLock && HasKeyword(Library.Resources.Locked))
        OpenTimedLock()
    ElseIf (aiTimerID == UnequipAfterModChange)
        Actor target = GetContainer() as Actor
        Form baseObject = GetBaseObject()
        If (target != None)
            target.UnequipItem(baseObject, false, true) ; should get reverted
        EndIf
        StartTimer(0.1, EquipAfterModChange) ; in case it did not get reverted
    ElseIf (aiTimerID == EquipAfterModChange)
        Actor target = GetContainer() as Actor
        Form baseObject = GetBaseObject()
        If (target != None && !target.IsEquipped(baseObject))
            ForceEquip(target)
        EndIf
    EndIf
EndEvent