;
; Script for prisoner mat furniture.
; This may or may not be a workshop object; if it is a workshop object, it also needs to have PrisonerMatWorkshopObjectScript.
;
Scriptname RealHandcuffs:PrisonerMat extends RealHandcuffs:WaitMarkerBase

; the temporary restraints to create for the victim if it is not restrained
Armor Property TemporaryBonds Auto Const Mandatory

; a decorator shown when the temporary restraints are not in use
Static Property Decorator Auto Const
Float Property DecoratorOffsetX Auto Const
Float Property DecoratorOffsetY Auto Const
Float Property DecoratorOffsetZ Auto Const
Float Property DecoratorAngle Auto Const

; a marker to show in edit mode
Static Property Marker Auto Const

ObjectReference _decorator
ObjectReference _marker
WorkshopNPCScript _assignedActor

;
; Event handler called when the furniture is "used".
;
Event OnActivate(ObjectReference akActionRef)
    Actor target = akActionRef as Actor
    If (target != None)
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info(RealHandcuffs:Log.FormIdAsString(target) + " " + target.GetDisplayName() + " activated prisoner mat.", Library.Settings)
        EndIf
        If (target == Game.GetPlayer())
            Activate(target, true) ; kick player out of furniture
            ; player is not supported for now
        Else
            SetDestroyed(true) ; prevent further activations while this activation is being processed
            Actor registeredActor = GetRegisteredActor()
            If (target == registeredActor)
                MoveIntoPosition(target) ; kick NPC out of furniture
                If (Animation != "")
                    Var[] akArgs = new Var[3]
                    akArgs[0] = target
                    akArgs[1] = Animation
                    akArgs[2] = true
                    CallFunctionNoWait("StartAnimationAndWait", akArgs)
                ElseIf (!DisablePoseInteraction)
                    target.AddKeyword(Library.Resources.Posable)
                EndIf
            Else
                If (target != _assignedActor)
                    ; most probably the actor is a follower commanded to activate the prisoner mat ("sit")
                    ; abort the currently command by running the dummy scene
                    ; this is very heavy-handed but I did not find another way to abort the current command
                    Library.StartDummyScene(target)
                EndIf
                MoveIntoPosition(target) ; kick NPC out of furniture
                If (registeredActor == None)
                    If (Register(target))
                        WorkshopObjectScript workshopObject = (Self as ObjectReference) as WorkshopObjectScript ; both scripts are attached to the same object
                        If (Library.Settings.AutoAssignPrisonerMatUsers && workshopObject != None && workshopObject.workshopID >= 0)
                            RealHandcuffs:NPCToken token = Library.TryGetActorToken(target) as RealHandcuffs:NPCToken
                            If (token != None) ; not expected but check to be safe
                                RealHandcuffs:Log.Info("Auto-assigning " + RealHandcuffs:Log.FormIdAsString(target) + " " + target.GetDisplayName() + " to workshop.", Library.Settings)
                                token.AssignToWorkshop(workshopObject.workshopID, workshopObject)
                            EndIf
                        EndIf
                    EndIf
                ElseIf (registeredActor != _assignedActor)
                    ; only replace currently registered actor if it is not the assigned actor
                    Unregister(registeredActor)
                    Register(target)
                EndIf
            EndIf
            SetDestroyed(false) ; allow activations again
        EndIf
    EndIf
EndEvent

;
; Override: Register an actor with this marker.
;
Bool Function Register(Actor akActor)
    If (!Library.GetHandsBoundBehindBack(akActor))
        EquipTemporaryRestraint(akActor)
    EndIf
    If (!Parent.Register(akActor))
        UnequipTemporaryRestraint(akActor)
        Return false
    EndIf
    If (Library.Settings.InfoLoggingEnabled)
        RealHandcuffs:Log.Info("Registered " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName() + " with prisoner mat.", Library.Settings)
    EndIf
    RegisterForCustomEvent(Library, "OnRestraintUnapplied")
    Return true
EndFunction

;
; Override: Unregister the registered actor from the marker.
;
Function Unregister(Actor akActor)
    Bool isRegistered = (akActor == GetRegisteredActor())
    Parent.Unregister(akActor)
    If (isRegistered )
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("Unregistered " + RealHandcuffs:Log.FormIdAsString(akActor) + " " + akActor.GetDisplayName() + " from prisoner mat.", Library.Settings)
        EndIf
        CancelTimer(UpdateRegisteredActorRestraint) ; may do nothing
        UnregisterForCustomEvent(Library, "OnRestraintUnapplied")
        UnequipTemporaryRestraint(akActor)
    EndIf
EndFunction

;
; Override: Fix position and animation of the registered actor.
;
Function FixPositionAndAnimation()
    If (_assignedActor != None && GetRegisteredActor() == None && _assignedActor.GetLinkedRef(Library.Resources.WaitMarkerLink) == None)
        SetLinkedRef(_assignedActor, Library.Resources.WaitMarkerLink)
        _assignedActor.SetLinkedRef(Self, Library.Resources.WaitMarkerLink)
        RegisterForRemoteEvent(_assignedActor, "OnCommandModeEnter")
        If (Animation != "")
            StartAnimationAndWait(_assignedActor, Animation, false) ; do not play enter animation
        ElseIf (!DisablePoseInteraction)
            _assignedActor.AddKeyword(Library.Resources.Posable)
        EndIf
    EndIf
    Parent.FixPositionAndAnimation()
EndFunction

;
; Event handler for menu open/close, used to show/hide marker.
;
Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    If (asMenuName == "WorkshopMenu" && _marker)
        If (abOpening)
            _marker.EnableNoWait()
        Else
            _marker.DisableNoWait()
        EndIf
    EndIf
EndEvent

;
; Event called when a restraint is unapplied.
;
Event RealHandcuffs:Library.OnRestraintUnapplied(Library akSender, Var[] akArgs)
    Actor registeredActor = GetRegisteredActor()
    If (registeredActor == None)
        ; not expected, fallback
        UnregisterForCustomEvent(Library, "OnRestraintUnapplied")
    ElseIf (registeredActor == (akArgs[0] as Actor))
        StartTimer(0.1, UpdateRegisteredActorRestraint) ; do this in a timer in case a menu is open
    EndIf
EndEvent

;
; Event called when assigned actor is commanded by player.
;
Event Actor.OnCommandModeGiveCommand(Actor sender, int aeCommandType, ObjectReference akTarget)
    WorkshopObjectScript workshopObject = (Self as ObjectReference) as WorkshopObjectScript
    If (sender != _assignedActor)
        ; not expected, fallback
        UnregisterForRemoteEvent(sender, "OnCommandModeGiveCommand")
    ElseIf (workshopObject != None && aeCommandType == 10 && akTarget != Self) ; 10: Workshop Assign
        ; unassign when player assigns to different workshop item, unless it is a bed
        Int workshopId = _assignedActor.GetWorkshopID()
        If (workshopId >= 0)
            WorkshopScript workshop = workshopObject.WorkshopParent.GetWorkshop(workshopId)
            WorkshopObjectScript newWorkshopItem = akTarget as WorkshopObjectScript
            If (workshop != None && workshopId == workshop.GetWorkshopID() && newWorkshopItem != None && !newWorkshopItem.IsBed())
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Unassigning " + RealHandcuffs:Log.FormIdAsString(_assignedActor) + " " + _assignedActor.GetDisplayName() + " from prisoner mat after player assigned to different work item.", Library.Settings)
                EndIf
                ; Use WS / UFO4P function if it exists, and fail if it does not exist.
                ; function UnassignActorFromObjectPUBLIC(WorkshopNPCScript theActor, WorkshopObjectScript theObject, bool bSendUnassignEvent = true, bool bTryToAssignResources = true)
                Var[] kArgs = new Var[4]
                kArgs[0] = _assignedActor
                kArgs[1] = workshopObject
                kArgs[2] = true
                kArgs[3] = false
                workshopObject.WorkshopParent.CallFunction("UnassignActorFromObjectPUBLIC", kArgs)
            EndIf
        EndIf
    EndIf
EndEvent

;
; Equip a temporary restraint on an actor.
;
Function EquipTemporaryRestraint(Actor target)
    ObjectReference spawnedObject = Game.GetPlayer().PlaceAtMe(TemporaryBonds, 1, false, true, false)
    RealHandcuffs:RestraintBase restraint = spawnedObject as RealHandcuffs:RestraintBase
    If (restraint == None || restraint.GetImpact() != Library.HandsBoundBehindBack)
        RealHandcuffs:Log.Error("Temporary spawned restraint is of wrong type.", Library.Settings)
        spawnedObject.Delete()
        Return
    EndIf
    restraint.AddKeyword(Library.DeleteWhenUnequipped)
    restraint.SetLinkedRef(Self, Library.DeleteWhenUnequipped)
    restraint.EnableNoWait()
    target.AddItem(restraint, 1, false)
    restraint.ForceEquip(false)
    If (_decorator != None)
        _decorator.DisableNoWait()
    EndIf
EndFunction

;
; Check if an actor has a temporary restraint equipped
;
Bool Function HasTemporaryRestraint(Actor target)
    RealHandcuffs:RestraintBase[] wornRestraints = Library.GetWornRestraints(target)
    Int index = 0
    While (index < wornRestraints.Length)
        RealHandcuffs:RestraintBase restraint = wornRestraints[index]
        If (restraint.HasKeyword(Library.DeleteWhenUnequipped) && restraint.GetLinkedRef(Library.DeleteWhenUnequipped) == Self)
            Return true
        EndIf
        index += 1
    EndWhile
    Return false
EndFunction

;
; Unequip the temporary restraint from an actor.
;
Function UnequipTemporaryRestraint(Actor target)
    RealHandcuffs:RestraintBase[] restraintsToRemove = new RealHandcuffs:RestraintBase[0]
    RealHandcuffs:RestraintBase[] wornRestraints = Library.GetWornRestraints(target)
    Int index = 0
    While (index < wornRestraints.Length)
        RealHandcuffs:RestraintBase restraint = wornRestraints[index]
        If (restraint.HasKeyword(Library.DeleteWhenUnequipped) && restraint.GetLinkedRef(Library.DeleteWhenUnequipped) == Self)
            restraintsToRemove.Add(restraint)
        EndIf
        index += 1
    EndWhile
    index = 0
    While (index < restraintsToRemove.Length)
        restraintsToRemove[0].ForceUnequip()
        index += 1
    EndWhile
    If (_decorator != None)
        _decorator.EnableNoWait()
    EndIf
EndFunction

;
; Handle creation of the prisoner mat.
;
Function HandleCreation()
    If (Decorator != None)
        _decorator = PlaceAtMe(Decorator, 1, false, true, true)
    EndIf
    If (Marker != None)
        _marker = PlaceAtMe(Marker, 1, false, true, true)
        RegisterForMenuOpenCloseEvent("WorkshopMenu")
    EndIf
    AssignActor(None)
    If (_marker != None || _decorator != None)
        UpdatePosition()
    EndIf
EndFunction

;
; Hide all markers.
;
Function HideMarkers()
    If (_decorator != None)
        _decorator.DisableNoWait()
    EndIf
    If (_marker != None)
        _marker.DisableNoWait()
    EndIf
EndFunction

;
; Update the positon of the prisoner mat.
;
Function UpdatePosition()
    If (_decorator != None)
        Float alpha = 90 - GetAngleZ() ; use math conventions for calculation
        Float sinAlpha = Math.Sin(alpha)
        Float cosAlpha = Math.Cos(alpha)
        Float offsetX = DecoratorOffsetX * cosAlpha - DecoratorOffsetY * sinAlpha
        Float offsetY = DecoratorOffsetX * sinAlpha + DecoratorOffsetY * cosAlpha
        _decorator.MoveTo(Self, offsetX, offsetY, DecoratorOffsetZ, true)
        If (DecoratorAngle != 0.0)
            Float angleX = GetAngleX()
            Float angleY = GetAngleY()
            Float angleZ = 90 - alpha + DecoratorAngle
            _decorator.SetAngle(angleX, angleY, angleZ)
        EndIf
        _decorator.EnableNoWait()
    EndIf
    If (_marker != None)
        MoveIntoPosition(_marker)
        If (UI.IsMenuOpen("WorkshopMenu"))
            _marker.EnableNoWait()
        EndIf
    EndIf
EndFunction

;
; Handle deletion of the prisoner mat.
;
Function HandleDeletion()
    If (_decorator != None)
        _decorator.DisableNoWait()
        _decorator.Delete()
        _decorator = None
    EndIf
    If (_marker != None)
        _marker.DisableNoWait()
        _marker.Delete()
        _marker = None
        UnregisterForMenuOpenCloseEvent("WorkshopMenu")
    EndIf
    AssignActor(None)
    Actor registeredActor = GetRegisteredActor()
    If (registeredActor != None)
        Unregister(registeredActor)
    EndIf
EndFunction

;
; Handle assignment of actor.
;
Function AssignActor(WorkshopNPCScript newActor = None)
    SetDestroyed(true) ; prevent further activations while we are processing this assignment
    WorkshopObjectScript workshopObject = (Self as ObjectReference) as WorkshopObjectScript
    WorkshopNPCScript assignedActor = _assignedActor
    If (assignedActor != None && assignedActor != newActor)
        _assignedActor = None
        If (assignedActor.GetLinkedRef(Library.Resources.PrisonerMatLink) == Self) ; may no longe be true, e.g. if assigned to another prisoner mat
            assignedActor.SetLinkedRef(None, Library.Resources.PrisonerMatLink)
            Library.PrisonerMatActors.RemoveRef(assignedActor)
        EndIf
        UnregisterForRemoteEvent(assignedActor, "OnCommandModeGiveCommand")        
        Actor registeredActor = GetRegisteredActor()
        If (registeredActor == assignedActor)
            Unregister(registeredActor)
        ElseIf (assignedActor.GetLinkedRef(Library.Resources.WaitMarkerLink) == None && assignedActor.GetLinkedRef(Library.Resources.PrisonerMatLink) == None)
            ; fallback to remove posable keyword in case the actor was assigned but never registered
            assignedActor.ResetKeyword(Library.Resources.Posable)
            assignedActor.EvaluatePackage(false)
        EndIf
        RealHandcuffs:NPCToken token = Library.TryGetActorToken(assignedActor) as RealHandcuffs:NPCToken
        If (token != None) ; not expected but check for it
            ; the workshop events are not 100% reliable, so make sure the token knows
            token.HandleUnassignedFromWorkObject(workshopObject)
        EndIf
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info(RealHandcuffs:Log.FormIdAsString(assignedActor) + " " + assignedActor.GetDisplayName() + " unassigned from prisoner mat.", Library.Settings)
        EndIf
    EndIf
    assignedActor = newActor
    If (assignedActor != None)
        _assignedActor = assignedActor
        assignedActor.SetLinkedRef(Self, Library.Resources.PrisonerMatLink)
        Library.PrisonerMatActors.AddRef(assignedActor)
        Actor registeredActor = GetRegisteredActor()
        If (registeredActor != None && registeredActor != assignedActor)
            Unregister(registeredActor)
        EndIf
        RegisterForRemoteEvent(assignedActor, "OnCommandModeGiveCommand")        
        RealHandcuffs:NPCToken token = Library.TryGetActorToken(assignedActor) as RealHandcuffs:NPCToken
        If (token != None) ; may really be true
            ; the workshop events are not 100% reliable, so make sure the token knows
            token.HandleAssignedToWorkObject(workshopObject)
        EndIf
        If (registeredActor != assignedActor)
            If (!DisablePoseInteraction)
                assignedActor.AddKeyword(Library.Resources.Posable) ; do this even before the actor registers
            EndIf
            assignedActor.EvaluatePackage(true)
        EndIf
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info(RealHandcuffs:Log.FormIdAsString(assignedActor) + " " + assignedActor.GetDisplayName() + " assigned to prisoner mat.", Library.Settings)
        EndIf
        CallFunctionNoWait("UnassignFromOtherResources", new Var[0]) ; use NoWait as we are inside a public workshop parent function
    EndIf
    SetDestroyed(false) ; allow activations again
EndFunction

;
; Unassign the assigned actor from all other resources.
;
Function UnassignFromOtherResources()
    WorkshopNPCScript assignedActor = _assignedActor;
    If (assignedActor != None)
        WorkshopObjectScript workshopObject = (Self as ObjectReference) as WorkshopObjectScript
        WorkshopScript workshop = workshopObject.WorkshopParent.GetWorkshop(workshopObject.workshopID)
        ObjectReference[] ownedResourceObjects = workshop.GetWorkshopOwnedObjects(assignedActor)
        Int index = 0
        Int unassignedCount = 0
        While (index < ownedResourceObjects.Length)
            WorkshopObjectScript resourceObject = ownedResourceObjects[index] as WorkshopObjectScript
            If (resourceObject != None && resourceObject != workshopObject)
                ; unassign actor from all other workshop objects when assigned to prisoner mat
                ; Use WS / UFO4P function if it exists, and fail if it does not exist.
                ; function UnassignActorFromObjectPUBLIC(WorkshopNPCScript theActor, WorkshopObjectScript theObject, bool bSendUnassignEvent = true, bool bTryToAssignResources = true)
                Var[] kArgs = new Var[4]
                kArgs[0] = assignedActor
                kArgs[1] = resourceObject
                kArgs[2] = true
                kArgs[3] = true
                workshopObject.WorkshopParent.CallFunction("UnassignActorFromObjectPUBLIC", kArgs)
                unassignedCount += 1
            EndIf
            index += 1
        EndWhile
        If (unassignedCount > 0)
            workshop.RecalculateWorkshopResources(true)
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("Unassigned " + RealHandcuffs:Log.FormIdAsString(assignedActor) + " " + assignedActor.GetDisplayName() + " from " + unassignedCount + " other objects.", Library.Settings)
            EndIf
        EndIf
        If (assignedActor.assignedMultiResource != None)
            If (assignedActor.multiResourceProduction == 0.0)
                assignedActor.SetMultiResource(None)
                RealHandcuffs:Log.Info("Cleared assigned multi resource.", Library.Settings)
            Else
                RealHandcuffs:Log.Info("Unable to clear assigned multi resource.", Library.Settings)
            EndIf
        EndIf
    EndIf
EndFunction

;
; Timer definitions.
;
Group Timers
    Int Property UpdateRegisteredActorRestraint = 1 AutoReadOnly
EndGroup

;
; Timer event.
;
Event OnTimer(Int aiTimerID)
    If (aiTimerID == UpdateRegisteredActorRestraint)
        Actor registeredActor = GetRegisteredActor()
        If (registeredActor != None)
            If (Library.GetHandsBoundBehindBack(registeredActor))
                If (_decorator != None)
                    If (HasTemporaryRestraint(registeredActor))
                        _decorator.DisableNoWait()
                    Else
                        _decorator.EnableNoWait()
                    EndIf
                EndIf
            Else
                EquipTemporaryRestraint(registeredActor)
            EndIf
        EndIf
    EndIf
EndEvent