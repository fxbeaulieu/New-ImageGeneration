[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $Instance
)

switch ($Instance) {
    XL { $Global:URLGetStatus = "http://192.168.4.254:64640/sdapi/v1/progress?skip_current_image=false" }
    SD { $Global:URLGetStatus = "http://localhost:64640/sdapi/v1/progress?skip_current_image=false" }
    XLT { $Global:URLGetStatus = "http://localhost:64669/sdapi/v1/progress?skip_current_image=false" }
    Default {}
}

function Compare-Progress
{
    if ($Global:CurrentProgression -gt 0.00 -and $Global:CurrentProgression -lt 0.99)
    {
        return $true
    }
    else{
        return $false
    }
}

Start-Sleep -Seconds 15
$Global:CurrentProgression = (((Invoke-WebRequest -Uri $Global:URLGetStatus |Select-Object Content).Content | ConvertFrom-Json) | Select-Object -Property progress).progress
While(Compare-Progress -eq $True)
{
    $Global:CurrentProgression = (((Invoke-WebRequest -Uri $Global:URLGetStatus |Select-Object Content).Content | ConvertFrom-Json) | Select-Object -Property progress).progress
    if ($Global:CurrentProgression -like "0.19","0,20","0,21" -or $Global:CurrentProgression -like "0.49","0.50","0.51" -or $Global:CurrentProgression -like "0.79","0.80","0.81")
    {
    $CurrentPreview = (((Invoke-WebRequest -Uri $Global:URLGetStatus |Select-Object Content).Content | ConvertFrom-Json) | Select-Object -property current_image).current_image
    $Picture = [Drawing.Bitmap]::FromStream([IO.MemoryStream][Convert]::FromBase64String($CurrentPreview))
    $PreviewPicturePath = "$ENV:TEMP\GenerationPreviewTMP.png"
    $Picture.Save("$PreviewPicturePath")
    Start-Process -FilePath $PreviewPicturePath
    }
    Start-Sleep -Seconds 3
    Write-Host ("{0:N2}" -f $Global:CurrentProgression)
}
Write-Host "Pas en cours de génération"