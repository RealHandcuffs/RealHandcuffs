;
; Script handling remote trigger activation.
;
; The inner workings of the remote trigger are rather complicated. A short summary is:
; - the remote trigger is set up as a pistol, using the 10mm dummy receiver mesh (which is invisible)
; - there is a hidden "standard receiver" mod which adds the mesh of the actual receiver
; - the weapon is tagged with an animation keyword (RH_AnimsRemoteTrigger)
; - animations for this keyword are defined in RH_HumanRaceSubgraphData and RH_PowerArmorRaceSubgraphData
; - the ammo property of the weapon is set to null
; - there is a transmitter mod that overrides the fired projectile
; - the transimmter mod sets the projectile, for example RH_ModStandardTransmitter sets it to RH_RemoteTriggerStandardProjectile
; - when the remote is used, this projectile is fired from the "pistol"
; - the projectile is invisible and set to have no speed, almost no range, and no lifetime
; - the projectile will explode, for example RH_RemoteTriggerStandardProjectile will explude using RH_RemoteTriggerStandardProjectileDummyExplosion
; - the explosion has zero force and damage, and no visual affect
; - the explosion will spawn an activator object, e.g. RH_RemoteTriggerStandardProjectileDummyExplosion will spawn RH_RemoteTriggerStandardActivator
; The activator is the only thing that we care about; the only purpose of projectile and explosion are to spawn an activator, enabling us to get an
; event that we can react on. The location of the activator is the location of the weapon (or close enough that it does not make a diference).
; 
Scriptname RealHandcuffs:RemoteTriggerActivator extends ObjectReference Const

RealHandcuffs:Library Property Library Auto Const Mandatory
Keyword Property ActorTypeHuman Auto Const Mandatory
Keyword Property ActorTypeGhoul Auto Const Mandatory
Keyword Property ActorTypeSynth Auto Const Mandatory

Float Property Range Auto Const Mandatory ; in game units

;
; Event triggered when an activator is spawned by the explosion (see explanation above).
;
Event OnInit()
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Remote trigger activator placed, range: " + Range, Library.Settings)
    EndIf
    DisableNoWait()
    ; find all references with RemoteTriggerEffect and trigger them
    ObjectReference[] foundReferences = FindAllReferencesWithKeyword(Library.Resources.RemoteTriggerEffect, Range)
    Int index = 0
    While (index < foundReferences.Length)
        ObjectReference foundReference = foundReferences[index]
        If (!foundReference.IsDisabled())
            Actor victim = foundReference as Actor
            If (victim != None && !victim.IsDead())
                ActorToken token = Library.TryGetActorToken(victim)
                If (token != None)
                    token.CallFunctionNoWait("HandleRemoteTriggerFired", new Var[0])
                EndIf
            EndIf
            If (foundReference != None)
                ObjectReference linked = foundReference.GetLinkedRef(Library.Resources.LinkedRemoteTriggerObject)
                If (linked != None)
                    Var[] kArgs = new Var[1]
                    kArgs[0] = linked
                    CallFunctionNoWait("TriggerLinkedRefChain", kArgs)
                EndIf
            EndIf
            index += 1
        EndIf
    EndWhile
    ; fallback for triggering vanilla shock collars, for example nuka world NPCs
    ; replacing all nuka world shock collars would require changing a lot of NPCs
    ; this quick and dirty solution has a higher chance of being compatible with other mods
    TriggerVanillaShockCollars(FindAllReferencesWithKeyword(ActorTypeHuman, Range))
    TriggerVanillaShockCollars(FindAllReferencesWithKeyword(ActorTypeGhoul, Range))
    TriggerVanillaShockCollars(FindAllReferencesWithKeyword(ActorTypeSynth, Range))
    ; done, delete activator
    Delete()
EndEvent

Function TriggerLinkedRefChain(ObjectReference linked)
    While (linked != None)
        ObjectReference next = linked.GetLinkedRef(Library.Resources.LinkedRemoteTriggerObject)
        RealHandcuffs:RestraintBase restraint = linked as RealHandcuffs:RestraintBase
        If (restraint != None)
            restraint.Trigger(None, false)
        EndIf
        linked = next
    EndWhile
EndFunction

Function TriggerVanillaShockCollars(ObjectReference[] candidateActors)
    Int index = 0
    While (index < candidateActors)
        Actor target = candidateActors[index]
        If (target != None && !target.HasKeyword(Library.Resources.RemoteTriggerEffect) && Library.SoftDependencies.IsWearingVanillaShockCollar(target))
            RealHandcuffs:Log.Warning("TODO trigger collar of " + RealHandcuffs:Log.FormIDAsString(target) + " " + target + ".", Library.Settings)
        EndIf
        index += 1
    EndWhile
EndFunction