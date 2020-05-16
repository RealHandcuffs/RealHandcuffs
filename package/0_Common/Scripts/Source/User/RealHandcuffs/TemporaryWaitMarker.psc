;
; Script for temporary wait marker placed when bound NPCs are told to wait.
;
Scriptname RealHandcuffs:TemporaryWaitMarker extends RealHandcuffs:WaitMarkerBase

RefCollectionAlias Property TemporaryWaitMarkers Auto Const Mandatory

;
; Override: Unregister an actor from this marker.
;
Function Unregister(Actor akActor)
    Parent.Unregister(akActor)
    Actor registeredActor = GetRegisteredActor()
    If (registeredActor == None || registeredActor.IsDead())
        ; delete the temporary wait marker as soon as it is no longer needed
        DisableNoWait()
        TemporaryWaitMarkers.RemoveRef(Self)
        Delete()
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Deleted TemporaryWaitMarker " + RealHandcuffs:Log.FormIdAsString(Self) + ".", Library.Settings)
        EndIf
    EndIf
EndFunction

;
; Override: Move an object reference into position on the wait marker.
;
Function MoveIntoPosition(ObjectReference target)
    target.MoveTo(Self, 0.0, 0.0, 0.0, false) ; keep current rotation of target, temporary wait marker has no angle
EndFunction

;
; Override: Translate an object reference into position on the wait marker.
;
Function TranslateIntoPosition(ObjectReference target, Float duration)
    Float distance = target.GetDistance(Self)
    target.TranslateTo(Self.X, Self.Y, Self.Z, target.GetAngleX(), target.GetAngleY(), target.GetAngleZ(), distance/duration, 0) ; keep current rotation of target
EndFunction