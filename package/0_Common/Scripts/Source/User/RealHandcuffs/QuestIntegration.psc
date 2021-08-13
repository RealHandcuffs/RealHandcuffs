;
; A script that integrates handcuffs with some vanilla quests.
;
Scriptname RealHandcuffs:QuestIntegration extends ReferenceAlias

RealHandcuffs:Library Property Library Auto Const Mandatory
RealHandcuffs:AnimationHandler Property AnimationHandler Auto Const Mandatory
Armor Property Handcuffs Auto Const Mandatory
Keyword Property Stay Auto Const Mandatory
Keyword Property OpenInventoryIfBound Auto Const Mandatory

Quest Property MinRecruit02 Auto Const Mandatory

Actor _minRecruit02KidnapVictim
RealHandcuffs:TemporaryWaitMarker _minRecruit02TemporaryWaitMarker

;
; Initialize the script after installing or upgrading the mod.
;
Function Initialize(Bool upgrade)
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Initializing QuestIntegration (upgrade=" + upgrade + ").", Library.Settings)
    EndIf
    EvaluateQuests() ; register for running quests
    IsInitialized = true
EndFunction

;
; Uninitialize the script before uninstalling or upgrading the mod.
;
Function Uninitialize(Bool upgrade)
    UnregisterFromAllQuests()
    IsInitialized = false
EndFunction

;
; Check if the script is initialized.
;
Bool Property IsInitialized Auto

;
; Event called when the player changes location.
;
Event OnLocationChange(Location akOldLoc, Location akNewLoc)
    If (IsInitialized)
        EvaluateQuests()
    EndIf
EndEvent


;
; Evaluate the quests and register on events for quests that are running.
;
Function EvaluateQuests()
    If (MinRecruit02.IsRunning())
        If (_minRecruit02KidnapVictim == None)
            RegisterForMinRecruit02()
        EndIf
    Else
        If (_minRecruit02KidnapVictim != None)
            UnRegisterForMinRecruit02()
        EndIf
    EndIf
EndFunction

;
;
;
Function UnregisterFromAllQuests()
    If (_minRecruit02KidnapVictim != None)
        UnRegisterForMinRecruit02()
    EndIf
EndFunction


;
; Register for the "Kidnapping" quest.
;
Function RegisterForMinRecruit02()
    RealHandcuffs:Log.Info("Registering for events of quest MinRecruit02.", Library.Settings)
    _minRecruit02KidnapVictim = (MinRecruit02.GetAlias(38) as ReferenceAlias).GetActorReference()
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Kidnapped victim: " + RealHandcuffs:Log.FormIdAsString(_minRecruit02KidnapVictim) + " " + _minRecruit02KidnapVictim.GetDisplayName(), Library.Settings)
    EndIf
    RegisterForRemoteEvent(MinRecruit02, "OnStageSet")
    RegisterForRemoteEvent(_minRecruit02KidnapVictim, "OnCellAttach")
    RegisterForRemoteEvent(_minRecruit02KidnapVictim, "OnCellDetach")
EndFunction

;
; Unregister from the "Kidnapping" quest.
;
Function UnRegisterForMinRecruit02()
    RealHandcuffs:Log.Info("Unregistering from events of quest MinRecruit02.", Library.Settings)
    _minRecruit02KidnapVictim = None
    UnregisterForRemoteEvent(_minRecruit02KidnapVictim, "OnCellDetach")
    UnregisterForRemoteEvent(_minRecruit02KidnapVictim, "OnCellAttach")
    UnregisterForRemoteEvent(MinRecruit02, "OnStageSet")
EndFunction


;
; Event handler for quest stages set.
;
Event Quest.OnStageSet(Quest q, int auiStageID, int auiItemID)
    If (q == MinRecruit02)
        If (_minRecruit02KidnapVictim != None)
            If (auiStageID >= 150)
                ; make kidnap victim stand up and follow player
                If (_minRecruit02TemporaryWaitMarker != None)
                    _minRecruit02TemporaryWaitMarker.Unregister(_minRecruit02KidnapVictim) ; will delete the wait marker as a side effect
                    _minRecruit02TemporaryWaitMarker = None
                EndIf
                If (Library.GetHandsBoundBehindBack(_minRecruit02KidnapVictim))
                    If (auiStageID < 400)
                        _minRecruit02KidnapVictim.AddKeyword(OpenInventoryIfBound)
                        _minRecruit02KidnapVictim.SetLinkedRef(Game.GetPlayer(), Library.LinkedOwner)
                    EndIf
                    _minRecruit02KidnapVictim.ResetKeyword(Stay)
                    If (auiStageID < 400)
                        _minRecruit02KidnapVictim.EvaluatePackage()
                    EndIf
                EndIf
            EndIf
            If (auiStageID >= 400)
                ; stop kidnap victim following player if bound
                _minRecruit02KidnapVictim.ResetKeyword(OpenInventoryIfBound)
                _minRecruit02KidnapVictim.SetLinkedRef(None, Library.LinkedOwner)
                _minRecruit02KidnapVictim.EvaluatePackage()
            EndIf
        EndIf
    Else
        UnregisterForRemoteEvent(q, "OnStageSet")
    EndIf
EndEvent

;
; Event handler for cell attached for an object reference.
;
Event ObjectReference.OnCellAttach(ObjectReference sender)
    If (sender == _minRecruit02KidnapVictim)
        If (Library.Settings.IntegrateHandcuffsInVanillaScenes && MinRecruit02.GetStage() == 100)
            ; player enters cell, put kidnap victim into handcuffs
            _minRecruit02KidnapVictim.AddKeyword(Stay)
            RealHandcuffs:NpcToken token = Library.TryGetActorToken(_minRecruit02KidnapVictim) as RealHandcuffs:NpcToken
            If (token == None || !token.GetHandsBoundBehindBack())
                RealHandcuffs:HandcuffsConverter converter = (Self as ScriptObject) as HandcuffsConverter
                RealHandcuffs:HandcuffsBase restraint = converter.CreateRandomHandcuffsAt(_minRecruit02KidnapVictim)
                _minRecruit02KidnapVictim.AddItem(restraint, 1, true)
                restraint.ForceEquip(false, true)
                token = Library.TryGetActorToken(_minRecruit02KidnapVictim) as RealHandcuffs:NpcToken
                If (token != None && token.IsApplied(restraint))
                    ; add key to boss inventory
                    Actor boss = (MinRecruit02.GetAlias(35) as ReferenceAlias).GetActorReference()
                    If (boss != None && boss.GetCurrentLocation() == _minRecruit02KidnapVictim.GetCurrentLocation())
                        boss.AddItem(restraint.GetKeyObject(), 1, true)
                    EndIf
                Else
                    restraint.Drop(true)
                    restraint.DisableNoWait()
                    restraint.Delete()
                EndIf
            EndIf
            ; make kidnap victim sit
            If (token.GetHandsBoundBehindBack() && _minRecruit02TemporaryWaitMarker == None)
                ObjectReference captiveMarker = (MinRecruit02.GetAlias(37) as ReferenceAlias).GetReference()
                _minRecruit02KidnapVictim.MoveTo(captiveMarker)
                _minRecruit02TemporaryWaitMarker = token.TryCreateTemporaryWaitMarker("", false)
                If (_minRecruit02TemporaryWaitMarker != None)
                    _minRecruit02TemporaryWaitMarker.StartAnimationAndWait(_minRecruit02KidnapVictim, AnimationHandler.HeldHostageKneelHandsUp, false)
                EndIf
            Else
                _minRecruit02KidnapVictim.ResetKeyword(Stay)
            EndIf
        EndIf
    Else
        UnregisterForRemoteEvent(sender, "OnCellAttach")
    EndIf
EndEvent

;
; Event handler for cell detached for an object reference.
;
Event ObjectReference.OnCellDetach(ObjectReference sender)
    If (sender == _minRecruit02KidnapVictim)
        ; do nothing for now
    Else
        UnregisterForRemoteEvent(sender, "OnCellDetach")
    EndIf
EndEvent
