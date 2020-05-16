;
; A script to inject stuff into leveled lists.
; This has better compatibility with other mods than editing them directly.
;
Scriptname RealHandcuffs:LeveledListInjector extends Quest

FormList Property lootItemsUncommon Auto Const Mandatory
FormList Property lootItemsRare Auto Const Mandatory
LeveledItem Property LL_Junk_Tiny Auto Const Mandatory
LeveledItem Property LL_Junk_Small Auto Const Mandatory
LeveledItem Property LL_Junk_Large Auto Const Mandatory
LeveledItem Property LLI_Vendor_Items_Small_Rare Auto Const Mandatory
LeveledItem Property LLI_Vendor_Items_Large_Rare Auto Const Mandatory
LeveledItem Property LL_Vendor_Junk_G_M Auto Const Mandatory
LeveledItem Property LL_Vendor_Junk_N_Z Auto Const Mandatory
LeveledItem Property LL_Household_Small Auto Const Mandatory
LeveledItem Property LL_Junk_Mailbox Auto Const Mandatory
LeveledItem Property LLI_Loot_Items_Small_Rare Auto Const Mandatory
LeveledItem Property LLI_Loot_Items_Large_Rare Auto Const Mandatory
LeveledItem Property LL_Junk_Small_Personal Auto Const Mandatory
LeveledItem Property LL_Component_Vendor_Circuitry Auto Const Mandatory
LeveledItem Property LL_Component_Vendor_Copper Auto Const Mandatory
LeveledItem Property LL_Component_Vendor_Crystal Auto Const Mandatory
LeveledItem Property LL_Component_Vendor_Screws Auto Const Mandatory
LeveledItem Property LL_Component_Vendor_Springs Auto Const Mandatory
LeveledItem Property LL_Component_Vendor_Steel Auto Const Mandatory

RealHandcuffs:Settings Property Settings Auto Const Mandatory
GlobalVariable Property LeveledListInjectorState Auto Const Mandatory
Armor Property Handcuffs Auto Const Mandatory
Armor Property HandcuffsBroken Auto Const Mandatory
Armor Property HandcuffsHinged Auto Const Mandatory
Armor Property HandcuffsHingedBroken Auto Const Mandatory
Armor Property ShockCollar Auto Const Mandatory
MiscObject Property HandcuffsKey Auto Const Mandatory
MiscObject Property HighSecurityHandcuffsKey Auto Const Mandatory
Weapon Property RemoteTrigger Auto Const Mandatory
LeveledItem Property Random_Handcuffs_Any_MaybeKey Auto Const Mandatory
LeveledItem Property Random_ShockCollar_Any_MaybeRemoteTrigger Auto Const Mandatory

Int Property LatestState = 2 AutoReadOnly

Function UpdateLeveledLists()
    If (LeveledListInjectorState.GetValueInt() < LatestState)
        If (LeveledListInjectorState.GetValueInt() < 1)
            LeveledListInjectorState.SetValueInt(1)
            AddToFormList(lootItemsUncommon, Handcuffs)
            AddToFormList(lootItemsUncommon, HandcuffsBroken)
            AddToFormList(lootItemsUncommon, HandcuffsHinged)
            AddToFormList(lootItemsUncommon, HandcuffsHingedBroken)
            AddToLeveledList(LL_Junk_Tiny, Random_Handcuffs_Any_MaybeKey)
            AddToLeveledList(LL_Junk_Small, Random_Handcuffs_Any_MaybeKey)
            AddToLeveledList(LLI_Vendor_Items_Small_Rare, Random_Handcuffs_Any_MaybeKey)
            AddToLeveledList(LL_Vendor_Junk_G_M, Random_Handcuffs_Any_MaybeKey)
            AddToLeveledList(LL_Household_Small, Random_Handcuffs_Any_MaybeKey)
            AddToLeveledList(LL_Junk_Mailbox, Random_Handcuffs_Any_MaybeKey)
            AddToLeveledList(LLI_Loot_Items_Small_Rare, Random_Handcuffs_Any_MaybeKey)
            AddToLeveledList(LL_Junk_Small_Personal, Random_Handcuffs_Any_MaybeKey)
            AddToLeveledList(LL_Component_Vendor_Screws, Random_Handcuffs_Any_MaybeKey)
            AddToLeveledList(LL_Component_Vendor_Springs, Random_Handcuffs_Any_MaybeKey)
            AddToLeveledList(LL_Component_Vendor_Steel, Random_Handcuffs_Any_MaybeKey)
            RealHandcuffs:Log.Info("Updated leveled lists to state 1.", Settings)
        EndIf
        If (LeveledListInjectorState.GetValueInt() < 2)
            LeveledListInjectorState.SetValueInt(2)
            AddToFormList(lootItemsUncommon, HandcuffsKey)
            AddToFormList(lootItemsRare, HighSecurityHandcuffsKey)
            AddToFormList(lootItemsRare, ShockCollar)
            AddToFormList(lootItemsRare, RemoteTrigger)
            AddToLeveledList(LL_Junk_Large, Random_ShockCollar_Any_MaybeRemoteTrigger)
            AddToLeveledList(LLI_Vendor_Items_Large_Rare, Random_ShockCollar_Any_MaybeRemoteTrigger)
            AddToLeveledList(LL_Vendor_Junk_N_Z, Random_ShockCollar_Any_MaybeRemoteTrigger)
            AddToLeveledList(LLI_Loot_Items_Large_Rare, Random_ShockCollar_Any_MaybeRemoteTrigger)
            AddToLeveledList(LL_Component_Vendor_Circuitry, Random_ShockCollar_Any_MaybeRemoteTrigger)
            AddToLeveledList(LL_Component_Vendor_Copper, Random_ShockCollar_Any_MaybeRemoteTrigger)
            AddToLeveledList(LL_Component_Vendor_Crystal, Random_ShockCollar_Any_MaybeRemoteTrigger)
            AddToLeveledList(LL_Component_Vendor_Steel, Random_ShockCollar_Any_MaybeRemoteTrigger)
            RealHandcuffs:Log.Info("Updated leveled lists to state 2.", Settings)
        EndIf
    Else
            RealHandcuffs:Log.Info("Leveled lists already up-to-date.", Settings)
    EndIf
EndFunction

Function AddToFormList(FormList list, Form item)
    list.AddForm(item)
EndFunction

Function AddToLeveledList(LeveledItem list, Form item)
    list.AddForm(item, 1, 1)
EndFunction