[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $Instance,
    [Parameter(Mandatory)]
    [int]
    $NbImg,
    [Parameter(Mandatory)]
    [string]
    $GenerationTemplate
)

$Global:PicOutputDirectory = "$ENV:USERPROFILE\Pictures\SDMonster"

if (! (Test-Path -Path $Global:PicOutputDirectory))
{
    New-Item -Path (Split-Path -Path $Global:PicOutputDirectory -Parent) -Name (Split-Path -Path $Global:PicOutputDirectory -LeafBase) -ItemType Directory -Force
}

switch ($Instance) {
    XL { $TextGenerationURL = 'http://192.168.4.254:64640/sdapi/v1/txt2img' }
    SD { $TextGenerationURL = 'http://localhost:64640/sdapi/v1/txt2img' }
    XLT { $TextGenerationURL = 'http://localhost:64669/sdapi/v1/txt2img' }
    Default {}
}

$GenerationTemplateData = Get-Content -Path $GenerationTemplate -Force | ConvertFrom-Json
$GenerationStatusArguments = "-File $PSScriptRoot\Get-Progress.ps1 -Instance $Instance"
if($NbImg -ne 1)
{
    $GenerationTemplateData.seed = -1
    $ImgBeingGenerated = 1
    do
    {
        Start-Process 'pwsh.exe' -ArgumentList $GenerationStatusArguments
        $Base64Picture = (((Invoke-WebRequest -Uri $TextGenerationURL -Method Post -ContentType "application/json" -Body ($GenerationTemplateData|ConvertTo-Json)).Content)|ConvertFrom-Json).images
        $ExportFileDate = Get-Date -Format FileDateTime
        $Picture = [Drawing.Bitmap]::FromStream([IO.MemoryStream][Convert]::FromBase64String($Base64Picture))
        $OutputPicturePath = ($Global:PicOutputDirectory+"\"+$Instance+$ExportFileDate+".png")
        $Picture.Save($OutputPicturePath)
        Start-Process -File $OutputPicturePath
        ++$ImgBeingGenerated
    }
    until
    (
        $ImgBeingGenerated = $NbImg
    )
}
else
{
    Start-Process 'pwsh.exe' -ArgumentList $GenerationStatusArguments
    $Base64Picture = (((Invoke-WebRequest -Uri $TextGenerationURL -Method Post -ContentType "application/json" -Body ($GenerationTemplateData|ConvertTo-Json)).Content)|ConvertFrom-Json).images
    $ExportFileDate = Get-Date -Format FileDateTime
    $Picture = [Drawing.Bitmap]::FromStream([IO.MemoryStream][Convert]::FromBase64String($Base64Picture))
    $OutputPicturePath = ($Global:PicOutputDirectory+"\"+$SDVersion+$ExportFileDate+".png")
    $Picture.Save($OutputPicturePath)
    Start-Process -File $OutputPicturePath
}