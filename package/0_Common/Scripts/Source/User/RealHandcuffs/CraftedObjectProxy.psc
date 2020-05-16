;
; A proxy for crafted objects. This allows crafting items that are already modded.
;
Scriptname RealHandcuffs:CraftedObjectProxy extends ObjectReference Const

RealHandcuffs:Library Property Library Auto Const Mandatory

Form Property BaseObject Auto Const Mandatory

ObjectMod Property ModOne Auto Const
Keyword Property ModTagOne Auto Const
ObjectMod Property ModTwo Auto Const
Keyword Property ModTagTwo Auto Const
ObjectMod Property ModThree Auto Const
Keyword Property ModTagThree Auto Const

Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
    Actor equipOnActor = None
    If (akOldContainer != None)
        equipOnActor = akOldContainer.GetLinkedRef(Library.Resources.LinkedActorToEquipCraftedItem) as Actor
    EndIf
    If (akNewContainer != None)
        If (akNewContainer.GetBaseObject() == Library.Resources.InvisibleContainer)
            Return ; defer conversion until moved out of invisible container
        EndIf
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Converting crafted object proxy " + GetDisplayName() + ".", Library.Settings)
        EndIf
        ObjectReference item = Game.GetPlayer().PlaceAtMe(BaseObject, 1, false, true, false)
        item.SetActorRefOwner(Game.GetPlayer())
        ObjectMod[] mods = new ObjectMod[0]
        Keyword[] modTags = new Keyword[0]
        If (ModOne != None)
            mods.Add(ModOne)
            modTags.Add(ModTagOne)
        EndIf
        If (ModTwo != None)
            mods.Add(ModTwo)
            modTags.Add(ModTagTwo)
        EndIf
        If (ModThree != None)
            mods.Add(ModThree)
            modTags.Add(ModTagThree)
        EndIf
        Int index = 0
        While (index < mods.Length)
            ObjectMod mod = mods[index]
            Keyword modTag = modTags[index]
            If (modTag != None)
                ObjectMod[] itemMods = item.GetAllMods()
                Int itemModIndex = 0
                While (itemModIndex < itemMods.Length)
                    If (Library.IsAddingKeyword(itemMods[itemModIndex], modTag))
                        item.RemoveMod(itemMods[itemModIndex])
                    EndIf
                    itemModIndex += 1
                EndWhile
            EndIf
            If (!item.AttachMod(mod))
                RealHandcuffs:Log.Warning("Failed to attached mod " + RealHandcuffs:Log.FormIdAsString(mod) + " " + mod.GetName() + " to " + item.GetDisplayName() + ".", Library.Settings)
            EndIf
            index += 1
        EndWhile
        item.EnableNoWait()
        If (equipOnActor == None)
            akNewContainer.AddItem(item, 1, true)
        Else
            equipOnActor.AddItem(item, 1, true)
        EndIf
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Conversion finished.", Library.Settings)
        EndIf
        Drop(true)
        DisableNoWait()
        Delete()
        If (equipOnActor != None)
            RealHandcuffs:Log.Info("Equipping converted item on " + RealHandcuffs:Log.FormIdAsString(equipOnActor) + " " + equipOnActor.GetDisplayName() + ".", Library.Settings)
            (item as RealHandcuffs:RestraintBase).ForceEquip()
        EndIf
    EndIf
EndEvent