;
; A dedicated quest script for MCM hotkeys.
;
Scriptname RealHandcuffs:McmHotkeysQuest extends Quest Conditional

RealHandcuffs:Library Property Library Auto Const Mandatory

RealHandcuffs:ChangePosePerk Property ChangePose Auto Const Mandatory
Message Property NoActorFoundUnderCrosshair Auto Const Mandatory
Message Property NoActionAvailableForActorUnderCrosshair Auto Const Mandatory

Bool Property ShowPoseActivation Auto Conditional

;
; Fallback for "interact with bonds" action in case tab does not work.
;
Function InteractWithBondsFallback()
    RealHandcuffs:Log.Info("InteractWithBondsFallback() called.", Library.Settings)
    RealHandcuffs:PlayerToken token = Library.GetOrCreateActorToken(Game.GetPlayer()) as RealHandcuffs:PlayerToken
    If (token != None)
        RealHandcuffs:RestraintBase boundHandsRestraint = token.GetHandsBoundBehindBackRestraint()
        If (boundHandsRestraint != None)
            boundHandsRestraint.PipboyPreventedInteraction()
            Return
        EndIf
    EndIf
    RealHandcuffs:Log.Info("Ignoring hotkey, player is not bound.", Library.Settings)
EndFunction

;
; Interact with NPC action.
;
Function InteractWithNpc()
    RealHandcuffs:Log.Info("InteractWithNpc() called.", Library.Settings)
    Actor targetActor = LL_FourPlay.LastCrossHairRef() as Actor
    If (targetActor == None || !targetActor.IsBoundGameObjectAvailable() || targetActor.IsDead() || Library.SoftDependencies.IsArmorRack(targetActor))
        NoActorFoundUnderCrosshair.Show()
        Return
    EndIf
    Bool posable = IsPosable(targetActor)
    If (posable)
        ChangePose.ChangePoseInteractive(targetActor)
        Return
    EndIf
    NoActionAvailableForActorUnderCrosshair.Show()
EndFunction


;
; Check if an actor is posable.
;
Bool Function IsPosable(Actor akActor)
    Return akActor.HasKeyword(Library.Resources.Posable)
EndFunction