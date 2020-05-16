;
; A script for "weapons" that actually aren't and should only be equipped outside of combat.
;
Scriptname RealHandcuffs:NonCombatWeapon extends ObjectReference

Bool _equipAfterCombatEnds

;
; Event triggered when the weapon is moved between containers.
;
Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
    ; make sure the script stays registered on OnCombatStateChanged of the owning actor
    Actor oldActor = akOldContainer as Actor
    If (oldActor != None)
        UnregisterForRemoteEvent(oldActor, "OnCombatStateChanged")
        _equipAfterCombatEnds = false
    EndIf
    Actor newActor = akNewContainer as Actor
    If (newActor != None && newActor != Game.GetPlayer())    
        RegisterForRemoteEvent(newActor, "OnCombatStateChanged")
    EndIf
EndEvent

;
; Event triggered when the weapon is in the inventory of an actor who enters or leaves combat.
;
Event Actor.OnCombatStateChanged(Actor akSender, Actor akTarget, int aeCombatState)
    Form baseObject = GetBaseObject()
    If (aeCombatState == 0)
        ; equip again when combat ends if it was equipped previously
        If (_equipAfterCombatEnds)
            akSender.EquipItem(baseObject, true, false)
            _equipAfterCombatEnds = false
        EndIf
    Else
        ; unequip when combat starts
        If (akSender.IsEquipped(baseObject))
            akSender.UnequipItem(baseObject, false, false)
            _equipAfterCombatEnds = true
        EndIf
    EndIf
EndEvent
