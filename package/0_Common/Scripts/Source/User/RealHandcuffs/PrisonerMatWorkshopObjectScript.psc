;
; Script extending WorkshopObjectScript, forwarding some functions to PrisonerMat script.
; This is necessary because PrisonerMat does not inherit from WorkshopObjectScript.
;
Scriptname RealHandcuffs:PrisonerMatWorkshopObjectScript extends WorkshopObjectScript

RealHandcuffs:PrisonerMat Property PrisonerMat
    RealHandcuffs:PrisonerMat Function Get()
        Return (Self as ObjectReference) as RealHandcuffs:PrisonerMat
    EndFunction
EndProperty

Function HandleCreation(bool bNewlyBuilt = true)
    PrisonerMat.HandleCreation()
    Parent.HandleCreation()
EndFunction

Function HideMarkers()
    PrisonerMat.HideMarkers()
    Parent.HideMarkers()
EndFunction

Function UpdatePosition()
    PrisonerMat.UpdatePosition()
    Parent.UpdatePosition()
EndFunction

Function HandleDeletion()
    PrisonerMat.HandleDeletion()
    Parent.HandleDeletion()
EndFunction

Function AssignNPCCustom(Actor newActor) ; necessary for WorkshopFramework 2.0+
    PrisonerMat.AssignActor(newActor as WorkshopNPCScript, true)
EndFunction

Function AssignActorCustom(WorkshopNPCScript newActor)
    PrisonerMat.AssignActor(newActor, true)
EndFunction