;
; Magic effect being hit by a taser syringe.
;
Scriptname RealHandcuffs:TaserShockEffect extends ActiveMagicEffect

RealHandcuffs:Library Property Library Auto Const Mandatory
Keyword Property TaserVictim Auto Const Mandatory

Int Property ShockType Auto Const Mandatory

Group ShockType
    Int Property ShockTypeDefaultShock = 0 AutoReadOnly
    Int Property ShockTypeThrobbingShock = 1 AutoReadOnly
EndGroup

Event OnEffectStart(Actor akTarget, Actor akCaster)
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Triggering taser hit shock effect (ShockType=" + ShockType + ") on " + RealHandcuffs:Log.FormIdAsString(akTarget) + " " + akTarget.GetDisplayName() + ".", Library.Settings)
    EndIf
    If ((Library.Settings.CastJBMarkSpellOnTaserVictims == 0 || (Library.Settings.CastJBMarkSpellOnTaserVictims == 1 && akTarget.IsBleedingOut())) && Library.SoftDependencies.IsValidJBMarkSpellVictim(akTarget))
        Library.SoftDependencies.JBMarkSpell.Cast(akTarget)
    EndIf
    akTarget.AddKeyword(TaserVictim)
    If (ShockType == ShockTypeDefaultShock)
        Library.ZapWithDefaultShock(akTarget, akCaster)
    ElseIf (ShockType == ShockTypeThrobbingShock)
        Library.ZapWithThrobbingShock(akTarget, akCaster)
    Else
        RealHandcuffs:Log.Error("TaserShockEffect: Unknown shock type " + ShockType, Library.Settings)
    EndIf
    Utility.Wait(2.0)
    akTarget.ResetKeyword(TaserVictim)
EndEvent