;
; A script observing bound hands packages.
;
Scriptname RealHandcuffs:BoundHandsPackage extends Package

RealHandcuffs:Library Property Library Auto Const Mandatory
String Property Name Auto Const Mandatory

Event OnStart(Actor akActor)
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("OnStart " + Name + ": " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName(), Library.Settings)
    EndIf
EndEvent
 
Event OnChange(Actor akActor)
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("OnChange " + Name + ": " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName(), Library.Settings)
    EndIf
    NpcToken token = Library.TryGetActorToken(akActor) as NpcToken
    If (token != None)
        token.HandleBoundHandsPackageChanged()
    EndIf
EndEvent

Event OnEnd(Actor akActor)
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("OnEnd " + Name + ": " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName(), Library.Settings)
    EndIf
EndEvent

; non-mandatory properties used to detect if the actor is following another actor
Bool Property IsFollowPlayerPackage Auto Const
Keyword Property FollowLinkedKeyword Auto Const
ReferenceAlias Property FollowAlias Auto Const

;
; Get the root actor that this actor is following - this only takes into account bound hands packages.
;
Actor Function GetFollowRoot(Actor akActor, Int currentRecursionDepth = 0)
    If (currentRecursionDepth <= 10) ; safety check as there might be a follow cycle
        If (IsFollowPlayerPackage)
            Return Game.GetPlayer()
        Else
            Actor followTarget = None
            If (FollowLinkedKeyword != None)
                followTarget = akActor.GetLinkedRef(FollowLinkedKeyword) as Actor
            ElseIf (FollowAlias != None)
                followTarget = FollowAlias.GetActorReference()
            EndIf
            If (followTarget != None)
                BoundHandsPackage followTargetPackage = followTarget.GetCurrentPackage() as BoundHandsPackage
                If (followTargetPackage != None)
                    Actor followTargetFollowRoot = followTargetPackage.GetFollowRoot(followTarget, currentRecursionDepth + 1)
                    If (followTargetFollowRoot != None)
                        Return followTargetFollowRoot
                    EndIf
                EndIf
                Return followTarget
            EndIf
        EndIf
    EndIf
    Return None
EndFunction