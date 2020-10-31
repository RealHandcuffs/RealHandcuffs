;
; Handles data input/output for shock collar terminal.
;
Scriptname RealHandcuffs:ShockCollarTerminalData extends Quest Conditional

;
; Reset all members to default values.
;
Function Reset()
    RegisteredShockCollar = None
    Flavor = NoCarrier
    PinInputState = 0
    NumberOfPinDigits = 0
    StoredPin = 0
    EnteredPin = 0
    EnteredPinDifference = 0
    PinDigitOne = 0
    PinDigitTwo = 0
    PinDigitThree = 0
    PinDigitFour = 0
    WrongPinEnteredAction = 0
    RemainingLockoutTime = 0
    CollarEnabled = False
    ElectronicLockState = 0
    TriggerShock = False
    InternalState = 0
    SupportedTriggerModes = 0
    TriggerMode = 0
	SupportsTortureMode = False
	RestartTortureMode = False
	TortureModeFrequency = 0
EndFunction

;
; Prepare all members required for pin input.
;
Function SetupPin(Int numberOfDigits, Int pin, Int wrongPinAction)
    If (numberOfDigits <= 0)
        ; pin not supported by this shock collar
        PinInputState = PinInputSucceeded
        NumberOfPinDigits = 0
        StoredPin = -1
    ElseIf (pin < 0)
        ; pin supported but no pin set
        PinInputState = PinInputSucceeded
        If (numberOfDigits >= 4)
            NumberOfPinDigits = 4
        Else
            NumberOfPinDigits = numberOfDigits
        EndIf
        StoredPin = -1
    Else
        PinInputState = PinInputRequired
        If (numberOfDigits == 1)
            NumberOfPinDigits = 1
            StoredPin = pin % 10
        ElseIf (numberOfDigits == 2)
            NumberOfPinDigits = 2
            StoredPin = pin % 100
        ElseIf (numberOfDigits == 3)
            NumberOfPinDigits = 3
            StoredPin = pin % 1000
        Else
            NumberOfPinDigits = 4
            StoredPin = pin % 10000
        EndIf
    EndIf
    EnteredPin = 0
    EnteredPinDifference = StoredPin
    EditingPinDigit = 0
    PinDigitOne = 0
    PinDigitTwo = 0
    PinDigitThree = 0
    PinDigitFour = 0
    WrongPinEnteredAction = wrongPinAction
EndFunction

;
; Update members after the user entered a pin digit.
;
Function UpdateAfterUserEnterPinDigit()
    EnteredPin = 0
    If (NumberOfPinDigits >= 1)
        EnteredPin = PinDigitOne
        If (NumberOfPinDigits >= 2)
            EnteredPin = 10 * EnteredPin + PinDigitTwo
            If (NumberOfPinDigits >= 3)
                EnteredPin = 10 * EnteredPin + PinDigitThree
                If (NumberOfPinDigits >= 4)
                    EnteredPin = 10 * EnteredPin + PinDigitFour
                EndIf
            EndIf
        EndIf
    EndIf
    EnteredPinDifference = StoredPin - EnteredPin
EndFunction

;
; Copy the stored pin to the pin digits.
;
Function CopyStoredPinToPinDigits()
    If (NumberOfPinDigits == 1)
        PinDigitOne = StoredPin % 10
    ElseIf (NumberOfPinDigits == 2)
        PinDigitOne = (StoredPin % 100) / 10
        PinDigitTwo = StoredPin % 10
    ElseIf (NumberOfPinDigits == 3)
        PinDigitOne = (StoredPin % 1000) / 100
        PinDigitTwo = (StoredPin % 100) / 10
        PinDigitThree = StoredPin % 10
    Else ; NumberOfPinDigits == 4
        PinDigitOne = (StoredPin % 10000) / 1000
        PinDigitTwo = (StoredPin % 1000) / 100
        PinDigitThree = (StoredPin % 100) / 10
        PinDigitFour = StoredPin % 10
    EndIf
EndFunction

;
; Contains a reference to the a shock collar that is 'registered' for the 'initiate connection'  option.
;
RealHandcuffs:ShockCollarBase Property RegisteredShockCollar Auto

;
; Queue an update of the last connected shock collar the next time the terminal menu closes.
;
Function RegisterForUpdateOnNextTerminalMenuClose()
    RegisterForMenuOpenCloseEvent("TerminalMenu")
EndFunction

;
; Update the shock collar when the menu closes.
;
Event OnMenuOpenCloseEvent(string asMenuName, bool abOpening)
    If (!abOpening && asMenuName == "TerminalMenu")
        UnregisterForMenuOpenCloseEvent("TerminalMenu")
        If (RegisteredShockCollar != None)
            Actor target = RegisteredShockCollar.SearchCurrentTarget()
            If (target != None)
                Int terminalResult = RegisteredShockCollar.UpdateShockCollarFromTerminalData(target)
                If (terminalResult == 2 && UI.IsMenuOpen("PipboyMenu"))
                    UI.CloseMenu("PipboyMenu")
                EndIf
            EndIf
        EndIf
    EndIf
EndEvent

;
; Group for firmware flavors.
;
Group Flavor
    Int Property NoCarrier = -1 AutoReadOnly
    Int Property MarkTwoFirmware = 0 AutoReadOnly
    Int Property MarkThreeFirmware = 1 AutoReadOnly
	Int Property HackedFirmware = 2 AutoReadOnly
EndGroup

;
; Current firmware flavor.
;
Int Property Flavor Auto Conditional

;
; Group for pin states.
;
Group PinInputState
    Int Property PinInputSucceeded = 0 AutoReadOnly
    Int Property PinInputFailed = 1 AutoReadOnly
    Int Property PinInputRequired = 2 AutoReadOnly
EndGroup

;
; Current pin input state.
;
Int Property PinInputState Auto Conditional

;
; How many digits the pin has (1, 2, 3, 4; or 0 for no pin).
;
Int Property NumberOfPinDigits Auto Conditional

;
; The pin stored in the system
;
Int Property StoredPin Auto Conditional

;
; The pin entered by the user as a number.
;
Int Property EnteredPin Auto

;
; The difference between the pin stored in the system and the pin entered by the user.
;
Int Property EnteredPinDifference Auto Conditional

;
; The index of the digit that the user is currently editing (1, 2, 3, 4; or 0 for none).
;
Int Property EditingPinDigit Auto Conditional

;
; First digit of the pin being entered by the user.
;
Int Property PinDigitOne Auto Conditional

;
; Second digit of the pin being entered by the user.
;
Int Property PinDigitTwo Auto Conditional

;
; Third digit of the pin being entered by the user.
;
Int Property PinDigitThree Auto Conditional

;
; Fourth digit of the pin being entered by the user.
;
Int Property PinDigitFour Auto Conditional

;
; Group for pin input states.
;
Group WrongPinEnteredAction
    Int Property WrongPinAllowRetry = 0 AutoReadOnly
    Int Property WrongPinLockout = 1 AutoReadOnly
    Int Property WrongPinShock = 2 AutoReadOnly
    Int Property WrongPinLockoutAndShock = 3 AutoReadOnly
EndGroup

;
; The action taken when entering the pin fails.
;
Int Property WrongPinEnteredAction Auto Conditional

;
; The remaining terminal lockout time.
;
Float Property RemainingLockoutTime Auto Conditional

;
; True if the collar is currently enabled, false otherwise
;
Bool Property CollarEnabled Auto Conditional

;
; Group for electronic lock states
;
Group ElectronicLockState
    Int Property NoElectronicLock = 0 AutoReadOnly
    Int Property ElectronicLockLocked = 1 AutoReadOnly
    Int Property ElectronicLockUnlocked = 2 AutoReadOnly
EndGroup

;
; The state of the electronic lock
;
Int Property ElectronicLockState Auto Conditional

;
; Set to true if a shock should be triggered after closing
;
Bool Property TriggerShock Auto Conditional

;
; Group for supported trigger modes.
;
Group SupportedTriggerModes
    Int Property SimpleSignalTriggerOnly = 0 AutoReadOnly
    Int Property SimpleSingleDoubleSignalTrigger = 1 AutoReadOnly
    Int Property SimpleSingleDoubleTripleSignalTrigger = 2 AutoReadOnly
EndGroup

;
; The supported trigger modes.
;
Int Property SupportedTriggerModes Auto Conditional

;
; Group for current trigger mode.
;
Group TriggerMode
    Int Property SimpleTrigger = 0 AutoReadOnly
    Int Property SingleSignalTrigger = 1 AutoReadOnly
    Int Property DoubleSignalTrigger = 2 AutoReadOnly
    Int Property TripleSignalTrigger = 3 AutoReadOnly
EndGroup

;
; The current trigger mode.
;
Int Property TriggerMode Auto Conditional

;
; Whether torture mode is supported (1) or not (0).
;
Bool Property SupportsTortureMode Auto Conditional

;
; Whether to restart torture mode.
;
Bool Property RestartTortureMode Auto

;
; How frequently to shock when in torture mode, in hours.
;
Float Property TortureModeFrequency Auto Conditional


;
; A blackbox value used by the terminal to track internal state.
; Must be set to zero before displaying the terminal.
;
Int Property InternalState Auto Conditional
