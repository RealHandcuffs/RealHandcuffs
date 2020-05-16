;
; Script for the pin settings subterminal in the shock collar terminal.
;
Scriptname RealHandcuffs:TerminalPinSettings extends Terminal Const

RealHandcuffs:Library Property Library Auto Const Mandatory
RealHandcuffs:ShockCollarTerminalData Property TerminalData Auto Const Mandatory

Event OnMenuItemRun(int auiMenuItemID, ObjectReference akTerminalRef)
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
        TerminalData.StoredPin = TerminalData.EnteredPin
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("User updated  pin: " + TerminalData.StoredPin, Library.Settings)
        EndIf
    ElseIf (auiMenuItemID == 51 || auiMenuItemID == 57)
        ; enable pin
        TerminalData.StoredPin = TerminalData.EnteredPin
        TerminalData.CopyStoredPinToPinDigits()
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("User enabled  pin: " + TerminalData.StoredPin, Library.Settings)
        EndIf
    ElseIf (auiMenuItemID == 52 || auiMenuItemID == 58)
        ; disable pin
        TerminalData.StoredPin = -1
        RealHandcuffs:Log.Info("User disabled  pin.", Library.Settings)
    ElseIf (auiMenuItemID == 53 || auiMenuItemID == 59)
        ; enable lockdown
        If (TerminalData.WrongPinEnteredAction == TerminalData.WrongPinShock)
            TerminalData.WrongPinEnteredAction = TerminalData.WrongPinLockoutAndShock
        Else
            TerminalData.WrongPinEnteredAction = TerminalData.WrongPinLockout
        EndIf
    ElseIf (auiMenuItemID == 54 || auiMenuItemID == 60)
        ; disable lockdown
        If (TerminalData.WrongPinEnteredAction == TerminalData.WrongPinLockoutAndShock)
            TerminalData.WrongPinEnteredAction = TerminalData.WrongPinShock
        Else
            TerminalData.WrongPinEnteredAction = TerminalData.WrongPinAllowRetry
        EndIf
    ElseIf (auiMenuItemID == 55 || auiMenuItemID == 61)
        ; enable shock
        If (TerminalData.WrongPinEnteredAction == TerminalData.WrongPinLockout)
            TerminalData.WrongPinEnteredAction = TerminalData.WrongPinLockoutAndShock
        Else
            TerminalData.WrongPinEnteredAction = TerminalData.WrongPinShock
        EndIf
    ElseIf (auiMenuItemID == 56 || auiMenuItemID == 62)
        ; disable shock
        If (TerminalData.WrongPinEnteredAction == TerminalData.WrongPinLockoutAndShock)
            TerminalData.WrongPinEnteredAction = TerminalData.WrongPinLockout
        Else
            TerminalData.WrongPinEnteredAction = TerminalData.WrongPinAllowRetry
        EndIf
    ElseIf (auiMenuItemID == 63 || auiMenuItemID == 64)
        ; randomize pin
        TerminalData.PinDigitOne = Utility.RandomInt(0, 9)
        If (TerminalData.NumberOfPinDigits >= 2)
            TerminalData.PinDigitTwo = Utility.RandomInt(0, 9)
        EndIf
        If (TerminalData.NumberOfPinDigits >= 3)
            TerminalData.PinDigitThree = Utility.RandomInt(0, 9)
        EndIf
        If (TerminalData.NumberOfPinDigits >= 4)
            TerminalData.PinDigitFour = Utility.RandomInt(0, 9)
        EndIf
        TerminalData.UpdateAfterUserEnterPinDigit()
        TerminalData.StoredPin = TerminalData.EnteredPin
        If (Library.Settings.InfoLoggingEnabled)
            RealHandcuffs:Log.Info("User randomized  pin: " + TerminalData.StoredPin, Library.Settings)
        EndIf
    EndIf
EndEvent