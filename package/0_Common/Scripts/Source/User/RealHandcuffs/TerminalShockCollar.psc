;
; Script for the shock collar terminal.
;
Scriptname RealHandcuffs:TerminalShockCollar extends Terminal Const

RealHandcuffs:Library Property Library Auto Const Mandatory
RealHandcuffs:ShockCollarTerminalData Property TerminalData Auto Const Mandatory

Event OnMenuItemRun(int auiMenuItemID, ObjectReference akTerminalRef)
    If (auiMenuItemID <= 54 || (auiMenuItemID >= 69 && auiMenuItemID <= 72))
        ; PIN mode
        If (auiMenuItemID <= 40)
            ; enter "submenu" to modify a pin digit: 1-10 = first digit, 11-20 = second digit, 21-30 = third digit, 31-40 = fourth digit
            TerminalData.EditingPinDigit = (auiMenuItemID + 9) / 10
        ElseIf (auiMenuItemID <= 50)
            ; modify the digit using the "submenu" and return to enter pin menu: 41 = 1, 42 = 2, 43 = 3, ..., 50 = 0
            Int selectedDigit = auiMenuItemID % 10
            If (TerminalData.EditingPinDigit == 1)
                TerminalData.PinDigitOne = selectedDigit
            ElseIf (TerminalData.EditingPinDigit == 2)
                TerminalData.PinDigitTwo = selectedDigit
            ElseIf (TerminalData.EditingPinDigit == 3)
                TerminalData.PinDigitThree = selectedDigit
            ElseIf (TerminalData.EditingPinDigit == 4)
                TerminalData.PinDigitFour = selectedDigit
            EndIf
            TerminalData.EditingPinDigit = 0
            TerminalData.UpdateAfterUserEnterPinDigit()
        ElseIf (auiMenuItemID == 51 || auiMenuItemID == 69)
            ; enter valid pin
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("User entered correct pin: " + TerminalData.EnteredPin, Library.Settings)
            EndIf
            TerminalData.PinInputState = TerminalData.PinInputSucceeded
        Else ; auiMenuItemID == 52 || auiMenuItemID == 53 || auiMenuItemID == 54 || auiMenuItemID == 70 || auiMenuItemID == 71 || auiMenuItemID == 72
            ; enter invalid pin, with different settings for WrongPinEnteredAction
            If (Library.Settings.InfoLoggingEnabled)
                RealHandcuffs:Log.Info("User entered wrong pin: " + TerminalData.EnteredPin + ", expected: " + TerminalData.StoredPin, Library.Settings)
            EndIf
            If (TerminalData.WrongPinEnteredAction != TerminalData.WrongPinAllowRetry)
                TerminalData.PinInputState = TerminalData.PinInputFailed
                If (TerminalData.WrongPinEnteredAction == TerminalData.WrongPinLockout || TerminalData.WrongPinEnteredAction == TerminalData.WrongPinLockoutAndShock)
                    TerminalData.RemainingLockoutTime = 3
                EndIf
                If (auiMenuItemID == 54 || auiMenuItemID == 72)
                    TerminalData.TriggerShock = true
                    Utility.WaitMenuMode(1) ; wait a short moment to allow the player to read the message before terminal closes
                EndIf
            EndIf
        EndIf
    ElseIf (auiMenuItemID == 55 || auiMenuItemID == 62)
        ; enter pin settings subterminal
        If (TerminalData.StoredPin >= 0)
            TerminalData.EnteredPin = TerminalData.StoredPin
            TerminalData.CopyStoredPinToPinDigits()
        EndIf
        TerminalData.EditingPinDigit = 0
    ElseIf (auiMenuItemID == 56 || auiMenuItemID == 64)
        ; unlock electronic lock, show disclaimer
        TerminalData.InternalState = 1
    ElseIf (auiMenuItemID == 57 || auiMenuItemID == 65)
        ; lock electronic lock
        TerminalData.ElectronicLockState = TerminalData.ElectronicLockLocked
    ElseIf (auiMenuItemID == 58 || auiMenuItemID == 66)
        ; confirm unlock electronic lock
        TerminalData.ElectronicLockState = TerminalData.ElectronicLockUnlocked
        TerminalData.InternalState = 0
    ElseIf (auiMenuItemID == 59 || auiMenuItemID == 67)
        ; cancel
        TerminalData.InternalState = 0
    ElseIf (auiMenuItemID == 60 || auiMenuItemID == 68)
        ; trigger collar
        TerminalData.TriggerShock = true
        Utility.WaitMenuMode(1) ; wait a short moment to allow the player to read the message before terminal closes
    ElseIf (auiMenuItemID == 61 || auiMenuItemID == 63)
        ; enter trigger settings subterminal
    ElseIf (auiMenuItemID == 73 || auiMenuItemID == 74)
        ; enter torture mode subterminal
    ElseIf (auiMenuItemID == 75)
        ; initiate connection
        RealHandcuffs:ShockCollarBase collar = TerminalData.RegisteredShockCollar
        If (collar != None)
            Actor player = Game.GetPlayer()
            Actor collarTarget = collar.SearchCurrentTarget()
            If (collarTarget == player || (collarTarget != None && player.GetDistance(collarTarget) <= 256) || (collarTarget == None && collar.GetContainer() == player))
                collar.CopyShockCollarDataToTerminalData()
                TerminalData.RegisterForUpdateOnNextTerminalMenuClose()
                If (Library.Settings.InfoLoggingEnabled)
                    RealHandcuffs:Log.Info("Connecting to collar of " + RealHandcuffs:Log.FormIdAsString(collarTarget) + " " + collarTarget.GetDisplayName(), Library.Settings)
                EndIf
            EndIf
        EndIf
        Utility.WaitMenuMode(1) ; wait a short moment to allow the player to read the message before terminal closes
    EndIf
EndEvent