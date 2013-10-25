@echo off
if "%~1"=="" (
	echo No task specified, defaulting to 'Test'
	set task=Test
) else (
	set task=%1
)
powershell.exe -noexit -ExecutionPolicy unrestricted -Command "invoke-psake .\build.ps1 %task%" 