;
; Main Quest for JustBusiness compatibility plugin.
;
Scriptname RealHandcuffs:JustBusiness:MainQuest Extends Quest

Int Property CurrentVersion = 2 AutoReadOnly
Int Property InstalledVersion Auto

RealHandcuffs:Library Property Library Auto Const Mandatory
ActorValue Property JBIsSubmissive Auto Const Mandatory
Armor Property ShockCollar Auto Const Mandatory
Armor Property VanillaShockCollar Auto Const Mandatory
Faction Property JBConvoyFaction Auto Const Mandatory
FormList Property JBRestrictList Auto Const Mandatory
Keyword Property CustomPackage Auto Const Mandatory
Keyword Property ProcessedByShockCollarProxy Auto Const Mandatory
Keyword Property ReplaceVanillaShockCollar Auto Const Mandatory
Furniture[] Property RestrictiveDevices Auto Const Mandatory
RefCollectionAlias Property JBSlaveCollection Auto Const Mandatory
Quest Property JBConvoyQuest Auto Const Mandatory

Int _lastConvoyStatus = -2
Actor[] _convoyMembers

Function RunInstallerTasks()
    If (InstalledVersion < CurrentVersion)
        If (InstalledVersion < 1)
            InstallV1()
        EndIf
        If (InstalledVersion < 2)
            InstallV2()
        EndIf
        UpdateFormlists()
    ElseIf (!UpdateFormlists())
        RealHandcuffs:Log.Info("RHJB Compatibility Plugin: Everything OK.", Library.Settings)
    EndIf
EndFunction

Function InstallV1()
    RealHandcuffs:Log.Info("RHJB Compatibility Plugin: Installing V1.", Library.Settings)
    Int index = 0
    While (index < JBSlaveCollection.GetCount())
        Actor akActor = JBSlaveCollection.GetAt(index) as Actor
        If (akActor != None && akActor.IsEquipped(VanillaShockCollar))
            If (akActor.Is3DLoaded())
                ReplaceShockCollar(akActor)
            Else
                akActor.AddKeyword(ReplaceVanillaShockCollar)
                RegisterForRemoteEvent(akActor, "OnLoad")
            EndIf
        EndIf
        index += 1
    EndWhile
    InstalledVersion = 1
    RealHandcuffs:Log.Info("RHJB Compatibility Plugin: Installed V1.", Library.Settings)
EndFunction

Function InstallV2()
    RealHandcuffs:Log.Info("RHJB Compatibility Plugin: Installing V2.", Library.Settings)
    OnTimer(CheckConvoyState)
    InstalledVersion = 2
    RealHandcuffs:Log.Info("RHJB Compatibility Plugin: Installed V2.", Library.Settings)
EndFunction

Bool Function UpdateFormlists()
    ; there is a race condition here, as we run in OnPlayerLoadGame()
    ; and JB uses the same event to clear the formlists if a plugin has disappeared
    ; if that happens, the problem will fix itself the next time the game is loaded
    Bool madeChanges = false
    Int index = 0
    While (index < RestrictiveDevices.Length)
        If (!JBRestrictList.HasForm(RestrictiveDevices[index]))
            JBRestrictList.AddForm(RestrictiveDevices[index])
            madeChanges = true
        EndIf
        index += 1
    EndWhile
    If (!madeChanges)
        Return false
    EndIf
    RealHandcuffs:Log.Info("RHJB Compatibility Plugin: Updated formlists.", Library.Settings)
    Return true
EndFunction

Event ObjectReference.OnLoad(ObjectReference sender)
    UnregisterForRemoteEvent(sender, "OnLoad")
    Actor akActor = sender as Actor
    If (akActor != None && !akActor.IsDead() && akActor.GetValue(JBIsSubmissive) >= 100 && akActor.HasKeyword(ReplaceVanillaShockCollar))
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("RHJB Compatibility Plugin: " + RealHandcuffs:Log.FormIdAsString(akActor) + " "  + akActor.GetDisplayName() + " has ReplaceVanillaShockCollar keyword, spawning shock collar.", Library.Settings)
        EndIf
        ReplaceShockCollar(akActor)
    EndIf
EndEvent

Function ReplaceShockCollar(Actor akActor)
    If (Library.Settings.AutoConvertHandcuffs)
        akActor.ResetKeyword(ReplaceVanillaShockCollar)
        akActor.AddKeyword(ProcessedByShockCollarProxy)
        akActor.UnequipItem(VanillaShockCollar, true, true)
        akActor.RemoveItem(VanillaShockCollar, 1, true, None)
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
EndFunction

Group Timers
    Int Property CheckConvoyState = 1 AutoReadOnly
EndGroup

Event OnTimer(int aiTimerID)
    If (aiTimerID == CheckConvoyState)
        ; there is no event when the convoy starts/ends, so instead check every 5 seconds
        Int convoyStatus = JBConvoyQuest.GetPropertyValue("iConvoyStatus") as Int
        If (convoyStatus != _lastConvoyStatus)
            ; convoy state changed, add RH_CustomPackage keyword to all convoy members and remove it from ex-members
            If (_convoyMembers == None)
                _convoyMembers = new Actor[0]
            EndIf
            Int index = _convoyMembers.Length - 1
            While (index >= 0)
                Actor convoyMember = _convoyMembers[index]
                If (convoyMember.IsDead() || !convoyMember.IsInFaction(JBConvoyFaction))
                    convoyMember.RemoveKeyword(CustomPackage)
                    _convoyMembers.Remove(index)
                    If (Library.Settings.InfoLoggingEnabled)
                        RealHandcuffs:Log.Info("Removed RH_CustomPackage from " + RealHandcuffs:Log.FormIdAsString(convoyMember) + " " + convoyMember.GetDisplayName() + ".", Library.Settings)
                    EndIf
                EndIf
                index -= 1
            EndWhile
            index = 0
            While (index < JBSlaveCollection.GetCount())
                Actor akActor = JBSlaveCollection.GetAt(index) as Actor
                If (akActor != None && akActor.IsInFaction(JBConvoyFaction) && !akActor.HasKeyword(CustomPackage))
                    _convoyMembers.Add(akActor)
                    akActor.AddKeyword(CustomPackage)
                    If (Library.Settings.InfoLoggingEnabled)
                        RealHandcuffs:Log.Info("Added RH_CustomPackage to " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName() + ".", Library.Settings)
                    EndIf
                EndIf
                index += 1
            EndWhile
            _lastConvoyStatus = convoyStatus
        EndIf
        StartTimer(5.0, CheckConvoyState)
    EndIf
EndEvent