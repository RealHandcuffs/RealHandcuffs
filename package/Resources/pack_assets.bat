@echo off
cd Data
..\Tools\Archive2\Archive2.exe Materials\RealHandcuffs,Meshes\AnimTextData,Meshes\RealHandcuffs,Scripts\RealHandcuffs -create="RealHandcuffs - Main.ba2"
echo You need to add the Sound\RealHandcuffs folder manually, with NO COMPRESSION
..\Tools\Archive2\Archive2.exe "RealHandcuffs - Main.ba2"
cd ..
