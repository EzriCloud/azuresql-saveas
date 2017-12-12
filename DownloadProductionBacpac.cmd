@echo off
mkdir data
for /f %%a in ('wmic path win32_localtime get day /format:list ^| findstr "="') do (set %%a)

REM Set the ENV Variables DBSTORAGEKEY and DBSTORAGENAME before running this script

SET CONTAINER=supportproduction
SET BACFILE=Support_Production%day%.bacpac
SET PATCHEDBACFILE=Support_Production%day%-patched.bacpac


"C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe" /Y /SourceKey:%DBSTORAGEKEY% /source:https://%DBSTORAGENAME%.blob.core.windows.net/%CONTAINER% /Pattern:%BACFILE% /Dest:data /Z:data\production-journal

powershell RemoveMasterKey.ps1  -bacpacPath data\%BACFILE%

del /Q data\%BACFILE%