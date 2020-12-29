;
; Script attached to a handcuffs instance.
;
Scriptname RealHandcuffs:Handcuffs extends RealHandcuffs:HandcuffsBase

Armor Property DummyHandcuffs Auto Const Mandatory
Armor Property DummyHandcuffsTD Auto Const Mandatory
ObjectMod Property ModArmsCuffedBehindBackRealHandcuffs Auto Const Mandatory
ObjectMod Property ModArmsCuffedBehindBackTortureDevices Auto Const Mandatory

;
; Set to true to prevent automatic selection of pose on equipping. After setting this, use
; SetPoseMod() to set a pose that will stay fixed.
;
Bool Property IgnorePoseSettings Auto

;
; Replace the mods of this instance by cloning mods from another restraint.
;
Function CloneModsFrom(RealHandcuffs:RestraintBase otherRestraint)
    Parent.CloneModsFrom(otherRestraint)
    ObjectMod[] mods = otherRestraint.GetAllMods()
    If (mods.Find(ModArmsCuffedBehindBackRealHandcuffs) >= 0)
        ReplaceMod(Library.Resources.PoseTag, ModArmsCuffedBehindBackRealHandcuffs)
    ElseIf (mods.Find(ModArmsCuffedBehindBackTortureDevices) >= 0)
        ReplaceMod(Library.Resources.PoseTag, ModArmsCuffedBehindBackTortureDevices)
    Else
        ObjectMod poseMod = ModArmsCuffedBehindBackRealHandcuffs
        If (Library.Settings.HandcuffsOnBackPose == 1)
            poseMod = ModArmsCuffedBehindBackTortureDevices
        EndIf
        ReplaceMod(Library.Resources.PoseTag, poseMod)
    EndIf
EndFunction

;
; Override: Break the handcuffs. This will delete the instance on success.
;
Bool Function BreakHandcuffs()
    AttachMod(Library.Converter.ModRemoveChain, 0)
    Return Library.Converter.ConvertRestraint(Self)
EndFunction

;
; Override: Get a 'dummy' armor that can be used to visually represent the restraint.
;
Armor Function GetDummyObject()
    If (HasKeyword(Library.Resources.AnimArmsCuffedBehindBackTortureDevices))
        Return DummyHandcuffsTD
    EndIf
    Return DummyHandcuffs
EndFunction

;
; Override: Set internal state after the restraint has been equipped and applied.
;
Function SetStateAfterEquip(Actor target, Bool interactive)
    CancelTimer(EquipAfterPoseModChange)
    Parent.SetStateAfterEquip(target, interactive)
    If (!IgnorePoseSettings)
        ObjectMod poseMod = ModArmsCuffedBehindBackRealHandcuffs
        If (Library.Settings.HandcuffsOnBackPose == 1)
            poseMod = ModArmsCuffedBehindBackTortureDevices
        EndIf
        If (ReplaceMod(Library.Resources.PoseTag, poseMod))
            ActorToken token = Library.TryGetActorToken(target)
            If (token != None)
                token.RefreshEffectsAndAnimations(false, None)
            EndIf
            StartTimer(0.1, UnequipAfterPoseModChange)
        EndIf
    EndIf
EndFunction

;
; Override: Check whether the MT animation for the arms can be changed.
;
Bool Function MtAnimationForArmsCanBeCycled()
    Return False ; for now, later:
                 ; Library.SoftDependencies.TortureDevicesAvailable || GetMod(Library.Resources.PoseTag) == ModArmsCuffedBehindBackTortureDevices
EndFunction

;
; Override: Try to cycle the MT animation for the arms.
;
Function CycleMtAnimationForArms(Actor target)
    ObjectMod poseMod = GetMod(Library.Resources.PoseTag)
    ObjectMod newPoseMod = None
    If (poseMod == ModArmsCuffedBehindBackRealHandcuffs)
        If (Library.SoftDependencies.TortureDevicesAvailable)
            newPoseMod = ModArmsCuffedBehindBackTortureDevices
        EndIf
    ElseIf (poseMod == ModArmsCuffedBehindBackTortureDevices)
        newPoseMod = ModArmsCuffedBehindBackRealHandcuffs
    Else
        RealHandcuffs:Log.Warning("Unknown pose mod: " + RealHandcuffs:Log.FormIdAsString(poseMod), Library.Settings)
    EndIf
    If (newPoseMod != None && SetPoseMod(newPoseMod))
        If (target != None)
            ActorToken token = Library.TryGetActorToken(target)
            If (token != None)
                token.RefreshEffectsAndAnimations(false, None)
            EndIf
        EndIf
        StartTimer(0.1, UnequipAfterPoseModChange)
    EndIf
EndFunction

;
; Override: Set internal state after the restraint has been unequipped and unapplied.
;
Function SetStateAfterUnequip(Actor target, Bool interactive)
    CancelTimer(UnequipAfterPoseModChange)
    Parent.SetStateAfterUnequip(target, interactive)
EndFunction

;
; Override: Start the player cut handcuffs with tools interaction.
;
Bool Function StartPlayerUseToolsInteraction(ObjectReference workshopRef)
    If (Library.GetInteractionType() != Library.InteractionTypePlayer) ; not expected but check to be sure
        Library.ClearInteractionType()
        Return false
    EndIf
    Int selection = Library.Resources.MsgBoxSelfHandcuffsOnBackUseWorkshopTools.Show()
    If (selection == 0)
        selection = Library.Resources.MsgBoxSelfHandcuffsOnBackCutWithWorkshopTools.Show()
        If (selection == 0)
            Actor player = Game.GetPlayer()
            Int chance = (25 + player.GetValue(Game.GetAgilityAV()) * 7.5) as Int
            Int d100 = Utility.RandomInt(1, 100)
            If (d100 <= chance)
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Player cut handcuffs (" + d100 + "&lt;=" + chance + ").", Library.Settings)
                EndIf
                Library.Resources.MsgBoxSelfHandcuffsOnBackCutWithWorkshopToolsSuccess.Show()
            Else
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Player cut handcuffs but got hurt (" + d100 + "&gt;" + chance + ").", Library.Settings)
                EndIf
                Library.Resources.MsgBoxSelfHandcuffsOnBackCutWithWorkshopToolsSuccessHurt.Show()
                ; reduce health by 30% of max health
                Float baseHealth = player.GetBaseValue(Game.GetHealthAV())
                player.DamageValue(Game.GetHealthAV(), baseHealth * 0.3)
                ; cripple one of the arms
                ActorValue armCondition = None
                If (Utility.RandomInt(0, 1) == 0)
                    armCondition = Library.Resources.LeftAttackCondition
                Else
                    armCondition = Library.Resources.RightAttackCondition
                EndIf
                player.DamageValue(armCondition, player.GetValue(armCondition))
            EndIf
            Library.ClearInteractionType()
            Return true
        EndIf
    EndIf
    Library.ClearInteractionType()
    Return false
EndFunction

;
; Group for timer events
;
Group Timers
    Int Property UnequipAfterPoseModChange = 2000 AutoReadOnly
    Int Property EquipAfterPoseModChange = 2001 AutoReadOnly
EndGroup

;
; Continue equip interaction.
;
Event OnTimer(int aiTimerID)
    If (aiTimerID == UnequipAfterPoseModChange)
        Actor target = GetContainer() as Actor
        Form baseObject = GetBaseObject()
        If (target != None)
            target.UnequipItem(baseObject, false, true) ; should get reverted
        EndIf
        StartTimer(0.1, EquipAfterPoseModChange) ; in case it did not get reverted
    ElseIf (aiTimerID == EquipAfterPoseModChange)
        Actor target = GetContainer() as Actor
        Form baseObject = GetBaseObject()
        If (target != None && !target.IsEquipped(baseObject))
            ForceEquip(target)
        EndIf
    Else
        Parent.OnTimer(aiTimerID)
    EndIf
EndEvent