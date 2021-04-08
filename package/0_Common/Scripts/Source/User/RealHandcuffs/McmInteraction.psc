;
; Script containing additional logic for interaction with the MCM UI that does not belong into Settings.psc.
;
Scriptname RealHandcuffs:McmInteraction extends Quest

RealHandcuffs:Library Property Library Auto Const Mandatory
FormList Property CraftedRestraints Auto Const Mandatory

;
; Group containing strings shown in main page.
;
Group MainPage
    ; currently installed version string, or message that installer is working; set by Installer.psc
    String Property FullVersionAndEdition Auto
EndGroup

;
; Group containing additional properties for MCM pages.
;
Group McmConditions
    ; set by OnMenuOpenCloseEvent
    Bool Property IsStandardEdition Auto
    Bool Property IsLiteEdition Auto
EndGroup

;
; Group containing strings shown in Debug Settings page.
;
Group DebugSettingsPage
    ; set by OnMenuOpenCloseEvent
    String Property PlayerName Auto
    String Property PlayerWornRestraints Auto
    Bool Property ShowTargetedNpc Auto
    Actor Property TargetedNpc Auto
    String Property TargetedNpcName Auto
    String Property TargetedNpcWornRestraints Auto
    String Property TargetedNpcCurrentPackage Auto
    String Property TargetedNpcActorBase Auto
    Bool Property ShowTargetedObject Auto
    String Property TargetedObjectName Auto
    String Property TargetedObjectInfo Auto
EndGroup

;
; Register for events sent by MCM.
;
Function RegisterForMcmEvents()
    ; OnMCMMenuOpen does not seem to work, so use OnMenuOpenCloseEvent instead
    RegisterForMenuOpenCloseEvent("PauseMenu")
EndFunction

;
; Unregister from events sent by MCM.
;
Function UnregisterForMcmEvents()
    UnregisterForMenuOpenCloseEvent("PauseMenu")    
EndFunction

;
; Handler for menu open/close event, will build strings for MCM.
;
Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    If (asMenuName == "PauseMenu" && abOpening)
        IsStandardEdition = Library.Settings.Edition == "Standard"
        IsLiteEdition = !IsStandardEdition
        Actor player = Game.GetPlayer()
        PlayerName = "Player: " + RealHandcuffs:Log.FormIdAsString(player) + " " + player.GetDisplayName()
        If (Library.IsFemale(player))
            PlayerName += " (female)"
        Else
            PlayerName += " (male)"
        EndIf
        PlayerWornRestraints = BuildWornRestraintsList(Game.GetPlayer())
        Actor targetActor = LL_FourPlay.LastCrossHairRef() as Actor
        If (targetActor == None || !targetActor.IsBoundGameObjectAvailable() || targetActor.IsDead() || Library.SoftDependencies.IsArmorRack(targetActor))
            ShowTargetedNpc = false
            TargetedNpc = None
            TargetedNpcName = ""
            TargetedNpcWornRestraints = ""
            TargetedNpcCurrentPackage = ""
        Else
            ShowTargetedNpc = true
            TargetedNpc = targetActor
            TargetedNpcName = "Targeted NPC: " + RealHandcuffs:Log.FormIdAsString(targetActor) + " " + targetActor.GetDisplayName()
            If (Library.IsFemale(targetActor))
                TargetedNpcName += " (female)"
            Else
                TargetedNpcName += " (male)"
            EndIf
            TargetedNpcActorBase = BuildActorBase(targetActor)
            TargetedNpcWornRestraints = BuildWornRestraintsList(targetActor)
            TargetedNpcCurrentPackage = BuildCurrentPackage(targetActor)
        EndIf
        ObjectReference targetObject = LL_FourPlay.LastCrossHairRef()
        If (targetObject == None || targetObject == targetActor)
            ShowTargetedObject = false
            TargetedObjectName = ""
            TargetedObjectInfo = ""
        Else
            ShowTargetedObject = true
            TargetedObjectName = "Targeted Object: " + RealHandcuffs:Log.FormIdAsString(targetObject) + " " + targetObject.GetDisplayName()
            Form baseObject = targetObject.GetBaseObject()
            TargetedObjectInfo = "Base: " + RealHandcuffs:Log.FormIdAsString(baseObject) + " " + baseObject.GetName()
            ObjectMod[] mods = targetObject.GetAllMods()
            If (mods.Length > 0)
                TargetedObjectInfo += ", Mods: "
                Int index = 0
                While (index < mods.Length)
                    If (index > 0)
                        TargetedObjectInfo += ", "
                    EndIf
                    ObjectMod mod = mods[index]
                    TargetedObjectInfo += RealHandcuffs:Log.FormIdAsString(mod) + " " + mod.GetName()
                    index += 1
                EndWhile
            EndIf
        EndIf
        MCM.RefreshMenu()
    EndIf
EndEvent

;
; Build a string suffix containing the plugin name.
;
String Function BuildPluginNameSuffix(Form item)
    Int formId = item.GetFormID()
    Int modIndex = formId / 0x01000000
    If (formId < 0)
        modIndex = (255 + modIndex)
    EndIf
    If (modIndex != 255)
        Game:PluginInfo[] plugins = Game.GetInstalledPlugins()
        Int index = 0
        While (index < plugins.Length)
            If (plugins[index].Index == modIndex)
                Return " [" + plugins[index].Name + "]"
            EndIf
            index += 1
        EndWhile
    EndIf
    Return ""
EndFunction

;
; Build a string showing the actor base of an actor.
;
String Function BuildActorBase(Actor target)
    ActorBase targetActorBase = target.GetActorBase()
    Return "Actor Base: " + RealHandcuffs:Log.FormIdAsString(targetActorBase) + BuildPluginNameSuffix(targetActorBase)
EndFunction

;
; Build a string listing the restraints worn by an actor.
;
String Function BuildWornRestraintsList(Actor target)
    RealHandcuffs:RestraintBase[] restraints = Library.GetWornRestraints(target)
    If (restraints.Length == 0)
        Return "Wearing: (none)"
    EndIf
    String commaSeparatedList = "Wearing: "
    Int index = 0
    While (index < restraints.Length)
        If (index > 0)
            commaSeparatedList += ", "
        EndIf
        If (restraints[index].IsBoundGameObjectAvailable())
            commaSeparatedList += restraints[index].GetDisplayName()
            If (restraints[index].HasKeyword(Library.Resources.TimedLock))
                commaSeparatedList += " (remaining: "
                Float remainingTime = restraints[index].GetRemainingTimedLockTimer()
                Int remainingTimeWhole = Math.Floor(remainingTime)
                Int remainingTimeFraction = Math.Floor((remainingTime - remainingTimeWhole) * 100)
                commaSeparatedList += remainingTimeWhole + "." + remainingTimeFraction + " h)"
            EndIf
        Else
            commaSeparatedList += "(missing restraint)"
        EndIf
        index += 1
    EndWhile
    Return commaSeparatedList
EndFunction

;
; Build a string showing the current package of an actor.
;
String Function BuildCurrentPackage(Actor target)
    Package currentPackage = target.GetCurrentPackage()
    RealHandcuffs:BoundHandsPackage boundHandsPackage = currentPackage as RealHandcuffs:BoundHandsPackage
    String packageName
    If (boundHandsPackage != None)
        packageName = boundHandsPackage.Name
    Else
        packageName = currentPackage.GetName()
    EndIf
    Scene currentScene = target.GetCurrentScene()
    If (currentScene != None)
        packageName += ", Scene: " + RealHandcuffs:Log.FormIdAsString(currentScene) + " " + currentScene.GetName()
    EndIf
    Return "Package: " + RealHandcuffs:Log.FormIdAsString(currentPackage) + BuildPluginNameSuffix(currentPackage) + " " + packageName
EndFunction

;
; Free the player from all restraints.
;
Function FreePlayer()
    If (Library.Settings.SettingsUnlocked)
        CancelTimer(FreePlayer)
        StartTimer(0.1, FreePlayer)
    EndIf
EndFunction

;
; Free a npc from all restraints.
;
Function FreeTargetedNpc()
    If (Library.Settings.SettingsUnlocked)
        CancelTimer(FreeTargetedNpc)
        StartTimer(0.1, FreeTargetedNpc)
    EndIf
EndFunction

;
; Reset the AI of a npc.
;
Function ResetTargetedNpcAI()
    If (Library.Settings.SettingsUnlocked)
        CancelTimer(FreeTargetedNpc)
        StartTimer(0.1, ResetTargetedNpcAI)
    EndIf
EndFunction

;
; Equip restraints on the player.
;
Function EquipPlayer()
    If (Library.Settings.SettingsUnlocked)
        CancelTimer(EquipPlayer)
        CancelTimer(EquipTargetedNpc)
        StartTimer(0.1, EquipPlayer)
    EndIf
EndFunction

;
; Equip restraints on the targeted player.
;
Function EquipTargetedNpc()
    If (Library.Settings.SettingsUnlocked)
        CancelTimer(EquipPlayer)
        CancelTimer(EquipTargetedNpc)
        StartTimer(0.1, EquipTargetedNpc)
    EndIf
EndFunction

;
; Event used to prevent items from getting lost in temporary container when equipping player or NPC.
;
Event ObjectReference.OnItemAdded(ObjectReference sender, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    If (akSourceContainer == Game.GetPlayer())
        sender.RemoveItem(akBaseItem, aiItemCount, true, akSourceContainer)
    EndIf
EndEvent


;
; Group for timers.
;
Group Timers
    Int Property FreePlayer = 1 AutoReadOnly
    Int Property FreeTargetedNpc = 2 AutoReadOnly
    Int Property ResetTargetedNpcAI = 3 AutoReadOnly
    Int Property EquipPlayer = 4 AutoReadOnly
    Int Property EquipTargetedNpc = 5 AutoReadOnly
EndGroup

;
; Timer event.
;
Event OnTimer(Int aiTimerID)
    If (aiTimerID == FreePlayer || aiTimerID == FreeTargetedNpc)
        Actor target
        If (aiTimerID == FreePlayer)
            target = Game.GetPlayer()
        Else
            target = TargetedNpc
        EndIf
        RealHandcuffs:RestraintBase[] restraints = Library.GetWornRestraints(target)
        Int index = restraints.Length - 1
        While (index >= 0)
            restraints[index].ForceUnequip()
            index -= 1
        EndWhile
        RealHandcuffs:ActorToken token = Library.TryGetActorToken(target) as RealHandcuffs:NpcToken
        token.RefreshEffectsAndAnimations(True, None) ; just to be on the safe side, e.g. if restraints are missing
    ElseIf (aiTimerID == ResetTargetedNpcAI)
        Actor target = TargetedNpc
        target.EnableAI(true, false)
        RealHandcuffs:NpcToken token = Library.TryGetActorToken(target) as RealHandcuffs:NpcToken
        If (token != None)
            token.RevertCurrentCommandChanges()
        EndIf
        Library.StartDummyScene(target)
    ElseIf (aiTimerID == EquipPlayer || aiTimerID == EquipTargetedNpc)
        ObjectReference tempContainer = Game.GetPlayer().PlaceAtMe(Library.Resources.InvisibleContainer, 1, false, true, true)
        If (aiTimerID == EquipPlayer)
            tempContainer.SetLinkedRef(Game.GetPlayer(), Library.Resources.LinkedActorToEquipCraftedItem)
        Else
            tempContainer.SetLinkedRef(TargetedNpc, Library.Resources.LinkedActorToEquipCraftedItem)
        EndIf
        Int index = 0
        While (index < CraftedRestraints.GetSize())
            tempContainer.AddItem(CraftedRestraints.GetAt(index), 1, true)
            index += 1
        EndWhile
        RegisterForRemoteEvent(tempContainer, "OnItemAdded")
        AddInventoryEventFilter(None)
        tempContainer.Activate(Game.GetPlayer(), false)
        Utility.Wait(0.5) ; TODO use event instead
        RemoveAllInventoryEventFilters()
        UnregisterForRemoteEvent(tempContainer, "OnItemAdded")
        tempContainer.SetLinkedRef(None, Library.Resources.LinkedActorToEquipCraftedItem)
        tempContainer.Delete()
    EndIf
EndEvent