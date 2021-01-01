Scriptname DefaultCaptiveActor extends Actor

;This script pops a message box when activating the prisoner
;if player frees, adds captors, himself, and prisoner to factions to make people hate each other
;You should make sure elsewhere that the captors have aggression high enough to attack their enemies


Group MainProperties
	bool Property DisableOnUnload = false Auto Const
	{after being freed, this actor will disable when unloaded}
	bool Property AlsoRemoveFromCaptiveFaction = false Auto Const
	{after being freed, this actor will also be removed from the CaptiveFaction
		Use this for actors that will be attacked while fleeing}
	int Property AggressionAfterFreed = -1 Auto Const
	{freed actor will be set with this aggression}
EndGroup

Group SetStageProperties
	Quest Property myQuest Auto
	{ If this is set, set the stage on this quest if StageToSetWhenFreed is not -1
		If myQuest is NOT set, it will try to set the stage on the owning quest}
	int Property StageToSetWhenFreed = -1 auto const
	{ this stage will be set when the prisoner is freed }
	int Property StageToSetOnCleanUp = -1 Auto Const
	{ this stage will be set when we try to clean up the actor }
	bool Property bSetStageOnlyIfPlayerFreed = true auto const
	{ false is always set stage when prisoner is freed }

EndGroup

Group CleanUpProperties
	Float Property CleanUpTime = 180.0 Auto
	{ Timer is started after freeing this prisoner, then once it has expired, clean up is viable when possible}
EndGroup

Group AutoFillProperties
	Keyword Property RESharedDialoguePrisonerSetFree Auto const

	Message Property REPrisonerMessageBox Auto const
	Faction Property BoundCaptiveFaction Auto const
	Faction Property CaptiveFaction Auto Const

	RefCollectionAlias Property Captors Auto const
	{ Try to get this from quest script REScript }
EndGroup



bool bound = True

int iDoNothing = 0
int iSetFree = 1
int iSetFreeShareItems = 2
int CleanupTimerID = 999
bool ReadyToCleanup = false

Event OnInit()
	AddToFaction(BoundCaptiveFaction)
EndEvent

Event OnLoad()
	if bound
		; TODO when we have it
		;playIdle(OffsetBoundStandingStart)

		;DL added this for short term use
		SetRestrained()
		SetFactionRank(BoundCaptiveFaction, 0)
		; begin RealHandcuffs changes
		If (IntegrateHandcuffsInVanillaScenes() && IsEnabled())
			If (_prisonerFurniture != None && _prisonerFurniture.IsBoundGameObjectAvailable() && !_prisonerFurniture.IsDeleted() && !_prisonerFurniture.IsDisabled() && !_prisonerFurniture.IsDestroyed() && _prisonerFurniture.WaitFor3DLoad() && WaitFor3DLoad())
				SnapIntoInteraction(_prisonerFurniture)
			EndIf
			_prisonerFurniture = None
			SetResetNoPackage(false)
			CreateAndEquipHandcuffs()
			ObjectReference currentFurniture = GetFurnitureReference()
			If (IsPrisonerFurniture(currentFurniture) && currentFurniture.WaitFor3DLoad() && WaitFor3DLoad())
				StartPrisonerPose(currentFurniture, false)
			EndIf
		EndIf
		; end RealHandcuffs changes
	EndIf
	RegisterForHitEvent(self, Game.GetPlayer())
EndEvent

Event OnUnload()
	; begin RealHandcuffs changes
	If (bound)
		UnequipAndDestroyHandcuffs()
		SetResetNoPackage(true)
	EndIf
	; end RealHandcuffs changes
	if DisableOnUnload && ReadyToCleanup
		ClearFactions()
		Disable()
		DeleteWhenAble()
	endif
EndEvent

Event OnTimer(int aiTimerID)
	if aiTimerID == CleanupTimerID
		ReadyToCleanup = true
	endif
EndEvent

Event OnActivate(ObjectReference akActionRef)

	if IsDead() || IsinCombat()
		debug.trace(self + "OnActivate() IsDead() or IsInCombat() so not showing message box")	
	
	Elseif Bound == true	
		debug.trace(self + "OnActivate() will call show message box")	
		Actor ActorRef = self

		int result = REPrisonerMessageBox.show()

		if result == iDoNothing
			debug.Notification("DO NOTHING")
			
		elseif result == iSetFree
			debug.Notification("SET FREE")	
			; begin RealHandcuffs changes
			If (!PlayerUnequipHandcuffs())
				Return
			EndIf
			; end RealHandcuffs changes
			FreePrisoner(ActorRef, OpenPrisonerInventory = False)
			
		elseif result == iSetFreeShareItems
			debug.Notification("SET FREE SHARE ITEMS")	
			; begin RealHandcuffs changes
			If (!PlayerUnequipHandcuffs())
				Return
			EndIf
			; end RealHandcuffs changes
			FreePrisoner(ActorRef, OpenPrisonerInventory = True)		
			
		EndIf
	
	EndIf
EndEvent

Event OnHit(ObjectReference akTarget, ObjectReference akAggressor, Form akSource, Projectile akProjectile, bool abPowerAttack, bool abSneakAttack, bool abBashAttack, bool abHitBlocked, string asMaterialName)
	if AkAggressor == game.getPlayer()
		;Game.GetPlayer().AddToFaction(REPrisonerFreedCombatPrisonerFaction)
		;AddRemoveCaptorFaction(REPrisonerFreedCombatCaptorFaction)
	endif
	RegisterForHitEvent(self, Game.GetPlayer())
endEvent


Function FreePrisoner(Actor ActorRef, bool playerIsLiberator= true, bool OpenPrisonerInventory = False)
	debug.trace(self + "FreePrisoner(" + ActorRef + "," + playerIsLiberator + ", " + OpenPrisonerInventory +")")	
	; begin RealHandcuffs changes
	SetResetNoPackage(true)
	If (_prisonerFurniture != None)
		StopPrisonerPose()
	EndIf
	If (IsWearingHandcuffs())
		Return ; failure
	EndIf
	; end RealHandcuffs changes
	ActorRef.SetFactionRank(BoundCaptiveFaction, 1)

	if AlsoRemoveFromCaptiveFaction
		ActorRef.RemoveFromFaction(CaptiveFaction)
	endif

	;DL added this for short term use
	SetRestrained(false)

	ActorRef.EvaluatePackage()
	if playerIsLiberator
		;Game.GetPlayer().AddToFaction(REPrisonerFreedCombatPrisonerFaction)
	EndIf
	
	if OpenPrisonerInventory
		ActorRef.openInventory(True)
	EndIf
	
	ActorRef.SayCustom(RESharedDialoguePrisonerSetFree)
	bound = False

	;AddRemoveCaptorFaction(REPrisonerFreedCombatCaptorFaction)
	
	if StageToSetWhenFreed > -1
		if playerIsLiberator || bSetStageOnlyIfPlayerFreed == false
			if myQuest
				myQuest.SetStage(StageToSetWhenFreed)
			else
				;GetOwningQuest().SetStage(StageToSetWhenFreed)
			endif
		endif
	endif
	ActorRef.EvaluatePackage()

	;Start The clean up timer, actor will not be clean up till after this
	StartTimer(CleanUpTime, CleanupTimerID)
EndFunction

;call when quest shuts down
Function ClearFactions()

	;Game.GetPlayer().RemoveFromFaction(REPrisonerFreedCombatPrisonerFaction)
	RemoveFromFaction(BoundCaptiveFaction)
	;TryToRemoveFromFaction(REPrisonerFreedCombatCaptorFaction)
	
	;AddRemoveCaptorFaction(REPrisonerFreedCombatCaptorFaction, false)

	if StageToSetOnCleanUp > -1
		if bSetStageOnlyIfPlayerFreed == false
			if myQuest
				myQuest.SetStage(StageToSetOnCleanUp)
			else
				;GetOwningQuest().SetStage(StageToSetOnCleanUp)
			endif
		endif
	endif
EndFunction

; functions added by RealHandcuffs

Bool Function IntegrateHandcuffsInVanillaScenes()
    Quest rhQuest = Game.GetFormFromFile(0x000F99, "RealHandcuffs.esp") as Quest
    ScriptObject settings = rhQuest.CastAs("RealHandcuffs:Settings")
    Return settings != None && (settings.GetPropertyValue("IntegrateHandcuffsInVanillaScenes") as Bool)
EndFunction

ScriptObject Function GetRealHandcuffsApi() Global
    Quest rhQuest = Game.GetFormFromFile(0x000F99, "RealHandcuffs.esp") as Quest
    Return rhQuest.CastAs("RealHandcuffs:ThirdPartyApi")
EndFunction

Function SetResetNoPackage(Bool reset)
    Keyword noPackage = Game.GetFormFromFile(0x000860, "RealHandcuffs.esp") as Keyword
    If (noPackage != None)
        If (reset)
            ResetKeyword(noPackage)
        Else
            AddKeyword(noPackage)
        EndIf
    EndIf
EndFunction

Function CreateAndEquipHandcuffs()
    ScriptObject api = GetRealHandcuffsApi()
    If (api != None)
        Var[] kArgs = new Var[1]
        kArgs[0] = Self as Actor
        Bool isBound = api.CallFunction("HasHandsBoundBehindBack", kArgs) as Bool
        If (!isBound)
            kArgs = new Var[4]
            kArgs[0] = Self as Actor
            kArgs[1] = 20 ; chance for hinged
            kArgs[2] = 0  ; chance for high-security
            kArgs[3] = 0  ; empty flags
            ObjectReference handcuffs = api.CallFunction("CreateRandomHandcuffsEquipOnActor", kArgs) as ObjectReference
        EndIf
    EndIf
EndFunction

Bool Function IsWearingHandcuffs()
    ScriptObject api = GetRealHandcuffsApi()
    If (api != None)
        Var[] kArgs = new Var[1]
        kArgs[0] = Self as Actor
        return api.CallFunction("HasHandsBoundBehindBack", kArgs) as Bool
    EndIf
    return false
EndFunction

Bool Function PlayerUnequipHandcuffs()
    ScriptObject api = GetRealHandcuffsApi()
    If (api != None)
        Var[] kArgs = new Var[2]
        kArgs[0] = Self as Actor
        kArgs[1] = 2 ; HandsBoundBehindBack
        ObjectReference handcuffs = api.CallFunction("GetFirstEquippedRestraintWithEffect", kArgs) as ObjectReference
        If (handcuffs != None)
            ScriptObject restraint = handcuffs.CastAs("RealHandcuffs:RestraintBase")
            If (restraint != None)
                kArgs = new Var[1]
                kArgs[0] = Self as Actor
                Bool success = restraint.CallFunction("UnequipInteraction", kArgs)
                If (!success)
                    Return false
                EndIf
            EndIf
            kArgs = new Var[3]
            kArgs[0] = handcuffs
            kArgs[1] = Game.GetPlayer() as ObjectReference
            kArgs[2] = 0 ; empty flags
            api.CallFunction("UnequipRestraintRemoveFromInventory", kArgs)
        EndIf
    EndIf
    Return true
EndFunction

Function UnequipAndDestroyHandcuffs()
    ScriptObject api = GetRealHandcuffsApi()
    If (api != None)
        Var[] kArgs = new Var[2]
        kArgs[0] = Self as Actor
        kArgs[1] = 2 ; HandsBoundBehindBack
        ObjectReference handcuffs = api.CallFunction("GetFirstEquippedRestraintWithEffect", kArgs) as ObjectReference
        If (handcuffs != None)
            kArgs = new Var[3]
            kArgs[0] = handcuffs
            kArgs[1] = None
            kArgs[2] = 0 ; empty flags
            api.CallFunction("UnequipRestraintRemoveFromInventory", kArgs)
        EndIf
    EndIf
EndFunction

Bool Function IsPrisonerFurniture(ObjectReference akFurniture) Global
    If (akFurniture == None)
        Return false
    EndIf
    Int baseId = akFurniture.GetBaseObject().GetFormID()
    return baseId == 0x000D9C37 ; NpcPrisonerFloorSit
EndFunction

ObjectReference _prisonerFurniture

Function StartPrisonerPose(ObjectReference akFurniture, Bool playAnimation)
    _prisonerFurniture = akFurniture
    Action actionInteractionExitQuick = Game.GetForm(0x0002248C) as Action
    PlayIdleAction(actionInteractionExitQuick)
    Idle kneelSitPose = Game.GetFormFromFile(0x00000f, "RealHandcuffs.esp") as Idle
    PlayIdle(kneelSitPose)
    TranslateToRef(akFurniture, 32)
EndFunction

ObjectReference Function StopPrisonerPose()
    Idle kneelSitToStand = Game.GetFormFromFile(0x00000e, "RealHandcuffs.esp") as Idle
    PlayIdle(kneelSitToStand)
    TranslateToRef(_prisonerFurniture, GetDistance(_prisonerFurniture) / 2.0)
    ObjectReference prisonerFurniture = _prisonerFurniture
    _prisonerFurniture = None
    Return prisonerFurniture
EndFunction

Event OnSit(ObjectReference akFurniture)
    If (IsPrisonerFurniture(akFurniture) && akFurniture.WaitFor3DLoad() && WaitFor3DLoad())
        StartPrisonerPose(akFurniture, true)
    EndIf
EndEvent

Event OnPackageChange(Package akOldPackage)
    If (_prisonerFurniture != None)
        StopPrisonerPose()
    EndIf
EndEvent
