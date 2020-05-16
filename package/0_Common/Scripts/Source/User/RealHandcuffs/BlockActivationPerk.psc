;
; Very simple perk script used for all perks that block activation of something.
;
Scriptname RealHandcuffs:BlockActivationPerk extends Perk

RealHandcuffs:Library Property Library Auto Const Mandatory

String Property PerkName Auto Const Mandatory
Int[] Property ActionByEntry Auto Const Mandatory
Int[] Property DataByEntry Auto Const Mandatory

Group EntryAction
    Int Property OpenLock = 1 AutoReadOnly          ; data: lock difficulty
    Int Property DisarmTrap = 2 AutoReadOnly        ; data: 0 = forbidden, 1 = allowed
    Int Property UseOrActivate = 3 AutoReadOnly     ; data: 0 = forbidden, 1 = allowed
    Int Property Harvest = 4 AutoReadOnly           ; data: 0 = forbidden, 1 = allowed
    Int Property PickPocket = 5 AutoReadOnly        ; data: 0 = forbidden, 1 = allowed
    Int Property EnterPowerArmor = 6 AutoReadOnly   ; data: 0 = forbidden, 1 = allowed
    Int Property Sleep = 7 AutoReadOnly             ; data: 0 = forbidden, 1 = allowed
    Int Property SearchContainer = 8 AutoReadOnly   ; data: 0 = forbidden, 1 = allowed
    Int Property UseTools = 9 AutoReadOnly          ; no data
    Int Property TakeObject = 10 AutoReadOnly       ; data: 0 = forbidden, 1 = allowed
    Int Property EatObject = 11 AutoReadOnly        ; no data
    Int Property DrinkOpenWater = 12 AutoReadOnly   ; no data
EndGroup

Event OnEntryRun(int auiEntryID, ObjectReference akTarget, Actor akOwner)
    If (akOwner == Game.GetPlayer())
        If (ActionByEntry == None || ActionByEntry.Length <= auiEntryID)
            RealHandcuffs:Log.Warning(PerkName + ": Missing action for entry " + auiEntryID, Library.Settings)
        EndIf
        Int entryAction = ActionByEntry[auiEntryID]
        If (DataByEntry == None || DataByEntry.Length <= auiEntryID)
            RealHandcuffs:Log.Warning(PerkName + ": Missing data for entry " + auiEntryID, Library.Settings)
        EndIf
        Int entryData = DataByEntry[auiEntryID]
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info(PerkName + ": Entry " + auiEntryID + ", Action " + EntryActionToString(entryAction )+ ", data " + entryData, Library.Settings)
        EndIf
        RealHandcuffs:PlayerToken token = Library.GetOrCreateActorToken(akOwner) as RealHandcuffs:PlayerToken
        token.HandleActivationBlocked(Self, akTarget, entryAction, entryData)
    EndIf
EndEvent

String Function EntryActionToString(Int entryAction)
    If (entryAction == OpenLock)
        Return "OpenLock"
    ElseIf (entryAction == DisarmTrap)
        Return "DisarmTrap"
    ElseIf (entryAction == UseOrActivate)
        Return "UseOrActivate"
    ElseIf (entryAction == Harvest)
        Return "Harvest"
    ElseIf (entryAction == PickPocket)
        Return "PickPocket"
    ElseIf (entryAction == EnterPowerArmor)
        Return "EnterPowerArmor"
    ElseIf (entryAction == Sleep)
        Return "Sleep"
    ElseIf (entryAction == SearchContainer)
        Return "SearchContainer"
    ElseIf (entryAction == UseTools)
        Return "UseTools"
    ElseIf (entryAction == TakeObject)
        Return "TakeObject"
    ElseIf (entryAction == EatObject)
        Return "EatObject"
    ElseIf (entryAction == DrinkOpenWater)
        Return "DrinkOpenWater"
    EndIf
    Return "" + entryAction ; fallback, not expected
EndFunction