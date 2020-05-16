
; Magic effect for decaying temporary shock damage.
;
Scriptname RealHandcuffs:TemporaryShockDamageDecayEffect extends ActiveMagicEffect

RealHandcuffs:Library Property Library Auto Const Mandatory
ActorValue Property TemporaryShockDamage Auto Const Mandatory
Keyword Property JustReceivedShock Auto Const Mandatory
Keyword Property TaserVictim Auto Const Mandatory
Spell Property BleedoutSpell Auto Const Mandatory
Spell Property TemporaryShockDamageDecay Auto Const Mandatory

; do not add further state to the spell, TemporaryShockDamageEffect will remove and readd it when damage is dealt
; if state needs to be tracked then track it with actor values and/or with keywords
Bool _running
Actor _target

Event OnEffectStart(Actor akTarget, Actor akCaster)
    _running = true
    _target = akTarget
    HandleState()
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    _running = false
    CancelTimer(1) ; may do nothing
    Float shockDamage = _target.GetValue(TemporaryShockDamage)
    If (_target.IsDead())
        ; cleanup for dead actors
        If (_target.HasSpell(TemporaryShockDamageDecay))
            _target.RemoveSpell(TemporaryShockDamageDecay)
        EndIf
        _target.RestoreValue(TemporaryShockDamage, shockDamage)
        If (_target.HasSpell(BleedoutSpell))
            _target.RemoveSpell(BleedoutSpell)
        EndIf
        If (Library.SoftDependencies.IsKnockedOut(_target))
            Library.SoftDependencies.WakeKnockedOutActor(_target)
        EndIf
    ElseIf (shockDamage > 0)
        If (_target.HasSpell(TemporaryShockDamageDecay))
            _target.RemoveSpell(TemporaryShockDamageDecay)
            Utility.Wait(0.1)
        EndIf
        _target.AddSpell(TemporaryShockDamageDecay, false)
    Else
        If (_target.HasSpell(BleedoutSpell))
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Releasing " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + " from bleedout.", Library.Settings);
            EndIf
            _target.RemoveSpell(BleedoutSpell)
        EndIf
        If (Library.SoftDependencies.IsKnockedOut(_target))
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Waking up " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + ".", Library.Settings);
            EndIf
            Library.SoftDependencies.WakeKnockedOutActor(_target)
        EndIf
    EndIf
EndEvent

Event OnTimer(int aiTimerID)
    If (_running && aiTimerID == 1)
        HandleState()
    EndIf
EndEvent

;
; Function triggered to handle state.
;
Function HandleState()
    If (_target.IsDead())
        _running = false
        _target.RemoveSpell(TemporaryShockDamageDecay)
        Return
    EndIf
    Float shockDamage = _target.GetValue(TemporaryShockDamage)
    Float shockAsHealthPercentage = CalculateShockHealthPercent(shockDamage)
    Float healthPercentage = _target.GetValuePercentage(Game.GetHealthAV())
    Bool shockCausedBleedout = false
    If (_target.HasKeyword(JustReceivedShock) && !Library.Settings.Disabled)
        ObjectReference currentFurniture = _target.GetFurnitureReference()
        If (currentFurniture != None)
            WorkshopObjectScript woFurniture = currentFurniture as WorkshopObjectScript
            If (woFurniture == None || !woFurniture.bWork24Hours)
                _target.PlayIdleAction(Library.Resources.ActionInteractionExitQuick)
            EndIf
        EndIf
        If (shockAsHealthPercentage >= healthPercentage)
            Bool spareTargetEvenWithExcessiveShockDamage = Library.Settings.ShockLethality == 2 || Library.Settings.ShockLethality == 1 && _target.IsEssential()
            If (_target.HasKeyword(TaserVictim) && Library.SoftDependencies.JBCompatibilityActive && Library.Settings.CastJBMarkSpellOnTaserVictims == 1 && Library.SoftDependencies.IsValidJBMarkSpellVictim(_target))
                Library.SoftDependencies.JBMarkSpell.Cast(_target)
                spareTargetEvenWithExcessiveShockDamage = true
            EndIf
            If (shockAsHealthPercentage >= 2.00) ; is equal to: shockDamage >= 487
                If (spareTargetEvenWithExcessiveShockDamage)
                    If (Library.Settings.InfoLoggingEnabled)
                        RealHandcuffs:Log.Info("Sparing " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + " despite excessive shock damage.", Library.Settings)
                    EndIf
                Else
                    If (Library.Settings.InfoLoggingEnabled)
                        RealHandcuffs:Log.Info("Killing " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + " because of excessive shock damage.", Library.Settings)
                    EndIf
                    If (Library.Settings.ShockLethality == 0)
                        _target.KillEssential()
                    Else
                        _target.Kill()
                    EndIf
                EndIf
                If (!_target.IsDead())
                    ; cap shock damage at 486 to prevent excessively long recovery time
                    _target.RestoreValue(TemporaryShockDamage, _target.GetValue(TemporaryShockDamage) - 444)
                    shockDamage = 486
                    shockAsHealthPercentage = CalculateShockHealthPercent(486)
                EndIf
            EndIf
            If (!_target.IsBleedingOut() && !Library.SoftDependencies.IsKnockedOut(_target))
                Bool allowKnockout = false ; disable knockout for now, it looks bad with handcuffs
                If (_target.HasSpell(BleedoutSpell))
                    If (allowKnockout && shockAsHealthPercentage > 1.0)
                        If (Library.Settings.InfoLoggingEnabled)
                            RealHandcuffs:Log.Info("Knocking out " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + " because of shock damage.", Library.Settings)
                        EndIf
                        _target.RemoveSpell(BleedoutSpell)
                        Library.SoftDependencies.KnockoutActor(_target)
                    EndIf
                Else
                    If (Library.Settings.InfoLoggingEnabled)
                        RealHandcuffs:Log.Info("Sending " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + " into bleedout because of shock damage.", Library.Settings)
                    EndIf
                    _target.AddSpell(BleedoutSpell)
                    shockCausedBleedout = true
                EndIf
            EndIf
        EndIf
        If (Library.SoftDependencies.JBCompatibilityActive && Library.Settings.ShockCollarJBSubmissionWeight > 0.0 && (Library.SoftDependencies.IsSlave(_target) || Library.SoftDependencies.IsEscapedSlave(_target)))
            ; code smell: should find a better way than hardcoding the shock damage values here, but we need to know them such that we can catch up for the missed intervals
            Float submissionValue = shockAsHealthPercentage * Library.Settings.ShockCollarJBSubmissionWeight * 0.5
            If (shockCausedBleedout)
                submissionValue += 0.75 * Library.Settings.ShockCollarJBSubmissionWeight * 0.5 ; bonus submission when sending slave to the ground
            EndIf
            If (Library.SoftDependencies.IncrementJBSubmission(_target, submissionValue))
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Incremented submission of " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + " by " + submissionValue + ".", Library.Settings)
                EndIf
            Else
                RealHandcuffs:Log.Info("Failed to increment submission.", Library.Settings)
            EndIf
        EndIf
        _target.ResetKeyword(JustReceivedShock)
    EndIf
    If (_target.HasSpell(BleedoutSpell) && shockAsHealthPercentage < healthPercentage)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Releasing " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + " from bleedout.", Library.Settings);
        EndIf
        _target.RemoveSpell(BleedoutSpell)
    EndIf
    If (Library.SoftDependencies.IsKnockedOut(_target) && shockDamage == 0)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Waking up " + RealHandcuffs:Log.FormIdAsString(_target) + " " + _target.GetDisplayName() + ".", Library.Settings);
        EndIf
        Library.SoftDependencies.WakeKnockedOutActor(_target)
    EndIf
    If (_running)
        If (_target.HasSpell(BleedoutSpell))
            ; bleeding out, check conditions every second
            StartTimer(1.0, 1)
        ElseIf (shockDamage > 0)
            ; not bleeding out, wake when shock damage has fully decayed
            StartTimer(Math.Max(1, Math.Min(shockDamage / 5, 10)), 1)
        Else
            _running = false
            _target.RemoveSpell(TemporaryShockDamageDecay)
        EndIf
    EndIf
EndFunction

;
; Calculate the "health percentage" of a temporary shock damage value.
; The returned value is normalized to 1, i.e. 0.5 is 50%, 1.0 is 100%, 1.5 is 150% etc.
;
Float Function CalculateShockHealthPercent(Float shockDamage) Global
    ; the below formula is selected to form a quadratic curve fit between temporary shock damage and health
    ; such that 70 temporary shock damage is 1/6 (16.6666% health) and 300 temporary shock damage is 1 (100% health)
    Return (shockDamage + 505) * shockDamage / 241500
EndFunction