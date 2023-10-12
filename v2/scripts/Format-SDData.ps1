[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $Instance,
    [Parameter(Mandatory)]
    [string]
    $NbImg,
    [Parameter(Mandatory)]
    [string]
    $InputCKPT,
    [Parameter(Mandatory)]
    [string]
    $Width,
    [Parameter(Mandatory)]
    [string]
    $Height,
    [Parameter(Mandatory)]
    [string]
    $Sampler,
    [Parameter(Mandatory)]
    [string]
    $Seed,
    [Parameter(Mandatory)]
    [string]
    $Attention,
    [Parameter(Mandatory)]
    [string]
    $Steps,
    [Parameter(Mandatory)]
    [string]
    $RestoreFaces,
    [Parameter(Mandatory)]
    [string]
    $Style,
    [Parameter(Mandatory)]
    [string]
    $Direction,
    [Parameter(Mandatory)]
    [string]
    $Prompt,
    [Parameter()]
    [string]
    $NegativePrompt,
    [Parameter()]
    [string]
    $Artist1,
    [Parameter()]
    [string]
    $Artist2,
    [Parameter()]
    [string]
    $Artist3,
    [Parameter()]
    [string]
    $Concept1,
    [Parameter()]
    [string]
    $Concept2,
    [Parameter()]
    [string]
    $Concept3,
    [Parameter()]
    [string]
    $Mood1,
    [Parameter()]
    [string]
    $Mood2,
    [Parameter()]
    [string]
    $Mood3
)

$Global:OutputDirectory = "$ENV:USERPROFILE\Documents\sd_generation_parameters_saved"
$Global:StylesDetails = Get-Content -Path "$PSScriptRoot\..\lists\styles.json" | ConvertFrom-Json

$Global:BasicNegative = "mutation, deformed, deformed iris, duplicate, morbid, mutilated, disfigured, poorly drawn hand, poorly drawn face, bad proportions, gross proportions, extra limbs, cloned face, long neck, malformed limbs, missing arm, missing leg, extra arm, extra leg, fused fingers, too many fingers, extra fingers, mutated hands, blurry, bad anatomy, out of frame, contortionist, contorted limbs, exaggerated features, disproportionate, twisted posture, unnatural pose, disconnected, disproportionate, warped, misshapen, out of scale, "
$Global:BasicPositive = "4k, 8k, uhd, hd, very detailed, high level of detail, rendered as masterpiece, very smooth, sharp, global illumination, ray tracing, stunning, masterpiece, best quality, "

$Global:DetailsEmbeddings = "fFaceDetail EyeDetail OverallDetail"
$Global:NegativeEmbeddings = "HandNeg-neg CyberRealistic_Negative-neg easynegative ng_deepnegative_v1_75t"

$TemplateTxtToImg = Get-Content -Path "$PSScriptRoot\..\templates\txttoimg-request-body.txt" | ConvertFrom-Json

$SetCheckpointArguments = "-File $PSSCriptRoot\Set-Checkpoint.ps1 -InputCKPT $InputCKPT -Instance $Instance"
Start-Process 'pwsh.exe' -NoNewWindow -Wait -ArgumentList $SetCheckpointArguments

$Artists = $Artist1, $Artist2, $Artist3
$Concepts = $Concept1, $Concept2, $Concept3
$Moods = $Mood1, $Mood2, $Mood3

[int]$NbImg = $NbImg
[int]$Width = $Width
[int]$Height = $Height
[int64]$Seed = $Seed
[int]$Attention = $Attention
[int]$Steps = $Steps

if($RestoreFaces -eq 'True')
{
    [System.Boolean]$RestoreFaces = $true
}
else
{
    [System.Boolean]$RestoreFaces = $false
}

function Format-ConceptualKeywordsToPrompt {
    param (
        [Parameter(Mandatory)]
        [array]
        $ConceptualKeywords
    )

    [string]$ConceptualKeywordsToPrompt = ""
    foreach($Word in $ConceptualKeywords)
    {
        if($Word -notlike "")
        {
            [string]$ConceptualKeywordsToPrompt+="($Word`:1.4), "
        }
    }

    Return $ConceptualKeywordsToPrompt
}

function Format-DirectionKeywordToPrompt {
    param(
        [Parameter(Mandatory)]
        [string]
        $DirectionKeyword
    )
    [string]$DirectionKeywordToPrompt = "($DirectionKeyword`:1.5), "

    Return $DirectionKeywordToPrompt
}

function Format-MoodKeywordsToPrompt {
    param (
        [Parameter(Mandatory)]
        [array]
        $MoodKeywords
    )

    [string]$MoodKeywordsToPrompt = ""
    foreach($Word in $MoodKeywords)
    {
        if($Word -notlike "")
        {
            [string]$MoodKeywordsToPrompt+="($Word`:1.3), "
        }
    }

    Return $MoodKeywordsToPrompt
}

function Format-StyleToPrompt {
    param (
        [Parameter(Mandatory)]
        [string]
        $ArtStyle
    )

        if ($ArtStyle -eq 'Random')
        {
            [int]$RandomlySelectedArtStyle = Get-Random -Minimum 0 -Maximum $Global:RandomStyleSelectorMaxValue
            [string]$SelectedArtStylePrompt = ($Global:StylesDetails[$RandomlySelectedArtStyle] | Select-Object -Property prompt).prompt
            [string]$SelectedArtStyleNegativePrompt = ($Global:StylesDetails[$RandomlySelectedArtStyle] | Select-Object -Property negative_prompt).negative_prompt
        }
        else
        {
            [string]$SelectedArtStylePrompt = ($Global:StylesDetails | Where-Object -Property name -eq $ArtStyle | Select-Object -Property prompt).prompt
            [string]$SelectedArtStyleNegativePrompt = ($Global:StylesDetails | Where-Object -Property name -eq $ArtStyle | Select-Object -Property negative_prompt).negative_prompt
        }

        Return $SelectedArtStylePrompt,$SelectedArtStyleNegativePrompt
}

function Format-ArtistsToPrompt {
    param (
        [Parameter(Mandatory)]
        [array]
        $Artists
    )

    [string]$ArtistsToPrompt = ""
    foreach($Artist in $Artists)
    {
        if($Artist -notlike "")
        {
        [string]$ArtistsToPrompt+="(style of $Artist`:1.3), "
        }
    }

    Return $ArtistsToPrompt
}

function Format-PromptComponents {
    if($null -eq $Concepts)
    {$Concepts = ""}
    else{[string]$ConceptualKeywordsToPrompt = Format-ConceptualKeywordsToPrompt -ConceptualKeywords $Concepts}
    [string]$DirectionKeywordToPrompt = Format-DirectionKeywordToPrompt -DirectionKeyword $Direction
    if($null -eq $Moods)
    {$Moods = ""}
    else{[string]$MoodKeywordsToPrompt = Format-MoodKeywordsToPrompt -MoodKeywords $Moods}
    [string]$SelectedArtStylePrompt,[string]$SelectedArtStyleNegativePrompt = Format-StyleToPrompt -ArtStyle $Style
    [string]$StyledPrompt = $SelectedArtStylePrompt.Replace('<<PROMPT HERE>>', $Prompt)
    if($null -eq $Artists)
    {$Artists = ""}
    else{[string]$ArtistsToPrompt = Format-ArtistsToPrompt -Artists $Artists}
    $StyledNegativePrompt = ($SelectedArtStyleNegativePrompt+", "+$Global:PromptParameters.NegativePrompt+", ")
    $FullUserPrompt = ($ConceptualKeywordsToPrompt+$DirectionKeywordToPrompt+$MoodKeywordsToPrompt+$StyledPrompt+$ArtistsToPrompt)
    Return $FullUserPrompt,$StyledNegativePrompt
}

$FormatedPrompt = Format-PromptComponents

if($Instance -ne 'SD')
{
    [string]$Global:FinalPromptComposition = ($FormatedPrompt[0]+$Global:BasicPositive)
    [string]$Global:FinalNegativePromptComposition = ($FormatedPrompt[1]+$Global:BasicNegative)
}
if($Instance -eq 'SD')
{
    [string]$Global:FinalPromptComposition = ($FormatedPrompt[0]+$Global:BasicPositive+$Global:DetailsEmbeddings)
    [string]$Global:FinalNegativePromptComposition = ($FormatedPrompt[1]+$Global:BasicNegative+$Global:NegativeEmbeddings)
}

$TemplateTxtToImg.n_iter = $NbImg
$TemplateTxtToImg.prompt = $Global:FinalPromptComposition
$TemplateTxtToImg.negative_prompt = $Global:FinalNegativePromptComposition
$TemplateTxtToImg.seed = $Seed
$TemplateTxtToImg.sampler_index = $Sampler
$TemplateTxtToImg.cfg_scale = $Attention
$TemplateTxtToImg.steps = $Steps
$TemplateTxtToImg.width = $Width
$TemplateTxtToImg.height = $Height
$TemplateTxtToImg.restore_faces = $RestoreFaces

if (! (Test-Path -Path $Global:OutputDirectory))
{
    New-Item -Path (Split-Path -Path $Global:OutputDirectory -Parent) -Name (Split-Path -Path $Global:OutputDirectory -LeafBase) -ItemType Directory -Force
}

$ExportFileDate = Get-Date -Format FileDateTime
$TemplateExportedPath = "$Global:OutputDirectory\SD_API_template_$ExportFileDate.txt"
Set-Content -Path $TemplateExportedPath -Value ($templatetxttoimg|ConvertTo-Json) -Force
Write-Host -ForegroundColor Cyan "Template de génération sauvegardé dans le fichier $TemplateExportedPath"

$InvokeSDAPIArguments = "-File $PSSCriptRoot\Invoke-SDAPI.ps1 -Instance $Instance -NbImg $NbImg -GenerationTemplate $Global:TemplateExportedPath"
Start-Process 'pwsh.exe' -NoNewWindow -Wait -ArgumentList $InvokeSDAPIArguments