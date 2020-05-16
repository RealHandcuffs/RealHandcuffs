;
; Script handling remote trigger activation.
;
Scriptname RealHandcuffs:RemoteTriggerActivator extends ObjectReference Const

RealHandcuffs:Library Property Library Auto Const Mandatory

Float Property Range Auto Const Mandatory ; in game units

Event OnInit()
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Remote trigger activator placed, range: " + Range, Library.Settings)
    EndIf
    DisableNoWait()
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