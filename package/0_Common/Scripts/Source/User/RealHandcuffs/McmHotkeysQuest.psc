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
Bool Property CanChangePoseOfArms Auto Conditional
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
    CanChangePoseOfArms = CanChangePoseOfArms(targetActor)
    If (!EnableQuickInventoryInteraction && !CanChangePoseOfArms)
        ; all optional interactions are disabled or do not apply, skip selection dialogue
        If (IsPosable)
            RealHandcuffs:Log.Info("Directly opening change pose dialog for " + RealHandcuffs:Log.FormIdAsString(targetActor) + " " + targetActor.GetDisplayName() + ".", Library.Settings)
            ChangePose.ChangePoseInteractive(targetActor)
            Return
        EndIf
    Else
        HasQuickInventory = IsValidQuickInventoryTarget(targetActor)
        If (IsPosable || CanChangePoseOfArms || HasQuickInventory)
            Int selection = NpcInteraction.Show()
            If (selection == 0)
                RealHandcuffs:Log.Info("Opening inventory of " + RealHandcuffs:Log.FormIdAsString(targetActor) + " " + targetActor.GetDisplayName() + ".", Library.Settings)
                targetActor.OpenInventory(1)
            ElseIf (selection == 1)
                RealHandcuffs:Log.Info("Opening change pose dialog for " + RealHandcuffs:Log.FormIdAsString(targetActor) + " " + targetActor.GetDisplayName() + ".", Library.Settings)
                ChangePose.ChangePoseInteractive(targetActor)
            ElseIf (selection == 2)
                RealHandcuffs:Log.Info("Changing pose of arms for " + RealHandcuffs:Log.FormIdAsString(targetActor) + " " + targetActor.GetDisplayName() + ".", Library.Settings)
                ChangePoseOfArms(targetActor)
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
; Check if the arms of an actor can be posed differently.
;
Bool Function CanChangePoseOfArms(Actor akActor)
    RealHandcuffs:RestraintBase[] restraints = Library.GetWornRestraints(akActor)
    Int index = restraints.Length - 1 ; start with highest priority restraint
    While (index >= 0)
        If (restraints[index].MtAnimationForArmsCanBeCycled())
            Return true
        EndIf
        index -= 1
    EndWhile
    Return false
EndFunction

;
; Change the pose of the arms of an actor.
;
Function ChangePoseOfArms(Actor akActor)
    RealHandcuffs:RestraintBase[] restraints = Library.GetWornRestraints(akActor)
    Int index = restraints.Length - 1 ; start with highest priority restraint
    While (index >= 0)
        If (restraints[index].MtAnimationForArmsCanBeCycled())
            restraints[index].CycleMtAnimationForArms(akActor)
            Return
        EndIf
        index -= 1
    EndWhile
EndFunction

;
; Check if an actor is a valid target for the quick-inventory action.
;
Bool Function IsValidQuickInventoryTarget(Actor akActor)
    If (akActor.HasKeyword(ActorTypeNPC) && Game.GetPlayer().GetDistance(akActor) <= 256)
        If (akActor.IsPlayerTeammate() || akActor.HasKeyword(PlayerTeammateFlagRemoved))
            Return true
        EndIf
        If (Library.SoftDependencies.IsJBSlave(akActor))
             Return !Library.SoftDependencies.IsEscapedJBSlave(akActor)
        EndIf
        If (Library.SoftDependencies.IsCAPPrisoner(akActor))
            Return !Library.SoftDependencies.IsEscapedCAPPrisoner(akActor)
        EndIf
        If (akActor.GetValue(WorkshopPlayerOwned) >= 1 && akActor.GetLinkedRef(WorkshopLinkHome) != None && !akActor.IsHostileToActor(Game.GetPlayer()))
            Return true
        EndIf
    EndIf
    Return false
EndFunction