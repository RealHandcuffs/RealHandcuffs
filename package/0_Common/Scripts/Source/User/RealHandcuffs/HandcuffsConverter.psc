;
; A script that converts handcuffs and other restraints in the player's inverntory.
;
Scriptname RealHandcuffs:HandcuffsConverter extends ReferenceAlias

RealHandcuffs:Library Property Library Auto Const Mandatory
Armor Property Handcuffs Auto Const Mandatory
Armor Property HandcuffsBroken Auto Const Mandatory
Armor Property HandcuffsHinged Auto Const Mandatory
Armor Property HandcuffsHingedBroken Auto Const Mandatory
Armor Property ShockCollar Auto Const Mandatory
GlobalVariable Property ChanceNoneKeys Auto Const Mandatory
Keyword Property Processed Auto Const Mandatory
Keyword Property ApFirmware Auto Const Mandatory
Keyword Property ApLock Auto Const Mandatory
Keyword Property ApShockModule Auto Const Mandatory
Keyword Property ApTime Auto Const Mandatory
Keyword Property ApConvert Auto Const Mandatory
Formlist Property do_ModMenuSlotKeywordList Auto Const Mandatory
Message Property MsgInstallationPlaythroughInProgress Auto Const Mandatory
MiscObject Property HandcuffsKey Auto Const Mandatory
MiscObject Property HighSecurityHandcuffsKey Auto Const Mandatory
MiscObject Property LegacyHandcuffs Auto Const Mandatory
ObjectMod Property ModConvertToStandardHandcuffs Auto Const Mandatory
ObjectMod Property ModConvertToHingedHandcuffs Auto Const Mandatory
ObjectMod Property ModRemoveChain Auto Const Mandatory
ObjectMod Property ModRemoveHinges Auto Const Mandatory
ObjectMod Property ModRepairChain Auto Const Mandatory
ObjectMod Property ModRepairHinges Auto Const Mandatory
ObjectMod Property ModStandardLock Auto Const Mandatory
ObjectMod Property ModHighSecurityLock Auto Const Mandatory
ObjectMod Property ModThrobbingShockModule Auto Const Mandatory
ObjectMod Property ModMarkThreeFirmware Auto Const Mandatory
Weapon Property RemoteTrigger Auto Const Mandatory
WorkshopScript Property SanctuaryWorkshopRef Auto Const Mandatory

Int Property PercentHinged = 20 AutoReadOnly
Int Property PercentHighSecurity = 20 AutoReadOnly
Int Property PercentThrobbing = 20 AutoReadOnly
Int Property PercentMarkThree = 20 AutoReadOnly

ObjectReference _lastUsedWorkbench

;
; Initialize the script after installing or upgrading the mod.
;
Function Initialize(Bool upgrade)
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Initializing HandcuffsConverter (upgrade=" + upgrade + ").", Library.Settings)
    EndIf
    AddInventoryEventFilter(LegacyHandcuffs)
    Actor player = Game.GetPlayer()
    If (!upgrade)
        If (player.GetItemCount(LegacyHandcuffs) > 0 && Library.Settings.AutoConvertHandcuffs)
            ConvertLegacyHandcuffsInsideContainer(player)
        EndIf
        If (SanctuaryWorkshopRef.OwnedByPlayer)
            If (player.GetItemCount(HandcuffsKey) == 0)
                RealHandcuffs:Log.Info("Adding handcuffs key to player.", Library.Settings)
                MsgInstallationPlaythroughInProgress.Show()
                Player.AddItem(HandcuffsKey, 1, false)
                Player.AddItem(Library.Resources.RobCoConnect, 1, false)
            EndIf
        Else
            ObjectReference sanctuaryWorkshopContainer = SanctuaryWorkshopRef.GetContainer()
            If (SanctuaryWorkshopRef.GetItemCount(HandcuffsKey) == 0)
                RealHandcuffs:Log.Info("Adding startup package to sanctuary workshop container.", Library.Settings)
                ObjectReference handcuffsRef = Game.GetPlayer().PlaceAtMe(Handcuffs, 1, false, true, false)
                handcuffsRef.EnableNoWait()
                sanctuaryWorkshopContainer.AddItem(handcuffsRef, 1, true)
                sanctuaryWorkshopContainer.AddItem(HandcuffsKey, 1, true)
                ObjectReference shockCollarRef = Game.GetPlayer().PlaceAtMe(ShockCollar, 1, false, true, false)
                shockCollarRef.EnableNoWait()
                sanctuaryWorkshopContainer.AddItem(shockCollarRef, 1, true)
                ObjectReference remoteTriggerRef = Game.GetPlayer().PlaceAtMe(RemoteTrigger, 1, false, true, false)
                remoteTriggerRef.EnableNoWait()
                sanctuaryWorkshopContainer.AddItem(remoteTriggerRef, 1, true)
                sanctuaryWorkshopContainer.AddItem(Library.Resources.RobCoConnect, 1, true)
            EndIf
        EndIf
        If (Library.SoftDependencies.DLCNukaWorldAvailable && player.GetItemCount(Library.SoftDependencies.ShockCollar) > 0 && Library.Settings.AutoConvertHandcuffs)
            ConvertLegacyShockCollarsInsideContainer(player)
        EndIf
    EndIf
    If (upgrade)
        do_ModMenuSlotKeywordList.RemoveAddedForm(ApFirmware)
        do_ModMenuSlotKeywordList.RemoveAddedForm(ApLock)
        do_ModMenuSlotKeywordList.RemoveAddedForm(ApShockModule)
        do_ModMenuSlotKeywordList.RemoveAddedForm(ApTime)
        do_ModMenuSlotKeywordList.RemoveAddedForm(ApConvert)
        RemoveAllInventoryEventFilters()
    EndIf
    do_ModMenuSlotKeywordList.AddForm(ApFirmware)
    do_ModMenuSlotKeywordList.AddForm(ApLock)
    do_ModMenuSlotKeywordList.AddForm(ApShockModule)
    do_ModMenuSlotKeywordList.AddForm(ApTime)
    do_ModMenuSlotKeywordList.AddForm(ApConvert)
    AddInventoryEventFilter(LegacyHandcuffs)
    If (Library.SoftDependencies.DLCNukaWorldAvailable)
        AddInventoryEventFilter(Library.SoftDependencies.ShockCollar)
    EndIf
    IsInitialized = true
EndFunction

;
; Uninitialize the script before uninstalling or upgrading the mod.
;
Function Uninitialize(Bool upgrade)
    IsInitialized = false
    RemoveAllInventoryEventFilters()
    do_ModMenuSlotKeywordList.RemoveAddedForm(ApConvert)
    do_ModMenuSlotKeywordList.RemoveAddedForm(ApFirmware)
    do_ModMenuSlotKeywordList.RemoveAddedForm(ApLock)
    do_ModMenuSlotKeywordList.RemoveAddedForm(ApTime)
    do_ModMenuSlotKeywordList.RemoveAddedForm(ApShockModule)
EndFunction

;
; Check if the script is initialized.
;
Bool Property IsInitialized Auto

;
; Event handler: Convert legacy handcuffs added to the player's inventory to real handcuffs.
;
Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    If (Library.Settings.AutoConvertHandcuffs)
        If (akBaseItem == LegacyHandcuffs)
            If (akItemReference != None)
                ConvertLegacyHandcuffs(akItemReference)
            Else
                ConvertLegacyHandcuffsInsideContainer(Game.GetPlayer())
            EndIf
        ElseIf (Library.SoftDependencies.DLCNukaWorldAvailable && akBaseItem == Library.SoftDependencies.ShockCollar)
            If (akItemReference != None)
                ConvertLegacyShockCollar(akItemReference)
            Else
                ConvertLegacyShockCollarsInsideContainer(Game.GetPlayer())
            EndIf
        EndIf
    EndIf
EndEvent

;
; Safe the last used workbench such that we can use it in OnPlayerModArmorWeapon.
;
Event OnPlayerUseWorkBench(ObjectReference akWorkBench)
    _lastUsedWorkbench = akWorkBench
EndEvent

;
; Event handler: Make sure necessary actions happen after creating restraing mod.
;
Event OnPlayerModArmorWeapon(Form akBaseObject, ObjectMod akModBaseObject)
    If (akModBaseObject == ModStandardLock)
        ; add key to inventory if player does not have it
        If (GetActorReference().GetItemCount(HandcuffsKey) == 0)
            GetActorReference().AddItem(HandcuffsKey, 1, false)
        EndIf
    ElseIf (akModBaseObject == ModHighSecurityLock)
        ; add key to inventory if player does not have it
        If (GetActorReference().GetItemCount(HighSecurityHandcuffsKey) == 0)
            GetActorReference().AddItem(HighSecurityHandcuffsKey, 1, false)
        EndIf
    ElseIf (Library.IsAddingKeyword(akModBaseObject, Library.Resources.ConvertTag))
        ; convert restraints in inventory of player
        Actor player = Game.GetPlayer()
        If (_lastUsedWorkbench != None)
            _lastUsedWorkbench.Activate(player, false)
        Else ; not expected
            player.MoveTo(player)
        EndIf
        ConvertRestraintsInContainer(player)
        If (_lastUsedWorkbench != None)
            Utility.Wait(0.6)
            _lastUsedWorkbench.Activate(player, false)
        EndIf
    EndIf
EndEvent

;
; Check if a restraint needs to be converted and convert it if necessary.
;
Bool Function ConvertRestraint(RealHandcuffs:RestraintBase item)
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Examining: " + RealHandcuffs:Log.FormIdAsString(item) + " " + item.GetDisplayName(), Library.Settings)
    EndIf
    If (item.HasKeyword(Library.Resources.ConvertTag))
        ObjectReference itemContainer = item.GetContainer()
        If (itemContainer != None)
            RealHandcuffs:Log.Info("Item is in container, switching to inventory conversion.", Library.Settings)
            Return ConvertRestraintsInContainer(itemContainer) > 0
        EndIf
        RealHandcuffs:RestraintBase convertedItem = CreateConvertedRestraint(item, item)
        If (convertedItem != None)
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Converted to: " + RealHandcuffs:Log.FormIdAsString(convertedItem) + " " + convertedItem.GetDisplayName(), Library.Settings)
            EndIf
            item.DisableNoWait()
            item.Delete()
            convertedItem.EnableNoWait()
            Return true
        Else
            RealHandcuffs:Log.Error("Unexpected situation (failed to convert item), deleting item.", Library.Settings)
        EndIf
    Else
        RealHandcuffs:Log.Info("Not converting item.", Library.Settings)
    EndIf
    Return false
EndFunction

;
; Scan inventory of container for restraints that need to be converted and convert them.
;
Int Function ConvertRestraintsInContainer(ObjectReference targetContainer)
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Converting restraints in inventory of " + RealHandcuffs:Log.FormIdAsString(targetContainer) + " " + targetContainer.GetDisplayName(), Library.Settings)
    EndIf
    Int convertedCount = 0
    Actor targetActor = targetContainer as Actor
    If (targetActor != None)
        RealHandcuffs:RestraintBase[] restraints = Library.GetWornRestraints(targetActor)
        If (restraints.Length > 0)
            RealHandcuffs:RestraintBase[] wornRestraints = new RealHandcuffs:RestraintBase[0] ; clone array as we will modify it inside the loop
            Int index = 0
            While (index < restraints.Length)
                wornRestraints.Add(restraints[index])
                index += 1
            EndWhile
            index = 0
            While (index < wornRestraints.Length)
                RealHandcuffs:RestraintBase wornRestraint = wornRestraints[index]
                If (wornRestraint.HasKeyword(Library.Resources.ConvertTag))
                    If (Library.Settings.InfoLoggingEnabled)
                        RealHandcuffs:Log.Info("Converting worn restraint: " + RealHandcuffs:Log.FormIdAsString(wornRestraint) + " " + wornRestraint.GetDisplayName(), Library.Settings)
                    EndIf
                    RealHandcuffs:RestraintBase convertedItem = CreateConvertedRestraint(wornRestraint, targetActor)
                    If (convertedItem != None)
                        If (Library.Settings.InfoLoggingEnabled)
                            RealHandcuffs:Log.Info("Converted to: " + RealHandcuffs:Log.FormIdAsString(convertedItem) + " " + convertedItem.GetDisplayName(), Library.Settings)
                        EndIf
                        convertedItem.EnableNoWait()
                        targetActor.AddItem(convertedItem, 1, true)
                        convertedItem.CopyParametersFrom(wornRestraint)
                        wornRestraint.ForceUnequip()
                        convertedItem.ForceEquip(true, false)
                        convertedCount += 1
                    Else
                        RealHandcuffs:Log.Error("Unexpected situation (failed to convert item), deleting item.", Library.Settings)
                        wornRestraint.ForceUnequip()
                    EndIf
                    targetActor.RemoveItem(wornRestraint, 1, true, None)
                EndIf
                index += 1
            EndWhile
        EndIf
    EndIf
    If (targetContainer.GetItemCount(Library.Resources.ConvertTag) > 0)
        ObjectReference tempContainer = targetContainer.PlaceAtMe(Library.Resources.InvisibleContainer, 1, false, true, true)
        ObjectReference moveBackToPlayerContainer = targetContainer.PlaceAtMe(Library.Resources.InvisibleContainer, 1, false, true, true)
        While (targetContainer.GetItemCount(Library.Resources.ConvertTag) > 0)
            RealHandcuffs:Log.Info("Removing items from targetContainer.", Library.Settings)
            targetContainer.RemoveItem(Library.Resources.ConvertTag, 1, false, tempContainer) ; bug: sometimes this seems to remove more than one item
            While (tempContainer.GetItemCount() > 0)
                ObjectReference item = tempContainer.DropObject(tempContainer.GetInventoryItems()[0], 1)
                If (item == None)
                    RealHandcuffs:Log.Error("Unexpected situation (no item found), aborting.", Library.Settings)
                    tempContainer.RemoveAllItems(moveBackToPlayerContainer, false) ; fallback code, not expected
                Else
                    If (Library.Settings.InfoLoggingEnabled)
                        RealHandcuffs:Log.Info("Examining: " + RealHandcuffs:Log.FormIdAsString(item) + " " + item.GetDisplayName(), Library.Settings)
                    EndIf
                    If (item.HasKeyword(Library.Resources.ConvertTag))
                        RealHandcuffs:RestraintBase convertedItem = CreateConvertedRestraint(item as RealHandcuffs:RestraintBase, item)
                        If (convertedItem != None)
                            If (Library.Settings.InfoLoggingEnabled)
                                RealHandcuffs:Log.Info("Converted to: " + RealHandcuffs:Log.FormIdAsString(convertedItem) + " " + convertedItem.GetDisplayName(), Library.Settings)
                            EndIf
                            convertedItem.EnableNoWait()
                            moveBackToPlayerContainer.AddItem(convertedItem, 1, true)
                            convertedCount += 1
                        Else
                            RealHandcuffs:Log.Error("Unexpected situation (failed to convert item), deleting item.", Library.Settings)
                        EndIf
                        item.DisableNoWait()
                        item.Delete()
                    Else
                        RealHandcuffs:Log.Info("Not converting item.", Library.Settings)
                        moveBackToPlayerContainer.AddItem(item, 1, true) ; fallback code, not expected
                    EndIf
                EndIf
            EndWhile
        EndWhile
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Done, moving " + moveBackToPlayerContainer.GetItemCount() + " items back to target.", Library.Settings)
        EndIf
        moveBackToPlayerContainer.RemoveAllItems(targetContainer, false)
        moveBackToPlayerContainer.Delete()
        tempContainer.Delete()
    EndIf
    Return convertedCount
EndFunction

;
; Apply the conversion mod to a restraint. The created restraint will be disabled.
;
RealHandcuffs:RestraintBase Function CreateConvertedRestraint(RealHandcuffs:RestraintBase restraint, ObjectReference placeAt)
    If (restraint != None)
        ObjectMod[] allMods = restraint.GetAllMods()
        If (allMods.Find(ModConvertToStandardHandcuffs) >= 0 || allMods.Find(ModRepairChain) >= 0)
            RealHandcuffs:Handcuffs createdHandcuffs = restraint.PlaceAtMe(Handcuffs, 1, false, true, false) as RealHandcuffs:Handcuffs
            createdHandcuffs.CloneModsFrom(restraint)
            Return createdHandcuffs as RealHandcuffs:RestraintBase
        ElseIf (allMods.Find(ModConvertToHingedHandcuffs) >= 0 || allMods.Find(ModRepairHinges) >= 0)
            RealHandcuffs:HandcuffsHinged createdHandcuffs = restraint.PlaceAtMe(HandcuffsHinged, 1, false, true, false) as RealHandcuffs:HandcuffsHinged
            createdHandcuffs.CloneModsFrom(restraint)
            Return createdHandcuffs as RealHandcuffs:RestraintBase
        ElseIf (allMods.Find(ModRemoveChain) >= 0)
            RealHandcuffs:HandcuffsBroken createdHandcuffs = restraint.PlaceAtMe(HandcuffsBroken, 1, false, true, false) as RealHandcuffs:HandcuffsBroken
            createdHandcuffs.CloneModsFrom(restraint)
            Return createdHandcuffs as RealHandcuffs:RestraintBase
        ElseIf (allMods.Find(ModRemoveHinges) >= 0)
            RealHandcuffs:HandcuffsBroken createdHandcuffs = restraint.PlaceAtMe(HandcuffsHingedBroken, 1, false, true, false) as RealHandcuffs:HandcuffsBroken
            createdHandcuffs.CloneModsFrom(restraint)
            Return createdHandcuffs as RealHandcuffs:RestraintBase
        EndIf
    EndIf
    Return None
EndFunction

;
; Convert a single legacy handcuffs instance to real handcuffs.
;
Function ConvertLegacyHandcuffs(ObjectReference item)
    If (!item.HasKeyword(Processed))
        item.AddKeyword(Processed)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Replacing " + RealHandcuffs:Log.FormIdAsString(item) + " " + item.GetDisplayName() + ".", Library.Settings)
        EndIf
        ; get the base id of the instance, we will use this for 'random chance' checks to make them
        ; consistent over play-throughs and load order changes
        Int formId = item.GetFormID()
        Int modId = formId / 0x01000000
        Int baseId
        If (formId >= 0)
            baseId = formId - modId * 0x1000000
        Else
            modId = (255 + modId)
            baseId = (256 - modId) * 0x1000000 + formId
        EndIf
        ; spawn handcuffs, with mods if necessary
        RealHandcuffs:HandcuffsBase replacement
        ObjectReference cont = item.GetContainer()
        If ((baseId * 37) % 100 <= PercentHinged)
            If (cont == None)
                replacement = item.PlaceAtMe(HandcuffsHinged, 1, false, true, false) as RealHandcuffs:HandcuffsBase
            Else
                replacement = cont.PlaceAtMe(HandcuffsHinged, 1, false, true, false) as RealHandcuffs:HandcuffsBase
            EndIf
        Else
            If (cont == None)
                replacement = item.PlaceAtMe(Handcuffs, 1, false, true, false) as RealHandcuffs:HandcuffsBase
            Else
                replacement = cont.PlaceAtMe(Handcuffs, 1, false, true, false) as RealHandcuffs:HandcuffsBase
            EndIf
        EndIf
        replacement.EnableNoWait()
        If ((baseId * 83) % 100 <= PercentHighSecurity)
            replacement.SetLockMod(ModHighSecurityLock)
        EndIf
        Form keyObject = replacement.GetKeyObject()
        If (cont == None)
            item.DisableNoWait()
            replacement.MoveTo(item, 0, 0, 0, true)
            If (keyObject != None && (baseId * 59) % 100 < (100 - ChanceNoneKeys.GetValue()))
                ObjectReference spawnedKey = item.PlaceAtMe(keyObject, 1, false, true, false) ; make the key persistent, too
                spawnedKey.EnableNoWait()
                spawnedKey.MoveTo(replacement, 0, 0, 0, false)
            EndIf
            item.Delete()
        Else
            cont.AddItem(replacement, 1, true)
            If (keyObject != None && (baseId * 59) % 100 < (100 - ChanceNoneKeys.GetValue()))
                cont.AddItem(keyObject, 1, true)
            EndIf
            cont.RemoveItem(item, 1, true, None)
        EndIf
    EndIf
EndFunction

;
; Convert all legacy handcuffs instances in a container to real handcuffs.
;
Function ConvertLegacyHandcuffsInsideContainer(ObjectReference cont)
    Int legacyHandcuffsCount = cont.GetItemCount(LegacyHandcuffs)
    If (legacyHandcuffsCount > 0)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Replacing " + legacyHandcuffsCount + " handcuffs inside " + RealHandcuffs:Log.FormIdAsString(cont) + " " + cont.GetDisplayName() + ".", Library.Settings)
        EndIf
        cont.RemoveItem(LegacyHandcuffs, legacyHandcuffsCount, true, None)
        cont.AddItem(Handcuffs, legacyHandcuffsCount, true)
    EndIf
EndFunction

;
; Convert a single legacy shock collars instance to a real shock collar
;
Function ConvertLegacyShockCollar(ObjectReference item)
    If (!item.HasKeyword(Processed))
        item.AddKeyword(Processed)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Replacing " + RealHandcuffs:Log.FormIdAsString(item) + " " + item.GetDisplayName() + ".", Library.Settings)
        EndIf
        ; get the base id of the instance, we will use this for 'random chance' checks to make them
        ; consistent over play-throughs and load order changes
        Int formId = item.GetFormID()
        Int modId = formId / 0x01000000
        Int baseId
        If (formId >= 0)
            baseId = formId - modId * 0x1000000
        Else
            modId = (255 + modId)
            baseId = (256 - modId) * 0x1000000 + formId
        EndIf
        ; spawn shock collar, with mods if necessary
        RealHandcuffs:ShockCollar replacement
        ObjectReference cont = item.GetContainer()
        If (cont == None)
            replacement = item.PlaceAtMe(ShockCollar, 1, false, true, false) as RealHandcuffs:ShockCollar
        Else
            replacement = cont.PlaceAtMe(ShockCollar, 1, false, true, false) as RealHandcuffs:ShockCollar
        EndIf
        replacement.EnableNoWait()
        If ((baseId * 37) % 100 <= PercentThrobbing)
            replacement.SetShockModuleMod(ModThrobbingShockModule)
        EndIf
        If ((baseId * 83) % 100 <= PercentMarkThree)
            replacement.SetFirmwareMod(ModMarkThreeFirmware)
        EndIf
        If (cont == None)
            item.DisableNoWait()
            replacement.MoveTo(item, 0, 0, 0, true)
            item.Delete()
        Else
            cont.AddItem(replacement, 1, true)
            cont.RemoveItem(item, 1, true, None)
        EndIf
    EndIf
EndFunction

;
; Convert all legacy shock collars in a container to real handcuffs.
;
Function ConvertLegacyShockCollarsInsideContainer(ObjectReference cont)
    Int legacyShockCollarCount = cont.GetItemCount(Library.SoftDependencies.ShockCollar)
    If (legacyShockCollarCount > 0)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Replacing " + legacyShockCollarCount + " shock collars inside " + RealHandcuffs:Log.FormIdAsString(cont) + " " + cont.GetDisplayName() + ".", Library.Settings)
        EndIf
        cont.RemoveItem(Library.SoftDependencies.ShockCollar, legacyShockCollarCount, true, None)
        cont.AddItem(ShockCollar, legacyShockCollarCount, true)
    EndIf
EndFunction

;
; Check if a legacy handcuffs instance has already been processed.
;
Bool Function IsProcessed(ObjectReference legacyHandcuffs)
    Return legacyHandcuffs.HasKeyword(Processed)
EndFunction