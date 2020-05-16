;
; A magic effect applying an image space modifier
;
Scriptname RealHandcuffs:ApplyImageSpaceModifierEffect extends ActiveMagicEffect Const

ImageSpaceModifier Property Modifier Auto Const Mandatory
Float Property Strength Auto Const Mandatory

Event OnEffectStart(Actor akTarget, Actor akCaster)
    Modifier.Apply(Strength)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    Modifier.Remove()
EndEvent