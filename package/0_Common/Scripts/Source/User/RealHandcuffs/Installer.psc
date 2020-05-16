;
; Script to install, uninstall, maintain, and update the mod.
;
Scriptname RealHandcuffs:Installer extends ReferenceAlias

RealHandcuffs:Library Property Library Auto Const Mandatory
RealHandcuffs:McmInteraction Property McmInteraction Auto Const Mandatory
RealHandcuffs:LeveledListInjector Property LeveledListInjector Auto Const Mandatory

Perk Property ChangePose Auto Const Mandatory
Perk Property InteractWithKnockedOut Auto Const Mandatory
RefCollectionAlias Property BleedoutActors Auto Const Mandatory
RefCollectionAlias Property KnockoutActors Auto Const Mandatory
RefCollectionAlias Property PrisonerMatActors Auto Const Mandatory
RefCollectionAlias Property TemporaryWaitMarkers Auto Const Mandatory
Spell Property BleedoutSpell Auto Const Mandatory

Perk Property RH_Obsolete_ObservePlayerCrosshair Auto Const Mandatory

Quest Property MQ102 Auto Const Mandatory ; "Out of Time" quest, used to defer some parts of initialization in early game

String Property UpdatePendingState = "UpdatePending" AutoReadOnly ; 'update pending' state string, will never change
String Property DisabledState      = "Disabled"      AutoReadOnly ; 'disabled' state, will never change

String Property StateVersion       = "V1"            AutoReadOnly ; internal state version string, will change when a new version requires different install/uninstall steps
String Property DetailedVersion    = "0.4.5"         AutoReadOnly ; user version string, will change with every new version

String Property InstalledDetailedVersion Auto ; currently installed detailed version
String Property InstalledEdition Auto         ; currently installed edition

Bool Property InstallerRunning Auto ; flag to prevent concurrent running of installer tasks

;
; Called on initial installation of the mod.
;
Event OnInit()
    Library.SoftDependencies.SoftDependenciesLoading = true
    Library.Settings.LogLevelNotificationArea = 1 ; to prevent user-visible messages about loading settings
    RealHandcuffs:Log.Info("Quest initialized. Version: " + DetailedVersion + " " + Library.Settings.Edition + " Edition.", Library.Settings)
    Library.Settings.Refresh()
    Library.SoftDependencies.RefreshOnGameLoad()
    RunInstallerTasks()
EndEvent

;
; Called when the player loads the game with the mod installed.
;
Event OnPlayerLoadGame()
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Game loaded. Version: " + DetailedVersion + " " + Library.Settings.Edition + " Edition. Installed version: " + InstalledDetailedVersion + " " + InstalledEdition + " Edition.", Library.Settings)
    EndIf
    Library.SoftDependencies.SoftDependenciesLoading = true
    Library.Settings.Refresh()
    Library.SoftDependencies.RefreshOnGameLoad()
    RunInstallerTasks()
EndEvent
    
;
; Called when mod settings are changed.
;    
Event RealHandcuffs:Settings.OnSettingsChanged(RealHandcuffs:Settings akSender, Var[] akArgs)
    Bool oldDisabled = GetState() == DisabledState
    Bool newDisabled = Library.Settings.Disabled
    If (oldDisabled != newDisabled)
        RunInstallerTasks()
    EndIf
EndEvent

;
; Helper function checking hard dependencies, will return "OK" if everything is fine, an error message otherwise.
;
String Function CheckDependencies()
    RealHandcuffs:Log.Info("Installer checking hard dependencies.", Library.Settings)
    Int f4seMajorVersion = F4SE.GetVersion()
    Int f4seMinorVersion = F4SE.GetVersionMinor()
    Int f4seBetaVersion = F4SE.GetVersionBeta()
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("F4SE: " + f4seMajorVersion + "." + f4seMinorVersion + "." + f4seBetaVersion, Library.Settings)
    EndIf
    If (f4seMajorVersion == 0 && f4seMinorVersion == 0 && f4seBetaVersion == 0)
        Return "F4SE is not installed."
    ElseIf ((f4seMinorVersion < 6 && f4seMajorVersion == 0) || (f4seBetaVersion < 14 && f4seMinorVersion == 6 && f4seMajorVersion == 0))
        Return "F4SE is too old, 0.6.14 or later is required."
    EndIf
    Float llfpVersion = LL_FourPlay.GetLLFPPluginVersion()
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("LLFP: " + llfpVersion, Library.Settings)
    EndIf
    If (llfpVersion == 0)
        Return "LL FourPlay F4SE plugin is not installed."
    EndIf
    If (llfpVersion < 28)
        Return "LL FourPlay F4SE plugin is too old, version 28 or later is required."
    EndIf
    Float llfpScriptVersion = LL_FourPlay.GetLLFPScriptVersion()
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("LLFP script: " + llfpScriptVersion, Library.Settings)
    EndIf
    If (llfpScriptVersion < 28)
        Return "LL FourPlay script is too old, version 28 or later is required."
    EndIf
    Return "OK"
EndFunction

;
; Main installer function will run installer tasks in a loop until everything is fine.
;
Function RunInstallerTasks()    
    If (InstallerRunning)
        Return
    EndIf
    InstallerRunning = true
    Float installerStartTime = Utility.GetCurrentRealTime()
    McmInteraction.FullVersionAndEdition = "Real Handcuffs installer is currently working. Please close MCM and wait for installer to finish."
    String dependenciesCheck = CheckDependencies()
    If (dependenciesCheck != "OK")
        If (GetState() != DisabledState)
            GoToState(DisabledState)
            InstalledDetailedVersion = ""
            InstalledEdition = ""
            RealHandcuffs:DebugWrapper.Notification("Disabled Real Handcuffs: " + dependenciesCheck)
        EndIf
        McmInteraction.FullVersionAndEdition = "Real Handcuffs " + DetailedVersion + " " + Library.Settings.Edition + " Edition<br><b>Disabled</b>: " + dependenciesCheck
        InstallerRunning = false
        Float elapsedTime = Utility.GetCurrentRealTime() - installerStartTime
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Installer worked for " + elapsedTime + " seconds.", Library.Settings)
        EndIf
        Return
    EndIf
    RegisterForCustomEvent(Library.Settings, "OnSettingsChanged")
    Int installerIterations = 0
    While (true)
        String newStateVersion = StateVersion
        String newDetailedVersion = DetailedVersion
        String newEdition = Library.Settings.Edition
        If (Library.Settings.Disabled)
            If (GetState() != DisabledState)
                McmInteraction.FullVersionAndEdition = "Real Handcuffs installer is currently disabling the mod. Please close MCM and wait for installer to finish."
                GoToState(DisabledState)
                InstalledDetailedVersion = ""
                InstalledEdition = ""
                RealHandcuffs:Log.Info("Disabled RealHandcuffs.", Library.Settings)
                If (Library.Settings.LogLevelNotificationArea > 0)
                    RealHandcuffs:DebugWrapper.Notification("Disabled RealHandcuffs.")
                EndIf
            EndIf
            If (Library.Settings.Disabled)
                If (Library.Settings.Edition == "Standard")
                    McmInteraction.FullVersionAndEdition = "Real Handcuffs " + DetailedVersion + " " + Library.Settings.Edition + " Edition<br><b>Disabled</b> by Debug Settings<br>Note that leveled list changes are still in effect because they are part of RealHandcuffs.esp. To revert these changes, uninstall Real Handcuffs or install Lite Edition."
                Else
                    McmInteraction.FullVersionAndEdition = "Real Handcuffs " + DetailedVersion + " " + Library.Settings.Edition + " Edition<br><b>Disabled</b> by Debug Settings<br>"
                EndIf
                InstallerRunning = false
                If (Library.Settings.InfoLoggingEnabled)
                    Float elapsedTime = Utility.GetCurrentRealTime() - installerStartTime
                    RealHandcuffs:Log.Info("Installer worked for " + elapsedTime + " seconds.", Library.Settings)
                EndIf
                Return
            EndIf
        ElseIf (GetState() != newStateVersion || InstalledDetailedVersion != newDetailedVersion)
            Bool upgrade = (GetState() != "" && GetState() != DisabledState)
            If (upgrade)
                McmInteraction.FullVersionAndEdition = "Real Handcuffs installer is currently upgrading from " + InstalledDetailedVersion + " to " + newDetailedVersion  + ". Please close MCM and wait for installer to finish."
            Else
                McmInteraction.FullVersionAndEdition = "Real Handcuffs installer is currently installing " + newDetailedVersion + ". Please close MCM and wait for installer to finish."
            EndIf
            If (upgrade && GetState() != UpdatePendingState)
                GoToState(UpdatePendingState)
            EndIf
            GoToState(newStateVersion)
            InstalledDetailedVersion = newDetailedVersion
            InstalledEdition = newEdition
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Installed " + InstalledDetailedVersion + " " + InstalledEdition + " Edition.", Library.Settings)
            EndIf
            If (Library.Settings.LogLevelNotificationArea > 0)
                If (upgrade)
                    RealHandcuffs:DebugWrapper.Notification("Upgraded RealHandcuffs to " + InstalledDetailedVersion + " " + InstalledEdition + " Edition.")
                Else
                    RealHandcuffs:DebugWrapper.Notification("Installed RealHandcuffs " + InstalledDetailedVersion + " " + InstalledEdition + " Edition.")
                EndIf
            EndIf
        ElseIf (InstalledEdition != newEdition || installerIterations == 0)
            McmInteraction.FullVersionAndEdition = "Real Handcuffs installer is currently performing maintainance. Please close MCM and wait for installer to finish."
            DoMaintenance()
            String oldEdition = InstalledEdition
            InstalledEdition = newEdition
            If (oldEdition != newEdition)
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Switched to " + InstalledEdition + " Edition.", Library.Settings)
                EndIf
                If (Library.Settings.LogLevelNotificationArea > 0)
                    RealHandcuffs:DebugWrapper.Notification("Switched to RealHandcuffs " + InstalledEdition + " Edition.")
                EndIf
            EndIf
        Else
            McmInteraction.FullVersionAndEdition = "Real Handcuffs " + InstalledDetailedVersion + " " + InstalledEdition + " Edition"
            InstallerRunning = false
            Float elapsedTime = Utility.GetCurrentRealTime() - installerStartTime
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Installer worked for " + elapsedTime + " seconds.", Library.Settings)
            EndIf
            Return
        EndIf
        installerIterations += 1
    EndWhile
EndFunction

;
; Remove event used in state V1 to track progress of MQ102 quest.
;
Event Quest.OnStageSet(Quest q, int auiStageID, int auiItemID)
    UnregisterForRemoteEvent(q, "OnStageSet")
EndEvent

;
; Remove event used in state V1 to track progress of MQ102 quest.
;
Event Quest.OnQuestShutdown(Quest q)
    UnregisterForRemoteEvent(q, "OnQuestShutdown")
EndEvent

;
; Function to do maintenance for the mod without reinstalling it.
;
Function DoMaintenance()
    ; nothing to do in empty state
EndFunction

;
; "Update pending" state, all updates switch to this state before switching to the target state.
;
State UpdatePending
    Event OnBeginState(String previousState)
        RealHandcuffs:Log.Info("Entered installer state UpdatePending.", Library.Settings)
    EndEvent
    Event OnEndState(String nextState)
        RealHandcuffs:Log.Info("Left installer state UpdatePending.", Library.Settings)
    EndEvent
EndState

;
; "Disabled" state, used if the mod is disabled in debug settings.
;
State Disabled
    Event OnBeginState(String previousState)
        RealHandcuffs:Log.Info("Entered installer state Disabled.", Library.Settings)
    EndEvent
    Event OnEndState(String nextState)
        RealHandcuffs:Log.Info("Left installer state Disabled.", Library.Settings)
    EndEvent
EndState

;
; State for internal version V1.
;
State V1
    Event OnBeginState(String previousState)
        Bool upgrade = (previousState == "UpdatePending")
        ; do some general initialization
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Entering installer state V1 (upgrade=" + upgrade + ").", Library.Settings)
        EndIf
        Library.ClearInteractionType()
        Bool earlyGameOver = MQ102.IsCompleted() || MQ102.GetCurrentStageID() >= 6;
        If (earlyGameOver)
            RealHandcuffs:HandcuffsConverter converter = (Self as ScriptObject) as RealHandcuffs:HandcuffsConverter
            converter.Initialize(upgrade)
        Else
            RealHandcuffs:Log.Info("Detected early game, skipping part of initialization.", Library.Settings)
            RegisterForRemoteEvent(MQ102, "OnStageSet")
            RegisterForRemoteEvent(MQ102, "OnQuestShutdown")
        EndIf
        LeveledListInjector.UpdateLeveledLists()
        ; maintain or create player token
        Actor player = Game.GetPlayer()
        RealHandcuffs:ActorToken token = Library.TryGetActorToken(player)
        If (earlyGameOver && (token == None || !token.CheckConsistency(player)))
            token = Library.GetOrCreateActorToken(player)
            If (!token.CheckConsistency(player))
                token = None
                RealHandcuffs:Log.Error("Unable to create player token.", Library.Settings)
            EndIf
        EndIf
        If (token != None)
            token.RefreshOnGameLoad(true)
            token.RefreshEventRegistrations()
        EndIf
        ; maintain npc tokens
        RefCollectionAlias restrained = Library.RestrainedNpcs
        Int index = 0
        While (index < restrained.GetCount())
            Actor restrainedNpc = restrained.GetAt(index) as Actor
            token = Library.TryGetActorToken(restrainedNpc)
            If (token != None && !token.CheckConsistency(restrainedNpc))
                token = Library.TryGetActorToken(restrainedNpc)
            EndIf
            If (token == None || restrainedNpc.IsDead() || token.Restraints == None || token.Restraints.Length == 0) ; fallback code, not expected
                String reason
                If (token == None)
                    reason = "no token"
                ElseIf (restrainedNpc.IsDead())
                    reason = "dead"
                Else
                    reason = "no restraints"
                EndIf
                restrained.RemoveRef(restrainedNpc)
                RealHandcuffs:Log.Warning("Removed from restrained NPCs [" + restrained.GetCount() + "]: " + RealHandcuffs:Log.FormIdAsString(restrainedNpc) + " " + restrainedNpc.GetDisplayName() + " (" + reason + ")", Library.Settings)
            Else
                token.RefreshOnGameLoad(true)
                token.RefreshEventRegistrations()
                index += 1
            EndIf
        EndWhile
        ; add perks
        If (!player.HasPerk(ChangePose))
            player.AddPerk(ChangePose)
        EndIf
        If (!player.HasPerk(InteractWithKnockedOut))
            player.AddPerk(InteractWithKnockedOut)
        EndIf
        ; run third party compatibility plugin installers
        If (Library.SoftDependencies.JBCompatibilityActive)
            Library.SoftDependencies.JBCompatibilityMainQuest.CallFunction("RunInstallerTasks", new Var[0])
        EndIf
        ; remove dead actors from bleedout ref collection alias
        index = BleedoutActors.GetCount() - 1
        While (index > 0)
            Actor bleedoutNpc = BleedoutActors.GetAt(index) as Actor
            If (bleedoutNpc != None &&  bleedoutNpc.IsDead())
                bleedoutNpc.RemoveSpell(BleedoutSpell)
            EndIf
            index -= 1
        EndWhile
        ; remove dead actors from knocked-out npc collection
        index = KnockoutActors.GetCount() - 1
        While (index > 0 )
            Actor knockoutNpc = KnockoutActors.GetAt(index) as Actor
            If (knockoutNpc != None && knockoutNpc.IsDead())
                Library.SoftDependencies.WakeKnockedOutActor(knockoutNpc)
            EndIf
            index -= 1
        EndWhile
        ; remove dead actors from prisoner mat npc collection
        index = PrisonerMatActors.GetCount() - 1
        While (index > 0 )
            Actor prisonerNpc = PrisonerMatActors.GetAt(index) as Actor
            If (prisonerNpc != None && prisonerNpc.IsDead())
                PrisonerMatActors.RemoveRef(prisonerNpc)
            EndIf
            index -= 1
        EndWhile
        ; remove orphaned temporary wait markers
        index = TemporaryWaitMarkers.GetCount() - 1
        While (index > 0)
            RealHandcuffs:TemporaryWaitMarker waitMarker = TemporaryWaitMarkers.GetAt(index) as RealHandcuffs:TemporaryWaitMarker
            If (waitMarker != None)
                Actor registeredNpc = waitMarker.GetRegisteredActor()
                If (registeredNpc == None || registeredNpc.IsDead())
                    waitMarker.Unregister(registeredNpc) ; will trigger delete
                EndIf
            EndIf
            index -= 1
        EndWhile
        ; done
        RealHandcuffs:Log.Info("Entered state V1.", Library.Settings)
    EndEvent
    
    Event Quest.OnStageSet(Quest q, int auiStageID, int auiItemID)
        If (q == MQ102 && auiStageID >= 6)
            UnregisterForRemoteEvent(q, "OnStageSet")
            UnregisterForRemoteEvent(q, "OnQuestShutdown")
            RealHandcuffs:Log.Info("MQ102 stage " + auiStageID + " set, running installer tasks.", Library.Settings)
            RunInstallerTasks()
        EndIf
    EndEvent
    
    Event Quest.OnQuestShutdown(Quest q)
        If (q == MQ102)
            UnregisterForRemoteEvent(q, "OnStageSet")
            UnregisterForRemoteEvent(q, "OnQuestShutdown")
            RealHandcuffs:Log.Info("MQ102 shut down, running installer tasks.", Library.Settings)
            RunInstallerTasks()
        EndIf
    EndEvent

    Function DoMaintenance()
        RealHandcuffs:Log.Info("Maintaining installer state V1.", Library.Settings)
        ; do some general initialization
        Library.ClearInteractionType()      
        Bool earlyGameOver = MQ102.IsCompleted() || MQ102.GetCurrentStageID() >= 6
        If (earlyGameOver)
            RealHandcuffs:HandcuffsConverter converter = (Self as ScriptObject) as RealHandcuffs:HandcuffsConverter
            If (!converter.IsInitialized)
                converter.Initialize(false)
            EndIf
        Else
            RealHandcuffs:Log.Info("Detected early game, skipping part of maintenance.", Library.Settings)
            RegisterForRemoteEvent(MQ102, "OnStageSet")
            RegisterForRemoteEvent(MQ102, "OnQuestShutdown")
        EndIf
        ; maintain or create player token
        Actor player = Game.GetPlayer()
        RealHandcuffs:ActorToken token = Library.TryGetActorToken(player)
        If (earlyGameOver && (token == None || !token.CheckConsistency(player)))
            token = Library.GetOrCreateActorToken(player)
            If (!token.CheckConsistency(player))
                token = None
                RealHandcuffs:Log.Error("Unable to create player token.", Library.Settings)
            EndIf
            UnregisterForRemoteEvent(MQ102, "OnStageSet")
            UnregisterForRemoteEvent(MQ102, "OnQuestShutdown")
        EndIf
        If (token != None)
            token.RefreshOnGameLoad(false)
        EndIf
        ; maintain npc tokens
        RefCollectionAlias restrained = Library.RestrainedNpcs
        Int index = 0
        While (index < restrained.GetCount())
            Actor restrainedNpc = restrained.GetAt(index) as Actor
            token = Library.TryGetActorToken(restrainedNpc)
            If (token != None && !token.CheckConsistency(restrainedNpc))
                token = Library.TryGetActorToken(restrainedNpc)
            EndIf
            If (token == None || restrainedNpc.IsDead() || token.Restraints == None || token.Restraints.Length == 0) ; fallback code, not expected
                String reason
                If (token == None)
                    reason = "no token"
                ElseIf (restrainedNpc.IsDead())
                    reason = "dead"
                Else
                    reason = "no restraints"
                EndIf
                restrained.RemoveRef(restrainedNpc)
                RealHandcuffs:Log.Warning("Removed from restrained NPCs [" + restrained.GetCount() + "]: " + RealHandcuffs:Log.FormIdAsString(restrainedNpc) + " " + restrainedNpc.GetDisplayName() + " (" + reason + ")", Library.Settings)
            Else
                token.RefreshOnGameLoad(false)
                index += 1
            EndIf
        EndWhile
        ; run third party compatibility plugin installers
        If (Library.SoftDependencies.JBCompatibilityActive)
            Library.SoftDependencies.JBCompatibilityMainQuest.CallFunction("RunInstallerTasks", new Var[0])
        EndIf
        ; remove dead actors from bleedout ref collection alias
        index = BleedoutActors.GetCount() - 1
        While (index > 0)
            Actor bleedoutNpc = BleedoutActors.GetAt(index) as Actor
            If (bleedoutNpc != None &&  bleedoutNpc.IsDead())
                bleedoutNpc.RemoveSpell(BleedoutSpell)
            EndIf
            index -= 1
        EndWhile
        ; remove dead actors from knocked-out npc collection
        index = KnockoutActors.GetCount() - 1
        While (index > 0 )
            Actor knockoutNpc = KnockoutActors.GetAt(index) as Actor
            If (knockoutNpc != None && knockoutNpc.IsDead())
                Library.SoftDependencies.WakeKnockedOutActor(knockoutNpc)
            EndIf
            index -= 1
        EndWhile
        ; remove dead actors from prisoner mat npc collection
        index = PrisonerMatActors.GetCount() - 1
        While (index > 0 )
            Actor prisonerNpc = PrisonerMatActors.GetAt(index) as Actor
            If (prisonerNpc != None && prisonerNpc.IsDead())
                PrisonerMatActors.RemoveRef(prisonerNpc)
            EndIf
            index -= 1
        EndWhile
        ; remove orphaned temporary wait markers
        index = TemporaryWaitMarkers.GetCount() - 1
        While (index > 0)
            RealHandcuffs:TemporaryWaitMarker waitMarker = TemporaryWaitMarkers.GetAt(index) as RealHandcuffs:TemporaryWaitMarker
            If (waitMarker != None)
                Actor registeredNpc = waitMarker.GetRegisteredActor()
                If (registeredNpc == None || registeredNpc.IsDead())
                    waitMarker.Unregister(registeredNpc) ; will trigger delete
                EndIf
            EndIf
            index -= 1
        EndWhile
        ; done
    EndFunction

    Event OnEndState(String nextState)
        Bool upgrade = (nextState == "UpdatePending")
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Leaving installer state V1 (upgrade=" + upgrade + ").", Library.Settings)
        EndIf
        ; do some general cleanup
        Library.ClearInteractionType()  
        Library.RestoreCommandModeActivatePackage()
        RealHandcuffs:HandcuffsConverter converter = (Self as ScriptObject) as RealHandcuffs:HandcuffsConverter
        converter.Uninitialize(upgrade)
        Actor player = Game.GetPlayer()
        If (!upgrade)
            ; suspend player token if this is not an upgrade
            RealHandcuffs:ActorToken token = Library.TryGetActorToken(player)
            If (token != None)
                token.SuspendEffectsAndAnimations()
            EndIf
            ; suspend npc tokens if this is not an upgrade
            RefCollectionAlias restrained = Library.RestrainedNpcs
            Int index = 0
            While (index < restrained.GetCount())
                Actor restrainedNpc = restrained.GetAt(index) as Actor
                token = Library.TryGetActorToken(restrainedNpc)
                If (token != None)
                    token.SuspendEffectsAndAnimations()
                EndIf
                index += 1
            EndWhile
            ; remove all actors from bleedout ref collection alias if this is not an upgrade
            index = BleedoutActors.GetCount() - 1
            While (index > 0)
                Actor bleedoutNpc = BleedoutActors.GetAt(index) as Actor
                If (bleedoutNpc != None)
                    bleedoutNpc.RemoveSpell(BleedoutSpell)
                EndIf
                index -= 1
            EndWhile
            ; remove all actors from knocked-out npc collection if this is not an upgrade
            index = KnockoutActors.GetCount() - 1
            While (index > 0 )
                Actor knockoutNpc = KnockoutActors.GetAt(index) as Actor
                If (knockoutNpc != None)
                    Library.SoftDependencies.WakeKnockedOutActor(knockoutNpc)
                EndIf
                index -= 1
            EndWhile
            ; remove all actors from prisoner mat npc collection if this is not an upgrade
            index = PrisonerMatActors.GetCount() - 1
            While (index > 0 )
                Actor prisonerNpc = PrisonerMatActors.GetAt(index) as Actor
                If (prisonerNpc != None)
                    PrisonerMatActors.RemoveRef(prisonerNpc)
                EndIf
                index -= 1
            EndWhile
            ; remove all temporary wait markers if this is not an upgrade
            index = TemporaryWaitMarkers.GetCount() - 1
            While (index > 0)
                RealHandcuffs:TemporaryWaitMarker waitMarker = TemporaryWaitMarkers.GetAt(index) as RealHandcuffs:TemporaryWaitMarker
                If (waitMarker != None)
                    Actor registeredNpc = waitMarker.GetRegisteredActor()
                    waitMarker.Unregister(registeredNpc) ; will trigger delete
                EndIf
                index -= 1
            EndWhile
        EndIf 
        ; remove perks
        If (player.HasPerk(ChangePose))
            player.RemovePerk(ChangePose)
        EndIf
        If (player.HasPerk(InteractWithKnockedOut))
            player.RemovePerk(InteractWithKnockedOut)
        EndIf
        ; remove the obsolete perk, necessary to support old v0.1 savegames
        If (player.HasPerk(RH_Obsolete_ObservePlayerCrosshair))
            player.RemovePerk(RH_Obsolete_ObservePlayerCrosshair)
            RealHandcuffs:Log.Info("Removed obsolete ObservePlayerCrosshair perk from player.", Library.Settings)
        EndIf
        ; unregister for quest events, will usually do nothing
        UnregisterForRemoteEvent(MQ102, "OnStageSet")
        UnregisterForRemoteEvent(MQ102, "OnQuestShutdown")
        ; done
        RealHandcuffs:Log.Info("Left installer state V1.", Library.Settings)
    EndEvent
EndState