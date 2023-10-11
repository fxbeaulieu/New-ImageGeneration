$Global:URLGetXLModels="http://192.168.4.254:64640/sdapi/v1/sd-models"
$Global:URLGetSDModels="http://localhost:64640/sdapi/v1/sd-models"
$Global:URLGetSDStatus = "http://localhost:64640/sdapi/v1/progress?skip_current_image=false"
$Global:URLGetXLStatus = "http://192.168.4.254:64640/sdapi/v1/progress?skip_current_image=false"
$Global:URLGetXLTStatus = "http://localhost:64669/sdapi/v1/progress?skip_current_image=false"

function Select-Model
{
$Global:SelectedModel = Read-Host -Prompt "Coller le nom du modèle obtenu avec Get-XLModels ou Get-SDModels et faire ENTER".
$Global:SetModelsOptions = $Global:SetModelsOptions.Replace('"',"`"$Global:SelectedModel`"")
}

function Get-XLModels
{
Write-Host -ForegroundColor Red "XL Models"
((Invoke-WebRequest -Uri $Global:URLGetXLModels |Select-Object Content).Content |ConvertFrom-Json | Select-Object model_name).model_name
}

function Get-SDModels
{
Write-Host -ForegroundColor Green "SD Models"
((Invoke-WebRequest -Uri $Global:URLGetSDModels |Select-Object Content).Content |ConvertFrom-Json | Select-Object model_name).model_name
}



function Get-SDStatus{
((Invoke-WebRequest -Uri $Global:URLGetSDStatus |Select-Object Content).Content | ConvertFrom-Json) | Select-Object -property progress,eta_relative
}

function Get-XLStatus{
((Invoke-WebRequest -Uri $Global:URLGetXLStatus |Select-Object Content).Content | ConvertFrom-Json) | Select-Object -property progress,eta_relative
}

function Get-XLTStatus{
((Invoke-WebRequest -Uri $Global:URLGetXLTStatus |Select-Object Content).Content | ConvertFrom-Json) | Select-Object -property progress,eta_relative
}

function Get-SDCurrentPic
{
if ((((Invoke-WebRequest -Uri $Global:URLGetSDStatus |Select-Object Content).Content | ConvertFrom-Json) | Select-Object -property progress).progress -ne 0)
{
$CurrentPic = (((Invoke-WebRequest -Uri $Global:URLGetSDStatus |Select-Object Content).Content | ConvertFrom-Json) | Select-Object -property current_image).current_image
$Picture = [Drawing.Bitmap]::FromStream([IO.MemoryStream][Convert]::FromBase64String($CurrentPic))
$Picture.Save("$ENV:TEMP\XLTTEMP.png")
Start-Process "$ENV:TEMP\XLTTEMP.png"
}
}

function Get-XLCurrentPic
{
if ((((Invoke-WebRequest -Uri $Global:URLGetXLStatus |Select-Object Content).Content | ConvertFrom-Json) | Select-Object -property progress).progress -ne 0)
{
$CurrentPic = (((Invoke-WebRequest -Uri $Global:URLGetXLStatus |Select-Object Content).Content | ConvertFrom-Json) | Select-Object -property current_image).current_image
$Picture = [Drawing.Bitmap]::FromStream([IO.MemoryStream][Convert]::FromBase64String($CurrentPic))
$Picture.Save("$ENV:TEMP\XLTTEMP.png")
Start-Process "$ENV:TEMP\XLTTEMP.png"
}
}

function Get-XLTCurrentPic
{
if ((((Invoke-WebRequest -Uri $Global:URLGetXLTStatus |Select-Object Content).Content | ConvertFrom-Json) | Select-Object -property progress).progress -ne 0)
{
$CurrentPic = (((Invoke-WebRequest -Uri $Global:URLGetXLTStatus |Select-Object Content).Content | ConvertFrom-Json) | Select-Object -property current_image).current_image
$Picture = [Drawing.Bitmap]::FromStream([IO.MemoryStream][Convert]::FromBase64String($CurrentPic))
$Picture.Save("$ENV:TEMP\XLTTEMP.png")
Start-Process "$ENV:TEMP\XLTTEMP.png"
}
}