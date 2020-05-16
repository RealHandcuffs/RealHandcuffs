;
; Very simple perk script used for opening the inventory of an actor.
;
Scriptname RealHandcuffs:OpenInventoryPerk extends Perk

Event OnEntryRun(int auiEntryID, ObjectReference akTarget, Actor akOwner)
    If (akOwner == Game.GetPlayer())
        Actor akActor = akTarget as Actor
        If (akActor != None)
            akActor.OpenInventory(true)
        EndIf
    EndIf
EndEvent