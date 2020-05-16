;
;
; Common base script for wait markers.
;
Scriptname RealHandcuffs:WaitMarkerBase extends ObjectReference

RealHandcuffs:Library Property Library Auto Const Mandatory

;
; An optional Z angle for the waiting actor.
;
Float Property WaitAngleZ Auto Const

;
; Optionally disable the "pose" interaction - this needs to be set before assigning/registering an actor.
;
Bool Property DisablePoseInteraction Auto

;
; An optional animation tag - must be one of the values of the AnimationHandler.Animations group.
;
String Property Animation Auto

ObjectReference _idleMarker
String _currentAnimation

;
; Get the actor who is currently registered with the wait marker.
;
Actor Function GetRegisteredActor()
    ; the link needs to be both ways to be valid
    ; this allows the system to somehow continue working after a previous link was only cleaned up partially
    Actor linkedActor = GetLinkedRef(Library.Resources.WaitMarkerLink) as Actor
    If (linkedActor != None && linkedActor.GetLinkedRef(Library.Resources.WaitMarkerLink) == Self)
        Return linkedActor
    EndIf
    Return None
EndFunction

;
; Register an actor with this marker. Only one actor can be registered with the actor.
; Returns true on success.
;
Bool Function Register(Actor akActor)
    If (akActor != None)
        Actor registeredActor = GetRegisteredActor()
        RealHandcuffs:WaitMarkerBase actorWaitMarker = akActor.GetLinkedRef(Library.Resources.WaitMarkerLink) as RealHandcuffs:WaitMarkerBase
        If (registeredActor == None && (actorWaitMarker == None || actorWaitMarker.GetLinkedRef(Library.Resources.WaitMarkerLink) != akActor))
            SetLinkedRef(akActor, Library.Resources.WaitMarkerLink)
            akActor.SetLinkedRef(Self, Library.Resources.WaitMarkerLink)
            akActor.EvaluatePackage(true)
            RegisterForRemoteEvent(akActor, "OnCommandModeEnter")
            If (Animation != "")
                Var[] akArgs = new Var[3]
                akArgs[0] = akActor
                akArgs[1] = Animation
                akArgs[2] = true
                CallFunctionNoWait("StartAnimationAndWait", akArgs)
            ElseIf (!DisablePoseInteraction)
                akActor.AddKeyword(Library.Resources.Posable)
            EndIf
            RegisterForPlayerTeleport()
            akActor.SetValue(Library.Resources.WaitingForPlayer, 1) ; don't bother with ModValue, the game will set/clear this, too
            If (GetParentCell().IsAttached())
                RegisterForPlayerSleep()
                RegisterForPlayerWait()
            EndIf
            Return true
        EndIf
    EndIf
    Return false
EndFunction

;
; Unregister the registered actor from the marker.
;
Function Unregister(Actor akActor)
    ; be defensive and only set linked refs to none if they have the expected value
    If (akActor != None && akActor.GetLinkedRef(Library.Resources.WaitMarkerLink) == Self)
        akActor.SetLinkedRef(None, Library.Resources.WaitMarkerLink)
        akActor.SetValue(Library.Resources.WaitingForPlayer, 0) ; don't bother with ModValue, the game will set/clear this, too
        ; StopAnimationAndWait will call EvaluatePackage at the "correct" moment to prevent breaking the animation
        ; so don't do it here
        Var[] akArgs = new Var[2]
        akArgs[0] = akActor
        akArgs[1] = true
        CallFunctionNoWait("StopAnimationAndWait", akArgs) ; even if there is no animation (the function will take care of that)
        UnregisterForRemoteEvent(akActor, "OnCommandModeEnter")
        UnregisterForPlayerTeleport()
        UnregisterForPlayerSleep()
        UnregisterForPlayerWait()
    EndIf
    Actor linkedActor = GetLinkedRef(Library.Resources.WaitMarkerLink) as Actor
    If (linkedActor == akActor)
        SetLinkedRef(None, Library.Resources.WaitMarkerLink)
    EndIf
EndFunction

;
; Start the animation. This function will block until the animation has fully started.
;
Function StartAnimationAndWait(Actor akActor, String animationToPlay, Bool playEnterAnimation)
    Bool cellIsAttached = GetParentCell().IsAttached()
    _currentAnimation = animationToPlay
    If (cellIsAttached && akActor.IsWeaponDrawn())
        ; probably freshly cuffed, try to wait until the weapon is stowed because
        ; starting animations with weapon out will keep the weapon out
        Int waitCount = 0
        While (akActor.IsWeaponDrawn() && waitCount < 30)
            Utility.Wait(0.1)
            waitCount += 1
        EndWhile
    EndIf
    If (_currentAnimation == "")
        Return ; concurrent stop of animation, abort
    EndIf
    IdleMarker idleMarkerForAnimation = Library.AnimationHandler.GetIdleMarkerFor(_currentAnimation)
    If (idleMarkerForAnimation == None)
        RealHandcuffs:Log.Warning("Failed to get idle marker for animation '" + _currentAnimation + "'.", Library.Settings)
    Else
        _idleMarker = PlaceAtMe(idleMarkerForAnimation, 1, false, false, true)
        If (WaitAngleZ != 0)
            Float angleZ = GetAngleZ() + WaitAngleZ
            If (angleZ >= 360)
                angleZ -= 360
            EndIf
            If (Math.Abs(_idleMarker.GetAngleZ() - angleZ) > 0.5)
                _idleMarker.SetAngle(_idleMarker.GetAngleX(), _idleMarker.GetAngleY(), angleZ)
            EndIf
        EndIf
        Float[] idleMarkerOffset = Library.AnimationHandler.GetIdleMarkerOffsetXY(_currentAnimation)
        If (idleMarkerOffset != None && (idleMarkerOffset[0] != 0 || idleMarkerOffset[1] != 0))
            Float alpha = 90 - _idleMarker.GetAngleZ() ; use math conventions for calculation
            Float sinAlpha = Math.Sin(alpha)
            Float cosAlpha = Math.Cos(alpha)
            Float offsetX = idleMarkerOffset[0] * cosAlpha - idleMarkerOffset[1] * sinAlpha
            Float offsetY = idleMarkerOffset[0] * sinAlpha + idleMarkerOffset[1] * cosAlpha
            _idleMarker.MoveTo(_idleMarker, offsetX, offsetY, 0, true)
        EndIf
    EndIf
    If (cellIsAttached && playEnterAnimation)
        Float waitTime = Library.AnimationHandler.PlayEnterFromStand(akActor, _currentAnimation)
        TranslateToIdleMarker(akActor, waitTime)
        Utility.Wait(waitTime)
        akActor.StopTranslation()
        If (_currentAnimation == "")
            Return ; concurrent stop of animation, abort
        EndIf
    EndIf
    If (cellIsAttached)
        Library.AnimationHandler.PlayIdleLoop(akActor, _currentAnimation)
    EndIf
    If (_idleMarker != None)
        akActor.SetLinkedRef(_idleMarker, Library.Resources.IdleMarkerLink)
        _idleMarker.SetLinkedRef(akActor, Library.Resources.IdleMarkerLink)
    EndIf
    akActor.EvaluatePackage(false)
    If (!DisablePoseInteraction)
        akActor.AddKeyword(Library.Resources.Posable)
    EndIf
EndFunction


;
; Stop the animation. This function will block until the animation has fully stopped.
; This function will always call akActor.EvaluatePackage(false), even if it did not do anything else.
;
Function StopAnimationAndWait(Actor akActor, Bool playExitAnimation)
    akActor.ResetKeyword(Library.Resources.Posable)
    ObjectReference oldIdleMarker = _idleMarker
    _idleMarker = None
    If (_currentAnimation != "")
        String getUpAnimation = _currentAnimation
        _currentAnimation = ""
        If (playExitAnimation && GetParentCell().IsAttached())
            akActor.SetLinkedRef(None, Library.Resources.IdleMarkerLink)
            akActor.EvaluatePackage(false)
            ; ugly workaround, we need to wait for the package to end, otherwise it will interrupt our animation
            ; using PackageChanged event turns out to be too slow (almost one second delay)
            Int waitCount = 0
            RealHandcuffs:BoundHandsPackage currentPackage = akActor.GetCurrentPackage() as RealHandcuffs:BoundHandsPackage
            While (currentPackage != None && currentPackage.Name == "RH_BoundHandsUseIdleMarker" && waitCount < 30)
                Utility.Wait(0.03333333)
                currentPackage = akActor.GetCurrentPackage() as RealHandcuffs:BoundHandsPackage
                waitCount += 1
            EndWhile
            Float waitTime = Library.AnimationHandler.PlayExitToStand(akActor, getUpAnimation)
            TranslateIntoPosition(akActor, waitTime)
            Utility.Wait(waitTime)
            akActor.StopTranslation()
        EndIf
    EndIf
    If (oldIdleMarker != None)
        If (akActor.GetLinkedRef(Library.Resources.IdleMarkerLink) == oldIdleMarker)
            akActor.SetLinkedRef(None, Library.Resources.IdleMarkerLink)
        EndIf
        akActor.EvaluatePackage(false)
        oldIdleMarker.SetLinkedRef(None, Library.Resources.IdleMarkerLink)
        oldIdleMarker.DisableNoWait()
        oldIdleMarker.Delete()
        oldIdleMarker = None
    Else
        akActor.EvaluatePackage(false)
    EndIf
EndFunction

;
; Change the animation. This function will block until the animation has fully been changed.
;
Function ChangeAnimation(Actor akActor, String newAnimation)
    Bool performQuickSwitch = newAnimation != "" && (newAnimation == _currentAnimation || Library.AnimationHandler.AreSimilarAnimations(newAnimation, _currentAnimation))
    If (performQuickSwitch)
        ObjectReference oldIdleMarker = _idleMarker
        _idleMarker = None
        Animation = newAnimation
        StartAnimationAndWait(akActor, newAnimation, false) ; directly, without StopAnimationAndWait!
        If (oldIdleMarker != None)
            If (akActor.GetLinkedRef(Library.Resources.IdleMarkerLink) == oldIdleMarker)
                ; StartAnimationAndWait was aborted
                akActor.SetLinkedRef(None, Library.Resources.IdleMarkerLink)
                akActor.EvaluatePackage(false)
            EndIf
            oldIdleMarker.SetLinkedRef(None, Library.Resources.IdleMarkerLink)
            oldIdleMarker.DisableNoWait()
            oldIdleMarker.Delete()
        EndIf
    Else
        Animation = newAnimation
        StopAnimationAndWait(akActor, true)
        If (GetRegisteredActor() != akActor || _currentAnimation != "")
            ; concurrent modification, "follow" command, etc
            Return
        EndIf
        If (Animation != "")
            StartAnimationAndWait(akActor, newAnimation, true)
        ElseIf (!DisablePoseInteraction)
            akActor.AddKeyword(Library.Resources.Posable)
        EndIf
    EndIf
EndFunction

;
; Restart the idle animation when command mode starts.
;
Event Actor.OnCommandModeEnter(Actor sender)
    If (GetRegisteredActor() != sender)
        ; not expected, fallback code
        UnregisterForRemoteEvent(sender, "OnCommandModeEnter")
        Return
    EndIf
    If (_currentAnimation != "")
        Library.AnimationHandler.PlayIdleLoop(sender, _currentAnimation) ; restore broken animation
    EndIf
EndEvent

;
; Register for events and move the registered NPC when the cell attaches.
;
Event OnCellAttach()
    If (GetRegisteredActor() != None)
        FixPositionAndAnimation()
        RegisterForPlayerSleep()
        RegisterForPlayerWait()
    EndIf
EndEvent

;
; Unregister from events when the cell detaches.
;
Event OnCellDetach()
    UnregisterForPlayerSleep()
    UnregisterForPlayerWait()
EndEvent

;
; Move the registered NPC when the player teleports (fast travel, etc).
;
Event OnPlayerTeleport()
    Actor registeredActor = GetRegisteredActor()
    If (registeredActor != None && registeredActor != Game.GetPlayer())
        ; the game clears WaitingForPlayer when the player fast travels
        registeredActor.SetValue(Library.Resources.WaitingForPlayer, 1)
        ; try to fix the position in case another mod (e.g. Better Followers) teleported the NPC
        ; this is a race condition, the last one wins; we try to "lose the race" by slowing down
        ; a bit, but this is still somewhat unreliable and may occasionally fail
        Utility.Wait(0.25)
        If (_idleMarker == None)
            MoveIntoPosition(registeredActor)
        Else
            registeredActor.MoveTo(_idleMarker, 0, 0, 0, true)
        EndIf
    EndIf
EndEvent

;
; Move the registered NPC when the player sleeps.
;
Event OnPlayerSleepStop(bool abInterrupted, ObjectReference akBed)
    ; NPCs may "wander off" while the player is sleeping
    FixPositionAndAnimation()
EndEvent

;
; Move the registered NPC when the player waits.
;
Event OnPlayerWaitStop(bool abInterrupted)
    ; NPCs may "wander off" while the player is waiting
    FixPositionAndAnimation()
EndEvent 

;
; Fix position and animation of the registered actor, usually after the cell has been attached or the game has skipped time.
;
Function FixPositionAndAnimation()
    Actor registeredActor = GetRegisteredActor()
    If (registeredActor != None && registeredActor != Game.GetPlayer())
        If (_idleMarker == None)
            MoveIntoPosition(registeredActor)
        Else
            registeredActor.MoveTo(_idleMarker, 0, 0, 0, true)
        EndIf
        If (_currentAnimation != "" && GetParentCell().IsAttached())
            Library.AnimationHandler.PlayIdleLoop(registeredActor, _currentAnimation)
        EndIf
    EndIf
EndFunction

;
; Move an object reference into position on the wait marker.
;
Function MoveIntoPosition(ObjectReference target)
    If (WaitAngleZ == 0.0)
        target.MoveTo(Self, 0.0, 0.0, 0.0, true)
    Else
        Float angleZ = GetAngleZ() + WaitAngleZ
        If (angleZ >= 360)
            angleZ -= 360
        EndIf
        target.SetAngle(target.GetAngleX(), target.GetAngleY(), angleZ)
        target.MoveTo(Self, 0.0, 0.0, 0.0, false)
    EndIf
EndFunction

;
; Translate an object reference into position on the wait marker.
; It may be necessary to call StopTranslation() later.
;
Function TranslateIntoPosition(ObjectReference target, Float duration)
    Float distance = target.GetDistance(Self)
    Float angleZ = Self.GetAngleZ()
    If (WaitAngleZ != 0.0)
        angleZ += WaitAngleZ
        If (angleZ >= 360)
            angleZ -= 360
        EndIf
    EndIf
    Float angleDistance = target.GetAngleZ() - angleZ
    If (angleDistance > 180)
        angleDistance -= 360
    ElseIf (angleDistance < -180)
        angleDistance += 360
    EndIf
    angleDistance = Math.Abs(angleDistance)
    target.TranslateTo(Self.X, Self.Y, Self.Z, target.GetAngleX(), target.GetAngleY(), angleZ, distance/duration, angleDistance/duration)
EndFunction

;
; Translate an object reference to the idle marker.
; It may be necessary to call StopTranslation() later.
;
Function TranslateToIdleMarker(ObjectReference target, Float duration)
    If (_idleMarker == None)
        Return
    EndIf
    Float distance = target.GetDistance(_idleMarker)
    Float angleZ = _idleMarker.GetAngleZ()
    Float angleDistance = target.GetAngleZ() - angleZ
    If (angleDistance > 180)
        angleDistance -= 360
    ElseIf (angleDistance < -180)
        angleDistance += 360
    EndIf
    angleDistance = Math.Abs(angleDistance)
    Float speed = Math.Max(distance/duration, 5)
    Float angleSpeed = Math.Max(10, angleDistance/duration)
    target.TranslateTo(_idleMarker.X, _idleMarker.Y, _idleMarker.Z, target.GetAngleX(), target.GetAngleY(), angleZ, distance/duration, angleDistance/duration)
EndFunction

