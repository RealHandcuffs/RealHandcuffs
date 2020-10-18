;
; Magic effect for bleedout.
;
Scriptname RealHandcuffs:BleedoutEffect extends ActiveMagicEffect

RealHandcuffs:Library Property Library Auto Const Mandatory
Keyword Property PlayerTeammateFlagRemoved Auto Const Mandatory
RefCollectionAlias Property BleedoutActors Auto Const Mandatory
ActorValue Property HC_IsCompanionInNeedOfHealing Auto Const Mandatory

Actor _target
Bool _usingBleedoutAnimation
Bool _noBleedoutRecoverySet
Bool _cantBeKnockedOutKeywordAdded
Bool _initialized

Event OnEffectStart(Actor akTarget, Actor akCaster)
    _target = akTarget
    Int waitCount = 0
    While (waitCount < 10 && BleedoutActors.Find(akTarget) >= 0)
        Utility.Wait(0.1)
    EndWhile
    If (BleedoutActors.Find(akTarget) < 0)
        BleedoutActors.AddRef(akTarget)
        If (akTarget == Game.GetPlayer())
            ; use bleedout animation for player
            Game.ForceThirdPerson()
            Utility.Wait(0.1)
            akTarget.PlayIdleAction(Library.Resources.ActionBleedoutStart)
            _usingBleedoutAnimation = true
        ElseIf (!akTarget.IsEssential() || (Library.SoftDependencies.IsSlave(akTarget) && !Library.SoftDependencies.IsEscapedSlave(akTarget)))
            ; use bleedout animation for non-essential NPCs and for regular slaves (even if essential)
            akTarget.PlayIdleAction(Library.Resources.ActionBleedoutStart)
            _usingBleedoutAnimation = true
        Else
            ; use "real" bleedout for essential NPCs because something could be waiting for OnEnterBleedout
            ; this method is much more complicated and less reliable, also it blocks knockout from working
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Using real bleedout for " + RealHandcuffs:Log.FormIdAsString(akTarget) + " " + akTarget.GetDisplayName() + ".", Library.Settings)
            EndIf
            _cantBeKnockedOutKeywordAdded = Library.SoftDependencies.KnockoutFrameworkAvailable && !akTarget.HasKeyword(Library.SoftDependencies.KFActorCantBeKnockedOutKeyword)
            If (_cantBeKnockedOutKeywordAdded)
                ; prevent knockout framework from interfering
                akTarget.AddKeyword(Library.SoftDependencies.KFActorCantBeKnockedOutKeyword)
                Utility.Wait(1.0)
            EndIf
            Bool noBleedoutRecoveryCleared = akTarget.GetNoBleedoutRecovery()
            If (noBleedoutRecoveryCleared)
                ; clear NoBleedoutRecovery flag as it can cause instant heal effects with companions
                akTarget.SetNoBleedoutRecovery(false)
            EndIf
            Bool addedToEssentialActors = Library.EssentialActors.Find(akTarget) < 0
            If (addedToEssentialActors)
                Library.EssentialActors.AddRef(akTarget)
            EndIf
            ActorValue health = Game.GetHealthAV()
            Float originalHealth = akTarget.GetValue(health)
            akTarget.Kill(None) ; will survive because it is in the EssentialActions refcollectionalias
            Utility.Wait(0.1)
            akTarget.SetNoBleedoutRecovery(true)
            _noBleedoutRecoverySet = !noBleedoutRecoveryCleared
            Float healthDelta = akTarget.GetValue(health) - originalHealth;
            If (healthDelta < 0)
                akTarget.RestoreValue(health, -healthDelta)
            ElseIf (healthDelta > 0)
                akTarget.DamageValue(health, healthDelta)
            EndIf
            If (addedToEssentialActors)
                Library.EssentialActors.RemoveRef(akTarget) ; only do this after restoring health
            EndIf
            akTarget.SetValue(HC_IsCompanionInNeedOfHealing, 0)
        EndIf
    EndIf
    _initialized = true
    Utility.Wait(Utility.RandomFloat(0.8, 2.0))
    Library.SpeechHandler.SayBleedoutTopic(_target)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    Int waitCount = 0
    While (!_initialized && waitCount < 40)
        Utility.Wait(0.1)
        waitCount += 1
    EndWhile
    If (_usingBleedoutAnimation && !Library.SoftDependencies.IsKnockedOut(_target))
        _target.PlayIdleAction(Library.Resources.ActionBleedoutStop)
    EndIf
    If (_cantBeKnockedOutKeywordAdded)
        _target.ResetKeyword(Library.SoftDependencies.KFActorCantBeKnockedOutKeyword)
    EndIf
    If (_noBleedoutRecoverySet)
        _target.SetNoBleedoutRecovery(false)
    EndIf
    BleedoutActors.RemoveRef(_target)
    If (!_target.IsDead() && _target.IsBleedingOut() && _target.GetNoBleedoutRecovery())
        Bool isPlayerTeammate = _target.HasKeyword(PlayerTeammateFlagRemoved) || _target.IsPlayerTeammate()
        If (isPlayerTeammate)
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Using workaround to make " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + " get up again.", Library.Settings)
            EndIf
            _target.SetNoBleedoutRecovery(false)
            waitCount = 0
            While (waitCount < 1000 && _target.IsBleedingOut() && BleedoutActors.Find(_target) < 0)
                Utility.Wait(0.1)
                waitCount += 1
            EndWhile
            _target.SetNoBleedoutRecovery(true)
        ElseIf (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Not changing bleedout recovery of " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + ".", Library.Settings)
        EndIf
    EndIf
EndEvent