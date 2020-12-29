;
; The ActorToken implementation for the player.
;
Scriptname RealHandcuffs:PlayerToken extends RealHandcuffs:ActorToken

Keyword Property AnimFlavorFahrenheit Auto Const Mandatory
Keyword Property IsSleepFurniture Auto Const Mandatory
Keyword Property VendorItemKey Auto Const Mandatory

FormList Property BoundHandsGenericFurnitureList Auto Const Mandatory
FormList Property BoundHandsTakeItemList Auto Const Mandatory
Keyword Property ActivateWithBoundHands Auto Const Mandatory
Keyword Property BoundHands Auto Const Mandatory
Keyword Property Dummy Auto Const Mandatory
Keyword Property ObjectTypeFood Auto Const Mandatory
Keyword Property RhKey Auto Const Mandatory
Perk Property ExamineLockedDoorOrContainer Auto Const Mandatory
Perk Property NoDisarmTraps Auto Const Mandatory
Perk Property NoGenericFurniture Auto Const Mandatory
Perk Property SearchContainer Auto Const Mandatory
Perk Property NoPickpocketing Auto Const Mandatory
Perk Property NoPowerArmor Auto Const Mandatory
Perk Property NoSleeping Auto Const Mandatory
Perk Property TakeSmallObjectOnly Auto Const Mandatory
Perk Property CraftOnArmorWorkbench Auto Const Mandatory
RefCollectionAlias Property Workshops Auto Const Mandatory
Spell Property BadAtSwimming Auto Const Mandatory

RealHandcuffs:RestraintBase _handsBoundBehindBackRestraint
Bool _hasRemoteTriggerRestraint

Bool _workbenchActivatorReplaced

ObjectReference _hiddenRestraintsContainer
ObjectReference _searchedContainer

String[] _registeredMenus
Bool _animationRefreshRequested

Int[] _registeredKeys
String[] _registeredKeysMappings

Float Property LastQuickKeyRealTime Auto
Form Property LastQuickKeyItem Auto

InputEnableLayer _inputLayer
Bool _disabledWorkshopFrameworkActivation

;
; Override: Get whether the hands of the actor are currently bound behind their back.
;
Bool Function GetHandsBoundBehindBack()
    Return _handsBoundBehindBackRestraint != None
EndFunction

;
; Get the restraint that binds tha hands of the player behind their back.
;
RealHandcuffs:RestraintBase Function GetHandsBoundBehindBackRestraint()
    Return _handsBoundBehindBackRestraint
EndFunction

;
; Override: Get whether firing a remote trigger in the vicinity may cause some effect.
;
Bool Function GetRemoteTriggerEffect()
    Return _hasRemoteTriggerRestraint
EndFunction

;
; Override: Initialize the actor token after creation.
;
Function Initialize(Actor myTarget)
    _inputLayer = InputEnableLayer.Create()
    Parent.Initialize(myTarget)
    RegisterMenus()
    RefreshKeyRegistrations()
    RegisterForRemoteEvent(Target, "OnSit")
    RegisterForRemoteEvent(Target, "OnGetUp")
EndFunction

;
; Override: Uninitialize the actor token before destruction.
;
Function Uninitialize()
    CancelTimer(StartCheckingWeapon) ; may do nothing but that is fine
    CancelTimer(CheckConsistency) ; may do nothing but that is fine
    UnregisterForRemoteEvent(Target, "OnGetUp")
    UnregisterForRemoteEvent(Target, "OnSit")
    UnregisterKeys()
    UnregisterMenus()
    Parent.Uninitialize()
    If (_inputLayer != None)
        _inputLayer.Delete()
        _inputLayer = None
    EndIf
EndFunction

;
; Override: Check if the token is in a good state. Returns false and deletes the token if not.
;
Bool Function CheckConsistency(Actor expectedTarget)
    If (Uninitialized)
        Return false
    EndIf
    If (Parent.CheckConsistency(expectedTarget))
        If (_inputLayer != None)
            Return true
        EndIf
        RealHandcuffs:Log.Warning("Deleting player token without input layer.", Library.Settings)
        DestroyInconsistentToken(expectedTarget)
    EndIf
    ; make sure settings are locked/unlocked
    If (Library != None)
        RealHandcuffs:ActorToken token = Library.TryGetActorToken(expectedTarget)
        If (token == None)
            Library.Settings.OnPlayerRestraintsChanged(new RealHandcuffs:RestraintBase[0])
        Else
            Library.Settings.OnPlayerRestraintsChanged(token.Restraints)
        EndIf
    EndIf
    Return false
EndFunction


;
; Override: Refresh data after the game has been loaded.
;
Function RefreshOnGameLoad(Bool upgrade)
    UnhideRestraints() ; may do nothing
    Parent.RefreshOnGameLoad(upgrade)
    LastQuickKeyRealTime = 0
    LastQuickKeyItem = None
    ; refresh key registrations, user could have changed the settings
    RefreshKeyRegistrations()
EndFunction

;
; Override: Refresh all static event registrations that don't depend on equipped restraints.
;
Function RefreshEventRegistrations()
    UnregisterForRemoteEvent(Target, "OnGetUp")
    UnregisterForRemoteEvent(Target, "OnSit")
    UnregisterKeys()
    UnregisterMenus()
    Parent.RefreshEventRegistrations()
    RegisterMenus()
    RefreshKeyRegistrations()
    RegisterForRemoteEvent(Target, "OnSit")
    RegisterForRemoteEvent(Target, "OnGetUp")
EndFunction

;
; Override: Apply a restraint to the actor and update all effects and animations.
;
Function ApplyRestraint(RealHandcuffs:RestraintBase restraint)
    CancelTimer(CheckConsistency) ; may do nothing but that is fine
    Parent.ApplyRestraint(restraint)
    StartTimer(2, CheckConsistency) ; fallback code to help catch problems
EndFunction

;
; Override: Unapply a restraint and update all effects and animations.
;
Function UnapplyRestraint(RealHandcuffs:RestraintBase restraint)
    CancelTimer(CheckConsistency) ; may do nothing but that is fine
    Parent.UnapplyRestraint(restraint)
    StartTimer(2, CheckConsistency) ; fallback code to help catch problems
EndFunction

;
; Suspend all effects and animations.
;
Function SuspendEffectsAndAnimations()
    Parent.SuspendEffectsAndAnimations()
    If (_workbenchActivatorReplaced)
        Target.RemovePerk(CraftOnArmorWorkbench)
        _workbenchActivatorReplaced = false
    EndIf
EndFunction

;
; Refresh all effects and animations.
;
Function RefreshEffectsAndAnimations(Bool forceRefresh, ObjectReference maybeNewlyAppliedRestraint)
    Parent.RefreshEffectsAndAnimations(forceRefresh, maybeNewlyAppliedRestraint)
    If (_workbenchActivatorReplaced && (forceRefresh || Restraints.Length == 0 || _handsBoundBehindBackRestraint != None))
        Target.RemovePerk(CraftOnArmorWorkbench)
        _workbenchActivatorReplaced = false
    EndIf
    If (!_workbenchActivatorReplaced && Restraints.Length > 0 && _handsBoundBehindBackRestraint == None)
        Target.AddPerk(CraftOnArmorWorkbench)
        _workbenchActivatorReplaced = true
    EndIf
EndFunction

;
; Override: Apply effects to the actor.
;
Function ApplyEffects(Bool forceRefresh, RealHandcuffs:RestraintBase handsBoundBehindBackRestraint, RealHandcuffs:RestraintBase[] remoteTriggerRestraints)
    Bool hasRemoteTriggerRestraint = remoteTriggerRestraints != None && remoteTriggerRestraints.Length > 0
    If (!forceRefresh && handsBoundBehindBackRestraint == _handsBoundBehindBackRestraint && hasRemoteTriggerRestraint == _hasRemoteTriggerRestraint)
        ; nothing to do
        Return
    EndIf
    Bool oldHandsBoundBehindBack = _handsBoundBehindBackRestraint != None
    _handsBoundBehindBackRestraint = handsBoundBehindBackRestraint
    Bool handsBoundBehindBack = handsBoundBehindBackRestraint != None
    If (!forceRefresh && handsBoundBehindBack == oldHandsBoundBehindBack && hasRemoteTriggerRestraint == _hasRemoteTriggerRestraint)
        Return
    EndIf
    If (forceRefresh || (oldHandsBoundBehindBack && !handsBoundBehindBack))
        If (oldHandsBoundBehindBack)
            RealHandcuffs:Log.Info("Removing hands bound behind back impact from player.", Library.Settings)
        EndIf
        ; remove 'bound hands' keyword
        Target.ResetKeyword(BoundHands)
        ; enable fighting
        CancelTimer(StartCheckingWeapon) ; may do nothing but that is fine
        UnregisterForAnimationEvent(Target, "weaponDraw") ; may do nothing, too
        _inputLayer.EnableFighting(true)
        _inputLayer.EnableVATS(true)
        ; enable pipboy and favorites
        _inputLayer.EnableMenu(true)
        _inputLayer.EnableFavorites(true)
        ; allow picking up objects and opening containers
        Target.RemovePerk(TakeSmallObjectOnly)
        Target.RemovePerk(SearchContainer)
        RemoveAllInventoryEventFilters() ; may do nothing
        UnregisterForRemoteEvent(Target, "OnItemAdded") ; may do nothing
        UnregisterForRemoteEvent(Target, "OnItemRemoved") ; may do nothing
        _searchedContainer = None ; may do nothing
        ; remove bad at swimming ability
        Target.RemoveSpell(BadAtSwimming)
        ; allow power armor use and generic furniture use
        Target.RemovePerk(NoPowerArmor)
        Target.RemovePerk(NoGenericFurniture)
        ; stop using use 'examine' action for locked doors and containers
        Target.RemovePerk(ExamineLockedDoorOrContainer)
        ; allow pickpocketing
        Target.RemovePerk(NoPickpocketing)
        ; allow disarming mines and similar traps
        Target.RemovePerk(NoDisarmTraps)
        ; allow workshop mode
        UnregisterForRemoteEvent(Workshops, "OnWorkshopMode")
        ; restore WorkshopsFramework activation
        If (_disabledWorkshopFrameworkActivation)
            GlobalVariable wsfwActivation = Library.SoftDependencies.WSFW_AlternateActivation_Workshop
            If (wsfwActivation != None)
                wsfwActivation.SetValueInt(1)
            EndIf
            _disabledWorkshopFrameworkActivation = false
        EndIf
    EndIf
    If ((forceRefresh || !oldHandsBoundBehindBack) && handsBoundBehindBack)
        RealHandcuffs:Log.Info("Applying hands bound behind back impact on player.", Library.Settings)
        ; add 'bound hands' keyword, for information only
        Target.AddKeyword(BoundHands)
        ; disable pipboy and favorites
        _inputLayer.EnableMenu(false)
        _inputLayer.EnableFavorites(false)
        If (UI.IsMenuOpen("PipboyMenu"))
            UI.CloseMenu("PipboyMenu")
            Utility.Wait(0.4)
        EndIf
        ; disable fighting
        Bool switchedCamera = false
        If (Game.GetPlayer().GetAnimationVariableBool("IsFirstPerson"))
            Game.ForceThirdPerson()
            switchedCamera = true
            Utility.Wait(0.1)
        EndIf
        _inputLayer.EnableFighting(false)
        _inputLayer.EnableVATS(false)
        StartTimer(3, StartCheckingWeapon) ; give the player some time to stow their weapon
        ; forbid picking up objects and opening containers
        Target.AddPerk(TakeSmallObjectOnly, false)
        Target.AddPerk(SearchContainer, false)
        If (UI.IsMenuOpen("ContainerMenu"))
            RegisterForRemoteEvent(Target, "OnItemAdded")
            RegisterForRemoteEvent(Target, "OnItemRemoved")
            AddInventoryEventFilter(None)
        EndIf
        ; add bad at swimming ability
        Target.AddSpell(BadAtSwimming, false)
        ; forbid power armor use and generic furniture use
        Target.AddPerk(NoPowerArmor, false)
        Target.AddPerk(NoGenericFurniture)
        If (Target.IsInPowerArmor())
            Target.SwitchToPowerArmor(None)
        Else
            ObjectReference currentFurniture = Target.GetFurnitureReference()
            If (currentFurniture != None && !currentFurniture.HasKeyword(ActivateWithBoundHands) && !BoundHandsGenericFurnitureList.HasForm(currentFurniture.GetBaseObject()))
                Target.MoveTo(Target, 0, 0, 0.1, true) ; kick out of furniture
            EndIf
        EndIf
        ; use 'examine' action for locked doors and containers
        Target.AddPerk(ExamineLockedDoorOrContainer)
        ; forbid pickpocketing
        Target.AddPerk(NoPickpocketing)
        ; prevent disarming mines and similar traps
        Target.AddPerk(NoDisarmTraps)
        ; disallow workshop mode
        RegisterForRemoteEvent(Workshops, "OnWorkshopMode")
        ; disable WorkshopsFramework activation
        GlobalVariable wsfwActivation = Library.SoftDependencies.WSFW_AlternateActivation_Workshop
        If (wsfwActivation != None && wsfwActivation.GetValueInt() == 1)
            wsfwActivation.SetValueInt(0)
            _disabledWorkshopFrameworkActivation = true
        EndIf
        ; restore camera
        If (switchedCamera)
            Utility.Wait(0.1)
            Game.ForceFirstPerson()
        EndIf
    EndIf
    If (forceRefresh || (_hasRemoteTriggerRestraint && !hasRemoteTriggerRestraint))
        If (_hasRemoteTriggerRestraint && Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Removing remote trigger effect impact from player.", Library.Settings)
        EndIf
        _hasRemoteTriggerRestraint = false
        Target.ResetKeyword(Library.Resources.RemoteTriggerEffect)
    EndIf
    If ((forceRefresh || !_hasRemoteTriggerRestraint) && hasRemoteTriggerRestraint)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Applying remote trigger effect impact on player.", Library.Settings)
        EndIf
        _hasRemoteTriggerRestraint = true
        Target.AddKeyword(Library.Resources.RemoteTriggerEffect)
    EndIf
    ApplyStatefulEffects()
EndFunction

;
; Override:Apply effects that depend on the state of the equipped restraints.
;
Function ApplyStatefulEffects()
    Parent.ApplyStatefulEffects()
    If (Target.HasKeyword(Library.Resources.FrequentlyRepeatingShocks))
        Target.AddPerk(NoSleeping)
    Else
        Target.RemovePerk(NoSleeping)
    EndIf
EndFunction


;
; Override: Kick the animations subsystem to trigger the changed animations.
;
Function KickAnimationSubsystem()
    If (UI.IsMenuOpen("PipboyMenu"))
        ; we must not change animations flavors when the pipboy menu is open, doing that will soft-lock the game
        ; do it as soon as the pipboy menu closes instead
        _animationRefreshRequested = true
    Else
        ; switch around animation flavors to make the game realize that something changed
        Game.GetPlayer().ChangeAnimFlavor(AnimFlavorFahrenheit)
        Game.GetPlayer().ChangeAnimFlavor()
    EndIf
EndFunction

;
; Event handler for weapon draw animation event.
;
Event OnAnimationEvent(ObjectReference akSource, string asEventName)
    If (asEventName == "weaponDraw" && _handsBoundBehindBackRestraint != None)
        CheckConsistency(Target)
    EndIf
EndEvent

;
; Override: React on the actor unequipping an item.
;
Function HandleItemUnequipped(Form akBaseObject, ObjectReference akReference)
    ; ignore the event if items are currently hidden
    ; this is to prevent interactions in that situation
    If (_hiddenRestraintsContainer == None)
        Parent.HandleItemUnequipped(akBaseObject, akReference)
    EndIf
EndFunction

;
; Register for menu event handling.
;
Function RegisterMenus()
    _registeredMenus = new String[4]
    _registeredMenus[0] = "BarterMenu"
    RegisterForMenuOpenCloseEvent("BarterMenu")
    _registeredMenus[1] = "PauseMenu"
    RegisterForMenuOpenCloseEvent("PauseMenu")
    _registeredMenus[2] = "PipboyMenu"
    RegisterForMenuOpenCloseEvent("PipboyMenu")
    _registeredMenus[3] = "ContainerMenu"
    RegisterForMenuOpenCloseEvent("ContainerMenu")
EndFunction

;
; Unregister from menu event handling.
;
Function UnregisterMenus()
    Int index = _registeredMenus.Length
    While (index > 0)
        index -= 1
        UnregisterForMenuOpenCloseEvent(_registeredMenus[index])
    EndWhile
    _registeredMenus = None
EndFunction

;
; Refresh registration for key event handling.
;
Function RefreshKeyRegistrations()
    Int[] keys = new Int[0]
    String[] mappings = new String[0]
    FindAllKeyRegistrations(keys, mappings)
    If (!KeyRegistationsUpToDate(keys, mappings))
        UnregisterKeys()
        _registeredKeys = keys
        _registeredKeysMappings = mappings
        Int index = 0
        While (index < keys.Length)
            RegisterForKey(keys[index])
            index += 1
        EndWhile
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Key registrations refreshed: " + keys.Length + " entries.", Library.Settings)
        EndIf
    EndIf
EndFunction

;
; Find key registrations for all interesting keys and add them to the keys/mappings array.
;
Function FindAllKeyRegistrations(Int[] keys, String[] mappings)
    FindKeyRegistrations("Pipboy", keys, mappings, 9) ; use tab as hardcoded default if no keyboard mapping found
    FindKeyRegistrations("QuickInventory", keys, mappings, -1)
    FindKeyRegistrations("Quickkey1", keys, mappings, -1)
    FindKeyRegistrations("Quickkey2", keys, mappings, -1)
    FindKeyRegistrations("Quickkey3", keys, mappings, -1)
    FindKeyRegistrations("Quickkey4", keys, mappings, -1)
    FindKeyRegistrations("Quickkey5", keys, mappings, -1)
    FindKeyRegistrations("Quickkey6", keys, mappings, -1)
    FindKeyRegistrations("Quickkey7", keys, mappings, -1)
    FindKeyRegistrations("Quickkey8", keys, mappings, -1)
    FindKeyRegistrations("Quickkey9", keys, mappings, -1)
    FindKeyRegistrations("Quickkey10", keys, mappings, -1)
    FindKeyRegistrations("Quickkey11", keys, mappings, -1)
    FindKeyRegistrations("Quickkey12", keys, mappings, -1)
EndFunction

;
; Find key registrations for a specified control and add them to the keys/mappings array.
;
Function FindKeyRegistrations(String control, Int[] keys, String[] mappings, Int defaultKeyboardScanCode)
    Int scanCode = Input.GetMappedKey(control, 0) ; keyboard
    If (scanCode == -1 && defaultKeyboardScanCode != -1)
        RealHandcuffs:Log.Info("Unable to detect keyboard mapping for " + control + ", falling back to default.", Library.Settings)
        scanCode = defaultKeyboardScanCode ; fallback in case mappings are somehow not working
    EndIf
    If (scanCode != -1)
        keys.Add(scanCode)
        mappings.Add(control)
    EndIf
    scanCode= Input.GetMappedKey(control, 1) ; mouse
    If (scanCode != -1)
        keys.Add(scanCode)
        mappings.Add(control)
    EndIf
    scanCode = Input.GetMappedKey(control, 2) ; gamepad
    If (scanCode != -1)
        keys.Add(scanCode)
        mappings.Add(control)
    EndIf
EndFunction

;
; Check if the existing key registrations are up to date with the passed key registrations.
;
Bool Function KeyRegistationsUpToDate(Int[] keys, String[] mappings)
    If (_registeredKeys == None || _registeredKeys.Length != keys.Length)
        Return false
    EndIf
    Int index = 0
    While (index < keys.Length)
        If (keys[index] != _registeredKeys[index] || mappings[index] != _registeredKeysMappings[index])
            Return false
        EndIf
        index += 1
    EndWhile
    Return true
EndFunction

;
; Unregister from key event handling.
;
Function UnregisterKeys()
    If (_registeredKeys != None)
        Int index = 0
        While (index < _registeredKeys.Length)
            UnregisterForKey(_registeredKeys[index])
            index += 1
        EndWhile
        _registeredKeys = None
        _registeredKeysMappings = None
    EndIf
EndFunction

;
; Get the index of a Quickkey mapping, e.g. "Quickkey4" -> 4, or 0 if not a quickkey mapping.
;
Int Function GetQuickkeyIndex(String mapping)
    If (mapping == "Quickkey1")
        Return 1
    ElseIf (mapping == "Quickkey2")
        Return 2
    ElseIf (mapping == "Quickkey3")
        Return 3
    ElseIf (mapping == "Quickkey4")
        Return 4
    ElseIf (mapping == "Quickkey5")
        Return 5
    ElseIf (mapping == "Quickkey6")
        Return 6
    ElseIf (mapping == "Quickkey7")
        Return 7
    ElseIf (mapping == "Quickkey8")
        Return 8
    ElseIf (mapping == "Quickkey9")
        Return 9
    ElseIf (mapping == "Quickkey10")
        Return 10
    ElseIf (mapping == "Quickkey11")
        Return 11
    ElseIf (mapping == "Quickkey12")
        Return 12
    EndIf
    Return 0
EndFunction

;
; Event handler for menu open/close event.
;
Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    If (abOpening && !CheckConsistency(Game.GetPlayer()))
        Return
    EndIf
    If (asMenuName == "BarterMenu" && abOpening && Restraints.Length > 0)
        HideRestraints()
        Return
    EndIf
    UnhideRestraints() ; may do nothing
    If (asMenuName == "PipboyMenu")
        If (_animationRefreshRequested && !abOpening)
            ; switch around animation flavors to make the game realize that animation keywords changed
            Game.GetPlayer().ChangeAnimFlavor(AnimFlavorFahrenheit)
            Game.GetPlayer().ChangeAnimFlavor()
            _animationRefreshRequested = false
        EndIf
    ElseIf (asMenuName == "PauseMenu")
        If (!abOpening)
            ; refresh key registrations, user could have changed the settings
            RefreshKeyRegistrations()
        EndIf
    ElseIf (asMenuName == "ContainerMenu")
        If (abOpening)
            If (_handsBoundBehindBackRestraint == None)
                If (_searchedContainer == None)
                    RealHandcuffs:Log.Info("Player opening unknown container.", Library.Settings)
                Else
                    RealHandcuffs:Log.Info("Player opening container " + _searchedContainer.GetDisplayName() + " " + RealHandcuffs:Log.FormIdAsString(_searchedContainer) + ".", Library.Settings)
                EndIf
            Else
                If (_searchedContainer == None)
                    RealHandcuffs:Log.Info("Player opening unknown container with bound hands.", Library.Settings)
                ElseIf (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Player opening container " + _searchedContainer.GetDisplayName() + " " + RealHandcuffs:Log.FormIdAsString(_searchedContainer) + " with bound hands.", Library.Settings)
                EndIf
            EndIf
            RegisterForRemoteEvent(Target, "OnItemAdded")
            RegisterForRemoteEvent(Target, "OnItemRemoved")
            If (_handsBoundBehindBackRestraint == None)
                AddInventoryEventFilter(Library.Resources.Restraint) ; only observe transfer of restraints if not bound
            Else
                AddInventoryEventFilter(None) ; observe everything if bound
            EndIf
            Actor maybeSearchedActor
            If (_searchedContainer != None)
                maybeSearchedActor = _searchedContainer as Actor
            Else
                maybeSearchedActor = LL_FourPlay.LastCrossHairActor()
            EndIf
            If (maybeSearchedActor != None && maybeSearchedActor.GetItemCount(Library.Resources.Restraint) > 0)
                Library.GetOrCreateActorToken(maybeSearchedActor) ; the token will observe OnItemEquipped, it is more reliable than OnEquipped
            EndIf
        Else
            RealHandcuffs:Log.Info("Player closing container.", Library.Settings)
            RemoveAllInventoryEventFilters()
            UnregisterForRemoteEvent(Target, "OnItemAdded")
            UnregisterForRemoteEvent(Target, "OnItemRemoved")
            _searchedContainer = None ; may do nothing
        EndIf
    EndIf
EndEvent

;
; Event handler for key down events.
;
Event OnKeyDown(int keyCode)
    If (Utility.IsInMenuMode() || UI.IsMenuOpen("DialogueMenu")) ; IsInMenuMode() returns false when dialogue menus is active
        ; ignore hotkey when menu is active
        Return
    EndIf
    If (Library.SoftDependencies.IsInAafScene(Target))
        ; ignore hotkey when running AAF animation
        Return
    EndIf
    String mapping
    Int index = 0
    While (index < _registeredKeys.Length)
        If (keyCode == _registeredKeys[index])
            mapping = _registeredKeysMappings[index]
            HandleMappedKey(mapping)
            Return
        EndIf
        index += 1
    EndWhile
EndEvent

;
; The actual logic of the mapped key event handler.
;
Function HandleMappedKey(String mapping)
    If (mapping == "Pipboy")
        If (!_inputLayer.IsMenuEnabled())
            Actor maybeDoingFavor = LL_FourPlay.LastCrossHairActor()
            If (maybeDoingFavor != None && maybeDoingFavor.IsBoundGameObjectAvailable() && !maybeDoingFavor.IsDead() && maybeDoingFavor.IsDoingFavor())
                ; stop command mode, otherwise it is impossible to exit command mode while menu is disabled
                ; as the game suppresses all actions for the menu key, not just opening the menu
                maybeDoingFavor.SetDoingFavor(false, false)
            Else
                _handsBoundBehindBackRestraint.PipboyPreventedInteraction()
            EndIf
        EndIf
    ElseIf (mapping == "QuickInventory")
        If (!_inputLayer.IsMenuEnabled())
            _handsBoundBehindBackRestraint.PipboyPreventedInteraction()
        EndIf
    Else
        Int quickkeyIndex = GetQuickkeyIndex(mapping)
        If (quickkeyIndex > 0)
            Form favoriteItem = FavoritesManager.GetFavorites()[quickkeyIndex - 1]
            If (favoriteItem != None)
                If (_inputLayer.IsFavoritesEnabled())
                    LastQuickKeyRealTime = Utility.GetCurrentRealTime()
                    LastQuickKeyItem = favoriteItem
                Else
                    _handsBoundBehindBackRestraint.QuickkeyPreventedInteraction(favoriteItem)
                EndIf
            EndIf
        EndIf
    EndIf
EndFunction

;
; Temporarily hide the restraints, for example to prevent the player from selling them in barter menu.
;
Function HideRestraints()
    If (_hiddenRestraintsContainer == None)
        _hiddenRestraintsContainer = Target.PlaceAtMe(Library.Resources.InvisibleContainer, 1, false, true, true)
        Int index = 0
        While (index < Restraints.Length)
            RealHandcuffs:RestraintBase restraint = Restraints[index]
            Form baseObject = restraint.GetBaseObject()
            Armor dummyObject = restraint.GetDummyObject()
            Target.UnequipItem(baseObject, false, true)
            Target.EquipItem(dummyObject, false, true)
            Target.RemoveItem(restraint, 1, true, _hiddenRestraintsContainer)
            index += 1
        EndWhile
    EndIf
EndFunction

;
; Restore the temporarily hidden restraints.
;
Function UnhideRestraints()
    If (_hiddenRestraintsContainer != None)
        ObjectReference hiddenRestraintsContainer = _hiddenRestraintsContainer
        _hiddenRestraintsContainer = None
        Int index = 0
        While (index < Restraints.Length)
            ObjectReference restraint = Restraints[index]
            Form baseObject = restraint.GetBaseObject()
            Int count = Target.GetItemCount(baseObject)
            If (count == 0)
                Target.AddItem(restraint, 1, true)
                Target.EquipItem(baseObject, false, true)
            Else
                ; equipping can only be done by object reference, so we need to take extra steps to make sure
                ; that this reference is equipped and not another one if there are others in the inventory
                Target.RemoveItem(baseObject, count, true, _hiddenRestraintsContainer)
                Target.AddItem(restraint, 1, true)
                Target.EquipItem(baseObject, false, true)
                _hiddenRestraintsContainer.RemoveItem(baseObject, count, true, Target)
            EndIf
            index += 1
        EndWhile
        hiddenRestraintsContainer.Delete()
        Target.RemoveItem(Dummy, 999, true, None)
    EndIf
EndFunction

;
; Event handler called when items are taken from a container.
;
Event ObjectReference.OnItemAdded(ObjectReference sender, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
    If (_searchedContainer == None)
        If (akSourceContainer == None || akSourceContainer.GetBaseObject() == Library.Resources.InvisibleContainer)
            Return
        EndIf
        _searchedContainer = akSourceContainer
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Detected container: " + _searchedContainer.GetDisplayName() + " " + RealHandcuffs:Log.FormIdAsString(_searchedContainer), Library.Settings)
        EndIf
        Actor sourceActor = akSourceContainer as Actor
        If (sourceActor != None && sourceActor.GetItemCount(Library.Resources.Restraint) > 0)
            Library.GetOrCreateActorToken(sourceActor) ; the token will observe OnItemEquipped, it is more reliable than OnEquipped
        EndIf
    EndIf
    If (akSourceContainer == _searchedContainer)
        If (akBaseItem.HasKeyword(Library.Resources.Restraint))
            If (akItemReference == None && !Target.IsEquipped(akBaseItem))
                ObjectReference ref = Target.DropObject(akBaseItem, 1) ; force the game to create a reference, this will improve odds of seeing it in OnItemEquipped
                Target.AddItem(ref, 1, true)
            EndIf
        EndIf
        If (_handsBoundBehindBackRestraint != None)
            Actor sourceAsActor = akSourceContainer as Actor
            If (sourceAsActor != None && !sourceAsActor.IsDead() && !Library.SoftDependencies.IsArmorRack(sourceAsActor) && !Library.GetHandsBoundBehindBack(sourceAsActor))
                ; allow trade with another actor who is not bound and can therefore help (follower, settler)
                Return
            EndIf
            If (Library.TrySetInteractionType(Library.InteractionTypeContainer, akSourceContainer, 0))
                ObjectReference temporaryContainer = Target.PlaceAtMe(Library.Resources.InvisibleContainer, 1, false, true, true)
                Target.RemoveItem(akBaseItem, aiItemCount, true, temporaryContainer)
                Bool shouldBeAllowed = (akBaseItem as Key) != None || temporaryContainer.GetItemCount(VendorItemKey) > 0 || temporaryContainer.GetItemCount(RhKey) > 0 || BoundHandsTakeItemList.HasForm(akBaseItem) || temporaryContainer.GetItemCount(ActivateWithBoundHands) > 0
                _handsBoundBehindBackRestraint.TakeItemFromContainerPreventedInteraction(akBaseItem, akSourceContainer, temporaryContainer, shouldBeAllowed)
                Int itemCount = temporaryContainer.GetItemCount(None)
                If (itemCount > 0)
                    temporaryContainer.RemoveItem(akBaseItem, itemCount, true, akSourceContainer)
                    If (temporaryContainer.GetItemCount(None) > 0) ; not expected, fallback code
                        temporaryContainer.RemoveAllItems(akSourceContainer, true)
                    EndIf
                    akSourceContainer.AddItem(Library.Resources.BobbyPin, 1, true)
                    akSourceContainer.RemoveItem(Library.Resources.BobbyPin, 1, true, None)
                EndIf
                temporaryContainer.Delete()
                Library.ClearInteractionType()
            Else
                ; player was taking whole container content, revert all changes
                Target.RemoveItem(akBaseItem, aiItemCount, false, akSourceContainer)
                akSourceContainer.AddItem(Library.Resources.BobbyPin, 1, true)
                akSourceContainer.RemoveItem(Library.Resources.BobbyPin, 1, true, None)
            EndIf
        EndIf
    EndIf
EndEvent

;
; Event handler called when items are put into a container.
;
Event ObjectReference.OnItemRemoved(ObjectReference sender, Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akDestContainer)
    If (_searchedContainer == None) ; fallback in case the perks do not take effect
        If (akDestContainer == None || akDestContainer.GetBaseObject() == Library.Resources.InvisibleContainer)
            Return
        EndIf
        _searchedContainer = akDestContainer
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Detected container: " + _searchedContainer.GetDisplayName() + " " + RealHandcuffs:Log.FormIdAsString(_searchedContainer), Library.Settings)
        EndIf
        Actor destActor = akDestContainer as Actor
        If (destActor != None && destActor.GetItemCount(Library.Resources.Restraint) > 0)
            Library.GetOrCreateActorToken(destActor) ; the token will observe OnItemEquipped, it is more reliable than OnEquipped
        EndIf
    EndIf
    If (akDestContainer == _searchedContainer)
        Actor destActor = akDestContainer as Actor
        If (destActor != None && akBaseItem.HasKeyword(Library.Resources.Restraint))
            If (akItemReference == None && !destActor.IsEquipped(akBaseItem))
                ObjectReference ref = destActor.DropObject(akBaseItem, 1) ; force the game to create a reference, this will improve odds of seeing it in OnItemEquipped
                destActor.AddItem(ref, 1, true)
            EndIf
            Library.GetOrCreateActorToken(destActor) ; the token will observe OnItemEquipped, it is more reliable than OnEquipped
        EndIf
        If (_handsBoundBehindBackRestraint != None)
            Actor sourceAsActor = akDestContainer as Actor
            If (sourceAsActor != None && !sourceAsActor.IsDead() && !Library.SoftDependencies.IsArmorRack(sourceAsActor) && !Library.GetHandsBoundBehindBack(sourceAsActor))
                ; allow trade with another actor who is not bound and can therefore help (follower, settler)
                Return
            EndIf
            If (Library.TrySetInteractionType(Library.InteractionTypeContainer, akDestContainer, 0))
                ObjectReference temporaryContainer = Target.PlaceAtMe(Library.Resources.InvisibleContainer, 1, false, true, true)
                akDestContainer.RemoveItem(akBaseItem, aiItemCount, true, temporaryContainer)
                Bool shouldBeAllowed = (akBaseItem as Key) != None || temporaryContainer.GetItemCount(VendorItemKey) > 0 || temporaryContainer.GetItemCount(RhKey) > 0 || BoundHandsTakeItemList.HasForm(akBaseItem) || temporaryContainer.GetItemCount(ActivateWithBoundHands) > 0
                _handsBoundBehindBackRestraint.PutItemIntoContainerPreventedInteraction(akBaseItem, akDestContainer, temporaryContainer, shouldBeAllowed)
                Int itemCount = temporaryContainer.GetItemCount(None)
                If (itemCount > 0)
                    temporaryContainer.RemoveItem(akBaseItem, itemCount, true, Target)
                    If (temporaryContainer.GetItemCount(None) > 0) ; not expected, fallback code
                        temporaryContainer.RemoveAllItems(Target, true)
                    EndIf
                    Target.AddItem(Library.Resources.BobbyPin, 1, true)
                    Target.RemoveItem(Library.Resources.BobbyPin, 1, true, None)
                EndIf
                temporaryContainer.Delete()
                Library.ClearInteractionType()
            Else
                ; player was putting all items, revert all changes
                akDestContainer.RemoveItem(akBaseItem, aiItemCount, false, Target)
                Target.AddItem(Library.Resources.BobbyPin, 1, true)
                Target.RemoveItem(Library.Resources.BobbyPin, 1, true, None)
            EndIf
        EndIf
    EndIf
EndEvent

;
; Event handler for entering furniture.
;
Event Actor.OnSit(Actor sender, ObjectReference akFurniture)
    UnhideRestraints() ; may do nothing
EndEvent

;
; Event handler for exiting furniture.
;
Event Actor.OnGetUp(Actor sender, ObjectReference akFurniture)
    UnhideRestraints() ; may do nothing
EndEvent

;
; React if activation of something has been blocked by one of 'cant use' perks.
;
Function HandleActivationBlocked(RealHandcuffs:BlockActivationPerk triggeringPerk, ObjectReference ref, Int entryAction, Int entryData)
    If (entryAction == triggeringPerk.OpenLock)
        Form baseObject = ref.GetBaseObject()
        If ((baseObject as Container) != None)
            ; trying to open a container
            _handsBoundBehindBackRestraint.OpenContainerPreventedInteraction(ref, entryData)
        ElseIf ((baseObject as Door) != None)
            ; trying to open a door
            _handsBoundBehindBackRestraint.OpenDoorPreventedInteraction(ref, entryData)
        EndIf
    ElseIf (entryAction == triggeringPerk.DisarmTrap)
        _handsBoundBehindBackRestraint.DisarmTrapPreventedInteraction(ref, entryData == 1)
    ElseIf (entryAction == triggeringPerk.UseOrActivate)
        _handsBoundBehindBackRestraint.ActivateFurniturePreventedInteraction(ref, entryData == 1)
    ElseIf (entryAction == triggeringPerk.Harvest)
        _handsBoundBehindBackRestraint.ActivateFurniturePreventedInteraction(ref, entryData == 1)
    ElseIf (entryAction == triggeringPerk.PickPocket)
        _handsBoundBehindBackRestraint.PickPocketsPreventedInteraction(ref, entryData == 1)
    ElseIf (entryAction == triggeringPerk.EnterPowerArmor)
        _handsBoundBehindBackRestraint.ActivateFurniturePreventedInteraction(ref, entryData == 1)
    ElseIf (entryAction == triggeringPerk.Sleep)
        Int index = 0
        While (index < Restraints.Length)
            RealHandcuffs:ShockCollarBase collar = Restraints[index] as RealHandcuffs:ShockCollarBase
            If (collar != None && collar.GetTortureModeFrequency() < 1.0)
                collar.ActivateFurniturePreventedInteraction(ref, false)
                Return
            EndIf
            index += 1
        EndWhile
    ElseIf (entryAction == triggeringPerk.SearchContainer)
        If (entryData == 0)
            _handsBoundBehindBackRestraint.OpenContainerPreventedInteraction(ref, 0)
        Else
            _searchedContainer = ref
            ref.Activate(Game.GetPlayer(), false)
        EndIf
    ElseIf (entryAction == triggeringPerk.UseTools)
        _handsBoundBehindBackRestraint.UseToolsInteraction(ref)
    ElseIf (entryAction == triggeringPerk.TakeObject)
        _handsBoundBehindBackRestraint.TakeItemPreventedInteraction(ref, entryData == 1)
    ElseIf (entryAction == triggeringPerk.EatObject)
        _handsBoundBehindBackRestraint.EatItemInteraction(ref)
    ElseIf (entryAction == triggeringPerk.DrinkOpenWater)
        _handsBoundBehindBackRestraint.DrinkOpenWaterInteraction(ref)
    Else
        RealHandcuffs:Log.Warning("Unhandled activation type.", Library.Settings)
    EndIf
EndFunction

;
; React if player activates workshop mode.
;
Event RefCollectionAlias.OnWorkshopMode(RefCollectionAlias rcaSender, ObjectReference sender, bool aStart)
    If (_handsBoundBehindBackRestraint != None)
        RealHandcuffs:Log.Info("Terminating workshop mode.", Library.Settings)
        sender.StartWorkshop(false)
    EndIf
EndEvent

;
; React on token moving between containers.
;
Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
    Actor player = Game.GetPlayer()
    If ((!Uninitialized && !IsBoundGameObjectAvailable()) || akNewContainer != player)
        CheckConsistency(player)
    EndIf
EndEvent

;
; Timer definitions.
;
Group Timers
    Int Property CheckConsistency = 1001 AutoReadOnly
    Int Property StartCheckingWeapon = 1002 AutoReadOnly
EndGroup

;
; Timer event.
;
Event OnTimer(Int aiTimerID)
    If (aiTimerID == CheckConsistency)
        CheckConsistency(Target)
    ElseIf (Target == None)
        Return
    ElseIf (aiTimerID == StartCheckingWeapon)
        If (_handsBoundBehindBackRestraint != None)
            RegisterForAnimationEvent(Target, "weaponDraw")
            If (Target.IsWeaponDrawn())
                CheckConsistency(Target)
            EndIf
        EndIf
    Else
        Parent.OnTimer(aiTimerID)
    EndIf
EndEvent