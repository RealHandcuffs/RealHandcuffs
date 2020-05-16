Scriptname LL_FourPlay Native Hidden

;
;	Shared community library of utility function from LoverLab distributed with FourPlay resources as a F4SE plugin with sources included
;

;	Version 35 for runtime 1.10.138	2019 11 01 by jaam and Chosen Clue and EgoBallistic

;	Runtime version: This file should be runtime neutral. The accompanying F4SE plugin (ll_fourplay_1_10_138.dll) is NOT!
;		You need to always use a plugin corresponding with the game version you play.
;		Plugin should be available just after F4SE has been updated for the modified runtime.
;		Runtime versions lower than 1.10.138 will no longer be supported.
;		Written and tested against F4SE 0.6.17. You should not use an older version of F4SE.
;
;
;

; Returns the version of this script (when someone has not forgotten to update it :) )
Float Function GetLLFPScriptVersion() global
	return 35.0
endFunction

; Returns the version of the plugin and servers to verify it is properly installed.
Float Function GetLLFPPluginVersion() native global

; Custom profile: written into "Data\F4SE\Plugins"
; ===============

; Returns the full path for custom profile name. IE "WhereverYourGameIs\Data\F4SE\Plugins\name". Don't forget to provide the .ini extension.
string Function GetCustomConfigPath(string name) native global

; Get the value of custom config string option
string Function GetCustomConfigOption(string name, string section, string key) native global

; Get the value of custom config integer option (Use 0/1 for boolean)
int Function GetCustomConfigOption_UInt32(string name, string section, string key) native global

; Get the value of custom config float option
Float Function GetCustomConfigOption_float(string name, string section, string key) native global

; Sets the value of custom config string option (at most 66535 characters per option). The directories and path will be created as needed. If the result is false, the set did not happen.
bool Function SetCustomConfigOption(string name, string section, string key, string value) native global

; Sets the value of custom config integer option. The directories and path will be created as needed. If the result is false, the set did not happen.
bool Function SetCustomConfigOption_UInt32(string name, string section, string key, int data) native global

; Sets the value of custom config float option. The directories and path will be created as needed. If the result is false, the set did not happen.
bool Function SetCustomConfigOption_float(string name, string section, string key, float data) native global

; Get all the keys and values contained in a section. Both at once to avoid discrepancies in the order.
;	The keys are in VarToVarArray(Var[0]) as String[] and the values in VarToVarArray(Var[1]) as String[]
Var[] Function GetCustomConfigOptions(string fileName, string section) native global

; Set a list of keys and values in a section. Any other existing key will be left alone.
bool Function SetCustomConfigOptions(string fileName, string section, string[] keys, string[] values) native global

; Reset all the keys and values contained in a section.
;	Any exiting key value pair will be suppressed first, so providing none arrays will effectivly removes all keys from the section.
bool Function ResetCustomConfigOptions(string fileName, string section, string[] keys, string[] values) native global

; Get all the sections in a file.
string[] Function GetCustomConfigSections(string fileName) native global

; For all array functions:
;	The implementation as an arbitrary limitation of 32767 bytes buffer for all Keys, Values or sections involved.
;		If needed because the limitation becomes a problem, another implementation can be done using memory allocation, though there will remain a limit imposed by Windows.
;	When arrays for keys and values are provided, the count of elements in both arrays must be identical or the function fails on purpose.
;	An empty value should be provided as a zero length string.	TO BE TESTED

;
;	Camera functions
;	================
;

; Forces the FlyCam state.
;	if activate is true and the FlyCam is not active AND the FXCam is not active either, the FlyCam will be activated.
;	if activate is false and the FlyCam is active, the FlyCam will be deactivated.
;	if the requested state is identical to the current state nothing is done.
;		Returns whether the FlyCam was active or not before the call so mods can restore the previous state if needed.
bool Function SetFlyCam(bool activate) native global

;	TO BE TESTED
; Forces the FlyCam state. Alternative version that allows to pause/unpause the game when entering FlyCam
;	if activate is true and the FlyCam is not active AND the FXCam is not active either, the FlyCam will be activated.
;		if pause then the game will be paused
;	if activate is false and the FlyCam is active, the FlyCam will be deactivated.
;	otherwise if the requested activate is identical to the current state nothing is done.
;		Returns whether the FlyCam was active or not before the call so mods can restore the previous state if needed.
;TBT; bool Function SetFlyCam2(bool activate, bool pause) native global
;	TO BE TESTED - So far this is useless as scripts seem to be stopped while in pause mode :(

; Get the current state of the FlyCam
bool Function GetFlyCam() native global

; Get the current pause state of the game
bool Function GetPaused() native global

; Get the current state of the FXCam
bool Function GetFXCam() native global

; Select the speed at which the FlyCam moves (identical to SetUFOCamSpeedMult/sucsm console command)
;	The console command supports an optional second parameter to control rotation speed.
;	The way it handles default value is not compatible so I use an explicit bool to select which speed to change
;	Returns the previous value of the selected speed.
float Function SetFlyCamSpeedMult(float speed, bool rotation=False) native global

;
;	Power Armor/Race/Skeleton functions
;	===================================
;

;	Returns the actor's race when in PowerArmor
Race Function GetActorPowerArmorRace(Actor akActor) native global

;	Returns the actor's skeleton when in PowerArmor
string Function GetActorPowerArmorSkeleton(Actor akActor) native global

;	Returns the actor's current skeleton, not affected by PowerArmor
string Function GetActorSkeleton(Actor akActor) native global

;Chosen Clue Edit

;
;	String functions
;	================
;

;	Returns the first index of the position the toFind string starts. You can use this to check if an animation has a tag on it. Is not case sensitive.
Int Function StringFind(string theString, string toFind, int startIndex = 0) native global

;	Returns the selected substring from theString. If no length is set, the entire string past the startIndex number is returned.
string Function StringSubstring(string theString, int startIndex, int len = 0) native global

;	Splits the string into a string array based on the delimiter given in the second parameter. 
;	As this function does ignore whitespace, putting a space as the delimiter will only result in a string being returned without spaces.
string[] Function StringSplit(string theString, string delimiter = ",") native global

;	Opposite of StringSplit.
string Function StringJoin(string[] theStrings, string delimiter = ",") native global


;
;	Array functions
;	===============
;

;Just a precursor: This does not mean we can use Alias based scripts to store animations like sexlab does, as the F4SE team has yet to include a typedef of them in the F4SE CPP files. I am guessing that they haven't reverse engineered it yet.

Form[] Function ResizeFormArray(Form[] theArray, int theSize, Form theFill = NONE) native global

String[] Function ResizeStringArray(String[] theArray, int theSize, String theFill = "") native global

Int[] Function ResizeIntArray(Int[] theArray, int theSize, Int theFill = 0) native global

Float[] Function ResizeFloatArray(Float[] theArray, int theSize, Float theFill = 0.0) native global

Bool[] Function ResizeBoolArray(Bool[] theArray, int theSize, Bool theFill = False) native global

Var[] Function ResizeVarArray2(Var[] theArray, int theSize) native global

Var[] Function ResizeVarArray(Var[] theArray, int theSize) global
	; Because filling with invalid values will CTD
	; Bugged for any version prior to 14
	; theFill will be ignored, but kept for compatibility. Anyway nobody used it ever as it would have CTD. Please use ResizeVarArray2
	Int theFill = 0
	return ResizeVarArrayInternal(theArray, theSize, theFill)
endFunction

;	if the int theSize is negative, the resulting array is a copy of the original array unchanged.

; Sets the minimum array size required by a mod. Returns false if the current value was greater.
Bool Function SetMinimalMaxArraySize(int theMaxArraySize) native global
; This patches ArrayAdd and ArrayInsert so they respect that maximum. The value is memorised in ToolLib.ini
;[Custom Arrays]
;uMaxArraySize=nnnnnn
;
; !! Creating arrays that are too large will adversaly affect your game !!

;
;	Keyword functions
;	=================
;

; Return the first keyword whose editorID is akEditorID
Keyword Function GetKeywordByName(string akEditorID) native global

; Adds a keyword to a form (not only a reference). Does not persists.
bool Function AddKeywordToForm(Form akForm, Keyword akKeyword) native global

; Delete a keyword from a form (not only a reference). Does not persists.
bool Function DelKeywordFromForm(Form akForm, Keyword akKeyword) native global

; Return an array of all keywords loaded in game.
Keyword[] Function GetAllKeywords() native global

;
;	CrossHair functions
;	====================
;

;	Returns the Reference that is currently under the CrossHair. Returns None if there isn't one currently.
ObjectReference Function LastCrossHairRef() native global

;	Returns the last Actor that is or was under the CrossHair. Returns None until there is one since the game was (re)started.
Actor Function LastCrossHairActor() native global

;
;	ObjectReference functions
;	=========================
;

;	Set the reference display name as a string without token. TO BE TESTED
bool Function ObjectReferenceSetSimpleDisplayName(ObjectReference akObject, string displayName) native global

;
;	Actor functions
;	===============
;

;	Check if the ActorBase has a specific skin. TO BE TESTED
bool Function ActorBaseIsClean(Actor akActor) native global

;	Return the WNAM ARMO of either the actor base or the actor's race
Form Function GetActorBaseSkinForm(Actor akActor) native global

;	MFG morph function provided by EgoBallistic

;   Apply a MFG Morph to the actor
bool Function MfgMorph(Actor akActor, int morphID, int intensity) native global

;	Set all MFG Morph values to zero on an actor
bool Function MfgResetMorphs(Actor akActor) native global

;	Save an actor's MFG Morph values to an array of float
Float[] Function MfgSaveMorphs(Actor akActor) native global

;	Restore an array of saved MFG morph values to an actor
bool Function MfgRestoreMorphs(Actor akActor, Float[] values) native global

;	Copy the MFG morph values from one actor to another
bool Function MfgCopyMorphs(Actor a0, Actor a1) native global

;	Apply a set of MFG morphs to an actor.  Morph ID morphIDs[x] will be set to values[x]
bool Function MfgApplyMorphSet(Actor akActor, int[] morphIDs, int[] values) native global

;
;	Collision functions
;	===================
;

;	Set the collision state of a reference. Returns the previous state.	TO BE TESTED _ currently fails.
;TBT;	bool Function ObjectReferenceSetCollision(ObjectReference akObject, bool enable=True) native global

;	Get the collision state of a reference. If akObject is None, return the global collision state (controlled by TCL).	TO BE TESTED
;TBT;	bool Function ObjectReferenceGetCollision(ObjectReference akObject) native global

;
;	Misc. Form functions
;	====================
;

;	Returns the Editor ID of a Race. Originally GetFormEditorID, but passing in a form and using the F4SE function GetEditorID() has only worked on Quest and Race forms. So I've just made it for race forms only.
String Function GetRaceEditorID(Race akForm) native global

; Returns the name of the plugin that created a form
String Function OriginalPluginName(Form akForm) native global

; Returns the persistent ID of a form (excluding the load index) Should be compatible with esl files. (Fixed as of v18)
Int Function OriginalPluginID(Form akForm) native global

; Returns whether a form is in a given leveled item list
bool Function GetInLeveledItem(Leveleditem akList, Form akForm) native global

;
;	Misc functions
;	==============
;

;	Prints a message to the debug console. Exposes the internal F4SE function Console_Print using the code found in Papyrutil in Skyrim.
bool Function PrintConsole(String text) native global

;
;	HIDDEN Functions. Never call directly.
;

; hidden function, use ResizeVarArray instead
Var[] Function ResizeVarArrayInternal(Var[] theArray, int theSize, Var theFill) native global

