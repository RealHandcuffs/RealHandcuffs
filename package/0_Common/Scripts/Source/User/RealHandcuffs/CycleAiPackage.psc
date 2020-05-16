;
; A special-purpose script for the 'CycleAiPackage' package.
;
Scriptname RealHandcuffs:CycleAiPackage extends RealHandcuffs:BoundHandsPackage Const

Event OnStart(Actor akActor)
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Cycling AI of " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName(), Library.Settings)
    EndIf
    Utility.Wait(1)
    akActor.ResetKeyword(Library.Resources.CycleAi)
    akActor.EvaluatePackage(false)
EndEvent
 
Event OnChange(Actor akActor)
    NpcToken token = Library.TryGetActorToken(akActor) as NpcToken
    If (token != None)
        token.HandleBoundHandsPackageChanged()
    EndIf
EndEvent

Event OnEnd(Actor akActor)
    ; do nothing (override base)
EndEvent