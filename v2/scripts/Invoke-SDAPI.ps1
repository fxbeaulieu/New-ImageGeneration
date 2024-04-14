[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [int]
    $NbImg,
    [Parameter(Mandatory)]
    [string]
    $GenerationTemplate
)

$Global:PicOutputDirectory = "$PSScriptRoot\..\SDMonster_output"

if (! (Test-Path -Path $Global:PicOutputDirectory))
{
    New-Item -Path (Split-Path -Path $Global:PicOutputDirectory -Parent) -Name (Split-Path -Path $Global:PicOutputDirectory -LeafBase) -ItemType Directory -Force
}

$TextGenerationURL = 'http://localhost:64640/sdapi/v1/txt2img'

$GenerationTemplateData = Get-Content -Path $GenerationTemplate -Force | ConvertFrom-Json
$ProgressionScript = "$PSScriptRoot\Get-Progress.ps1"
$GenerationStatusArguments = "-File $ProgressionScript"
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
        $OutputPicturePath = ($Global:PicOutputDirectory+"\"+$ExportFileDate+".png")
        $Picture.Save($OutputPicturePath)
        Start-Process -File $OutputPicturePath -WorkingDirectory $Global:PicOutputDirectory
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
    Start-Process -File "$OutputPicturePath" -WorkingDirectory "$Global:PicOutputDirectory"
}