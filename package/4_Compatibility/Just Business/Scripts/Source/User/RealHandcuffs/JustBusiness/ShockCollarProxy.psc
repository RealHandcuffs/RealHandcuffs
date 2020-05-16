;
; Proxy object for shock collars, spawned by JustBusiness when it thinks that a shock collar should be applied to a slave.
;
Scriptname RealHandcuffs:JustBusiness:ShockCollarProxy Extends ObjectReference

RealHandcuffs:Library Property Library Auto Const Mandatory
Armor Property ShockCollar Auto Const Mandatory
Armor Property VanillaShockCollar Auto Const Mandatory
Keyword Property ProcessedByShockCollarProxy Auto Const Mandatory
Keyword Property ReplaceVanillaShockCollar Auto Const Mandatory

Bool _disposed

;
; Event triggered when object comes into existence, usually by JustBusiness spawning and equipping it on a slave.
;
Event OnEquipped(Actor akActor)
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("RHJB ShockCollarProxy spawned for " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName() + ".", Library.Settings)
    EndIf
    If (!akActor.HasKeyword(ReplaceVanillaShockCollar) && !akActor.HasKeyword(ProcessedByShockCollarProxy) && Library.Settings.AddCollarsToJBSlaves == 0)
        ; wait up to 5 seconds to allow the transfer of existing restraints to start after the clone has been created
        Int waitCount = 0
        While (!_disposed && waitCount < 5 && !akActor.HasKeyword(Library.Resources.FreshlyCloned))
            Utility.Wait(1)
            waitCount += 1
        EndWhile
        ; if it has started, give the it up to another 10 seconds to finish
        If (!_disposed && akActor.HasKeyword(Library.Resources.FreshlyCloned))
            RealHandcuffs:Log.Info("RHJB ShockCollarProxy: Detected ongoing transfer of restraints, waiting for completion.", Library.Settings)
            waitCount = 0
            While (!_disposed && waitCount < 10 && akActor.HasKeyword(Library.Resources.FreshlyCloned))
                Utility.Wait(1)
                waitCount += 1
            EndWhile
            akActor.ResetKeyword(Library.Resources.FreshlyCloned)
        EndIf
    EndIf
    Dispose(akActor, false)
EndEvent

Event OnUnequipped(Actor akActor)
    Dispose(akActor, true)
EndEvent

Function Dispose(Actor akActor, Bool calledFromOnUnequipped)
    If (!_disposed)
        _disposed = true
        Bool spawnAndEquipCollar = false
        Bool removeVanillaCollar = false
        If (calledFromOnUnequipped)
            RealHandcuffs:Log.Info("RHJB ShockCollarProxy: Disposed from OnUnequipped(), not spawning shock collar.", Library.Settings)
        Else
            akActor.UnequipItem(GetBaseObject(), true, true)
            If (akActor.HasKeyword(ReplaceVanillaShockCollar))
                RealHandcuffs:Log.Info("RHJB ShockCollarProxy: Actor has ReplaceVanillaShockCollar keyword, spawning shock collar.", Library.Settings)
                spawnAndEquipCollar = true
                removeVanillaCollar = true
                akActor.ResetKeyword(ReplaceVanillaShockCollar)
            ElseIf (akActor.HasKeyword(ProcessedByShockCollarProxy))
                RealHandcuffs:Log.Info("RHJB ShockCollarProxy: Actor has ProcessedByShockCollarProxy keyword, not spawning shock collar.", Library.Settings)
            ElseIf (Library.GetRemoteTriggerEffect(akActor))
                RealHandcuffs:Log.Info("RHJB ShockCollarProxy: Detected equipped collar, not spawning shock collar.", Library.Settings)
            ElseIf (Library.Settings.AddCollarsToJBSlaves)
                RealHandcuffs:Log.Info("RHJB ShockCollarProxy: Spawning and equipping shock collar.", Library.Settings)
                spawnAndEquipCollar = true
            Else
                RealHandcuffs:Log.Info("RHJB ShockCollarProxy: Not spawning shock collar, disabled in settings.", Library.Settings)
            EndIf
        EndIf
        akActor.AddKeyword(ProcessedByShockCollarProxy)
        If (spawnAndEquipCollar)
            RealHandcuffs:RestraintBase restraint = Game.GetPlayer().PlaceAtMe(ShockCollar, 1, false, true, false) as RealHandcuffs:RestraintBase
            restraint.EnableNoWait()
            akActor.AddItem(restraint, 1, true)
            restraint.ForceEquip(false, true)
            RealHandcuffs:ActorToken token = Library.TryGetActorToken(akActor)
            If (token == None || !token.IsApplied(restraint))
                restraint.Drop(true)
                restraint.DisableNoWait()
                restraint.Delete()
            EndIf
        EndIf
        If (removeVanillaCollar)
            akActor.RemoveItem(VanillaShockCollar, 1, true, None)
        EndIf
        If (GetContainer() != None)
            Drop(true)
        EndIf
        DisableNoWait()
        Delete()
    EndIf
EndFunction