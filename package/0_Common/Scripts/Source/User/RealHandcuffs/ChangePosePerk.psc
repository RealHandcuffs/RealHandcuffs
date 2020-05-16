;
; A (relatively) simple perk script used for changing the pose of an actor.
;
Scriptname RealHandcuffs:ChangePosePerk extends Perk

RealHandcuffs:Library Property Library Auto Const Mandatory
Message Property MsgBoxChangePoseFemale Auto Const Mandatory
Message Property MsgBoxChangePoseMale Auto Const Mandatory
String[] Property AvailablePoses Auto Const Mandatory

Event OnEntryRun(int auiEntryID, ObjectReference akTarget, Actor akOwner)
    If (akOwner == Game.GetPlayer() && akTarget.HasKeyword(Library.Resources.Posable))
        ChangePoseInteractive(akTarget as Actor)
    EndIf
EndEvent

Function ChangePoseInteractive(Actor akActor)
    If (akActor != None)
        RealHandcuffs:WaitMarkerBase waitMarker = akActor.GetLinkedRef(Library.Resources.WaitMarkerLink) as RealHandcuffs:WaitMarkerBase
        Bool isRegistered = (waitMarker != None)
        If (!isRegistered)
            ; the actor might be assigned but not yet registered
            waitMarker = akActor.GetLinkedRef(Library.Resources.PrisonerMatLink) as RealHandcuffs:WaitMarkerBase
        EndIf
        If (waitMarker != None)
            Int selection
            If (Library.IsFemale(akActor))
                selection = MsgBoxChangePoseFemale.Show()
            Else
                selection = MsgBoxChangePoseMale.Show()
            EndIf
            If (selection < AvailablePoses.Length)
                If (!isRegistered)
                    waitMarker.Animation = "" ; to prevent Register() from starting animation
                    If (!waitMarker.Register(akActor))
                        waitMarker = None
                    EndIf
                EndIf
                If (waitMarker != None)
                    waitMarker.ChangeAnimation(akActor, AvailablePoses[selection])
                EndIf
            EndIf
        EndIf
        If (waitMarker == None)
            RealHandcuffs:Log.Warning("Failed to change pose of " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName() + ".", Library.Settings)
        EndIf
    EndIf
EndFunction