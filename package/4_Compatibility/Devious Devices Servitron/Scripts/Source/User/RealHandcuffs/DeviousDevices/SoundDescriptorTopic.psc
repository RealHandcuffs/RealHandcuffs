;
; A simple topic script that plays a sound descriptor when the topic us said.
; This can be used to turn a condition into a keyword.
;
Scriptname RealHandcuffs:DeviousDevices:SoundDescriptorTopic extends TopicInfo

Sound Property SoundDescriptor Auto Const Mandatory

Event OnBegin(ObjectReference akSpeakerRef, bool abHasBeenSaid)
    SoundDescriptor.Play(akSpeakerRef)
EndEvent