;
; Contains functions that make actors play animations.
;
Scriptname RealHandcuffs:AnimationHandler extends Quest

Idle Property KneelSit_EnterFromStand Auto Const Mandatory
Idle Property KneelSit_PoseAIdle1 Auto Const Mandatory
Idle Property KneelSit_ExitToStand Auto Const Mandatory
IdleMarker Property KneelSit_IdleMarker Auto Const Mandatory
Float[] Property KneelSit_IdleMarker_OffsetXY Auto Const Mandatory
Float Property KneelSit_EnterFromStand_Duration Auto Const Mandatory
Float Property KneelSit_ExitToStand_Duration Auto Const Mandatory

Idle Property HeldHostageKneelHandsUp_EnterFromStand Auto Const Mandatory
Idle Property HeldHostageKneelHandsUp_PoseAIdle1 Auto Const Mandatory
Idle Property HeldHostageKneelHandsUp_ExitToStand Auto Const Mandatory
IdleMarker Property HeldHostageKneelHandsUp_IdleMarker Auto Const Mandatory
Float[] Property HeldHostageKneelHandsUp_IdleMarker_OffsetXY Auto Const Mandatory
Float Property HeldHostageKneelHandsUp_EnterFromStand_Duration Auto Const Mandatory
Float Property HeldHostageKneelHandsUp_ExitToStand_Duration Auto Const Mandatory


;
; Group for the different animations that can be played by actors.
;
Group Animations
    String Property KneelSit = "KneelSit" AutoReadOnly
    String Property HeldHostageKneelHandsUp = "HeldHostageKneelHandsUp" AutoReadOnly
EndGroup

;
; Group for subanimations.
;
Group SubAnimations
    Int Property EnterFromStand = 0 AutoReadOnly
    Int Property IdleLoop = 1 AutoReadOnly
    Int Property ExitToStand = 2 AutoReadOnly
EndGroup


;
; Play the "enter from stand" sub-animation for an animation.
; Returns the number of seconds that the animation will take, or -1 on failure.
;
Float Function PlayEnterFromStand(Actor akActor, String animationToPlay)
    Return PlayAnimation (akActor, animationToPlay, EnterFromStand)
EndFunction

;
; Play the "idle loop" sub-animation for an animation.
; Returns true on success, false on failure.
;
Bool Function PlayIdleLoop(Actor akActor, String animationToPlay)
    Return PlayAnimation (akActor, animationToPlay, IdleLoop) >= 0
EndFunction

;
; Play the "exit to stand" sub-animation for an animation.
; Returns the number of seconds that the animation will take, or -1 on failure.
;
Float Function PlayExitToStand(Actor akActor, String animationToPlay)
    Return PlayAnimation (akActor, animationToPlay, ExitToStand)
EndFunction


;
; Play an animation.
; Returns the number of seconds that the animation will take, 0 if the animation is a looping animation, or -1 on failure.
;
Float Function PlayAnimation(Actor akActor, String animationToPlay, Int subAnimationToPlay)
    If (akActor != None)
        If (animationToPlay == KneelSit)
            If (subAnimationToPlay == EnterFromStand)
                Return StartIdle(akActor, KneelSit_EnterFromStand, KneelSit_EnterFromStand_Duration)
            ElseIf (subAnimationToPlay == IdleLoop)
                Return StartIdle(akActor, KneelSit_PoseAIdle1, 0)
            ElseIf (subAnimationToPlay == ExitToStand)
                Return StartIdle(akActor, KneelSit_ExitToStand, KneelSit_ExitToStand_Duration)
            EndIf
        ElseIf (animationToPlay == HeldHostageKneelHandsUp)
            If (subAnimationToPlay == EnterFromStand)
                Return StartIdle(akActor, HeldHostageKneelHandsUp_EnterFromStand, HeldHostageKneelHandsUp_EnterFromStand_Duration)
            ElseIf (subAnimationToPlay == IdleLoop)
                Return StartIdle(akActor, HeldHostageKneelHandsUp_PoseAIdle1, 0)
            ElseIf (subAnimationToPlay == ExitToStand)
                Return StartIdle(akActor, HeldHostageKneelHandsUp_ExitToStand, HeldHostageKneelHandsUp_ExitToStand_Duration)
            EndIf
        EndIf
    EndIf
    Return -1
EndFunction

;
; Get an idle marker for the "idle loop" subanimation of an animation.
;
IdleMarker Function GetIdleMarkerFor(String animationToPlay)
    If (animationToPlay == KneelSit)
        Return KneelSit_IdleMarker
    ElseIf (animationToPlay == HeldHostageKneelHandsUp)
        Return HeldHostageKneelHandsUp_IdleMarker
    EndIf
    Return None
EndFunction

;
; Get an optional array containing the X and Y offset to use for the idle marker.
; This is necessary because the enter/exit animation often moves "place" where the game is seeing the npc.
;
Float[] Function GetIdleMarkerOffsetXY(String animationToPlay)
    If (animationToPlay == KneelSit)
        Return KneelSit_IdleMarker_OffsetXY
    ElseIf (animationToPlay == HeldHostageKneelHandsUp)
        Return HeldHostageKneelHandsUp_IdleMarker_OffsetXY
    EndIf
    Return None
EndFunction

;
; Check if two animations are similar animations.
;
Bool Function AreSimilarAnimations(String animationOne, String animationTwo)
    If (animationOne == KneelSit)
        Return animationTwo == HeldHostageKneelHandsUp
    ElseIf (animationOne == HeldHostageKneelHandsUp)
        Return animationTwo == KneelSit
    EndIf
    Return false
EndFunction

;
; Internal function used to start idles.
;
Float Function StartIdle(Actor akActor, Idle idleToPlay, Float resultOnSuccess)
    If (akActor.PlayIdle(idleToPlay))
        Return resultOnSuccess
    EndIf
    Return -1
EndFunction