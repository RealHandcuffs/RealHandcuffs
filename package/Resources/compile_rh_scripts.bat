@echo off
cd Data\Scripts\Source\User
for %%f in (RealHandcuffs\*,RealHandcuffs\DeviousDevices\*,RealHandcuffs\JustBusiness\*) do (
    if %%f == RealHandcuffs\DebugWrapper.psc (
        echo %%f [DEBUG]
        "..\..\..\..\Papyrus Compiler\PapyrusCompiler.exe" %%f -final -optimize -quiet -flags=..\Base\Institute_Papyrus_Flags.flg -import=..\Base -output=..\..
    ) else (
       echo %%f
       "..\..\..\..\Papyrus Compiler\PapyrusCompiler.exe" %%f -release -final -optimize -quiet -flags=..\Base\Institute_Papyrus_Flags.flg -import=..\Base -output=..\..
    )
)
cd ..\..\..\..