;
; Contains general functions that make up most of the 'public interface' of the mod.
; Also take a look at RestraintBase, some of the functions there are 'public interface',
; especially ForceEquip() and ForceUnequip().
;
Scriptname RealHandcuffs:Library extends Quest

RealHandcuffs:HandcuffsConverter Property Converter Auto Const Mandatory

GlobalVariable Property CurrentInteractionType Auto Const Mandatory
GlobalVariable Property CurrentInteractionLockLevel Auto Const Mandatory
Keyword Property ActorTypeRobot Auto Const Mandatory
Keyword Property Female Auto Const Mandatory
Keyword Property LinkedActorToken Auto Const Mandatory
Keyword Property LinkedRemoteTriggerTarget Auto Const Mandatory
Keyword Property DeleteWhenUnequipped Auto Const Mandatory
MiscObject Property PlayerTokenObject Auto Const Mandatory
MiscObject Property NpcTokenObject Auto Const Mandatory
Race Property AssaultronRace Auto Const Mandatory
ReferenceAlias Property CurrentInteractionTarget Auto Const Mandatory
ReferenceAlias Property DummySceneTarget Auto Const Mandatory
RefCollectionAlias Property EssentialActors Auto Const Mandatory
RefCollectionAlias Property RemoteTriggerUsers Auto Const Mandatory
RefCollectionAlias Property PrisonerMatActors Auto Const Mandatory
Scene Property DummyScene Auto Const Mandatory
Weapon Property RemoteTrigger Auto Const Mandatory

InputEnableLayer _inputLayer
Form _originalCommandModeActivatePackage
Form _originalCommandModeTravelPackage
Bool _createTokenLock

;
; A 'enum' for the possible impacts of wearing a restraint.
; This might expand in the future to support other kinds of restraints.
;
Group Impacts
    ; Wearing the restraint has no impact
    String Property NoImpact = "NoImpact" AutoReadOnly
    ; Wearing the restraint binds the actors hands behind their back.
    String Property HandsBoundBehindBack = "HandsBoundBehindBack" AutoReadOnly
    ; Wearing the restraint will cause some effect when a remote trigger is fired in the vicinity.
    String Property RemoteTriggerEffect = "RemoteTriggerEffect" AutoReadOnly
EndGroup

;
; Get the current settings of the mod.
;
RealHandcuffs:Settings Property Settings Auto Const Mandatory

;
; Get the resources collection of the mod.
;
RealHandcuffs:Resources Property Resources Auto Const Mandatory

;
; Get the soft dependencies handler of the mod.
;
RealHandcuffs:SoftDependencies Property SoftDependencies Auto Const Mandatory

;
; Get the speech handler of the mod.
;
RealHandcuffs:SpeechHandler Property SpeechHandler Auto Const Mandatory

;
; Get the animation handler of the mod.
;
RealHandcuffs:AnimationHandler Property AnimationHandler Auto Const Mandatory

;
; The ref collection alias containing all restrained NPCs.
;
RefCollectionAlias Property RestrainedNpcs Auto Const Mandatory

;
; This keyword can be used to set up a situation where a bound npc follows another npc (his "owner").
; To achieve this, set the "owner" as a linked reference on the bound npc using this keyword.
;
Keyword Property LinkedOwner Auto Const Mandatory

;
; This keyword can be used to tell the framework that the player is not allowed to equip or unequip restraints.
; If put on a restraint, it will prevent the player from equipping or unequipping that restraint.
; If put on an actor, it will prevent the player from equipping or unequipping restraints on that actor.
; This works both for the player character and for NPCs.
;
Keyword Property BlockPlayerEquipUnequip Auto Const Mandatory

;
; Custom event sent when a restraint is applied to a character.
; akArgs[0]: Actor, akArgs[1]: Restraint
;
CustomEvent OnRestraintApplied

;
; Custom event sent when a restraint is unapplied from a character.
; akArgs[0]: Actor, akArgs[1]: Restraint
;
CustomEvent OnRestraintUnapplied

;
; Custom event sent when a restraint is triggered
; akArgs[0]: Actor, akArgs[1]: Restraint
;
CustomEvent OnRestraintTriggered

;
; Get the restraints currently worn by an actor.
;
RealHandcuffs:RestraintBase[] Function GetWornRestraints(Actor target)
    If (target != None)
        ActorToken token = target.GetLinkedRef(LinkedActorToken) as RealHandcuffs:ActorToken
        If (token != None)
            Return token.Restraints
        EndIf
    EndIf
    Return new RealHandcuffs:RestraintBase[0]    
EndFunction

;
; Check if the hands of an actor are bound behind their back.
;
Bool Function GetHandsBoundBehindBack(Actor target)
    If (target == None)
        Return false
    EndIf
    ActorToken token = target.GetLinkedRef(LinkedActorToken) as RealHandcuffs:ActorToken
    Return token != None && token.GetHandsBoundBehindBack()
EndFunction

;
; Get whether firing a remote trigger in the vicinity of an actor will cause some effect.
;
Bool Function GetRemoteTriggerEffect(Actor target)
    If (target == None)
        Return false
    EndIf
    ActorToken token = target.GetLinkedRef(LinkedActorToken) as RealHandcuffs:ActorToken
    Return token != None && token.GetRemoteTriggerEffect()
EndFunction


;
; Try to get the ActorToken for an Actor, will return None if the actor does not have a token.
;
RealHandcuffs:ActorToken Function TryGetActorToken(Actor target)
    If (target == None || target.IsDead() || SoftDependencies.IsArmorRack(target))
        Return None
    EndIf
    RealHandcuffs:ActorToken token = target.GetLinkedRef(LinkedActorToken) as RealHandcuffs:ActorToken
    If (token != None && token.Uninitialized)
        target.SetLinkedRef(None, LinkedActorToken)
        token = None
    EndIf
    Return token
EndFunction

;
; Get the ActorToken for an actor, will create one if the actor does not have a token.
; This can still return None, e.g. if the actor is dead or an armor rack.
;
RealHandcuffs:ActorToken Function GetOrCreateActorToken(Actor target)
    If (target == None || target.IsDead() || SoftDependencies.IsArmorRack(target))
        Return None
    EndIf
    RealHandcuffs:ActorToken token = target.GetLinkedRef(LinkedActorToken) as RealHandcuffs:ActorToken
    If (token != None && token.Uninitialized)
        target.SetLinkedRef(None, LinkedActorToken)
        token = None
    EndIf
    If (token == None)
        MiscObject tokenObject
        Actor player = Game.GetPlayer()
        If (target == player)
            tokenObject = PlayerTokenObject
        Else
            tokenObject = NpcTokenObject
        EndIf
        token = player.PlaceAtMe(tokenObject, 1, true, true, false) as RealHandcuffs:ActorToken ; force persistent reference
        token.EnableNoWait()
        token.Initialize(target)
        Int waitCount = 50 ; prevent endless wait in case of stuck lock
        While (_createTokenLock && waitCount >= 0)
            target.GetPropertyValue("X") ; yield by calling latent function
            waitCount -= 1
        EndWhile
        _createTokenLock = true
        RealHandcuffs:ActorToken concurrentToken = target.GetLinkedRef(LinkedActorToken) as RealHandcuffs:ActorToken
        If (concurrentToken == None)
            target.SetLinkedRef(token, LinkedActorToken)
            _createTokenLock = false
            If (Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Created token for " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + ".", Settings)
            EndIf
        Else
            _createTokenLock = false
            RealHandcuffs:Log.Info("Destroying concurrently created token for " + RealHandcuffs:Log.FormIdAsString(Target) + " " + Target.GetDisplayName() + ".", Settings)
            token.Uninitialize()
            token = concurrentToken
        EndIf
    EndIf
    Return token
EndFunction

;
; Check if an actor is female.
;
Bool Function IsFemale(Actor target)
    If (target.HasKeyword(ActorTypeRobot))
        Race targetRace = target.GetRace()
        If (targetRace == AssaultronRace)
            Return true
        EndIf
    Else
        ActorBase targetActorBase = target.GetLeveledActorBase()
        If (targetActorBase != None)
            Return targetActorBase.GetSex() != 0
        EndIf
        targetActorBase = target.GetActorBase()
        If (targetActorBase != None)
            Return targetActorBase.GetSex() != 0
        EndIf
    EndIf
    Return target.HasKeyword(Female)
EndFunction

;
; Check if a object mod is adding a keyword
;
Bool Function IsAddingKeyword(ObjectMod mod, Keyword targetKeyword)
    ObjectMod:PropertyModifier[] modifiers = mod.GetPropertyModifiers()
    Int index = 0
    While (index < modifiers.length)
        ObjectMod:PropertyModifier modifier = modifiers[index]
        If (modifier.operator == mod.Modifier_Operator_Add)
            Keyword kw = modifier.object as Keyword
            If (kw == targetKeyword)
                Return true
            EndIf
        EndIf
        index += 1
    EndWhile
    Return false
EndFunction

;
; A 'enum' for different types of user interactions. Used to check if a user interaction is currently running,
; and to facilitate setting up conditions in creation kit.
; DEVELOPER NOTE: The values must match the definitions of the RH_* constant globals.
;
Group InteractionTypes
    ; Interactions with doors (e.g. trying to unlock the door with bound hands).
    Int Property InteractionTypeDoor = 1 AutoReadOnly
    ; Interactions with furniture (e.g. trying to use the furniture with bound hands).
    Int Property InteractionTypeFurniture = 2 AutoReadOnly
    ; Interactions with NPCs (e.g. trying to bind the hands of an npc).
    Int Property InteractionTypeNpc = 3 AutoReadOnly
    ; Interactions with objects (e.g. trying to pick up an object with bound hands).
    Int Property InteractionTypeObject = 4 AutoReadOnly
    ; Interactions the player has with themselves (e.g. trying to get rid of bounds).
    Int Property InteractionTypePlayer = 5 AutoReadOnly
    ; Interactions the player has with containers (e.g. trying to loot containers).
    Int Property InteractionTypeContainer = 6 AutoReadOnly
EndGroup

;
; Get the current interation type, 0 if no interaction is running.
;
Int Function GetInteractionType()
    Return CurrentInteractionType.GetValueInt()
EndFunction

;
; Get the current interaction target, None if no interaction is running.
;
ObjectReference Function GetInteractionTarget()
    Return CurrentInteractionTarget.GetReference()
EndFunction

;
; Get the lock level of the current interaction target, 0 if no interaction is running.
;
Int Function GetInteractionLockLevel()
    Return CurrentInteractionLockLevel.GetValueInt()
EndFunction

;
; Set the interaction type and target if no interaction is running. Return true if something was modified, false otherwise.
;
Bool Function TrySetInteractionType(Int value, ObjectReference target, Int interactionLockLevel = 0)
    If (CurrentInteractionType.GetValueInt() != 0)
        Return False
    EndIf
    If (value != 0)
        CurrentInteractionType.SetValueInt(value)
        CurrentInteractionTarget.ForceRefTo(target)
        CurrentInteractionLockLevel.SetValueInt(interactionLockLevel)
        _inputLayer = InputEnableLayer.Create()
        _inputLayer.DisablePlayerControls(true, true, false, false, true, true, true, true, true, true, true)
    EndIf
    Return True
EndFunction

;
; Set the current interaction type and target, such that no interaction is running.
;
Function ClearInteractionType()
    CurrentInteractionType.SetValueInt(0)
    CurrentInteractionTarget.Clear()
    CurrentInteractionLockLevel.SetValueInt(0)
    If (_inputLayer != None)
        _inputLayer.Delete()
        _inputLayer = None
    EndIf
EndFunction

;
; A helper function checking if the player has the skill to pick a lock.
;
Bool Function HasPlayerLockpickingSkill(Int lockLevel = -1)
    If (lockLevel < 0)
        lockLevel = CurrentInteractionLockLevel.GetValueInt()
    EndIf
    If (lockLevel <= 25)
        Return True
    EndIf
    If (lockLevel <= 50 && Game.GetPlayer().HasPerk(Resources.Locksmith01))
        Return True
    EndIf
    If (lockLevel <= 75 && Game.GetPlayer().HasPerk(Resources.Locksmith02))
        Return True
    EndIf
    If (lockLevel <= 100 && Game.GetPlayer().HasPerk(Resources.Locksmith03))
        Return True
    EndIf
    Return False
EndFunction

;
; A helper function running an interactive lockpicking interaction with the player. Returns if the lock was picked, false otherwise.
;
Bool Function RunPlayerLockpickInteraction(Int lockLevel = -1)
    If (lockLevel < 0)
        lockLevel = CurrentInteractionLockLevel.GetValueInt()
    EndIf
    Actor player = Game.GetPlayer()
    If (player.GetItemCount(Resources.BobbyPin) == 0)
        Return false
    EndIf
    ObjectReference invisibleDoor = player.PlaceAtMe(Resources.InvisibleDoor, 1, false, true, true)
    invisibleDoor.EnableNoWait()
    invisibleDoor.SetLockLevel(lockLevel)
    invisibleDoor.Lock(true, false)
    If (UI.IsMenuOpen("PipboyMenu"))
        UI.CloseMenu("PipboyMenu")
    EndIf
    If (UI.IsMenuOpen("ContainerMenu"))
        UI.CloseMenu("ContainerMenu")
    EndIf
    Utility.Wait(0.1)
    invisibleDoor.Activate(player, true)
    Utility.Wait(0.1)
    Bool unlocked = !invisibleDoor.IsLocked()
    invisibleDoor.DisableNoWait()
    invisibleDoor.Delete()
    Return unlocked
EndFunction

;
; Temporarily override the 'command mode activate' package with a custom package.
;
Function OverrideCommandModeActivatePackage(Package overridePackage)
    DefaultObject do = Game.GetForm(0xD153D) as DefaultObject ; editor does not allow DefaultObjects as properties
    Form oldPackage = do.get()
    If (oldPackage != overridePackage)
        If (_originalCommandModeActivatePackage == None)
            _originalCommandModeActivatePackage = oldPackage
        EndIf
        do.Set(overridePackage)
        If (Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Overriding CommandModeActivatePackage_DO: " + RealHandcuffs:Log.FormIdAsString(oldPackage) + " -> " + RealHandcuffs:Log.FormIdAsString(overridePackage), Settings)
        EndIf
    EndIf
EndFunction

;
; Restore the 'command mode activate' package.
;
Function RestoreCommandModeActivatePackage()
    If (_originalCommandModeActivatePackage != None)
        Form originalPackage = _originalCommandModeActivatePackage
        DefaultObject do = Game.GetForm(0xD153D) as DefaultObject ; editor does not allow DefaultObjects as properties
        do.set(originalPackage)
        _originalCommandModeActivatePackage = None
        If (Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Restoring CommandModeActivatePackage_DO: " + RealHandcuffs:Log.FormIdAsString(originalPackage), Settings)
        EndIf
    EndIf
EndFunction

;
; Temporarily override the 'command mode travel' package with a custom package.
;
Function OverrideCommandModeTravelPackage(Package overridePackage)
    DefaultObject do = Game.GetForm(0xD153B) as DefaultObject ; editor does not allow DefaultObjects as properties
    Form oldPackage = do.get()
    If (oldPackage != overridePackage)
        If (_originalCommandModeTravelPackage == None)
            _originalCommandModeTravelPackage = oldPackage
        EndIf
        do.Set(overridePackage)
        If (Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Overriding CommandModeTravelPackage_DO: " + RealHandcuffs:Log.FormIdAsString(oldPackage) + " -> " + RealHandcuffs:Log.FormIdAsString(overridePackage), Settings)
        EndIf
    EndIf
EndFunction

;
; Restore the 'command mode travel' package.
;
Function RestoreCommandModeTravelPackage()
    If (_originalCommandModeTravelPackage != None)
        Form originalPackage = _originalCommandModeTravelPackage
        DefaultObject do = Game.GetForm(0xD153B) as DefaultObject ; editor does not allow DefaultObjects as properties
        do.set(originalPackage)
        _originalCommandModeTravelPackage = None
        If (Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Restoring CommandModeTravelPackage_DO: " + RealHandcuffs:Log.FormIdAsString(originalPackage), Settings)
        EndIf
    EndIf
EndFunction

;
; Runs a "dummy scene" with the actor. This can be used to force-terminate other scenes that are running with the actor.
; The function will return as soon as the dummy scene has been started.
;
Function StartDummyScene(Actor akActor)
    If (Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Starting dummy scene with " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName() + ".", Settings)
    EndIf
    DummySceneTarget.ForceRefTo(akActor)
    DummyScene.ForceStart()
    Var[] akArgs = new Var[1]
    akArgs[0] = akActor
    CallFunctionNoWait("RunDummyScene_Part2", akArgs) ; do not wait for dummy scene to finish
EndFunction

;
; Runs a "dummy scene" with the actor. This can be used to force-terminate other scenes that are running with the actor.
; The function will block until the dummy scene is over. This should take about one second. 
;
Function RunDummyScene(Actor akActor)
    StartDummyScene(akActor)
    RunDummyScene_Part2(akActor)
EndFunction
    
;
; Internal function for dummy scene, do not call externally.
;
Function RunDummyScene_Part2(Actor akActor)
    Int waitCount = 0
    While (DummySceneTarget.GetReference() == akActor && DummyScene.IsPlaying() && waitCount < 30)
        Utility.Wait(0.1)
    EndWhile
    If (DummySceneTarget.GetReference() == akActor && DummyScene.IsPlaying())
        RealHandcuffs:Log.Warning("Force-stopping dummy scene.", Settings)
        DummyScene.Stop()
    EndIf
    If (DummySceneTarget.GetReference() == akActor)
        DummySceneTarget.Clear()
    EndIf
    If (Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Dummy scene with " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName() + " has ended.", Settings)
    EndIf
EndFunction

;
; Make an actor fire the remote trigger, aiming it at the specified target. This function will block until the action has finished.
; The actor need to actually have a remote trigger in the inventory.
;
Bool Function FireRemoteTrigger(Actor akActor, Actor target, Int numberOfTimes)
    If (Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Firing remote trigger " + numberOfTimes + " times: " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName() + " aiming at " + RealHandcuffs:Log.FormIdAsString(target) + " " + target.GetDisplayName() + ".", Settings)
    EndIf
    Bool exitFurniture = akActor.GetFurnitureReference() != None
    Weapon equippedWeapon = akActor.GetEquippedWeapon()
    Bool waitForSwitchOrDraw = equippedWeapon != RemoteTrigger
    If (waitForSwitchOrDraw)
        akActor.EquipItem(RemoteTrigger, true, true)
    EndIf
    waitForSwitchOrDraw = waitForSwitchOrDraw || !akActor.isWeaponDrawn()
    akActor.SetLinkedRef(target, LinkedRemoteTriggerTarget)
    RemoteTriggerUsers.AddRef(akActor)
    akActor.EvaluatePackage(false)
    If (exitFurniture)
        akActor.PlayIdleAction(Resources.ActionInteractionExitQuick)
        Utility.Wait(0.8)
    EndIf
    If (waitForSwitchOrDraw)
        Utility.Wait(0.75)
    EndIf
    Int count = 0
    While (count < numberOfTimes)
        akActor.PlayIdleAction(Resources.ActionFireSingle)
        Utility.Wait(0.3)
        count += 1
    EndWhile
    RemoteTriggerUsers.RemoveRef(akActor)
    akActor.SetLinkedRef(None, LinkedRemoteTriggerTarget)
    akActor.EvaluatePackage(false)
    If (equippedWeapon != RemoteTrigger)
        akActor.UnequipItem(RemoteTrigger, true, true)
        If (equippedWeapon != None)
            akActor.EquipItem(equippedWeapon, akActor.IsPlayerTeammate(), true)
        EndIf
    EndIf
    Return true
EndFunction

;
; Zap the target actor with the default shock effect.
;
Function ZapWithDefaultShock(Actor target, Actor source = None)
    If (Settings.ShockLethality == 2)
        If (source == None)
            Resources.DefaultShockSpellNonLethal.Cast(target, target)
        Else
            Resources.DefaultShockSpellNonLethal.RemoteCast(target, source, target)
        EndIf
    Else
        If (source == None)
            Resources.DefaultShockSpell.Cast(target, target)
        Else
            Resources.DefaultShockSpell.RemoteCast(target, source, target)
        EndIf
    EndIf
    SpeechHandler.SayPainTopic(target)
EndFunction

;
; Zap the target actor with the throbbing shock effect.
;
Function ZapWithThrobbingShock(Actor target, Actor source = None)
    If (Settings.ShockLethality == 2)
        If (source == None)
            Resources.ThrobbingShockSpellNonLethal.Cast(target, target)
        Else
            Resources.ThrobbingShockSpellNonLethal.RemoteCast(target, source, target)
        EndIf
    Else
        If (source == None)
            Resources.ThrobbingShockSpell.Cast(target, target)
        Else
            Resources.ThrobbingShockSpell.RemoteCast(target, source, target)
        EndIf
    EndIf
    SpeechHandler.SayPainTopic(target)
EndFunction