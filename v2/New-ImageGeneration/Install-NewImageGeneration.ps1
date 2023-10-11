Set-Location $PSScriptRoot
if(! (Test-Path "$ENV:ALLUSERSPROFILE\chocolatey\bin\choco.exe"))
{
	#SetupChoco
}
if(! (Test-Path "C:\Python311\python.exe"))
{
	#Choco Install Python3
}
if(! (Test-Path "$PSScriptRoot\venv"))
{
	&'C:\python311\python.exe' -m venv "$PSScriptRoot\venv"
}
&"$PSScriptRoot\venv\Scripts\Activate.ps1" ; &"$PSScriptRoot\venv\Scripts\pip.exe" install -r "$PSScriptRoot\requirements.txt" ; &"$PSScriptRoot\venv\Scripts\python.exe" "$PSScriptRoot\New-ImageGeneration.py"
