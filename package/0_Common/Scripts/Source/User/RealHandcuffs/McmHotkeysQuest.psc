;
; A dedicated quest script for MCM hotkeys.
;
Scriptname RealHandcuffs:McmHotkeysQuest extends Quest Conditional

RealHandcuffs:Library Property Library Auto Const Mandatory

RealHandcuffs:ChangePosePerk Property ChangePose Auto Const Mandatory
Keyword Property PlayerTeammateFlagRemoved Auto Const Mandatory
ActorValue Property WorkshopPlayerOwned Auto Const Mandatory
Keyword Property ActorTypeNPC Auto Const Mandatory
Keyword Property WorkshopLinkHome Auto Const Mandatory
Message Property NpcInteraction Auto Const Mandatory
Message Property NoActorFoundUnderCrosshair Auto Const Mandatory
Message Property NoActionAvailableForActorUnderCrosshair Auto Const Mandatory

Bool Property ShowPoseActivation Auto Conditional
Bool Property EnableQuickInventoryInteraction Auto
Bool Property IsPosable Auto Conditional
Bool Property HasQuickInventory Auto Conditional

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
    IsPosable = IsPosable(targetActor)
    If (!EnableQuickInventoryInteraction)
        ; all optional interactions are disable, skip selection dialogue
        If (IsPosable)
            ChangePose.ChangePoseInteractive(targetActor)
            Return
        EndIf
    Else
        HasQuickInventory = IsValidQuickInventoryTarget(targetActor)
        If (IsPosable || HasQuickInventory)
            Int selection = NpcInteraction.Show()
            If (selection == 0)
                ChangePose.ChangePoseInteractive(targetActor)
            ElseIf (selection == 1)
                targetActor.OpenInventory(1)
            EndIf
            Return
        EndIf
    EndIf
    NoActionAvailableForActorUnderCrosshair.Show()
EndFunction


;
; Check if an actor is posable.
;
Bool Function IsPosable(Actor akActor)
    Return akActor.HasKeyword(Library.Resources.Posable)
EndFunction


;
; Check if an actor is a valid target for the quick-inventory action.
;
Bool Function IsValidQuickInventoryTarget(Actor akActor)
    If (akActor.HasKeyword(ActorTypeNPC))
        If (akActor.IsPlayerTeammate() || akActor.HasKeyword(PlayerTeammateFlagRemoved))
            Return true
        EndIf
        If (akActor.GetValue(WorkshopPlayerOwned) >= 1 && akActor.GetLinkedRef(WorkshopLinkHome) != None && !akActor.IsHostileToActor(Game.GetPlayer()))
            Return true
        EndIf
    EndIf
    Return false
EndFunction