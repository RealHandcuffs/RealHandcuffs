;
; A token living in the inventory of an living actor, tracking effects applied to the actor.
; This class is abstract and implemented by NpcToken and PlayerToken.
;
Scriptname RealHandcuffs:ActorToken extends ObjectReference

RealHandcuffs:Library Property Library Auto Const Mandatory

Actor _target
Form _itemInHand
RealHandcuffs:RestraintBase[] _restraints
Keyword _mtAnimationForArms
Bool _uninitialized

;
; Get the actor being tracked by this token.
;
Actor Property Target
    Actor Function Get()
        Return _target
    EndFunction
EndProperty

;
; Check whether this token has been uninitialized.
;
Bool Property Uninitialized
    Bool Function Get()
        Return _uninitialized
    EndFunction
EndProperty

;
; Actors may be able to hold a single small item in their hands when their hands are bound.
; This property allows access to that item. The item must be part of the actors inventory;
; if the item is not in the actors inventory, the getter will return None.
; DEVELOPER NOTE: We need to use base objects here, not object references. This means that we
; cannot differentiate which of multiple object with the same base object is held. Assume that
; (moddable) weapons and armors cannot be held, so it does not matter
;
Form Property ItemInHand
    Form Function Get()
        If (_itemInHand == None || _target.GetItemCount(_itemInHand) == 0)
            Return None
        EndIf
        Return _itemInHand
    EndFunction
    Function Set(Form item)
        _itemInHand = item
    EndFunction
EndProperty

;
; Get the restraints that are currently applied to the actor.
;
RealHandcuffs:RestraintBase[] Property Restraints
    RealHandcuffs:RestraintBase[] Function Get()
        Return _restraints
    EndFunction
EndProperty

;
; Get whether the hands of the actor are currently bound behind their back.
;
Bool Function GetHandsBoundBehindBack()
    RealHandcuffs:Log.Error("Missing GetHandsBoundBehindBack override in subclass.", Library.Settings)    
    Return False
EndFunction

;
; Get whether firing a remote trigger in the vicinity will cause some effect.
;
Bool Function GetRemoteTriggerEffect()
    RealHandcuffs:Log.Error("Missing GetHandsBoundBehindBack override in subclass.", Library.Settings)    
    Return False
EndFunction

;
; Initialize the actor token after creation.
;
Function Initialize(Actor myTarget)
    _target = myTarget
    _restraints = new RealHandcuffs:RestraintBase[0]
    _target.AddItem(Self, 1, true)
    RegisterForRemoteEvent(_target, "OnItemEquipped")
    RegisterForRemoteEvent(_target, "OnItemUnequipped")
EndFunction

;
; Uninitialize the actor token before destruction.
;
Function Uninitialize()
    If (_target != None)
        SuspendEffectsAndAnimations()
        UnregisterForRemoteEvent(_target, "OnItemEquipped")
        UnregisterForRemoteEvent(_target, "OnItemUnequipped")
    EndIf
    _target = None
    _restraints = None
    _uninitialized = true
    If (IsBoundGameObjectAvailable())
        ObjectReference myContainer = GetContainer()
        If (myContainer != None)
            myContainer.RemoveItem(Self, 1, true, None)
        Else
            Delete()
        EndIf
    EndIf
EndFunction

;
; Check if the token is in a good state. Returns false and deletes the token if not.
;
Bool Function CheckConsistency(Actor expectedTarget)
    If (_uninitialized)
        If (IsBoundGameObjectAvailable())
            ObjectReference myContainer = GetContainer()
            If (myContainer != None)
                myContainer.RemoveItem(Self, 1, true, None)
            Else
                Delete()
            EndIf
        EndIf
        Return false
    EndIf
    If (!IsBoundGameObjectAvailable())
        If (Library == None)
            RealHandcuffs:Log.Warning("Deleting corrupt null token.", Library.Settings)
        ElseIf (_target == None)
            RealHandcuffs:Log.Warning("Deleting null token without target.", Library.Settings)
        Else
            RealHandcuffs:Log.Warning("Deleting null token for " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + ".", Library.Settings)
        EndIf
    ElseIf (Library != None && expectedTarget != None && _target == expectedTarget)
        RealHandcuffs:ActorToken targetToken = _target.GetLinkedRef(Library.LinkedActorToken) as RealHandcuffs:ActorToken
        If (targetToken == Self)
            ObjectReference myContainer = GetContainer()
            If (myContainer != _target)
                If (myContainer == None)
                    _target.AddItem(Self, 1, true)
                Else
                    myContainer.RemoveItem(Self, 1, true, _target)
                EndIf
                myContainer = GetContainer()
                If (myContainer == _target)
                    If (Library.Settings.InfoLoggingEnabled)
                        RealHandcuffs:Log.Info("Moved token back to " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + ".", Library.Settings) ; Info because we trigger this condition, too
                    EndIf
                Else
                    RealHandcuffs:Log.Warning("Failed to move token back to " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + ".", Library.Settings)
                EndIf
            EndIf
            Int itemCount = myContainer.GetItemCount(GetBaseObject())
            If (itemCount > 1)
                RealHandcuffs:Log.Warning("Cleaning up " + (itemCount - 1) + " additional tokens in inventory of " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + ".", Library.Settings)
                Drop(true)
                myContainer.DropObject(GetBaseObject(), itemCount) ; will force another CheckConsistency on all tokens
            EndIf
            Return true
        Else
            RealHandcuffs:Log.Warning("Deleting orphaned token for " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + ".", Library.Settings)
        EndIf
    ElseIf (Library == None)
        RealHandcuffs:Log.Warning("Deleting corrupt token.", Library.Settings)
    ElseIf (_target == None)
        RealHandcuffs:Log.Warning("Deleting token without target.", Library.Settings)
    Else
        RealHandcuffs:Log.Warning("Deleting token with wrong target.", Library.Settings)
    EndIf
    DestroyInconsistentToken(expectedTarget)
    Return false
EndFunction

;
; Destroy a inconsistent token and tries to restore the worn restraints.
;
Function DestroyInconsistentToken(Actor expectedTarget)
    RealHandcuffs:RestraintBase[] maybeWornRestraints = None
    If (Library != None && expectedTarget != None)
        maybeWornRestraints = _restraints
        If ((expectedTarget.GetLinkedRef(Library.LinkedActorToken) as RealHandcuffs:ActorToken) == Self)
            expectedTarget.SetLinkedRef(None, Library.LinkedActorToken)
        EndIf
    EndIf
    Uninitialize()
    If (maybeWornRestraints != None)
        RealHandcuffs:ActorToken newToken = None
        Int index = 0
        While (index < maybeWornRestraints.Length)
            If (expectedTarget.IsEquipped(maybeWornRestraints[index].GetBaseObject()))
                If (newToken == None)
                    newToken = Library.GetOrCreateActorToken(expectedTarget)
                    If (newToken.Restraints.Length != 0)
                        RealHandcuffs:Log.Warning("Unable to restore worn restraints.", Library.Settings)
                        Return ; chicken out
                    EndIf
                EndIf
                newToken.Restraints.Add(maybeWornRestraints[index])
            EndIf
            index += 1
        EndWhile
        If (newToken != None)
            newToken.RefreshEffectsAndAnimations(true, None)
            RealHandcuffs:Log.Warning("Restored worn restraints: " + newToken.Restraints.Length, Library.Settings)
        EndIf
    EndIf
EndFunction

;
; Refresh data after the game has been loaded.
;
Function RefreshOnGameLoad(Bool upgrade)
    Int index = 0
    While (index < _restraints.Length)
        _restraints[index].RefreshOnGameLoad(upgrade)
        index += 1
    EndWhile
    If (index > 0 && upgrade)
        RefreshEffectsAndAnimations(true, None)
    EndIf
EndFunction

;
; Refresh all static event registrations that don't depend on equipped restraints.
; This function is called when the version of the mod is updated.
;
Function RefreshEventRegistrations()
    If (_target != None)
        UnregisterForRemoteEvent(_target, "OnItemEquipped")
        RegisterForRemoteEvent(_target, "OnItemEquipped")
        UnregisterForRemoteEvent(_target, "OnItemUnequipped")
        RegisterForRemoteEvent(_target, "OnItemUnequipped")
    EndIf
EndFunction

;
; Check if a specified restraint instance is currently applied to the actor.
;
Bool Function IsApplied(RealHandcuffs:RestraintBase restraint)
    Int index = 0
    While (index < _restraints.Length)
        If (_restraints[index] == restraint)
            Return True
        EndIf
        index += 1
    EndWhile
    Return False
EndFunction

;
; Return all currently applied restraints that have conflicting item slots with the specified slot mask.
;
RealHandcuffs:RestraintBase[] Function GetConflictingRestraints(Int slotMask)
    RealHandcuffs:RestraintBase[] conflicts = None
    Int index = 0
    While (index < _restraints.Length)
        RealHandcuffs:RestraintBase restraint = _restraints[index]
        If (Math.LogicalAnd(slotMask, restraint.GetBaseObject().GetSlotMask()) != 0)
            If (conflicts == None)
                conflicts = new RealHandcuffs:RestraintBase[0]
            EndIf
            conflicts.Add(restraint)
        EndIf
        index += 1
    EndWhile
    return conflicts
EndFunction

;
; Apply a restraint to the actor and update all effects and animations.
;
Function ApplyRestraint(RealHandcuffs:RestraintBase restraint)
    ObjectReference restraintContainer = restraint.GetContainer()
    If (restraintContainer != _target)
        If (_target == None)
            RealHandcuffs:Log.Warning("Trying to apply restraint on token without target.", Library.Settings)
            CheckConsistency(restraintContainer as Actor)
            Return
        ElseIf (restraintContainer == None)
            RealHandcuffs:Log.Warning("Trying to apply restraint that is not in inventory, adding restraint.", Library.Settings)
            _target.AddItem(restraint, 1, false)
        Else
            RealHandcuffs:Log.Warning("Trying to apply restraint that is not in inventory.", Library.Settings)
            Return
        EndIf
    EndIf
    Int index = 0
    Int position = 0
    While (index < _restraints.Length)
        If (_restraints[index] == restraint)
            RealHandcuffs:Log.Warning("Trying to apply restraint that is already applied.", Library.Settings)
            Return
        EndIf
        If (restraint.GetPriority() >= _restraints[index].GetPriority())
            position = index + 1
        EndIf
        index += 1
    EndWhile
    _restraints.Insert(restraint, position) ; keep restraints sorted by increasing priority
    RefreshEffectsAndAnimations(false, restraint)
    Var[] kArgs = new Var[2]
    kArgs[0] = _target
    kArgs[1] = restraint
    Library.SendCustomEvent("OnRestraintApplied", kArgs)
EndFunction

;
; Unapply a restraint and update all effects and animations.
;
Function UnapplyRestraint(RealHandcuffs:RestraintBase restraint)
    Int index = 0
    While (index < _restraints.Length)
        If (_restraints[index] == restraint)
            _restraints.Remove(index)
            RefreshEffectsAndAnimations(false, None)
            Var[] kArgs = new Var[2]
            kArgs[0] = _target
            kArgs[1] = restraint
            Library.SendCustomEvent("OnRestraintUnapplied", kArgs)
            If (restraint.HasKeyword(Library.DeleteWhenUnequipped))
                ObjectReference cnt = restraint.GetContainer()
                If (cnt != None)
                    ; unequip before dropping to prevent visual errors
                    Actor cntActor = cnt as Actor
                    If (cntActor != None)
                        Form baseObject = restraint.GetBaseObject()
                        If (cntActor.IsEquipped(baseObject))
                            cntActor.UnequipItem(baseObject, false, true)
                        EndIf                
                    EndIf
                    restraint.Drop()
                    restraint.DisableNoWait()
                    If (UI.IsMenuOpen("ContainerMenu"))
                        restraint.KickContainerUI(cnt)
                    EndIf
                Else
                    restraint.DisableNoWait()
                EndIf
                restraint.Delete()
            EndIf
            Return
        EndIf
        index += 1
    EndWhile
    RealHandcuffs:Log.Warning("Trying to unapply restraint that is not applied.", Library.Settings)
EndFunction

;
; Suspend all effects and animations.
;
Function SuspendEffectsAndAnimations()
    ApplyEffects(False, None, None)
    ApplyAnimations(False, None)
EndFunction

;
; Refresh all effects and animations.
;
Function RefreshEffectsAndAnimations(Bool forceRefresh, ObjectReference maybeNewlyAppliedRestraint)
    If (Library.Settings.Disabled)
        If (forceRefresh)
            ApplyEffects(True, None, None)
            ApplyAnimations(True, None)
        EndIf
        Return
    EndIf
    ; combine all effects and animations
    ; _restraints are sorted by increasing priority, so the last one wins for each effect / animation
    Bool isInPowerArmor = _target.IsInPowerArmor()
    RealHandcuffs:RestraintBase[] unequippedRestraints = None
    RealHandcuffs:RestraintBase handsBoundBehindBackRestraint = None
    Keyword mtAnimationForArms = None
    RealHandcuffs:RestraintBase[] remoteTriggerRestraints = None
    Int restraintIndex = 0
    While (restraintIndex < _restraints.Length)
        RealHandcuffs:RestraintBase restraint = _restraints[restraintIndex]
        String impact = restraint.GetImpact()
        If (restraint.GetContainer() != _target || impact == "")
            RealHandcuffs:Log.Warning("Removing " + restraint.GetDisplayName() + " impact from " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + ", restraint missing or invalid.", Library.Settings)
            _restraints.Remove(restraintIndex, 1)
            If (_target == Game.GetPlayer())
                Library.Settings.OnPlayerRestraintsChanged(Restraints)
            EndIf
            ; continue loop without any other actions!
        Else
            If (!isInPowerArmor && restraint != maybeNewlyAppliedRestraint && !_target.IsEquipped(restraint.GetBaseObject()))
                If (unequippedRestraints == None)
                    unequippedRestraints = new RealHandcuffs:RestraintBase[1]
                    unequippedRestraints[0] = restraint
                Else
                    unequippedRestraints.Add(restraint)
                EndIf
            EndIf
            If (impact == Library.HandsBoundBehindBack)
                handsBoundBehindBackRestraint = restraint
                Keyword animation = restraint.GetMtAnimationForArms()
                If (animation != None)
                    mtAnimationForArms = animation
                EndIf
            ElseIf (impact == Library.RemoteTriggerEffect)
                If (remoteTriggerRestraints == None)
                    remoteTriggerRestraints = new RealHandcuffs:RestraintBase[1]
                    remoteTriggerRestraints[0] = restraint
                Else
                    remoteTriggerRestraints.Add(restraint)
                EndIf
            ElseIf (impact != Library.NoImpact)
                RealHandcuffs:Log.Error("Unknown impact '" + impact + "', restraint: " + RealHandcuffs:Log.FormIdAsString(restraint.GetBaseObject()) + " " + restraint.GetDisplayName(), Library.Settings)
            EndIf
            restraintIndex += 1
        EndIf
    EndWhile
    ApplyEffects(forceRefresh, handsBoundBehindBackRestraint, remoteTriggerRestraints)
    ApplyAnimations(forceRefresh, mtAnimationForArms)
    If (unequippedRestraints != None)
        restraintIndex = 0
        While (restraintIndex < unequippedRestraints.Length)
            RealHandcuffs:RestraintBase restraint = unequippedRestraints[restraintIndex]
            RealHandcuffs:Log.Warning("Reequipping unequipped restraint " + restraint.GetDisplayName() + " on " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + ".", Library.Settings)
            restraint.ForceEquip(true) ; unequip conflicting to resolve conflicts according to priority
            restraintIndex += 1
        EndWhile
    EndIf
EndFunction

;
; Apply effects to the actor.
;
Function ApplyEffects(Bool forceRefresh, RealHandcuffs:RestraintBase handsBoundBehindBackRestraint, RealHandcuffs:RestraintBase[] remoteTriggerRestraints)
    RealHandcuffs:Log.Error("Missing ApplyEffects override in subclass.", Library.Settings)    
EndFunction

;
; Apply animations to the actor.
;
Function ApplyAnimations(Bool forceRefresh, Keyword mtAnimationForArms)
    If (!forceRefresh && mtAnimationForArms == _mtAnimationForArms)
        ; nothing to do
        Return
    EndIf
    ; add or remove up the 'override' keywords that are here to increase the chance that our animations are picked up
    Bool oldHasAnimations = _mtAnimationForArms != None
    Bool newHasAnimations = mtAnimationForArms != None
    If (forceRefresh || oldHasAnimations != newHasAnimations)
        If (forceRefresh || !newHasAnimations)
            _target.ResetKeyword(Library.Resources.OverrideAnims0)
            _target.ResetKeyword(Library.Resources.OverrideAnims1)
            _target.ResetKeyword(Library.Resources.OverrideAnims2)
            _target.ResetKeyword(Library.Resources.OverrideAnims3)
        EndIf
        If (newHasAnimations)
            _target.AddKeyword(Library.Resources.OverrideAnims0)
            _target.AddKeyword(Library.Resources.OverrideAnims1)
            _target.AddKeyword(Library.Resources.OverrideAnims2)
            _target.AddKeyword(Library.Resources.OverrideAnims3)
        EndIf
    EndIf
    ; add or remove the actual animation keywords
    If (_mtAnimationForArms != None)
        _target.ResetKeyword(_mtAnimationForArms)
    EndIf
    _mtAnimationForArms = mtAnimationForArms
    If (mtAnimationForArms != None)
        _target.AddKeyword(mtAnimationForArms)
    EndIf
    KickAnimationSubsystem()
EndFunction

;
; Apply effects that depend on the state of the equipped restraints.
;
Function ApplyStatefulEffects()
    Bool frequentlyRepeatingShocks = false
    Bool repeatingShocks = false
    Int index = 0
    While (index < _restraints.Length)
        RealHandcuffs:ShockCollarBase collar = _restraints[index] as RealHandcuffs:ShockCollarBase
        If (collar != None)
            Float frequency = collar.GetTortureModeFrequency()
            If (frequency > 0)
                If (frequency < 1)
                    frequentlyRepeatingShocks = true
                Else
                    repeatingShocks = true
                EndIf
            EndIf
        EndIf
        index += 1
    EndWhile
    If (frequentlyRepeatingShocks)
        _target.AddKeyword(Library.Resources.FrequentlyRepeatingShocks)
    Else
        _target.ResetKeyword(Library.Resources.FrequentlyRepeatingShocks)
    EndIf
    If (repeatingShocks)
        _target.AddKeyword(Library.Resources.RepeatingShocks)
    Else
        _target.ResetKeyword(Library.Resources.RepeatingShocks)
    EndIf
EndFunction

;
; Kick the animations subsystem to trigger the changed animations.
;
Function KickAnimationSubsystem()
    RealHandcuffs:Log.Error("Missing KickAnimations override in subclass.", Library.Settings)
EndFunction

;
; Handle a remote trigger being fired in the vicinity.
;
Bool Function HandleRemoteTriggerFired()
    If (GetRemoteTriggerEffect())
        RealHandcuffs:RestraintBase[] restraintsToTrigger = new RealHandcuffs:RestraintBase[0]
        Int index = 0
        While (index < _restraints.Length)
            RealHandcuffs:RestraintBase restraint = _restraints[index]
            If (restraint.GetImpact() == Library.RemoteTriggerEffect)
                restraintsToTrigger.Add(restraint)
            EndIf
            index += 1
        EndWhile
        Index = 0
        While (index < restraintsToTrigger.Length)
            restraintsToTrigger[index].Trigger(Target, false)
            index += 1
        EndWhile
    EndIf
EndFunction

;
; Event handler for equipping items. This will just forward to HandleItemEquipped.
;
Event Actor.OnItemEquipped(Actor sender, Form akBaseObject, ObjectReference akReference)
    HandleItemEquipped(akBaseObject, akReference)
EndEvent

;
; Event handler for actor unequipped item. This will just forward to HandleItemUnequipped.
;
Event Actor.OnItemUnequipped(Actor sender, Form akBaseObject, ObjectReference akReference)
    If (!sender.IsDead())
        HandleItemUnequipped(akBaseObject, akReference)
    EndIf
EndEvent

;
; React on the actor equipping an item.
;
Function HandleItemEquipped(Form akBaseObject, ObjectReference akReference)
    If (akReference != None && akBaseObject.HasKeyword(Library.Resources.Restraint)) ; we can only do the sanity check if akReference is set
        RealHandcuffs:RestraintBase restraint = akReference as RealHandcuffs:RestraintBase
        If (restraint == None)
            RealHandcuffs:Log.Error("Detected restraint (" + RealHandcuffs:Log.FormIdAsString(akReference) + " " + akReference.GetDisplayName() + ") with missing script in inventory of " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + ".", Library.Settings)
            akReference.Drop(true) ; will unequip, too
            _target.AddItem(akReference, 1, true)
            If (UI.IsMenuOpen("ContainerMenu"))
                ; copy of RestraintBase.KickContainerUI, we cannot use it here as the script might still be missing
                _target.AddItem(Library.Resources.BobbyPin, 1, true)
                _target.RemoveItem(Library.Resources.BobbyPin, 1, true, None)
            EndIf
        EndIf
    EndIf
EndFunction

;
; React on the actor unequipping an item.
;
Function HandleItemUnequipped(Form akBaseObject, ObjectReference akReference)
    ; akReference is often None
    Int index = 0
    While (index < _restraints.Length)
        RealHandcuffs:RestraintBase restraint = _restraints[index]
        If (akReference != None)
            If (restraint == akReference)
                restraint.HandleUnequipped(_target) ; forward event to restraint
                Return
            EndIf
        ElseIf (restraint.GetBaseObject() == akBaseObject)
            restraint.HandleUnequipped(_target) ; forward event to restraint
            Return
        EndIf
        index += 1
    EndWhile
EndFunction