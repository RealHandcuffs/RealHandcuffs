;
; A very simple magic effect adding a keyword to the actor as long as the effect is active.
; This can be used to turn a condition into a keyword.
;
Scriptname RealHandcuffs:AddKeywordEffect extends ActiveMagicEffect

Keyword Property TheKeyword Auto Const Mandatory

Event OnEffectStart(Actor akTarget, Actor akCaster)
    akTarget.AddKeyword(TheKeyword)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
    akTarget.ResetKeyword(TheKeyword)
EndEvent