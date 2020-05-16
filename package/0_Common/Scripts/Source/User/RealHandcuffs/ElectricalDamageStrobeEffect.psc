;
; Magic effect for electrical damage with a visual "strobe" effect.
;
Scriptname RealHandcuffs:ElectricalDamageStrobeEffect extends ActiveMagicEffect

Spell Property ElectricalDamageZeroPointsSpell Auto Const Mandatory

Int Property ShockCount Auto Mandatory
Float Property TimeBetweenShocks Const Auto Mandatory

Event OnEffectStart(Actor akTarget, Actor akCaster)
    Int count = 1 ; the first shock vfx is dealt by the non-script part of the effect
    While (count < ShockCount)
        Utility.Wait(TimeBetweenShocks)
        ElectricalDamageZeroPointsSpell.Cast(akCaster, akTarget)
        count += 1
    EndWhile
EndEvent