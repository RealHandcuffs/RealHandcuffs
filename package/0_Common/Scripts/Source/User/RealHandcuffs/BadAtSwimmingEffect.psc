;
; Magic effect for swimming with restraints that make swimming difficult.
; This effect must be put on the actor using a condition, such that it is only active during swimming
;
Scriptname RealHandcuffs:BadAtSwimmingEffect extends RealHandcuffs:AddKeywordEffect

RealHandcuffs:Library Property Library Auto Const Mandatory

ActorValue Property SpeedMult Auto Const Mandatory
Keyword Property ActorTypeNpc Auto Const Mandatory
Keyword Property ActorTypeSynth Auto Const Mandatory
Keyword Property UnderwaterKeyword Auto Const Mandatory
MagicEffect Property AbWaterBreathing Auto Const Mandatory
Perk Property AquaBoy01 Auto Const Mandatory
Perk Property AquaGirl01 Auto Const Mandatory
Sound Property NPCHumanDrowning Auto Const Mandatory

Float _speedMultDamage
Bool _lastUnderwater
Int _counter
Int _drowningSoundCounter

;
; Initialize when the actor starts swimming.
;
Event OnEffectStart(Actor akTarget, Actor akCaster)
    Parent.OnEffectStart(akTarget, akCaster)
    If (akTarget.HasPerk(AquaBoy01) || akTarget.HasPerk(AquaGirl01))
        ; slow down aquaboys/girls to 70% speed
        _speedMultDamage = akTarget.GetValue(SpeedMult) * 0.3
    Else
        ; slow down everybody else to 40% speed
        _speedMultDamage = akTarget.GetValue(SpeedMult) * 0.6
    EndIf
    akTarget.DamageValue(SpeedMult, _speedMultDamage)
    ; check state every second
    StartTimer(1, 1)
EndEvent

;
; Terminate when the actor stops swimming.
;
Event OnEffectFinish(Actor akTarget, Actor akCaster)
    CancelTimer(1)
    akTarget.RestoreValue(SpeedMult, _speedMultDamage)
    Parent.OnEffectFinish(akTarget, akCaster)
EndEvent

;
; Timer triggered every second to check state.
;
Event OnTimer(int aiTimerID)
    _counter += 1
    Actor target = GetTargetActor()
    Bool underwater = target.HasKeyword(UnderwaterKeyword)
    If (underwater != _lastUnderwater)
        _lastUnderwater = underwater
        If (!underwater)
            ; don't play drowning sound directly after surfacing, the game plays breathing sounds
            _drowningSoundCounter = _counter
        EndIf
    EndIf
    If (!underwater && (_counter - _drowningSoundCounter >= 2))
        If (target.HasKeyword(ActorTypeNpc) && !target.HasKeyword(ActorTypeSynth) && !target.HasPerk(AquaBoy01) && !target.HasPerk(AquaGirl01) && !target.HasMagicEffect(AbWaterBreathing))
            ; play drowing sound but don't do any damage, this is just flavor
            NPCHumanDrowning.Play(target)
            If (target == Game.GetPlayer())
                Library.Resources.MsgStruggleSwimming.Show()
            EndIf
            _drowningSoundCounter = _counter
        EndIf
    EndIf
    StartTimer(1, 1)
EndEvent