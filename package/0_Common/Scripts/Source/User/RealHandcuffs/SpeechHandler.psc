;
; Contains functions that make actors say generic topics.
; Conceptually this is a big switch-case statement for various voice types.
;
Scriptname RealHandcuffs:SpeechHandler extends Quest

RealHandcuffs:Library Property Library Auto Const Mandatory

FormList Property VoicesDialogueGenericList Auto Const Mandatory
Topic Property DialogueGenericDeathGroup Auto Const Mandatory
Topic Property DialogueGenericBleedoutGroup Auto Const Mandatory

;
; Group for the different topics that can be said by actors.
;
Group Topics
    ; pain topic - usually a painful grunt or scream
    String Property Pain = "Pain" AutoReadOnly
    ; bleedout topic - usually painful grunts, coughing, etc.
    String Property Bleedout = "Bleedout" AutoReadOnly
EndGroup


;
; Make an actor say the pain topic - usually a painful grunt or scream.
; This may fail for actors with some voice types (usually it only works for generic voice types).
; If testOnly is true, this will only test if the function would work or not.
;
Bool Function SayPainTopic(Actor akActor, Bool testOnly = false)
    Return SayTopic(akActor, Pain, testOnly)
EndFunction

;
; Make an actor say the bleedout topic - usually painful grunts, coughing, etc.
; This may fail for actors with some voice types (usually it only works for generic voice types).
; If testOnly is true, this will only test if the function would work or not.
;
Bool Function SayBleedoutTopic(Actor akActor, Bool testOnly = false)
    Return SayTopic(akActor, Bleedout, testOnly)
EndFunction


;
; Say a topic passed by identifier string - topicIdentifier must be one of the strings defined in the Topics group.
; This may fail for actors with some voice types (usually it only works for generic voice types).
; If testOnly is true, this will only test if the function would work or not.
;
Bool Function SayTopic(Actor akActor, String topicIdentifier, Bool testOnly = false)
    If (akActor == None)
        Return false
    EndIf
    If (Library.SoftDependencies.IsDeviousDevicesGagged(akActor))
        Return SayTopicDeviousDevicesGagged(akActor, topicIdentifier, testOnly)
    EndIf
    VoiceType voice = akActor.GetVoiceType()
    If (VoicesDialogueGenericList.HasForm(voice))
        Return SayTopicGenericVoice(akActor, topicIdentifier, testOnly)
    EndIf
    If (Library.SoftDependencies.DLCNukaWorldAvailable)
        If (Library.SoftDependencies.DLC04VoicesDialogueRaider.HasForm(voice))
            Return SayTopicDLC04RaiderVoice(akActor, topicIdentifier, testOnly)
        EndIf
        If (Library.SoftDependencies.DLC04SettlementNPCVoices.HasForm(voice))
            Return SayTopicDLC04SettlementNPCVoice(akActor, topicIdentifier, testOnly)
        EndIf
    EndIf
    If (Library.SoftDependencies.SSConquerorAvailable && Library.SoftDependencies.kgConq_RaiderGangVoiceList.HasForm(voice))
        Return SayTopicSSConqRaiderGangVoice(akActor, topicIdentifier, testOnly)
    EndIf
    Return False
EndFunction


;
; Function to say topics for Devious Devices gagged actors.
;
Bool Function SayTopicDeviousDevicesGagged(Actor akActor, String topicIdentifier, Bool testOnly = false)
    If (!Library.SoftDependencies.DDCompatibilityActive)
        Return false
    EndIf
    If (Library.IsFemale(akActor))
        If (topicIdentifier == Bleedout)
            If (!testOnly)
                akActor.Say(Library.SoftDependencies.DDCompatibilityFemaleGaggedExhausted, None, false, None)
            EndIf
        ElseIf (topicIdentifier == Pain)
            If (!testOnly)
                akActor.Say(Library.SoftDependencies.DDCompatibilityFemaleGaggedPain, None, false, None)
            EndIf
        Else
            Return false
        EndIf
    Else
        ; Devious Devices only supports female gagged voices
        Return false
    EndIf
    Return true
EndFunction

;
; Function to say topics for actors using generic voices.
;
Bool Function SayTopicGenericVoice(Actor akActor, String topicIdentifier, Bool testOnly = false)
    If (topicIdentifier == Bleedout)
        If (!testOnly)
            akActor.Say(DialogueGenericBleedoutGroup, None, false, None)
        EndIf
    ElseIf (topicIdentifier == Pain)
        ; use the death topic, it has more pronounced screams than the hit topic
        If (!testOnly)
            akActor.Say(DialogueGenericDeathGroup, None, false, None)
        EndIf
    Else
        Return false
    EndIf
    Return true
EndFunction

;
; Function to say topics for actors using the NukaWorld raider voices.
;
Bool Function SayTopicDLC04RaiderVoice(Actor akActor, String topicIdentifier, Bool testOnly = false)
    If (topicIdentifier == Bleedout)
        If (!testOnly)
            akActor.Say(Library.SoftDependencies.DLC04GenericBleedoutGroup, None, false, None)
        EndIf
    ElseIf (topicIdentifier == Pain)
        ; use either hit or death topic randomly
        If (!testOnly)
            If (Utility.RandomInt(0, 1) == 0)
                akActor.Say(Library.SoftDependencies.DLC04GenericHitGroup, None, false, None)
            Else
                akActor.Say(Library.SoftDependencies.DLC04GenericDeathGroup, None, false, None)
            EndIf
        EndIf
    Else
        Return false
    EndIf
    Return true
EndFunction

;
; Function to say topics for actors using the NukaWorld settlement voices.
;
Bool Function SayTopicDLC04SettlementNPCVoice(Actor akActor, String topicIdentifier, Bool testOnly = false)
    If (topicIdentifier == Bleedout || topicIdentifier == Pain)
        ; there is no bleedout/hit topic, use the death topic
        If (!testOnly)
            akActor.Say(Library.SoftDependencies.DLC04SettlementDeathGroup, None, false, None)
        EndIf
    Else
        Return false
    EndIf
    Return true
EndFunction

;
; Function to say topics for actors using the Sim Settlements Conqueror Raider Gang voices.
;
Bool Function SayTopicSSConqRaiderGangVoice(Actor akActor, String topicIdentifier, Bool testOnly)
    If (topicIdentifier == Bleedout)
        If (!testOnly)
            akActor.Say(Library.SoftDependencies.kgConq_Dialogue_Raiders_Bleedout, None, false, None)
        EndIf
    ElseIf (topicIdentifier == Pain)
        ; use either hit or death topic randomly
        If (!testOnly)
            If (Utility.RandomInt(0, 1) == 0)
                akActor.Say(Library.SoftDependencies.kgConq_Dialogue_Raiders_Hit, None, false, None)
            Else
                akActor.Say(Library.SoftDependencies.kgConq_Dialogue_Raiders_Death, None, false, None)
            EndIf
        EndIf
    Else
        Return false
    EndIf
    Return true
EndFunction