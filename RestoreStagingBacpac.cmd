for /f %%a in ('wmic path win32_localtime get day /format:list ^| findstr "="') do (set %%a)

SET PATCHEDBACFILE=Support_Staging%day%-patched.bacpac

sqlcmd -S localhost -d master -Q "alter database [Support_StagingLocal] set single_user with rollback immediate"
sqlcmd -S localhost -d master -Q "drop database [Support_StagingLocal]"

"C:\Program Files (x86)\Microsoft SQL Server\140\DAC\bin\sqlpackage.exe" /a:Import /sf:data\%PATCHEDBACFILE% /tsn:localhost /tdn:Support_StagingLocal