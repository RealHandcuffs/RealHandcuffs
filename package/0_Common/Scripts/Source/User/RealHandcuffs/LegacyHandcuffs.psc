;
; A script on legacy (junk) handcuffs to convert them to real handcuffs.
; Even if this script is not running, HandcuffsConverter should convert them
; when picked up by the player, though maybe at a loss of functionality.
;
Scriptname RealHandcuffs:LegacyHandcuffs extends ObjectReference

RealHandcuffs:HandcuffsConverter Property Converter Auto Const Mandatory
RealHandcuffs:Settings Property Settings Auto Const Mandatory

Bool _eventRegistered

Function UpdateState()
    If (IsBoundGameObjectAvailable())
        UpdateStateContainerKnown(GetContainer())
    Else
        UpdateStateContainerKnown(None)
    EndIf
    
EndFunction

Function UpdateStateContainerKnown(ObjectReference myContainer)
    If (myContainer != None)
        ; in container: sleep
        If (_eventRegistered)
            UnregisterForCustomEvent(Settings, "OnSettingsChanged")
            _eventRegistered = false
        EndIf
    ElseIf (!IsBoundGameObjectAvailable())
        ; no native object bound to script, do nothing
    ElseIf (Converter.IsProcessed(Self))
        ; already converted or in container: sleep
        If (_eventRegistered)
            UnregisterForCustomEvent(Settings, "OnSettingsChanged")
            _eventRegistered = false
        EndIf
    Else
        Cell parentCell = GetParentCell()
        If (parentCell == None || !parentCell.IsAttached())
            ; parent cell not attached: sleep
            If (_eventRegistered)
                UnregisterForCustomEvent(Settings, "OnSettingsChanged")
                _eventRegistered = false
            EndIf
        ElseIf (Settings.AutoConvertHandcuffs)
            ; parent cell attached, setting is true: convert
            If (_eventRegistered)
                UnregisterForCustomEvent(Settings, "OnSettingsChanged")
                _eventRegistered = false
            EndIf
            Converter.ConvertLegacyHandcuffs(Self)
        Else
            ; parent cell attached, setting is false: listen for settings changed event
            If (!_eventRegistered)
                RegisterForCustomEvent(Settings, "OnSettingsChanged")
                _eventRegistered = true
            EndIf
        EndIf
    EndIf
EndFunction

Event OnInit()
    If (!Converter.SanctuaryWorkshopRef.OwnedByPlayer && GetContainer() == Converter.SanctuaryWorkshopRef.GetContainer())
        ; special handling for legacy handcuffs spawned in sanctuary workshop container
        ; this is even done for lite edition as we still want to replace the legacy handcuffs inside the sanctuary workshop
        RealHandcuffs:Log.Info("Removing legacy handcuffs from sanctuary workshop container.", Converter.Library.Settings)
        Converter.SanctuaryWorkshopRef.GetContainer().RemoveItem(Converter.LegacyHandcuffs, 1, true, None)
    Else
        ; usually, Settings.AutoConvertHandcuffs is true, so UpdateState will convert in OnInit and that's it
        UpdateState()
    EndIf
EndEvent

Event OnContainerChanged(ObjectReference akNewContainer, ObjectReference akOldContainer)
    If (akOldContainer != None && akNewContainer == None)
        RealHandcuffs:Log.Info("Ignoring legacy handcuffs being dropped from container.", Converter.Library.Settings)
    Else
        UpdateStateContainerKnown(akNewContainer)
    EndIf
EndEvent

Event OnCellAttach()
    UpdateState()
EndEvent

Event OnCellDetach()
    UpdateState()
EndEvent

Event RealHandcuffs:Settings.OnSettingsChanged(RealHandcuffs:Settings akSender, Var[] akArgs)
    UpdateState()
EndEvent