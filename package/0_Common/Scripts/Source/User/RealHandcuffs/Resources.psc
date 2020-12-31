;
; A library of resources for restraints. This allows RestraintBase to just have a property for Library instead of properties
; for individual resources, making the definition of actual restraint implementations simpler and more stable when the
; framework changes.
;
Scriptname RealHandcuffs:Resources extends Quest

;
; Keywords to help overriding animations.
;
Keyword Property OverrideAnims0 Auto Const Mandatory
Keyword Property OverrideAnims1 Auto Const Mandatory
Keyword Property OverrideAnims2 Auto Const Mandatory
Keyword Property OverrideAnims3 Auto Const Mandatory

;
; Keywords for individual animations.
;
Keyword Property AnimArmsCuffedBehindBack Auto Const Mandatory
Keyword Property AnimArmsCuffedBehindBackTortureDevices Auto Const Mandatory
Keyword Property AnimArmsCuffedBehindBackHinged Auto Const Mandatory

;
; Keywords for mod types.
;
Keyword Property FirmwareTag Auto Const Mandatory
Keyword Property LockTag Auto Const Mandatory
Keyword Property LockTimeTag Auto Const Mandatory
Keyword Property PoseTag Auto Const Mandatory
Keyword Property ShockModuleTag Auto Const Mandatory
Keyword Property ConvertTag Auto Const Mandatory

;
; Keyword for various lock types.
;
Keyword Property EasyLock Auto Const Mandatory
Keyword Property FirmwareControlledLock Auto Const Mandatory
Keyword Property HighSecurityLock Auto Const Mandatory
Keyword Property TimedLock Auto Const Mandatory
Keyword Property TimeDial Auto Const Mandatory ; not a lock type but has similar function

;
; Keywords for lock time of timed locks
;
Keyword Property LockTime1h Auto Const Mandatory
Keyword Property LockTime2h Auto Const Mandatory
Keyword Property LockTime3h Auto Const Mandatory
Keyword Property LockTime4h Auto Const Mandatory
Keyword Property LockTime5h Auto Const Mandatory
Keyword Property LockTime6h Auto Const Mandatory
Keyword Property LockTime7h Auto Const Mandatory
Keyword Property LockTime8h Auto Const Mandatory
Keyword Property LockTime9h Auto Const Mandatory
Keyword Property LockTime10h Auto Const Mandatory
Keyword Property LockTime11h Auto Const Mandatory
Keyword Property LockTime12h Auto Const Mandatory

;
; ObjectMods setting lock time of timed locks
;
ObjectMod Property ModLockTime1h Auto Const Mandatory
ObjectMod Property ModLockTime2h Auto Const Mandatory
ObjectMod Property ModLockTime3h Auto Const Mandatory
ObjectMod Property ModLockTime4h Auto Const Mandatory
ObjectMod Property ModLockTime5h Auto Const Mandatory
ObjectMod Property ModLockTime6h Auto Const Mandatory
ObjectMod Property ModLockTime7h Auto Const Mandatory
ObjectMod Property ModLockTime8h Auto Const Mandatory
ObjectMod Property ModLockTime9h Auto Const Mandatory
ObjectMod Property ModLockTime10h Auto Const Mandatory
ObjectMod Property ModLockTime11h Auto Const Mandatory
ObjectMod Property ModLockTime12h Auto Const Mandatory

;
; Keywords for shock collar firmware
;
Keyword Property MarkTwoFirmware Auto Const Mandatory
Keyword Property MarkThreeFirmware Auto Const Mandatory
Keyword Property HackedFirmware Auto Const Mandatory

;
; Keywords for shock modules
;
Keyword Property DefaultShock Auto Const Mandatory
Keyword Property Explosive Auto Const Mandatory
Keyword Property ThrobbingShock Auto Const Mandatory

;
; Keywords for repeating shocks
;
Keyword Property RepeatingShocks Auto Const Mandatory
Keyword Property FrequentlyRepeatingShocks Auto Const Mandatory

;
; Keyword for restraints that are currently locked.
;
Keyword Property Locked Auto Const Mandatory

;
; Keyword used for tracing cloning operations.
;
Keyword Property ClonedTarget Auto Const Mandatory
Keyword Property FreshlyCloned Auto Const Mandatory

;
; Keywords for remote triggering of effects.
; 
Keyword Property RemoteTriggerEffect Auto Const Mandatory
Keyword Property LinkedRemoteTriggerObject Auto Const Mandatory

;
; Keywords for AI packages.
;
Keyword Property CycleAi Auto Const Mandatory
Keyword Property IdleMarkerLink Auto Const Mandatory
Keyword Property PrisonerMatLink Auto Const Mandatory
Keyword Property WaitMarkerLink Auto Const Mandatory

;
; Keywords for perks
;
Keyword Property Posable Auto Const Mandatory

;
; Special keywords
;
Keyword Property LinkedActorToEquipCraftedItem Auto Const Mandatory
Keyword Property Restraint Auto Const Mandatory

;
; Infrastructure used for vertibird riding
;
Keyword Property LinkedOwnerSpecial Auto Const Mandatory
Keyword Property LinkedVertibird Auto Const Mandatory
Location Property HoldingCell Auto Const Mandatory
ObjectReference Property HoldingCellMarker Auto Const Mandatory

;
; Idle animation: Struggle with hands bound on back.
;
Idle Property HandcuffsOnBackStruggle Auto Const Mandatory

;
; Idle animation: Struggle against locked bracelets.
;
Idle Property LockedBraceletsStruggle Auto Const Mandatory

;
; Action: Fire a single shot from the currently equipped and drawn weapon.
;
Action Property ActionFireSingle Auto Const Mandatory

;
; Actions for faking bleedout.
;
Action Property ActionBleedoutStart Auto Const Mandatory
Action Property ActionBleedoutStop Auto Const Mandatory

;
; Action: Quickly leave a furniture object.
;
Action Property ActionInteractionExitQuick Auto Const Mandatory

;
; A invisible container that can used to temporarily stow items. 
;
Container Property InvisibleContainer Auto Const Mandatory

;
; A invisible door that can used to initiate the lockpicking minigame.
;
Door Property InvisibleDoor Auto Const Mandatory

;
; Bobby pin object.
;
MiscObject Property BobbyPin Auto Const Mandatory

;
; RobCo Connect Holotape
;
Holotape Property RobCoConnect Auto Const Mandatory

;
; Workshop keyword.
;
Keyword Property WorkshopKeyword Auto Const Mandatory

;
; Actor values for limb health.
;
ActorValue Property LeftAttackCondition Auto Const Mandatory
ActorValue Property RightAttackCondition Auto Const Mandatory

; Actor values for AI handling.
ActorValue Property WaitingForPlayer Auto Const Mandatory

;
; Locksmith perks required to pick locks.
;
Perk Property Locksmith01 Auto Const Mandatory
Perk Property Locksmith02 Auto Const Mandatory
Perk Property Locksmith03 Auto Const Mandatory

;
; Shock spells.
;
Spell Property DefaultShockSpell Auto Const Mandatory
Spell Property DefaultShockSpellNonLethal Auto Const Mandatory
Spell Property ThrobbingShockSpell Auto Const Mandatory
Spell Property ThrobbingShockSpellNonLethal Auto Const Mandatory


;
; Resources for messages boxes.
;
Message Property MsgBoxActivateHandcuffsWithTimedLock Auto Const Mandatory                              ; 0: change dial value, 1: consider putting on wrists, 2: abort
Message Property MsgBoxBoobyTrapArmorRack Auto Const Mandatory											; 0: booby-trap armor rack, 1: abort
Message Property MsgBoxBoobyTrapCorpse Auto Const Mandatory												; 0: booby-trap corpse, 1: abort
Message Property MsgBoxChangeTimedLockDuration Auto Const Mandatory                                     ; 0-11: (x+1) hours
Message Property MsgBoxNpcEquipRobcoShockCollarFemale Auto Const Mandatory                              ; 0: connect pip-box, 1: equip 2: both, 3: abort
Message Property MsgBoxNpcEquipRobcoShockCollarMale Auto Const Mandatory                                ; 0: connect pip-box, 1: equip 2: both, 3: abort
Message Property MsgBoxNpcManualPipBoyTerminalMode Auto Const Mandatory                                 ; 0: OK
Message Property MsgBoxNpcRobcoShockCollarEquippedFemale Auto Const Mandatory                           ; 0: connect pip-boy, 1: abort
Message Property MsgBoxNpcRobcoShockCollarEquippedMale Auto Const Mandatory                             ; 0: connect pip-boy, 1: abort
Message Property MsgBoxNpcRobcoShockCollarFemaleLockedEnslave Auto Const Mandatory                      ; 0: Enslave using JB, 1: abort
Message Property MsgBoxNpcRobcoShockCollarMaleLockedEnslave Auto Const Mandatory                        ; 0: Enslave using JB, 1: abort
Message Property MsgBoxNpcUnlockHandcuffsBrokenNoKeyFemale Auto Const Mandatory                         ; 0: try to pick lock, 1: abort
Message Property MsgBoxNpcUnlockHandcuffsBrokenNoKeyFemaleLPSkillNotHighEnough Auto Const Mandatory     ; 0: abort
Message Property MsgBoxNpcUnlockHandcuffsBrokenNoKeyMale Auto Const Mandatory                           ; 0: try to pick lock, 1: abort
Message Property MsgBoxNpcUnlockHandcuffsBrokenNoKeyMaleLPSkillNotHighEnough Auto Const Mandatory       ; 0: abort
Message Property MsgBoxNpcUnlockHandcuffsNoKeyFemale Auto Const Mandatory                               ; 0: try to pick lock, 1: abort
Message Property MsgBoxNpcUnlockHandcuffsNoKeyFemaleLockpickingSkillNotHighEnough Auto Const Mandatory  ; 0: abort
Message Property MsgBoxNpcUnlockHandcuffsNoKeyMale Auto Const Mandatory                                 ; 0: try to pick lock, 1: abort
Message Property MsgBoxNpcUnlockHandcuffsNoKeyMaleLockpickingSkillNotHighEnough Auto Const Mandatory    ; 0: abort
Message Property MsgBoxNpcUnlockHandcuffsTimedLockFemale Auto Const Mandatory                           ; 0: abort
Message Property MsgBoxNpcUnlockHandcuffsTimedLockMale Auto Const Mandatory                             ; 0: abort
Message Property MsgBoxSelfEquipHandcuffsBrokenPart1 Auto Const Mandatory                               ; 0: put them on wrists, 1: abort
Message Property MsgBoxSelfEquipHandcuffsOnBackPart1 Auto Const Mandatory                               ; 0: bind hands on back, 1: abort
Message Property MsgBoxSelfEquipHandcuffsHingedOnBackPart1 Auto Const Mandatory                         ; 0: bind hands on back lock facing away from hands, 1: bind hands on back lock facing towards hands, 2: abort
Message Property MsgBoxSelfEquipHandcuffsBrokenPart2 Auto Const Mandatory                               ; 0,1,2: tightness
Message Property MsgBoxSelfEquipHandcuffsOnBackPart2 Auto Const Mandatory                               ; 0,1,2: tightness
Message Property MsgBoxSelfEquipRobcoShockCollarPart1 Auto Const Mandatory                              ; 0: connect pip-boy, 1: put it on, 2: abort
Message Property MsgBoxSelfEquipRobcoShockCollarPart2 Auto Const Mandatory                              ; 0: lock it on, 1: abort
Message Property MsgBoxSelfHandcuffsBrokenQuiteTight Auto Const Mandatory                               ; 0: struggle, 1: investigate lock, 2: abort, 3: tighten
Message Property MsgBoxSelfHandcuffsBrokenRatherLoose Auto Const Mandatory                              ; 0: struggle, 1: investigate lock, 2: abort, 3: tighten
Message Property MsgBoxSelfHandcuffsBrokenVeryTight Auto Const Mandatory                                ; 0: struggle, 1: investigate lock, 2: abort
Message Property MsgBoxSelfHandcuffsBrokenKeyInInventory Auto Const Mandatory                           ; 0: unlock, 1: abort
Message Property MsgBoxSelfHandcuffsBrokenNoKeyLockpickingSkillNotHighEnough Auto Const Mandatory       ; 0: abort
Message Property MsgBoxSelfHandcuffsBrokenNoKeyNoBobbyPins Auto Const Mandatory                         ; 0: abort
Message Property MsgBoxSelfHandcuffsBrokenNoKeyBobbyPinsInInventory Auto Const Mandatory                ; 0: try to pick lock, 1: abort
Message Property MsgBoxSelfHandcuffsBrokenTimedLock Auto Const Mandatory                                ; 0: abort
Message Property MsgBoxSelfHandcuffsBrokenTimedLockUnlocks Auto Const Mandatory                         ; 0: remove
Message Property MsgBoxSelfHandcuffsOnBackBobbyPinInHand Auto Const Mandatory                           ; 0: struggle to unlock, 1: abort, 2: drop bobby pin, 3+ : use %3
Message Property MsgBoxSelfHandcuffsOnBackKeyInHand Auto Const Mandatory                                ; 0: struggle to unlock, 1: abort, 2: drop key
Message Property MsgBoxSelfHandcuffsOnBackKeyInHandEasyToReach Auto Const Mandatory                     ; 0: unlock, 1: abort, 2: drop key
Message Property MsgBoxSelfHandcuffsOnBackKeyInInventory Auto Const Mandatory                           ; 0: struggle for key, 1+: abort
Message Property MsgBoxSelfHandcuffsOnBackKeyInInventoryHandsNotEmpty Auto Const Mandatory              ; 0: struggle for key, 1+: abort
Message Property MsgBoxSelfHandcuffsOnBackNoKeyBobbyPinsInInventory Auto Const Mandatory                ; 0: struggle for bobby pin, 1+: abort
Message Property MsgBoxSelfHandcuffsOnBackNoKeyBobbyPinsInInventoryHandsNotEmpty Auto Const Mandatory   ; 0: struggle for bobby pin, 1+: abort
Message Property MsgBoxSelfHandcuffsHingedOnBackCannotReachLock Auto Const Mandatory                    ; 0: abort
Message Property MsgBoxSelfHandcuffsOnBackNoKeyLockTooDifficult Auto Const Mandatory                    ; 0+: abort
Message Property MsgBoxSelfHandcuffsOnBackNoKeyLockpickingSkillNotHighEnough Auto Const Mandatory       ; 0+: abort
Message Property MsgBoxSelfHandcuffsOnBackNoKeyNoBobbyPins Auto Const Mandatory                         ; 0+: abort
Message Property MsgBoxSelfHandcuffsOnBackPickUpHandsNotEmpty Auto Const Mandatory                      ; 0: pick up, 1: abort
Message Property MsgBoxSelfHandcuffsOnBackPickUpItemAllowed Auto Const Mandatory                        ; 0: pick up, 1: abort
Message Property MsgBoxSelfHandcuffsOnBackPickUpItemNotAllowed Auto Const Mandatory                     ; 0: abort
Message Property MsgBoxSelfHandcuffsOnBackTakeItemFromContainerHandsNotEmpty Auto Const Mandatory		; 0: pick up, 1: abort
Message Property MsgBoxSelfHandcuffsOnBackTakeItemFromContainerAllowed Auto Const Mandatory				; 0: pick up, 1: abort
Message Property MsgBoxSelfHandcuffsOnBackTakeItemFromContainerNotAllowed Auto Const Mandatory			; 0: abort
Message Property MsgBoxSelfHandcuffsOnBackPutItemIntoContainerAllowed Auto Const Mandatory				; 0: drop, 1: abort
Message Property MsgBoxSelfHandcuffsOnBackPutItemIntoContainerNotAllowed Auto Const Mandatory			; 0: abort
Message Property MsgBoxSelfHandcuffsOnBackQuiteTight Auto Const Mandatory                               ; 0: struggle, 1: investigate lock, 2: abort, 3: tighten
Message Property MsgBoxSelfHandcuffsOnBackTimedLock Auto Const Mandatory                                ; 0: abort
Message Property MsgBoxSelfHandcuffsOnBackTimedLockUnlocks Auto Const Mandatory                         ; 0: remove
Message Property MsgBoxSelfHandcuffsOnBackUseWorkshopTools Auto Const Mandatory                         ; 0: sit on working surface, 1: abort
Message Property MsgBoxSelfHandcuffsOnBackCutWithWorkshopTools Auto Const Mandatory                     ; 0: use power tools to cut chain, 1: abort
Message Property MsgBoxSelfHandcuffsOnBackCutWithWorkshopToolsSuccess Auto Const Mandatory              ; 0: done
Message Property MsgBoxSelfHandcuffsOnBackCutWithWorkshopToolsSuccessHurt Auto Const Mandatory          ; 0: done
Message Property MsgBoxSelfHandcuffsHingedOnBackCutWithWorkshopTools Auto Const Mandatory               ; 0: use power tools to cut chain, 1: abort
Message Property MsgBoxSelfHandcuffsHingedOnBackCutWithWorkshopToolsSuccess Auto Const Mandatory        ; 0: done
Message Property MsgBoxSelfHandcuffsHingedOnBackCutWithWorkshopToolsSuccessHurt Auto Const Mandatory    ; 0: done
Message Property MsgBoxSelfHandcuffsHingedOnBackQuiteTight Auto Const Mandatory                         ; 0: struggle, 1: investigate lock, 2: abort, 3: tighten
Message Property MsgBoxSelfHandcuffsOnBackRatherLoose Auto Const Mandatory                              ; 0: struggle, 1: investigate lock, 2: abort, 3: tighten
Message Property MsgBoxSelfHandcuffsHingedOnBackRatherLoose Auto Const Mandatory                        ; 0: struggle, 1: investigate lock, 2: abort, 3: tighten
Message Property MsgBoxSelfHandcuffsOnBackVeryTight Auto Const Mandatory                                ; 0: struggle, 1: investigate lock, 2: abort
Message Property MsgBoxSelfHandcuffsHingedOnBackVeryTight Auto Const Mandatory                          ; 0: struggle, 1: investigate lock, 2: abort
Message Property MsgBoxSelfManualPipBoyTerminalMode Auto Const Mandatory                                ; 0: OK 
Message Property MsgBoxSelfRobcoShockCollarEquipped Auto Const Mandatory                                ; 0: connect pip-boy, 1: abort
Message Property MsgBoxStruggleFailToEscapeBrokenHandcuffsQuiteTight Auto Const Mandatory               ; 0: struggle, 1: abort
Message Property MsgBoxStruggleFailToEscapeBrokenHandcuffsVeryTight Auto Const Mandatory                ; 0: struggle, 1: abort
Message Property MsgBoxStruggleFailToEscapeQuiteTight Auto Const Mandatory                              ; 0: struggle, 1: abort
Message Property MsgBoxStruggleFailToEscapeVeryTight Auto Const Mandatory                               ; 0: struggle, 1: abort
Message Property MsgBoxStruggleFailToReachBobbyPin Auto Const Mandatory                                 ; 0: struggle for bobby pin, 1: abort
Message Property MsgBoxStruggleFailToReachKey Auto Const Mandatory                                      ; 0: struggle for key, 1: abort
Message Property MsgBoxStruggleFailToUnlock Auto Const Mandatory                                        ; 0: struggle to unlock, 1: abort, 2: drop key
Message Property MsgBoxSelfHandcuffsOnBackDrinkOpenWater Auto Const Mandatory							; 0: drink, 1: abort
Message Property MsgBoxSelfHandcuffsOnBackEatItem Auto Const Mandatory									; 0: eat, 1: abort

;
; Resources for messages.
;

Message Property MsgBondsPreventManipulationOfShockCollar Auto Const Mandatory
Message Property MsgBondsPreventUnlockingOfHandcuffs Auto Const Mandatory
Message Property MsgFrequentShocksPreventSleeping Auto Const Mandatory
Message Property MsgNpcLockHandcuffsBrokenFemale Auto Const Mandatory
Message Property MsgNpcLockHandcuffsBrokenMale Auto Const Mandatory
Message Property MsgNpcLockHandcuffsOnBackFemale Auto Const Mandatory
Message Property MsgNpcLockHandcuffsOnBackMale Auto Const Mandatory
Message Property MsgSlipOutOfHandcuffs Auto Const Mandatory
Message Property MsgStruggleSwimming Auto Const Mandatory
Message Property MsgUnlockHandcuffsWithKey Auto Const Mandatory
; messages from base game
Message Property CantUseInCombatMessage Auto Const Mandatory