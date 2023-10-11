$BasePath = "C:\Program Files\New-ImageGeneration"
Set-Location -Path "$BasePath\New-ImageGeneration"
if(Test-Path -Path "$BasePath\.env_setup_done")
{
	&"$BasePath\venv\Scripts\Activate.ps1" ; &"$BasePath\venv\Scripts\python.exe" "$BasePath\New-ImageGeneration\New-ImageGeneration.py"
}
if (! (Test-Path -Path "$BasePath\.env_setup_done"))
{
	if (! (Test-Path -Path 'C:\ProgramData\chocolatey\bin\choco.exe')){
		Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
	}
	if (! (Test-Path -Path 'C:\Python311')){
		Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force; &'C:\ProgramData\chocolatey\bin\choco.exe' install python311 -y --ignorechecksum --ignoredetectedreboot --params "/NoLockdown"
	}
	if(! (Test-Path "$BasePath\venv"))
	{
		&'C:\python311\python.exe' -m venv "$BasePath\venv"
	}
	Set-Content -Value "1" -Path "$BasePath\.env_setup_done" -Force
	&"$BasePath\venv\Scripts\Activate.ps1" ; &"$BasePath\venv\Scripts\pip.exe" install -r "$BasePath\New-ImageGeneration\requirements.txt" ; &"$BasePath\venv\Scripts\python.exe" "$BasePath\New-ImageGeneration\New-ImageGeneration.py"
}