;
; Magic effect for temporary shock damage.
;
Scriptname RealHandcuffs:TemporaryShockDamageEffect extends ActiveMagicEffect Const

RealHandcuffs:Library Property Library Auto Const Mandatory
Spell Property TemporaryShockDamageDecay Auto Const Mandatory
Keyword Property JustReceivedShock Auto Const Mandatory

Event OnEffectStart(Actor akTarget, Actor akCaster)
    Library.SpeechHandler.SayPainTopic(akTarget)
    akTarget.AddKeyword(JustReceivedShock)
    If (akTarget.HasSpell(TemporaryShockDamageDecay))
        ; nudge the spell, it will automatically reapply itself in OnEffectFinish
        akTarget.RemoveSpell(TemporaryShockDamageDecay)
    Else
        akTarget.AddSpell(TemporaryShockDamageDecay, false)        
    EndIf
EndEvent