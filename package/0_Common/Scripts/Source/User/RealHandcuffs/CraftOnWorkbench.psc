;
; Very simple perk script used for all perks that allow crafting on a workbench while wearing restraints.
;
Scriptname RealHandcuffs:CraftOnWorkbench extends Perk

RealHandcuffs:Library Property Library Auto Const Mandatory

Event OnEntryRun(int auiEntryID, ObjectReference akTarget, Actor akOwner)
    If (akOwner == Game.GetPlayer())
        RealHandcuffs:PlayerToken token = Library.GetOrCreateActorToken(akOwner) as RealHandcuffs:PlayerToken
        If (token.Restraints.Length > 0)
            token.HideRestraints()
        EndIf
        akTarget.Activate(akOwner)
    EndIf
EndEvent
