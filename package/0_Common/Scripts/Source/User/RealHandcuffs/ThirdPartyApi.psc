;
; A script with functions for third party mods that want to use RealHandcuffs as a (soft) depencency.
; All arguments and return types are generic types to facilitate using this with CallFunction / CallFunctionNoWait.
; This should be considered a stable API, i.e. the signature of existing functions should not change between versions.
; You may also want to take a look at the file "integrating into other mods.txt" in the Resources folder of the RealHandcuffs zip file.
;
Scriptname RealHandcuffs:ThirdPartyApi extends Quest


;
; --------- Functions to determine the installed version of RealHandcuffs. ----------
;

;
; Get the user-visible version of RealHandcuffs. This is the same version as shown in the MCM page, for example "0.3 beta 6".
; This can be used to show a error message like "Detected RealHandcuffs version <UserVisibleVersion> but version x.y.z is required."
;
String Function UserVisibleVersion()
    Return Installer.DetailedVersion
EndFunction

;
; Get the version of this API. This is a integer version number that will be incemented when changes are made to this script.
; It can be used to check if the installed version is compatible with your mod.
;
; ApiVersion    UserVisibleVersion
; 1             0.3 beta 6
; 2             0.3 beta 7
; 3             0.3 RC 2
; 4             0.3 RC 3
; 5             0.4 beta 1
; 6             0.4 beta 5
; 7             0.4 beta 6
; 8             0.4 RC 1
; 9             0.4.4 beta 1
; 10            0.4.4 RC 1
; 11            0.4.9 beta 1
;
Int Function ApiVersion()
    Return 10
EndFunction


;
; --------- Constants for flags. ---------
;

;
; Many functions take a 'Int flags' argument that can be used to specify options for the function. Multiple options can be combined by adding them.
; The actual values will stay constant between versions, so callers can directly hardcode flag values; it is not necessary to call the properties.
; For example, to create and equip hinged high security handcuffs on the player using CallFunction, unequipping any currently worn handcuffs, use the
; following code:
;
;     Var[] kArgs = new Var[3]
;     kArgs[0] = Game.GetPlayer()
;     kArgs[1] = 9 ; FlagUnequipConflictingRestraints (1) +  FlagHinged (8)
;     kArgs[2] = 1 ; ModHighSecurityLock, see below in group Mods
;     thirdPartyApi.CallFunction("CreateHandcuffsWithModsEquipOnActor", kArgs)
;
; While this looks more complicated than just adding a bunch of Bool flags at the end of each function, it allows adding new flags to the API without
; changing the signatures of existing functions, so compatibility is maintained.
;
Group Flags

    ;
    ; A flag specifying that conflicting restraints should be unequipped to allow equipping of a restraint.
    ; Added in api version: 4
    ;
    Int Property FlagUnequipConflictingRestraints = 1 AutoReadOnly

    ;
    ; A flag specifying that objects should be added/removed silently.
    ; In other words, abSilent will be set to true when calling ObjectReference functions like AddItem, RemoveItem and Drop.
    ; Added in api version: 4
    ;
    Int Property FlagAddRemoveObjectsSilently = 2 AutoReadOnly

    ;
    ; A flag specifying that a created object reference should be disabled.
    ; In other words, abInitiallyDisabled will be set to true when calling ObjectReference.PlaceAtMe.
    ; Added in api version: 4
    ;
    Int Property FlagInitiallyDisabled = 4 AutoReadOnly

    ;
    ; A flag specifying that restraints should be of the hinged variant.
    ; Added in api version: 4
    ;
    Int Property FlagHinged = 8 AutoReadOnly

    ; made obsolete in api version: 5
    Int Property FlagHighSecurity = 16 AutoReadOnly

EndGroup


;
; ---------- Constants for restraint effects. ----------
;

;
; Restraints can be classified by the effect that they have on the actor wearing them.
; Some functions allow to filter by effect. Combining multiple effects by adding them
; will make the filter work on restraints with any of the combined effects.
;
Group Effects

    ;
    ; Wearing the restraint has no functional impact; the restraint is just visual.
    ; Example: Broken handcuffs. Added in api version: 8
    ;
    Int Property NoImpact = 1 AutoReadOnly
    
    ;
    ; Wearing the restraint binds the actors hands behind their back.
    ; Example: Handcuffs. Added in api version: 8
    ;
    Int Property HandsBoundBehindBack = 2 AutoReadOnly
    
    ;
    ; Wearing the restraint will cause some effect when a remote trigger is fired in the vicinity.
    ; Example: Shock collar. Added in api version: 8
    ;
    Int Property RemoteTriggerEffect = 4 AutoReadOnly

EndGroup


;
; ---------- Constants for mods. ----------
;

;
; Functions that create objects take a 'Int mods' argument that can be used to specify mods for the object to create. Multiple options can be combined
; by adding them, provided that they are compatible (i.e. they are for different mod slots). The actual values will stay constant between versions, so
; callers can directly hardcode flag values; it is not necessary to call the properties.
;
Group Mods
   
   ; mods for handcuffs
   
   ;
   ; Replace the standard lock with a high security lock.
   ; Added in api version: 5
   ;
   Int Property ModHighSecurityLock = 1 AutoReadOnly
   
   ; mods for shock collars
   
   ;
   ; Replace the standard shock module with a throbbing shock module.
   ; Added in api version: 5
   ;
   Int Property ModThrobbingShockModule = 1 AutoReadOnly
   
   ;
   ; Replace the standard shock module with a explosive module.
   ; Added in api version: 5
   ;
   Int Property ModExplosiveModule = 2 AutoReadOnly
   
   ;
   ; Replace the standard firmware with mark three firmware.
   ; Added in api version: 5
   ;
   Int Property ModMarkThreeFirmware = 4 AutoReadOnly

   ;
   ; Replace the standard firmware with hacked firmware.
   ; Added in api version: 7
   ;
   Int Property ModHackedFirmware = 8 AutoReadOnly
   
   ; mods for remote triggers
   
   ;
   ; Replaces the standard transmitter with powerful transmitter.
   ; Added in api version: 8
   ;
   Int Property ModPowerfulTransmitter = 1 AutoReadOnly   

EndGroup


;
; ---------- Constants for trigger modes. ----------
;

;
; Some restraints (shock collars!) can be configured how they can be triggered. Options cannot be combined. The actual values will stay constant between
; versions, so callers can directly hardcode trigger modes; it is not necessary to call the properties.
;
Group TriggerMode

    ;
    ; The restraint triggers after receiving any signal.
    ; Added in api version: 5
    ;
    Int Property SimpleTrigger = 0 AutoReadOnly
    
    ;
    ; The restraint triggers after receiving a single signal, followed by no further signals for 0.5 seconds.
    ; Added in api version: 5
    ;
    Int Property SingleSignalTrigger = 1 AutoReadOnly
    
    ;
    ; The restraint triggers after receiving two signals with not more than 0.5 seconds between signals, followed by no further signals for 0.5 seconds.
    ; Added in api version: 5
    ;
    Int Property DoubleSignalTrigger = 2 AutoReadOnly

    ;
    ; The restraint triggers after receiving three signals with not more than 0.5 seconds between signals, followed by no further signals for 0.5 seconds.
    ; Added in api version: 5
    ;
    Int Property TripleSignalTrigger = 3 AutoReadOnly

EndGroup


;
; ---------- Constants for failed access actions. ----------
;

;
; Some restraints (shock collars!) can be configured how to react on failed/unauthorized access. Options cannot be combined. The actual values will stay constant
; between versions, so callers can directly hardcode failed access actions; it is not necessary to call the properties.
;
Group UnauthorizedAccessAction
    
    ;
    ; Ignore failed/unauthorized access.
    ; Added in api version: 5
    ;
    Int Property IgnoreUnauthorizedAccess = 0 AutoReadOnly

    ;
    ; Lock for some time on failed/unauthorized access.
    ; Added in api version: 5
    ;
    Int Property UnauthorizedAccessLockout = 1 AutoReadOnly
    
    ;
    ; Trigger the restraint on unauthorized access.
    ; Added in api version: 5
    ;
    Int Property UnauthorizedAccessTrigger = 2 AutoReadOnly
    
    ;
    ; Lock for some time and trigger the restraint on unauthorized access.
    ; Added in api version: 5
    ;
    Int Property UnauthorizedAccessLockAndTrigger = 3 AutoReadOnly

EndGroup


;
; ---------- Constants for poses. ----------
;

;
; Some functions may put an actor into a pose. These are the valid values for the pose.
;
Group Pose
    
    ;
    ; No pose (i.e. standing, may even walk around depending on package).
    ; Added in api version: 10
    ;
    Int Property PoseNone = 0 AutoReadOnly

    ;
    ; Kneeling/sitting pose, looks rather submissive.
    ; Added in api version: 10
    ;
    Int Property PoseKneelSit = 1 AutoReadOnly
    
    ;
    ; Uneasy kneeling pose, uses the "hostage" animation.
    ; Added in api version: 10
    ;
    Int Property PoseHeldHostageKneelHandsUp = 2 AutoReadOnly
    
EndGroup


;
; --------- Functions to create and destroy restraints and keys. ----------
;

;
; Create  handcuffs close to a reference.
; The following flags are supported: FlagInitiallyDisabled, FlagHinged
; Returns the handcuffs. Added in api version: 4
;
ObjectReference Function CreateHandcuffsCloseTo(ObjectReference placeAtReference, Int flags = 0)
    If (Math.LogicalAnd(flags, FlagHighSecurity) != 0)
        Return CreateHandcuffsWithModsCloseTo(placeAtReference, flags - FlagHighSecurity, ModHighSecurityLock) ; obsolete code path
    Else
        Return CreateHandcuffsWithModsCloseTo(placeAtReference, flags, 0)    
    EndIf
EndFunction

;
; Create handcuffs with mods close to a reference.
; The following flags are supported: FlagInitiallyDisabled, FlagHinged
; The following mods are supported: ModHighSecurityLock
; Returns the handcuffs. Added in api version: 5
;
ObjectReference Function CreateHandcuffsWithModsCloseTo(ObjectReference placeAtReference, Int flags = 0, Int mods = 0)
    ObjectReference placeAtTarget = placeAtReference
    If (placeAtTarget == None)
        placeAtTarget = Game.GetPlayer() ; fallback
    EndIf
    ObjectReference restraint
    If (Math.LogicalAnd(flags, FlagHinged) == 0)
        restraint = placeAtTarget.PlaceAtMe(Handcuffs, 1, false, true, false)
    Else
        restraint = placeAtTarget.PlaceAtMe(HandcuffsHinged, 1, false, true, false)
    EndIf
    If (Math.LogicalAnd(mods, ModHighSecurityLock) != 0)
        SetHighSecurityLock(restraint)
    EndIf
    If (Math.LogicalAnd(flags, FlagInitiallyDisabled) == 0)
        restraint.EnableNoWait()
    EndIf
    Return restraint
EndFunction

;
; Create random handcuffs close to a reference. Percent values are expected to be in the range [0, 100].
; The following flags are supported: FlagInitiallyDisabled
; Returns the handcuffs. Added in api version: 4
;
ObjectReference Function CreateRandomHandcuffsCloseTo(ObjectReference placeAtReference, Int percentHinged = 20, Int percentHighSecurity = 20, Int flags = 0)
    Int actualFlags = Math.LogicalAnd(flags, FlagInitiallyDisabled)
    Int actualMods = 0
    If (CheckRandomPercent(percentHinged))
        actualFlags += FlagHinged
    EndIf
    If (CheckRandomPercent(percentHighSecurity))
        actualMods += ModHighSecurityLock
    EndIf
    Return CreateHandcuffsWithModsCloseTo(placeAtReference, actualFlags, actualMods)
EndFunction

;
; Create a key for a restraint in the same place as the restraint.
; The following flags are supported: FlagInitiallyDisabled, FlagAddRemoveObjectsSilently
; Returns the key on success, None on failure (e.g. if the restraint has no keys). Added in api version: 4
;
ObjectReference Function CreateKeyCloseToRestraint(ObjectReference restraint, Int flags)
    RealHandcuffs:RestraintBase restraintBase = restraint as RealHandcuffs:RestraintBase
    If (restraintBase == None)
        ; restraint None or not supported
        Return None
    EndIf
    Form keyObject = restraintBase.GetKeyObject()
    If (keyObject == None)
        ; restraint has no keys (e.g. timed lock)
        Return None
    EndIf
    ObjectReference cont = restraint.GetContainer()
    ObjectReference createdKey = restraint.PlaceAtMe(keyObject, 1, false, true, false)
    If (cont != None)
        createdKey.EnableNoWait()
        cont.AddItem(createdKey, 1, Math.LogicalAnd(flags, FlagAddRemoveObjectsSilently) != 0)
    ElseIf (Math.LogicalAnd(flags, FlagInitiallyDisabled) == 0)
        createdKey.EnableNoWait()
    EndIf
    Return createdKey
EndFunction

;
; Add keys for a restraint to a container.
; The following flags are supported: FlagAddRemoveObjectsSilently
; The container can be an Actor, but for this to work with CallFunction, the Actor needs to be cast to ObjectReference:
;    kArgs[1] = actorToReceiveKeys as ObjectReference
; Returns true on success, false on failure. Added in api version: 4
;
Bool Function CreateKeysInContainer(ObjectReference restraint, ObjectReference containerToAddKeys, Int keyCount = 1, Int flags = 0)
    RealHandcuffs:RestraintBase restraintBase = restraint as RealHandcuffs:RestraintBase
    If (restraintBase == None || containerToAddKeys == None)
        ; restraint None or not supported, or containerToAddKeys None
        Return false
    EndIf
    Form keyObject = restraintBase.GetKeyObject()
    If (keyObject == None)
        ; restraint has no keys (e.g. timed lock)
        Return false
    EndIf
    containerToAddKeys.AddItem(keyObject, keyCount, Math.LogicalAnd(flags, FlagAddRemoveObjectsSilently) != 0)
    Return true
EndFunction


;
; Remove all keys for a restraint from a container.
; If containerToAddKeys is specified, the keys are added to that container; otherwise they are deleted.
; Either container can be an Actor, but for this to work with CallFunction, the Actor needs to be cast to ObjectReference:
;    kArgs[1] = actorToRemoveKeys as ObjectReference
;    kArgs[2] = actorToAddKeys as ObjectReference
; The following flags are supported: FlagAddRemoveObjectsSilently
; Returns the number of removed keys. Added in api version: 4
;
Int Function RemoveKeysFromContainer(ObjectReference restraint, ObjectReference containerToRemoveKeys, ObjectReference containerToAddKeys = None, Int flags = 0)
    RealHandcuffs:RestraintBase restraintBase = restraint as RealHandcuffs:RestraintBase
    If (restraintBase == None || containerToRemoveKeys == None)
        ; restraint None or not supported, or containerToRemoveKeys None
        Return 0
    EndIf
    Form keyObject = restraintBase.GetKeyObject()
    If (keyObject == None)
        ; restraint has no keys (e.g. timed lock)
        Return 0
    EndIf
    Int keyCount = containerToRemoveKeys.GetItemCount(keyObject)
    If (keyCount != 0)
        containerToRemoveKeys.RemoveItem(keyObject, keyCount, Math.LogicalAnd(flags, FlagAddRemoveObjectsSilently) != 0, containerToAddKeys)
    EndIf
    Return keyCount
EndFunction


;
; Create a shock collar close to a reference.
; The following flags are supported: FlagInitiallyDisabled
; Returns the shock collar. Added in api version: 5
;
ObjectReference Function CreateShockCollarCloseTo(ObjectReference placeAtReference, Int flags = 0)
    Return CreateShockCollarWithModsCloseTo(placeAtReference, flags, 0)
EndFunction

;
; Create a shock collar with mods close to a reference.
; The following flags are supported: FlagInitiallyDisabled
; The following mods are supported: ModThrobbingShockModule, ModExplosiveModule, ModMarkThreeFirmware, ModHackedFirmware
; Returns the shock collar. Added in api version: 5
;
ObjectReference Function CreateShockCollarWithModsCloseTo(ObjectReference placeAtReference, Int flags = 0, Int mods = 0)
    ObjectReference placeAtTarget = placeAtReference
    If (placeAtTarget == None)
        placeAtTarget = Game.GetPlayer() ; fallback
    EndIf
    ObjectReference restraint = placeAtTarget.PlaceAtMe(ShockCollar, 1, false, true, false)
    If (Math.LogicalAnd(mods, ModThrobbingShockModule) != 0)
        SetThrobbingShockModule(restraint)
    ElseIf (Math.LogicalAnd(mods, ModExplosiveModule) != 0)
        SetExplosiveModule(restraint)
    EndIf
    If (Math.LogicalAnd(mods, ModMarkThreeFirmware) != 0)
        SetMarkThreeFirmware(restraint)
    ElseIf (Math.LogicalAnd(mods, ModHackedFirmware) != 0)
        SetHackedFirmware(restraint)
    EndIf
    If (Math.LogicalAnd(flags, FlagInitiallyDisabled) == 0)
        restraint.EnableNoWait()
    EndIf
    Return restraint
EndFunction

;
; Create a random shock collar close to a reference. Percent values are expected to be in the range [0, 100].
; The following flags are supported: FlagInitiallyDisabled
; Returns the handcuffs. Added in api version: 5
;
ObjectReference Function CreateRandomShockCollarCloseTo(ObjectReference placeAtReference, Int percentThrobbing = 20, Int percentMarkThreeFirmware = 20, Int flags = 0)
    Int actualFlags = Math.LogicalAnd(flags, FlagInitiallyDisabled)
    Int actualMods = 0
    If (CheckRandomPercent(percentThrobbing))
        actualMods += ModThrobbingShockModule
    EndIf
    If (CheckRandomPercent(percentMarkThreeFirmware))
        actualMods += ModMarkThreeFirmware
    EndIf
    Return CreateShockCollarWithModsCloseTo(placeAtReference, actualFlags, actualMods)
EndFunction

;
; Create a remote trigger close to a reference.
; The following flags are supported: FlagInitiallyDisabled
; Returns the remote trigger. Added in api version: 5
;
ObjectReference Function CreateRemoteTriggerCloseTo(ObjectReference placeAtReference, Int flags = 0)
    Return CreateRemoteTriggerWithModsCloseTo(placeAtReference, flags, 0)
EndFunction

; Create a remote trigger with mods close to a reference.
; The following flags are supported: FlagInitiallyDisabled
; The following mods are supported: ModPowerfulTransmitter
; Returns the remote trigger. Added in api version: 8
;
ObjectReference Function CreateRemoteTriggerWithModsCloseTo(ObjectReference placeAtReference, Int flags = 0, Int mods = 0)
    ObjectReference placeAtTarget = placeAtReference
    If (placeAtTarget == None)
        placeAtTarget = Game.GetPlayer() ; fallback
    EndIf
    ObjectReference remote = placeAtTarget.PlaceAtMe(RemoteTrigger, 1, false, true, false)
    If (Math.LogicalAnd(mods, ModPowerfulTransmitter) != 0)
        SetPowerfulTransmitter(remote)
    EndIf
    If (Math.LogicalAnd(flags, FlagInitiallyDisabled) == 0)
        remote.EnableNoWait()
    EndIf
    Return remote
EndFunction


;
; --------- Functions to check equipped restraints. ----------
;

;
; Get the restraints currently equipped on an actor.
; Returns a Var that is actually a ObjectReference[] array containing the equipped restraints.
; Added in api version: 3
; Notes:
; The resulting Var can be converted back to an array using Utility.VarToVarArray (this requires F4SE). So over all,
; the code to get the equipped restraints for an actor is the following:
;
;     Var[] akArgs = new Var[1]
;     akArgs[0] = akActor
;     Var restraintsAsVar = thirdPartyApi.CallFunction("GetEquippedRestraints", akArgs)
;     ObjectReference[] restraints = Utility.VarToVarArray(restraintsAsVar) as ObjectReference[]﻿
;
Var Function GetEquippedRestraints(Actor target)
    ObjectReference[] restraints = new ObjectReference[0]
    ActorToken token = Library.TryGetActorToken(target)
    If (token != None)
        RealHandcuffs:RestraintBase[] wornRestraints = token.Restraints
        Int index = 0
        While (index < wornRestraints.Length)
            restraints.Add(wornRestraints[index])
            index += 1
        EndWhile
    EndIf
    Return Utility.VarArrayToVar(restraints as Var[])
EndFunction

;
; A specialized version of GetEquippedRestraints() that filters the result to only return restraints with the specified effect.
; See the documentation of GetEquippedRestraints for more details. Added in api version: 8
;
Var Function GetEquippedRestraintsWithEffect(Actor target, Int effect)
    ObjectReference[] restraints = new ObjectReference[0]
    ActorToken token = Library.TryGetActorToken(target)
    If (token != None)
        RealHandcuffs:RestraintBase[] wornRestraints = token.Restraints
        Int index = 0
        While (index < wornRestraints.Length)
            If (HasEffect(wornRestraints[index], effect))
                restraints.Add(wornRestraints[index])
            EndIf
            index += 1
        EndWhile
    EndIf
    Return Utility.VarArrayToVar(restraints as Var[])
EndFunction

;
; Check if a restraint has the specified effect. This will return true if any one matches if multiple effects are specified by adding effect values.
; Added in api version: 8
;
Bool Function HasEffect(ObjectReference restraint, Int effect)
    RealHandcuffs:RestraintBase restraintBase = restraint as RealHandcuffs:RestraintBase
    If (restraintBase != None)
        If (Math.LogicalAnd(effect, HandsBoundBehindBack) != 0 && restraintBase.GetImpact() == Library.HandsBoundBehindBack)
            Return true
        ElseIf (Math.LogicalAnd(effect, RemoteTriggerEffect) != 0 && restraintBase.GetImpact() == Library.RemoteTriggerEffect)
            Return true
        ElseIf (Math.LogicalAnd(effect, NoImpact) != 0 && restraintBase.GetImpact() == Library.NoImpact)
            Return true
        EndIf
    EndIf
    Return false
EndFunction

;
; Check if the hands of an actor are bound behind their back.
; Added in api version: 6
;
Bool Function HasHandsBoundBehindBack(Actor target)
    Return Library.GetHandsBoundBehindBack(target)
EndFunction

;
; Get whether firing a remote trigger in the vicinity of an actor will cause some effect.
; This usually means that the actor is wearing a shock (or explosive) coller
; Added in api version: 6
;
Bool Function HasRemoteTriggerEffect(Actor target)
    Return Library.GetRemoteTriggerEffect(target)
EndFunction


;
; ---------- Functions to equip and unequip restraints. ----------
;

;
; Create handcuffs and equip them on an actor.
; The following flags are supported: FlagHinged, FlagUnequipConflictingRestraints, FlagAddRemoveObjectsSilently
; Returns the handcuffs on success, None on failure. Added in api version: 4
;
ObjectReference Function CreateHandcuffsEquipOnActor(Actor target, Int flags = 0)
    If (target == None)
        Return None
    EndIf
    RealHandcuffs:RestraintBase restraint = CreateHandcuffsCloseTo(Game.GetPlayer(), flags + FlagInitiallyDisabled) as RealHandcuffs:RestraintBase
    Return EquipOrDeleteNewlyCreatedDisabledRestraint(restraint, target, flags)
EndFunction

;
; Create handcuffs with mods and equip them on an actor.
; The following flags are supported: FlagHinged, FlagUnequipConflictingRestraints, FlagAddRemoveObjectsSilently
; The following mods are supported: ModHighSecurityLock
; Returns the handcuffs on success, None on failure. Added in api version: 5
;
ObjectReference Function CreateHandcuffsWithModsEquipOnActor(Actor target, Int flags = 0, Int mods = 0)
    If (target == None)
        Return None
    EndIf
    RealHandcuffs:RestraintBase restraint = CreateHandcuffsWithModsCloseTo(Game.GetPlayer(), flags + FlagInitiallyDisabled, mods) as RealHandcuffs:RestraintBase
    Return EquipOrDeleteNewlyCreatedDisabledRestraint(restraint, target, flags)
EndFunction

;
; Create random handcuffs and equip them on an actor. Percent values are expected to be in the range [0, 100].
; The following flags are supported: FlagUnequipConflictingRestraints, FlagAddRemoveObjectsSilently
; Returns the handcuffs. Added in api version: 4
;
ObjectReference Function CreateRandomHandcuffsEquipOnActor(Actor target, Int percentHinged = 20, Int percentHighSecurity = 20, Int flags = 0)
    If (target == None)
        Return None
    EndIf
    RealHandcuffs:RestraintBase restraint = CreateRandomHandcuffsCloseTo(Game.GetPlayer(), percentHinged, percentHighSecurity, flags + FlagInitiallyDisabled) as RealHandcuffs:RestraintBase
    Return EquipOrDeleteNewlyCreatedDisabledRestraint(restraint, target, flags)
EndFunction

;
; Create a shock collar and equip it on an actor.
; The following flags are supported: FlagUnequipConflictingRestraints, FlagAddRemoveObjectsSilently
; Returns the shock collar on success, None on failure. Added in api version: 5
;
ObjectReference Function CreateShockCollarEquipOnActor(Actor target, Int flags = 0)
    If (target == None)
        Return None
    EndIf
    RealHandcuffs:RestraintBase restraint = CreateShockCollarCloseTo(Game.GetPlayer(), flags + FlagInitiallyDisabled) as RealHandcuffs:RestraintBase
    Return EquipOrDeleteNewlyCreatedDisabledRestraint(restraint, target, flags)
EndFunction

;
; Create a shock collar with mods and equip it on an actor.
; The following flags are supported: FlagUnequipConflictingRestraints, FlagAddRemoveObjectsSilently
; The following mods are supported: ModThrobbingShockModule, ModExplosiveModule, ModMarkThreeFirmware, ModHackedFirmware
; Returns the handcuffs on success, None on failure. Added in api version: 5
;
ObjectReference Function CreateShockCollarWithModsEquipOnActor(Actor target, Int flags = 0, Int mods = 0)
    If (target == None)
        Return None
    EndIf
    RealHandcuffs:RestraintBase restraint = CreateShockCollarWithModsCloseTo(Game.GetPlayer(), flags + FlagInitiallyDisabled, mods) as RealHandcuffs:RestraintBase
    Return EquipOrDeleteNewlyCreatedDisabledRestraint(restraint, target, flags)
EndFunction

;
; Create a random shock collar and equip it on an actor. Percent values are expected to be in the range [0, 100].
; The following flags are supported: FlagUnequipConflictingRestraints, FlagAddRemoveObjectsSilently
; Returns the handcuffs. Added in api version: 5
;
ObjectReference Function CreateRandomShockCollarEquipOnActor(Actor target, Int percentThrobbing = 20, Int percentMarkThree = 20, Int flags = 0)
    If (target == None)
        Return None
    EndIf
    RealHandcuffs:RestraintBase restraint = CreateRandomShockCollarCloseTo(Game.GetPlayer(), percentThrobbing, percentMarkThree, flags + FlagInitiallyDisabled) as RealHandcuffs:RestraintBase
    Return EquipOrDeleteNewlyCreatedDisabledRestraint(restraint, target, flags)
EndFunction

;
; Equip a restraint on an actor using default settings.
; The following flags are supported: FlagUnequipConflictingRestraints, FlagAddRemoveObjectsSilently
; Returns true on success, false on failure. Added in api version: 4
;
Bool Function EquipRestraintUsingDefaultSettings(ObjectReference restraint, Actor target, Int flags = 0)
    RealHandcuffs:RestraintBase restraintBase = restraint as RealHandcuffs:RestraintBase
    If (restraintBase == None || target == None)
        ; restraint None or not supported, or target None
        Return false
    EndIf
    ObjectReference cont = restraintBase.GetContainer()
    If (restraintBase.IsDisabled())
        restraintBase.EnableNoWait()
    EndIf
    If (cont == None)
        target.AddItem(restraintBase, 1, Math.LogicalAnd(flags, FlagAddRemoveObjectsSilently) != 0)
    Else
        Actor actorCont = cont as Actor
        If (actorCont != None)
            RealHandcuffs:ActorToken contToken = Library.TryGetActorToken(actorCont)
            If (contToken != None && contToken.IsApplied(restraintBase))
                ; restraint already equipped on an actor: return true if actor is target, false otherwise
                Return (actorCont == target)
            EndIf
        EndIf
        If (actorCont != target)
            cont.RemoveItem(restraintBase, 1, Math.LogicalAnd(flags, FlagAddRemoveObjectsSilently) != 0, target)
        EndIf
    EndIf
    restraintBase.ForceEquip(Math.LogicalAnd(flags, FlagUnequipConflictingRestraints) != 0 , true)
    RealHandcuffs:ActorToken token = Library.GetOrCreateActorToken(target)
    Return token.IsApplied(restraintBase)
EndFunction

;
; Equip handcuffs on an actor with non-default settings. This is a specialized version of EquipRestraintUsingDefaultSettings.
; - tightness: 0: very thight, 1: quite tight, 2: rather loose
; - lockFacingAwayFromHands: true to equip hinged handcuffs with the lock facing away from the hands, ignored for non-hinged handcuffs
; The following flags are supported: FlagUnequipConflictingRestraints, FlagAddRemoveObjectsSilently
; Returns true on success, false on failure. Added in api version: 4
;
Bool Function EquipHandcuffsUsingCustomSettings(ObjectReference cuffs, Actor target, Int tightness = 0, Bool lockFacingAwayFromHands = true, Int flags = 0)
    RealHandcuffs:HandcuffsBase baseCuffs = cuffs as RealHandcuffs:HandcuffsBase
    If (baseCuffs == None || target == None)
        ; restraint None or not supported, or target None
        Return false
    EndIf
    If (tightness < 0 || tightness > 2)
        ; unsupported value for tightness
        return false
    EndIf
    If (!EquipRestraintUsingDefaultSettings(baseCuffs, target, flags))
        Return false
    EndIf
    baseCuffs.Tightness = tightness
    RealHandcuffs:HandcuffsHinged hingedCuffs = baseCuffs as RealHandcuffs:HandcuffsHinged
    If (hingedCuffs != None)
        hingedCuffs.LockFacingAwayFromHands = lockFacingAwayFromHands
    EndIf
    Return true
EndFunction

;
; Unequip a restraint from the actor it is currently equipped on but keep it in the actor's inventory.
; The following flags are supported: (none)
; Returns true on success, false on failure. Added in api version: 4
;
Bool Function UnequipRestraintKeepInInventory(ObjectReference restraint, Int flags = 0)
    RealHandcuffs:RestraintBase restraintBase = restraint as RealHandcuffs:RestraintBase
    If (restraintBase == None)
        ; restraint None or not supported
        Return false
    EndIf
    Actor target = restraintBase.SearchCurrentTarget()
    If (target == None)
        ; restraint not equipped
        Return false
    EndIf
    RealHandcuffs:ActorToken token = Library.TryGetActorToken(target)
    If (token == None || !token.IsApplied(restraintBase))
        ; restraint not equipped
        Return false
    EndIf
    restraintBase.ForceUnequip()
    Return true
EndFunction

;
; Unequip a restraint from the actor it is currently equipped on and remove it from the actor's inventory.
; If containerToAddRestraint is specified, the restraint is added to that container; otherwise it is deleted.
; The container can be an Actor, but for this to work with CallFunction, the Actor needs to be cast to ObjectReference:
;    kArgs[1] = containerToAddRestraint as ObjectReference
; The following flags are supported: FlagAddRemoveObjectsSilently
; Returns true on success, false on failure. Added in api version: 4
;
Bool Function UnequipRestraintRemoveFromInventory(ObjectReference restraint, ObjectReference containerToAddRestraint = None, Int flags = 0)
    If (!UnequipRestraintKeepInInventory(restraint, flags))
        Return false
    EndIf
    RemoveRestraintFromInventory(restraint, containerToAddRestraint, flags)
    Return true
EndFunction

;
; Unequip all restraints from an actor but keep them in the actor's inventory.
; The following flags are supported: (none)
; Returns true on success, false on failure. Added in api version: 8
;
Bool Function UnequipAllRestraintsKeepInInventory(Actor target, Int flags = 0)
    RealHandcuffs:RestraintBase[] restraints = GetRestraintsMaybeFilterByEffect(target, 0)
    If (restraints != None)
        Int index = 0
        While (index < restraints.Length)
            restraints[index].ForceUnequip()
            index += 1
        EndWhile
        Return true
    EndIf
    Return false
EndFunction

;
; Unequip all restraints from an actor and remove them from the actor's inventory.
; If containerToAddRestraint is specified, they are added to that container; otherwise they are deleted.
; The container can be an Actor, but for this to work with CallFunction, the Actor needs to be cast to ObjectReference:
;    kArgs[1] = containerToAddRestraint as ObjectReference
; The following flags are supported: FlagAddRemoveObjectsSilently
; Returns true on success, false on failure. Added in api version: 8
;
Bool Function UnequipAllRestraintsRemoveFromInventory(Actor target, ObjectReference containerToAddRestraint = None, Int flags = 0)
    RealHandcuffs:RestraintBase[] restraints = GetRestraintsMaybeFilterByEffect(target, 0)
    If (restraints != None)
        Int index = 0
        While (index < restraints.Length)
            restraints[index].ForceUnequip()
            RemoveRestraintFromInventory(restraints[index], containerToAddRestraint, flags)
            index += 1
        EndWhile
        Return true
    EndIf
    Return false
EndFunction

;
; A specialized version of UnequipAllRestraintsKeepInInventory() that only unequips restraints with the specified effect.
; See the documentation of UnequipAllRestraintsKeepInInventory for more details. Added in api version: 8
;
Bool Function UnequipRestraintsWithEffectKeepInInventory(Actor target, Int effect, Int flags = 0)
    If (effect != 0)
        RealHandcuffs:RestraintBase[] restraints = GetRestraintsMaybeFilterByEffect(target, effect)
        If (restraints != None)
            Int index = 0
            While (index < restraints.Length)
                restraints[index].ForceUnequip()
                index += 1
            EndWhile
            Return true
        EndIf
    EndIf
    Return false
EndFunction

;
; A specialized version of UnequipAllRestraintsRemoveFromInventory() that only unequips restraints with the specified effect.
; See the documentation of UnequipAllRestraintsRemoveFromInventory for more details. Added in api version: 8
;
Bool Function UnequipRestraintsWithEffectRemoveFromInventory(Actor target, Int effect, ObjectReference containerToAddRestraint = None, Int flags = 0)
    If (effect != 0)
        RealHandcuffs:RestraintBase[] restraints = GetRestraintsMaybeFilterByEffect(target, effect)
        If (restraints != None)
            Int index = 0
            While (index < restraints.Length)
                restraints[index].ForceUnequip()
                RemoveRestraintFromInventory(restraints[index], containerToAddRestraint, flags)
                index += 1
            EndWhile
            Return true
        EndIf
    EndIf
    Return false
EndFunction


;
; --------- Functions to modify existing restraints. ----------
;

;
; Change the lock of a restraint to a standard lock (this is the default, so it is only necessary if the lock was modified previously).
; Returns true on success, false on failure. Added in api version: 1
;
Bool Function SetStandardLock(ObjectReference restraint)
    RealHandcuffs:HandcuffsBase handcuffsBase = restraint as RealHandcuffs:HandcuffsBase
    If (handcuffsBase != None)
        handcuffsBase.SetLockMod(ModObjectStandardLock)
        Return true
    EndIf
    ; restraint None or not supported
    Return false
EndFunction

;
; Change the lock of a restraint to a high security lock.
; Returns true on success, false on failure. Added in api version: 1
;
Bool Function SetHighSecurityLock(ObjectReference restraint)
    RealHandcuffs:HandcuffsBase handcuffsBase = restraint as RealHandcuffs:HandcuffsBase
    If (handcuffsBase != None)
        handcuffsBase.SetLockMod(ModObjectHighSecurityLock)
        Return true
    EndIf
    ; restraint None or not supported
    Return false
EndFunction

;
; Change the lock of a restraint to a timed lock. Valid times are 3, 6, 9 and 12 hours.
; Returns true on success, false on failure. Added in api version: 1
;
Bool Function SetTimedLock(ObjectReference restraint, Int timeHours)
    ObjectMod timedLockMod
    If (timeHours == 3)
        timedLockMod = ModObjectTimedLock3h
    ElseIf (timeHours == 6)
        timedLockMod = ModObjectTimedLock6h
    ElseIf (timeHours == 9)
        timedLockMod = ModObjectTimedLock9h
    ElseIf (timeHours == 12)
        timedLockMod = ModObjectTimedLock12h
    Else
        ; timeHours value not supported
        Return false
    EndIf
    RealHandcuffs:HandcuffsBase handcuffsBase = restraint as RealHandcuffs:HandcuffsBase
    If (handcuffsBase != None)
        handcuffsBase.SetLockMod(timedLockMod)
        Return true
    EndIf
    ; restraint None or not supported
    Return false
EndFunction

;
; Change the shock module of a restraint to the standard shock module.
; Returns true on success, false on failure. Added in api version: 5
;
Bool Function SetStandardShockModule(ObjectReference restraint)
    RealHandcuffs:ShockCollarBase shockCollarBase = restraint as RealHandcuffs:ShockCollarBase
    If (shockCollarBase != None)
        shockCollarBase.SetShockModuleMod(ModObjectStandardShockModule)
        Return true
    EndIf
    ; restraint None or not supported
    Return false
EndFunction

;
; Change the shock module of a restraint to a throbbing shock module.
; Returns true on success, false on failure. Added in api version: 5
;
Bool Function SetThrobbingShockModule(ObjectReference restraint)
    RealHandcuffs:ShockCollarBase shockCollarBase = restraint as RealHandcuffs:ShockCollarBase
    If (shockCollarBase != None)
        shockCollarBase.SetShockModuleMod(ModObjectThrobbingShockModule)
        Return true
    EndIf
    ; restraint None or not supported
    Return false
EndFunction

;
; Change the shock module of a restraint to an explosive module.
; Returns true on success, false on failure. Added in api version: 5
;
Bool Function SetExplosiveModule(ObjectReference restraint)
    RealHandcuffs:ShockCollarBase shockCollarBase = restraint as RealHandcuffs:ShockCollarBase
    If (shockCollarBase != None)
        shockCollarBase.SetShockModuleMod(ModObjectExplosiveModule)
        Return true
    EndIf
    ; restraint None or not supported
    Return false
EndFunction

;
; Change the firmware of a restraint to the mark two firmware.
; Returns true on success, false on failure. Added in api version: 5
;
Bool Function SetMarkTwoFirmware(ObjectReference restraint)
    RealHandcuffs:ShockCollarBase shockCollarBase = restraint as RealHandcuffs:ShockCollarBase
    If (shockCollarBase != None)
        shockCollarBase.SetFirmwareMod(ModObjectMarkTwoFirmware)
        Return true
    EndIf
    ; restraint None or not supported
    Return false
EndFunction

;
; Change the firmware of a restraint to the mark three firmware.
; Returns true on success, false on failure. Added in api version: 5
;
Bool Function SetMarkThreeFirmware(ObjectReference restraint)
    RealHandcuffs:ShockCollarBase shockCollarBase = restraint as RealHandcuffs:ShockCollarBase
    If (shockCollarBase != None)
        shockCollarBase.SetFirmwareMod(ModObjectMarkThreeFirmware)
        Return true
    EndIf
    ; restraint None or not supported
    Return false
EndFunction

;
; Change the firmware of a restraint to the hacked firmware.
; Returns true on success, false on failure. Added in api version: 7
;
Bool Function SetHackedFirmware(ObjectReference restraint)
    RealHandcuffs:ShockCollarBase shockCollarBase = restraint as RealHandcuffs:ShockCollarBase
    If (shockCollarBase != None)
        shockCollarBase.SetFirmwareMod(ModObjectHackedFirmware)
        Return true
    EndIf
    ; restraint None or not supported
    Return false
EndFunction

;
; Get the number of digits of the access code for restraints that support an access code.
; Returns the number of digits, or 0 if the restraint does not support an access code. Added in api version: 5
;
Int Function GetAccessCodeNumberOfDigits(ObjectReference restraint)
    RealHandcuffs:ShockCollarBase collar = restraint as RealHandcuffs:ShockCollarBase
    If (collar != None)
        Return collar.GetNumberOfAccessCodeDigits()
    EndIf
    Return 0
EndFunction

;
; Get the access code for restraints that support an access code.
; Returns the access code as an integer, or -1 if the restraint does either not support access codes or does not currently have
; an access code set. Added in api version: 5
;
Int Function GetAccessCode(ObjectReference restraint)
    RealHandcuffs:ShockCollarBase collar = restraint as RealHandcuffs:ShockCollarBase
    If (collar != None)
        Return collar.GetAccessCode()
    EndIf
    Return -1
EndFunction

;
; Get the access code for restraints that support an access code, as a string. The purpose of returning a string is to make the
; access code unambiguous even in the precense of leading zeros.
; Returns the access code as a string, or None if the restraint does either not support access codes or does not currently have
; an access code set. Added in api version: 5
;
String Function GetAccessCodeAsString(ObjectReference restraint)
    RealHandcuffs:ShockCollarBase collar = restraint as RealHandcuffs:ShockCollarBase
    If (collar != None)
        Int numberOfDigits = collar.GetNumberOfAccessCodeDigits()
        If (numberOfDigits > 0)
            Int accessCode = collar.GetAccessCode()
            If (accessCode >= 0)
                String accessCodeAsString = ""
                While (numberOfDigits > 0)
                    accessCodeAsString = (accessCode % 10) + accessCodeAsString
                    accessCode /= 10
                    numberOfDigits -= 1
                EndWhile
                Return accessCodeAsString
            EndIf
        EndIf
    EndIf
    Return None
EndFunction

;
; Set the access code for restraints that support an access code. Use -1 to disable the access code for restraints that support
; disabling the access code.
; Returns the resulting access code as an integer. This may be -1, and may be different from the provided access code if the
; provided access code has too many digits.
; Added in api version: 5
;
Int Function SetAccessCode(ObjectReference restraint, Int accessCode)
    RealHandcuffs:ShockCollarBase collar = restraint as RealHandcuffs:ShockCollarBase
    If (collar != None)
        collar.SetAccessCode(accessCode)
        Return collar.GetAccessCode()
    EndIf
    Return -1
EndFunction

;
; Get the action that a restraint with access code performs on failed/unauthorized access.
; Returns the unauthorized access action, see above in definition of Group UnauthorizedAccessAction, or -1 if not supported.
; Added in api version: 5
;
Int Function GetUnauthorizedAccessAction(ObjectReference restraint)
    RealHandcuffs:ShockCollarBase collar = restraint as RealHandcuffs:ShockCollarBase
    If (collar != None)
        Return collar.ActionOnFailedAccessCodeEntry
    EndIf
    Return -1
EndFunction

;
; Set the action of a restraint with access code performs on failed/unauthorized access. See above in definition of Group UnauthorizedAccessAction.
; Returns the resulting unauthorized access action. This can be -1, or different from the provided unauthorited access action as not all restraints
; can support all unauthorized access actions. Added in api version: 5
;
Int Function SetUnauthorizedAccessAction(ObjectReference restraint, Int unauthorizedAccessAction)
    RealHandcuffs:ShockCollarBase collar = restraint as RealHandcuffs:ShockCollarBase
    If (collar != None)
        collar.ActionOnFailedAccessCodeEntry = Math.Max(IgnoreUnauthorizedAccess, Math.Min(UnauthorizedAccessLockAndTrigger, unauthorizedAccessAction)) as Int
        Return collar.ActionOnFailedAccessCodeEntry
    EndIf
    Return -1
EndFunction

;
; Get the trigger mode of a restraint that can be triggered using different ways.
; Returns the trigger mode, see above in definition of Group TriggerMode, or -1 if not supported. Added in api version: 5
;
Int Function GetTriggerMode(ObjectReference restraint)
    RealHandcuffs:ShockCollarBase collar = restraint as RealHandcuffs:ShockCollarBase
    If (collar != None)
        Return collar.GetTriggerMode()
    EndIf
    Return -1
EndFunction

;
; Set the trigger mode of a restraint that can be triggered using different ways. See above in definition of Group TriggerMode.
; Returns the resulting trigger mode. This can be -1, or different from the provided trigger mode as not all restraints
; can support all trigger modes. Added in api version: 5
;
Int Function SetTriggerMode(ObjectReference restraint, Int triggerMode)
    RealHandcuffs:ShockCollarBase collar = restraint as RealHandcuffs:ShockCollarBase
    If (collar != None)
        collar.SetTriggerMode(triggerMode)
        Return collar.GetTriggerMode()
    EndIf
    Return -1
EndFunction

;
; Start the torture mode of an equiped restraint that supports torture mode.
; Returns true on success, false if the restraint is not equipped or does not support torture mode. Added in api version: 11
;
Bool Function StartTortureMode(ObjectReference restraint, Int shocksPerGameHour)
    RealHandcuffs:ShockCollarBase collar = restraint as RealHandcuffs:ShockCollarBase
    If (collar != None && collar.GetSupportsTortureMode())
        Actor target = collar.SearchCurrentTarget()
        If (target != None)
            Float frequency = 1.0 / Math.Max(1.0, Math.Min(6.0, shocksPerGameHour)) ; clamp shocksPerGameHour to 1..6
            collar.SetTortureModeFrequency(frequency)
            collar.RestartTortureMode(target)
            Return true
        EndIf
    EndIf
    Return false
EndFunction

;
; Stops the torture mode of an equiped restraint that supports torture mode.
; Returns true on success, false if the restraint is not equipped or does not support torture mode. Added in api version: 11
;
Bool Function StopTortureMode(ObjectReference restraint)
    RealHandcuffs:ShockCollarBase collar = restraint as RealHandcuffs:ShockCollarBase
    If (collar != None && collar.GetSupportsTortureMode())
        Actor target = collar.SearchCurrentTarget()
        If (target != None)
            collar.SetTortureModeFrequency(0.0)
            collar.RestartTortureMode(target)
            Return true
        EndIf
    EndIf
    Return false
EndFunction

;
; Start the torture mode on an actor, if the actor has an equiped restraint that supports torture mode.
; Returns true on success, false if the actor has no such restraint. Added in api version: 11
;
Bool Function StartTortureModeOnActor(Actor target, Int shocksPerGameHour)
    RealHandcuffs:RestraintBase[] restraints = GetRestraintsMaybeFilterByEffect(target, RemoteTriggerEffect)
    Int index = 0
    While (index < restraints.Length)
        RealHandcuffs:ShockCollarBase collar = restraints[index] as RealHandcuffs:ShockCollarBase
        If (collar != None && collar.GetSupportsTortureMode())
            Float frequency = 1.0 / Math.Max(1.0, Math.Min(6.0, shocksPerGameHour)) ; clamp shocksPerGameHour to 1..6
            collar.SetTortureModeFrequency(frequency)
            collar.RestartTortureMode(target)
            Return true ; return after the first device
        EndIf
        index += 1
    EndWhile
    Return false
EndFunction

;
; Stop the torture mode on an actor, if the actor has an equiped restraint that supports torture mode.
; Returns true on success, false if the actor has no such restraint. Added in api version: 11
;
Bool Function StopTortureModeOnActor(Actor target)
    RealHandcuffs:RestraintBase[] restraints = GetRestraintsMaybeFilterByEffect(target, RemoteTriggerEffect)
    Int index = 0
    Int stoppedDeviceCount = 0
    While (index < restraints.Length)
        RealHandcuffs:ShockCollarBase collar = restraints[index] as RealHandcuffs:ShockCollarBase
        If (collar != None && collar.GetSupportsTortureMode())
            collar.SetTortureModeFrequency(0.0)
            collar.RestartTortureMode(target)
            stoppedDeviceCount += 1 ; continue with other devices
        EndIf
        index += 1
    EndWhile
    Return stoppedDeviceCount > 0
EndFunction

;
; Change the transmitter ot a remote trigger to the standard transmitter.
; Returns true on success, false on failure. Added in api version: 8
;
Bool Function SetStandardTransmitter(ObjectReference remote)
    If (remote != None && remote.GetBaseObject() == RemoteTrigger)
        Return SetTransmitterMod(remote, ModObjectStandardTransmitter)
    EndIf
    Return false
EndFunction

;
; Change the transmitter ot a remote trigger to the long range transmitter.
; Returns true on success, false on failure. Added in api version: 8
;
Bool Function SetPowerfulTransmitter(ObjectReference remote)
    If (remote != None && remote.GetBaseObject() == RemoteTrigger)
        Return SetTransmitterMod(remote, ModObjectPowerfulTransmitter)
    EndIf
    Return false
EndFunction


;
; ---------- Functions for setting up prisoner scenes. ----------
;

;
; Make a bound NPC follow another actor (usually a NPC, but this also works to make them follow the player).
; Note that in the case of player teammates, they will follow the player by default. So in most situations
; Actor.SetPlayerTeammate is a better way to make bound NPCs follow the player; this function can be used
; to make bound NPCs follow the player if they should not be flagged as teammates.
; Also note that the game teleports player teammates and companions to the player when the player fast-travels
; or uses some elevators, so to set up NPCs to follow other NPCs, dismiss them if they are companions and
; clear the player teammate flag.
; Removing the bonds will make the NPC stop following (the default AI will resume), but it will NOT undo the
; change that this function has made. If the NPC is then bound again, they will resume following. Therefore
; it is important to clean up by calling CleanBoundHandsFollowTarget when the scene ends!
; Added in api version: 10
;
Bool Function SetBoundHandsFollowTarget(Actor boundActor, Actor actorToFollow)
    If (boundActor == None || actorToFollow == None)
        Return false
    EndIf
    ; do not check if boundActor is actually bound; allow calling this function before binding the actor
    ; note to the reader: if you are using RealHandcuffs as a hard dependency, you can also just set the
    ; linked ref using the RH_LinkedOwner keyword (0x??000849), this is all the magic of this function
    ; this can for example be done in a reference alias that will hold the prisoner
    boundActor.SetLinkedRef(actorToFollow, Library.LinkedOwner)
    boundActor.EvaluatePackage(true)
    Return true
EndFunction

;
; Make a bound NPC stop following another actor.
; Note that in the case of player teammates, they will follow the player by default, so this function
; will NOT stop them from following the player.
; Added in api version: 10
;
Bool Function ClearBoundHandsFollowTarget(Actor boundActor)
    If (boundActor == None)
        Return false
    EndIf
    boundActor.SetLinkedRef(None, Library.LinkedOwner)
    boundActor.EvaluatePackage(false)
    Return true
EndFunction

;
; Put an NPC into a bound wait state. The hands of the NPC must be bound behind their back for this to work.
; Use one of the other functions to equip handcuffs on them if necessary before calling this function.
; Unequipping the handcuffs will end bound wait state, as will calling EndBoundWaitState(target).
; If playEnterAnimation is true, the target will play an enter animation for its pose (e.g. slowly kneel down);
; otherwise the target will snap instantly into its pose (useful when setting up the pose off-screen).
; If makePlayerPosable is true, the player is allowed to change the pose of the actor, similar to NPCs assigned to prisoner mats.
; This function will not wait until the animation is finished (if any); it will return as soon as everything is set up.
; Added in api version: 10
;
Bool Function StartBoundWaitState(Actor target, Int pose, Bool playEnterAnimation, Bool makePlayerPosable)
    If (target == None || target == Game.GetPlayer())
        Return false
    EndIf
    RealHandcuffs:NpcToken token = Library.TryGetActorToken(target) as RealHandcuffs:NpcToken
    If (token == None || !token.GetHandsBoundBehindBack())
        Return false
    EndIf
    RealHandcuffs:WaitMarkerBase waitMarker = target.GetLinkedRef(Library.Resources.WaitMarkerLink) as RealHandcuffs:WaitMarkerBase
    If (waitMarker != None)
        ; unregister from existing wait marker or prisoner mat
        waitMarker.Unregister(target)
    EndIf
    String animation = ConvertPoseToAnimation(pose)
    If (playEnterAnimation)
        waitMarker = token.TryCreateTemporaryWaitMarker(animation, !makePlayerPosable)
    Else
        waitMarker = token.TryCreateTemporaryWaitMarker("", !makePlayerPosable)
        If (waitMarker != None)
            Var[] kArgs = new Var[3]
            kArgs[0] = target
            kArgs[1] = animation
            kArgs[2] = false ; do not play enter animation
            waitMarker.CallFunctionNoWait("StartAnimationAndWait", kArgs)
        EndIf
    EndIf
    If (waitMarker == None)
        ; failure, not sure why
        Return false
    EndIf
    Return true
EndFunction

;
; Change the pose of an NPC in bound wait state.
; This function will also work on NPCs who are assigned to prisoner mats, and on followers who are put into bound wait
; state manually by the player. This function will not wait until the animation is finished (if any); it will return
; as soon as everything is set up.
; Added in api version: 10
;
Bool Function ChangeBoundWaitStatePose(Actor target, Int pose)
    If (target == None)
        Return false
    EndIf
    RealHandcuffs:WaitMarkerBase waitMarker = target.GetLinkedRef(Library.Resources.WaitMarkerLink) as RealHandcuffs:WaitMarkerBase
    If (waitMarker == None)
        Return false
    EndIf
    String newAnimation
    If (pose == PoseNone)
        newAnimation = ""
    Else
        newAnimation = ConvertPoseToAnimation(pose)
        If (newAnimation == "")
            Return false ; fail for unknown pose values
        EndIf
    EndIf
    ; use CallFunctionNoWait to change the animation so we don't block
    Var[] akArgs = new Var[2]
    akArgs[0] = target
    akArgs[1] = newAnimation
    waitMarker.CallFunctionNoWait("ChangeAnimation", akArgs)
    Return true
EndFunction

;
; Free an actor from bound wait state. Note that removing the handcuffs will remove bound wait state, too.
; The purpose of this function is to free an actor from bound wait state while keeping their hands bound.
; Added in api version: 10
;
Bool Function StopBoundWaitState(Actor target)
    If (target != None)
        RealHandcuffs:WaitMarkerBase waitMarker = target.GetLinkedRef(Library.Resources.WaitMarkerLink) as RealHandcuffs:WaitMarkerBase
        If (waitMarker != None)
            waitMarker.Unregister(target)
            Return target.GetLinkedRef(Library.Resources.WaitMarkerLink) != waitMarker
        EndIf
    EndIf
    Return false ; not in bound wait state (most probably), or unexpected failure to free
EndFunction

;
; --------- Other functions. ----------
;

;
; Forbid the player to equip/unequip restraints - not the player character (!) but the human playing the game.
; If target is a restraint, the player cannot equip or unequip the restraint, both on self and on NPCs.
; If target is an actor, the player cannot equip/unequip restraints to/from that actor.
; This will not prevent scripts from equipping or unequipping restraints.
; Returns true if a change was made, meaning that the caller will have to call AllowPlayerEquipUnequipRestraint later,
; false if equipping/unequipping was already forbidden before this call and forceUpdate was false.
; Added in api version: 2
;
Bool Function ForbidPlayerEquipUnequipRestraints(ObjectReference target, Bool forceUpdate = false)
    If (target.HasKeyword(Library.BlockPlayerEquipUnequip) && !forceUpdate)
        Return false
    EndIf
    ; the keyword could also come from a reference alias, so AddKeyword is not always redundant
    target.AddKeyword(Library.BlockPlayerEquipUnequip)
    Return true
EndFunction

;
; Allow the player to equip/unequip restraints. See ForbidPlayerEquipUnequip for details.
; Returns true if the player is now allowed to equip/unequip, false if something else (e.g. a reference alias) still
; forbids equipping/unequipping.
; Added in api version: 2
;
Bool Function AllowPlayerEquipUnequipRestraints(ObjectReference target)
    target.ResetKeyword(Library.BlockPlayerEquipUnequip)
    Return !target.HasKeyword(Library.BlockPlayerEquipUnequip)
EndFunction

;
; Make a npc aim a remote trigger at the specified target and fire it the specified number of times in rapid succession (numbers other
; than 1 can be used to trigger restraints that are set to activate on a specific number of signals only). This function will block until
; the NPC has finished this action, which can take several seconds. If the NPC has a remote trigger in the inventory, that remote trigger 
; will be equipped and used; otherwise a temporary remote trigger will be provided.
; Returns true if the remote trigger was fired successfully (this is expected unless there is a problem). Added in api version: 8
; Added in api version: 8
;
Bool Function NpcAimAndFireRemoteTrigger(Actor akActor, Actor target, Int numberOfTimes = 1)
    NpcAimAndFireRemoteTriggerWithMods(akActor, target, numberOfTimes, 0)
EndFunction

;
; Make a npc aim a remote trigger at the specified target and fire it the specified number of times in rapid succession (numbers other
; than 1 can be used to trigger restraints that are set to activate on a specific number of signals only). This function will block until
; the NPC has finished this action, which can take several seconds. If the NPC has a remote trigger in the inventory, that remote trigger 
; will be equipped and used; otherwise a temporary remote trigger will be provided.
; The following mods are supported: ModPowerfulTransmitter.
; Returns true if the remote trigger was fired successfully (this is expected unless there is a problem). Added in api version: 8
;
Bool Function NpcAimAndFireRemoteTriggerWithMods(Actor akActor, Actor target, Int numberOfTimes = 1, Int mods = 0)
    Bool success = false
    If (akActor != None && !akActor.IsDead() && !Library.GetHandsBoundBehindBack(akActor))
        ObjectReference createdRemote = None
        If (akActor.GetItemCount(RemoteTrigger) == 0)
            createdRemote = CreateRemoteTriggerWithModsCloseTo(akActor, 0, mods)
            akActor.AddItem(createdRemote, 1, true)
        EndIf
        Actor actualTarget = target
        If (actualTarget == None)
            actualTarget = akActor.GetCombatTarget()
            If (actualTarget == None)
                actualTarget = Game.GetPlayer() ; fallback
            EndIf
        EndIf
        success = Library.FireRemoteTrigger(akActor, actualTarget, numberOfTimes)
        If (createdRemote != None)
            createdRemote.Drop()
            createdRemote.DisableNoWait()
            createdRemote.Delete()
        EndIf
    EndIf
    Return success
EndFunction

;
; Trigger a restraint by providing the required number of signals to trigger it. By default this will be done using standard
; pulse signals, so other restraints in the vicininty may be triggered, too. If useInternalSignal is specified the restraint
; will instead be triggered by an internal signal. This function will NOT wait for the restraint to activate, which can take
; several seconds; it will just send the signal and return.
; Added in api version: 5
;
Function TriggerRestraint(ObjectReference restraint, Bool useInternalSignal = false)
    RealHandcuffs:RestraintBase restraintBase = restraint as RealHandcuffs:RestraintBase
    If (restraintBase != None)
        Actor target = restraintBase.SearchCurrentTarget()
        If (target != None)
            If (useInternalSignal)
                restraintBase.Trigger(target, true)
            Else
                Int numberOfSignals = 0
                RealHandcuffs:ShockCollarBase collar = restraintBase as RealHandcuffs:ShockCollar
                If (collar != None)
                    numberOfSignals = collar.GetTriggerMode()
                    If (numberOfSignals == 0)
                        numberOfSignals = 1
                    EndIf
                EndIf
                If (numberOfSignals > 0)
                    Var[] kArgs = new Var[4]
                    kArgs[0] = target as ObjectReference
                    kArgs[1] = RemoteTriggerStandardActivator as Form
                    kArgs[2] = numberOfSignals
                    kArgs[3] = 0.16666666
                    CallFunctionNoWait("PlaceMultipleObjects", kArgs)
                EndIf
            EndIf
        EndIf
    EndIf
EndFunction

;
; Booby-trap a corpse by equipping an explosive collar on the corpse.
; For this to work, corpse must be a dead actor, and explosiveCollar must be a shock collar with explosive module.
; Also the corpse must not already be wearing another collar and the head must not be dismembered.
; This function will return true on success, false on failure.
; Added in api version: 8
;
Bool Function BoobyTrapCorpse(Actor corpse, ObjectReference explosiveCollar)
    If (explosiveCollar != None && explosiveCollar.HasKeyword(Library.Resources.Explosive) && corpse != None && (corpse.IsDead() || Library.SoftDependencies.IsArmorRack(corpse)) && !corpse.IsEquipped(explosiveCollar.GetBaseObject()) && !corpse.IsDismembered("Head1"))
        RealHandcuffs:ShockCollarBase collar = explosiveCollar as RealHandcuffs:ShockCollarBase
        If (collar != None)
            ObjectReference last = corpse
            ObjectReference linked = corpse.GetLinkedRef(Library.Resources.LinkedRemoteTriggerObject)
            While (linked != None)
                RealHandcuffs:RestraintBase existingCollar = linked as RealHandcuffs:ShockCollarBase
                If (existingCollar != None)
                    Return false ; abort, already booby-trapped with another collar
                EndIf
                last = linked
                linked = last.GetLinkedRef(Library.Resources.LinkedRemoteTriggerObject)
            EndWhile
            If (collar.GetContainer() != None)
                collar.Drop(true)
            EndIf
            collar.EnableNoWait()
            last.SetLinkedRef(collar, Library.Resources.LinkedRemoteTriggerObject)
            corpse.AddItem(collar, 1, true)
            corpse.EquipItem(collar.GetBaseObject())
            corpse.AddKeyword(Library.Resources.RemoteTriggerEffect)
            Return true
        EndIf
    EndIf
    Return false
EndFunction


;
; A special formlist that contains furnitures and activators that may be used/activated with bound hands (base objects,
; not object references). This list contains a lot of activators by default. Add more if necessary for compatibility.
; Note that adding furniture is usually a bad idea, as the furniture animation will break the "bound hands" effect and
; the result will look bad.
; Added in api version: 9
;
FormList Property BoundHandsGenericFurnitureList Auto Const Mandatory

;
; A special formlist that contains items that may be picked up with bound hands (base objects, not object references).
; This list only contains the bobby pin by default. Add more if necessary for compatibility, e.g. to allow completion
; of fetch quests with bound hands. In general the items should be small. 
; Added in api version: 9
;
FormList Property BoundHandsTakeItemList Auto Const Mandatory


;
; ---------- Obsolete functions, do not use, only here to prevent breaking mods developed against a old version of the API. ----------
;

; Made obsolete in api version: 4

ObjectReference Function CreateHandcuffs(ObjectReference placeAtReference, Bool initiallyDisabled = false)
    Return CreateHandcuffsCloseTo(placeAtReference, ConvertBoolToFlag(initiallyDisabled, FlagInitiallyDisabled))
EndFunction

ObjectReference Function CreateHingedHandcuffs(ObjectReference placeAtReference, Bool initiallyDisabled = false)
    Return CreateHandcuffsCloseTo(placeAtReference, ConvertBoolToFlag(initiallyDisabled, FlagInitiallyDisabled) + FlagHinged)
EndFunction

ObjectReference Function CreateRandomHandcuffs(ObjectReference placeAtReference, Int percentHinged = 20, Int percentHighSecurity = 20, Bool initiallyDisabled = false)
    Return CreateRandomHandcuffsCloseTo(placeAtReference, percentHinged, percentHighSecurity, ConvertBoolToFlag(initiallyDisabled, FlagInitiallyDisabled))
EndFunction

ObjectReference Function CreateKey(ObjectReference restraint)
    Return CreateKeyCloseToRestraint(restraint, 0)
EndFunction

Bool Function AddKeys(ObjectReference restraint, ObjectReference containerToAddKeys, int keyCount = 1)
    Return CreateKeysInContainer(restraint, containerToAddKeys, keyCount, 0)
EndFunction

ObjectReference Function CreateAndEquipHandcuffs(Actor target, Bool unequipConflictingRestraint = false)
    Return CreateHandcuffsEquipOnActor(target, ConvertBoolToFlag(unequipConflictingRestraint, FlagUnequipConflictingRestraints))
EndFunction

ObjectReference Function CreateAndEquipHingedHandcuffs(Actor target, Bool unequipConflictingRestraint = false)
    Return CreateHandcuffsEquipOnActor(target, FlagHinged +  ConvertBoolToFlag(unequipConflictingRestraint, FlagUnequipConflictingRestraints))
EndFunction

ObjectReference Function CreateAndEquipRandomHandcuffs(Actor target, Int percentHinged = 20, Int percentHighSecurity = 20, Bool unequipConflictingRestraint = false)
    Return CreateRandomHandcuffsEquipOnActor(target, percentHinged, percentHighSecurity, ConvertBoolToFlag(unequipConflictingRestraint, FlagUnequipConflictingRestraints))
EndFunction

Bool Function EquipRestraint(ObjectReference restraint, Actor target, Bool unequipConflictingRestraint = false)
    Return EquipRestraintUsingDefaultSettings(restraint, target, ConvertBoolToFlag(unequipConflictingRestraint, FlagUnequipConflictingRestraints))
EndFunction

Bool Function EquipHandcuffs(ObjectReference cuffs, Actor target, Int tightness = 0, Bool lockFacingAwayFromHands = true, Bool unequipConflictingRestraint = false)
    Return EquipHandcuffsUsingCustomSettings(cuffs, target, tightness, lockFacingAwayFromHands, ConvertBoolToFlag(unequipConflictingRestraint, FlagUnequipConflictingRestraints))
EndFunction

Bool Function UnequipRestraint(ObjectReference restraint, Bool destroyRestraint = false)
    If (destroyRestraint)
        Return UnequipRestraintRemoveFromInventory(restraint, None, 0)
    Else
        Return UnequipRestraintKeepInInventory(restraint, 0)
    EndIf
EndFunction

Int Function RemoveKeys(ObjectReference restraint, ObjectReference containerToRemoveKeys)
    Return RemoveKeysFromContainer(restraint, containerToRemoveKeys, None, 0)
EndFunction

; Made obsolete in api version: 8

Bool Function NpcFireRemoteTrigger(Actor akActor, Int numberOfTimes = 1)
    NpcAimAndFireRemoteTriggerWithMods(akActor, None, numberOfTimes, 0)
EndFunction

;
; ---------- Private properties and functions, do not call. These may change from version to version. ----------
;

Int Function ConvertBoolToFlag(Bool value, Int flag)
    If (value)
        Return flag
    EndIf
    Return 0
EndFunction

Bool Function CheckRandomPercent(int percentChance)
    If (percentChance <= 0)
        Return false
    ElseIf (percentChance >= 100)
        Return true
    EndIf
    Int d100 = Utility.RandomInt(1, 100)
    Return d100 <= percentChance
EndFunction

ObjectReference Function EquipOrDeleteNewlyCreatedDisabledRestraint(RealHandcuffs:RestraintBase restraint, Actor target, Int flags)
    restraint.EnableNoWait()
    target.AddItem(restraint, 1, Math.LogicalAnd(flags, FlagAddRemoveObjectsSilently) != 0)
    restraint.ForceEquip(Math.LogicalAnd(flags, FlagUnequipConflictingRestraints), true)
    RealHandcuffs:ActorToken token = Library.GetOrCreateActorToken(target)
    If (token.IsApplied(restraint))
        Return restraint
    Else
        restraint.Drop(Math.LogicalAnd(flags, FlagAddRemoveObjectsSilently))
        restraint.DisableNoWait()
        restraint.Delete()
        Return None
    EndIf
EndFunction

Function PlaceMultipleObjects(ObjectReference refToPlaceAt, Form objectToPlace, Int numberOfObjects, Float timeBetweenObjects)
    If (numberOfObjects > 0)
        refToPlaceAt.PlaceAtMe(objectToPlace, 1, false, true, false).EnableNoWait()
        Int placedObjects = 1
        While (placedObjects < numberOfObjects)
            Utility.Wait(timeBetweenObjects)
            refToPlaceAt.PlaceAtMe(objectToPlace, 1, false, true, false).EnableNoWait()
            placedObjects += 1
        EndWhile
    EndIf
EndFunction

Bool Function SetTransmitterMod(ObjectReference remote, ObjectMod mod)
    ObjectMod[] mods = remote.GetAllMods()
    If (mods.Find(mod) >= 0)
        Return False
    EndIf
    Int index = 0
    While (index < mods.Length)
        If (Library.IsAddingKeyword(mods[index], TransmitterTag))
            remote.RemoveMod(mods[index])
        EndIf
        index += 1
    EndWhile
    Return remote.AttachMod(mod)
EndFunction

RealHandcuffs:RestraintBase[] Function GetRestraintsMaybeFilterByEffect(Actor target, Int effect)
    ActorToken token = Library.TryGetActorToken(target)
    If (token != None)
        RealHandcuffs:RestraintBase[] wornRestraints = token.Restraints
        RealHandcuffs:RestraintBase[] filteredRestraints = new RealHandcuffs:RestraintBase[0]
        Int index = 0
        While (index < wornRestraints.Length)
            If (effect == 0 || HasEffect(wornRestraints[index], effect))
                filteredRestraints.Add(wornRestraints[index])
            EndIf
            index += 1
        EndWhile
        If (filteredRestraints.Length > 0)
            Return filteredRestraints
        EndIf
    EndIf
    Return None
EndFunction

Function RemoveRestraintFromInventory(ObjectReference restraint, ObjectReference containerToAddRestraint, Int flags)
    If (restraint.GetContainer() != None)
        restraint.Drop(Math.LogicalAnd(flags, FlagAddRemoveObjectsSilently))
    EndIf
    If (containerToAddRestraint == None)
        restraint.DisableNoWait()
        restraint.Delete()
    Else
        containerToAddRestraint.AddItem(restraint, 1, Math.LogicalAnd(flags, FlagAddRemoveObjectsSilently))
    EndIf
EndFunction

String Function ConvertPoseToAnimation(Int pose)
    If (pose == PoseKneelSit)
        Return Library.AnimationHandler.KneelSit
    ElseIf (pose == PoseHeldHostageKneelHandsUp)
        Return Library.AnimationHandler.HeldHostageKneelHandsUp
    EndIf
    Return "" ; PoseNone, or unknown pose
EndFunction

RealHandcuffs:Installer Property Installer Auto Const Mandatory
RealHandcuffs:Library Property Library Auto Const Mandatory
Activator Property RemoteTriggerStandardActivator Auto Const Mandatory
Armor Property Handcuffs Auto Const Mandatory
Armor Property HandcuffsHinged Auto Const Mandatory
Armor Property ShockCollar Auto Const Mandatory
Keyword Property TransmitterTag Auto Const Mandatory
ObjectMod Property ModObjectStandardLock Auto Const Mandatory
ObjectMod Property ModObjectHighSecurityLock Auto Const Mandatory
ObjectMod Property ModObjectTimedLock3h Auto Const Mandatory
ObjectMod Property ModObjectTimedLock6h Auto Const Mandatory
ObjectMod Property ModObjectTimedLock9h Auto Const Mandatory
ObjectMod Property ModObjectTimedLock12h Auto Const Mandatory
ObjectMod Property ModObjectStandardShockModule Auto Const Mandatory
ObjectMod Property ModObjectMarkTwoFirmware Auto Const Mandatory
ObjectMod Property ModObjectMarkThreeFirmware Auto Const Mandatory
ObjectMod Property ModObjectHackedFirmware Auto Const Mandatory
ObjectMod Property ModObjectThrobbingShockModule Auto Const Mandatory
ObjectMod Property ModObjectExplosiveModule Auto Const Mandatory
ObjectMod Property ModObjectStandardTransmitter Auto Const Mandatory
ObjectMod Property ModObjectPowerfulTransmitter Auto Const Mandatory
Weapon Property RemoteTrigger Auto Const Mandatory
