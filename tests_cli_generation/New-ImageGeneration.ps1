[CmdletBinding()]
param (

    #### Paramètres de génération
    ####
    # La description de que vous voulez comme image
    [Parameter(Mandatory,ParameterSetName="GenerationParameters")]
    [string]
    $Prompt,

    # La description de ce que vous ne voulez pas voir dans votre image
    [Parameter(Mandatory,ParameterSetName="GenerationParameters")]
    [string]
    $NegativePrompt,

    # Le checkpoint (modèle) de Stable Diffusion à utiliser pour générer l'image. Pour afficher la liste complète de modèles disponibles lancer le script avec le paramètre -ShowModelsList
    [Parameter(Mandatory,ParameterSetName="GenerationParameters")]
    [ValidateScript({Get-Content -Path "$PSScriptRoot\Models.txt"})]
    [string]
    $Checkpoint,

    # Tableau de 2 valeurs : Hauteur et Largeur de l'image. En pixels. Si aucune valeur n'est entrée, 512x512 sera utilisé (sauf pour les modèles avec une valeur autre spécifiée par défaut).
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateCount(2,2)]
    [array]
    $Resolution,

    # La méthode de sampling utilisée dans la génération de l'image. Si aucun n'est indiqué, DPM++ 2M Karas est utilisé.
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateSet('DPM++ 2M Karas','DPM++ 2M SDE Karas','DPM++ 2M SDE Exponential','DPM++ 3M SDE Karas','DPM++ 3M SDE Exponential','Euler A','Euler','PLMS')]
    [string]
    $SamplingMethod,

    # Le nombre d'étapes de génération. Valeur en chiffre (entre 10 et 150). Si aucun n'est indiqué, 20 est utilisé (sauf pour les modèles avec une valeur autre spécifiée par défaut).
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateRange(10,150)]
    [int]
    $NumberOfSteps,

    # Le niveau d'attention à votre description que le modèle doit garder durant la génération. Valeur en chiffre (entre 1 et 30). Plus le nombre est bas, moins le modèle prendra en compte votre description et plus il «improvisera». Si aucun n'est choisi, 7 sera sélectionné (sauf pour les modèles avec une valeur autre spécifiée par défaut).
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateRange(1,30)]
    [double]
    $CFGScale,

    # La valeur utilisée dans la génération de nombre aléatoire pour débuter la génération. Si rien n'est indiqué, -1 est utilisé (génération complètement aléatoire).
    [Parameter(ParameterSetName="GenerationParameters")]
    [int]
    $Seed,

    # Le style artistique particulier que vous voulez pour votre image. Si rien n'est sélectionné uniquement votre prompt et negative prompt sont utilisés comme instructions de style par le modèle. Vous pouvez spécifier 'Random' pour qu'un choix soit fait automatiquement parmi les styles disponibles. Pour afficher la liste complète de styles disponibles lancer le script avec le paramètre -ShowStylesList
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateScript({Get-Content -Path "$PSScriptRoot\Artists.txt"})]
    [string]
    $ArtStyle,

    #Choix du keyword directif pour amplifier le style désiré dans l'image.
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateSet('Cel shading','Detailed illustration','Realistic','Masterpiece','Screen print','Rough sketch','Technical illustration','Ultra detailed','Ultrarealistic','Visual novel')]
    [string]
    $DirectionKeyword,

    # Choix des keywords conceptuels (maximum de 3) pour diriger le concept général de l'image. Pour afficher la liste complète de noms disponibles, lancer le script avec le paramètre -ShowConceptualKeywordsList
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateScript({Get-Content -Path "$PSScriptRoot\ConceptualKeyword.txt"})]
    [ValidateCount(0, 3)]
    [array]
    $ConceptualKeyword,

    #Choix des keywords émotifs (maximum de 3) pour diriger l'apparence générale du sujet de l'image. Pour afficher la liste complète de noms disponibles, lancer le script avec le paramètre -ShowMoodKeywordsList
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateScript({Get-Content -Path "$PSScriptRoot\MoodKeyword.txt"})]
    [ValidateCount(0, 3)]
    [array]
    $MoodKeyword,

    # Choix d'artistes (maximum de 3) à utiliser comme inspiration pour le modèle durant la génération. Pour afficher la liste complète de noms disponibles lancer le script avec le paramètre -ShowArtistsList
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateScript({Get-Content -Path "$PSScriptRoot\Artists.txt"})]
    [ValidateCount(0, 3)]
    [array]
    $Artists,

    #### Options du script
    ####
    # Pour choisir comment formatter le prompt; Pour générer directement ou pour obtenir le texte à copier dans Stable-diffusion WebUI
    [Parameter(Mandatory,ParameterSetName="GenerationParameters")]
    [ValidateSet('CLI','WebUI')]
    [string]
    $PromptFormat,

    # Pour afficher tous les modèles disponibles
    [Parameter(ParameterSetName="ScriptOptionsModelsList")]
    [switch]
    $ShowModelsList,

    # Pour afficher tous les artistes disponibles
    [Parameter(ParameterSetName="ScriptOptionsArtistList")]
    [switch]
    $ShowArtistsList,

    # Pour afficher tous les styles disponibles
    [Parameter(ParameterSetName="ScriptOptionsStylesList")]
    [switch]
    $ShowStylesList,

    # Pour afficher tous les keywords conceptuels disponibles
    [Parameter(ParameterSetName="ScriptOptionsConceptuallyList")]
    [switch]
    $ShowConceptualKeywordsList,

    # Pour afficher tous les keywords émotifs disponibles
    [Parameter(ParameterSetName="ScriptOptionsMoodList")]
    [switch]
    $ShowMoodKeywordsList
)

$Global:PromptFormat = $PromptFormat

if ($PSBoundParameters.ContainsKey('ShowModelsList')) {
    $ListToDisplay = Get-Content -Path "$PSScriptRoot\Models.txt"
    Start-Process 'powershell.exe' -ArgumentList "Write-Host $ListToDisplay; Read-Host"
    exit
}

if ($PSBoundParameters.ContainsKey('ShowArtistsList')) {
    $ListToDisplay = Get-Content -Path "$PSScriptRoot\Artists.txt"
    Start-Process 'powershell.exe' -ArgumentList "Write-Host $ListToDisplay; Read-Host"
    exit
}

if ($PSBoundParameters.ContainsKey('ShowStylesList')) {
    $ListToDisplay = Get-Content -Path "$PSScriptRoot\Styles.txt"
    Start-Process 'powershell.exe' -ArgumentList "Write-Host $ListToDisplay; Read-Host"
    exit
}

if ($PSBoundParameters.ContainsKey('ShowConceptualKeywordsList')) {
    $ListToDisplay = Get-Content -Path "$PSScriptRoot\ConceptualKeyword.txt"
    Start-Process 'powershell.exe' -ArgumentList "Write-Host $ListToDisplay; Read-Host"
    exit
}

if ($PSBoundParameters.ContainsKey('ShowMoodKeywordsList')) {
    $ListToDisplay = Get-Content -Path "$PSScriptRoot\MoodKeyword.txt"
    Start-Process 'powershell.exe' -ArgumentList "Write-Host $ListToDisplay; Read-Host"
    exit
}

if (! (Test-Path -Path "$ENV:USERPROFILE\Documents\sd_generations_parameters_saved"))
{
    New-Item -Path "$ENV:USERPROFILE\Documents" -Name "sd_generations_parameters_saved" -ItemType Directory -Force
}

$OutputDirectory = "$ENV:USERPROFILE\Documents\sd_generations_parameters_saved"
$OutputImageDirectory = "$ENV:USERPROFILE\Pictures\sd_generations"

$Global:BasicNegative = "mutation, deformed, deformed iris, duplicate, morbid, mutilated, disfigured, poorly drawn hand, poorly drawn face, bad proportions, gross proportions, extra limbs, cloned face, long neck, malformed limbs, missing arm, missing leg, extra arm, extra leg, fused fingers, too many fingers, extra fingers, mutated hands, blurry, bad anatomy, out of frame, contortionist, contorted limbs, exaggerated features, disproportionate, twisted posture, unnatural pose, disconnected, disproportionate, warped, misshapen, out of scale, "
$Global:BasicPositive = "4k, 8k, uhd, hd, very detailed, high level of detail, rendered as masterpiece, very smooth, sharp, global illumination, ray tracing, stunning, masterpiece, best quality, "

$Global:DetailsEmbeddings = "fFaceDetail EyeDetail OverallDetail"
$Global:NegativeEmbeddings = "HandNeg-neg CyberRealistic_Negative-neg easynegative ng_deepnegative_v1_75t"
$Global:DetailsEmbeddingsCLI = "A:\sd1.6.0\embeddings\Details\fFaceDetail.pt", "A:\sd1.6.0\embeddings\Details\EyeDetail.pt", "A:\sd1.6.0\embeddings\Details\OverallDetail.pt"
$Global:NegativeEmbeddingsCLI = "A:\sd1.6.0\embeddings\Negative\CyberRealistic_Negative-neg.pt", "A:\sd1.6.0\embeddings\Negative\ng_deepnegative_v1_75t.pt", "A:\sd1.6.0\embeddings\Negative\easynegative.safetensors"

$Global:Styles = Get-Content -Path "$PSScriptRoot\styles.json" | ConvertFrom-Json
$Global:RandomStyleSelectorMaxValue = 40

$Global:ModelsKeywords = (@("Deliberate","mj,cozy,cinematic, "), @("SmokeyDreams","dense smoke fetish, "), @("NextPhoto","photo,photograph, "), @("Niji3D","3D model, "), @("ToonYou","flat color, "))

function Get-StylePromptPart {
    param (
        # Le style sélectionné au lancement de l'exécution
        [Parameter(Mandatory)]
        [string]
        $ArtStyle,
        [Parameter(Mandatory)]
        [string]
        $Prompt
    )

        if ($ArtStyle -eq 'Random')
        {
            $RandomlySelectedArtStyle = Get-Random -Minimum 0 -Maximum $Global:RandomStyleSelectorMaxValue
            $SelectedArtStylePrompt = $Global:Styles[$RandomlySelectedArtStyle] | Select-Object -Property prompt
            $SelectedArtStyleNegativePrompt = $Global:Styles[$RandomlySelectedArtStyle] | Select-Object -Property negative_prompt
        }
        else
        {
            $SelectedArtStylePrompt = $Global:Styles | Where-Object -Property name -eq $ArtStyle | Select-Object -Property prompt
            $SelectedArtStyleNegativePrompt = $Global:Styles | Where-Object -Property name -eq $ArtStyle | Select-Object -Property negative_prompt    
        }

        $StyledPrompt = $SelectedArtStylePrompt.prompt.Replace('<<PROMPT HERE>>', "$Prompt")
        $StyledNegativePrompt = ($SelectedArtStyleNegativePrompt.negative_prompt+", "+"$NegativePrompt")

        Return $StyledPrompt,$StyledNegativePrompt
}

function Get-ModelKeywords {
    param (
        # Le checkpoint choisi pour la génération
        [Parameter(Mandatory)]
        [string]
        $Checkpoint
    )
    foreach($KeywordList in $Global:ModelsKeywords)
    {
        if($KeywordList[0] -eq $Checkpoint)
        {
            $SelectedCheckpointKeywords = $KeywordList[1]
        }
    }

    Return $SelectedCheckpointKeywords
}

function Get-ArtistsToPrompt {
    # La liste d'artistes choisis au début de l'exécution
    param (
        [Parameter(Mandatory)]
        [array]
        $Artists
    )

    $ArtistsToPrompt = ""
    foreach($Artist in $Artists)
    {
        if($Global:PromptFormat -eq 'CLI')
        {
            $ArtistsToPrompt+="style of $Artist`:1.3, "
        }
        elseif ($Global:PromptFormat -eq 'WebUI') 
        {
            $ArtistsToPrompt+="(style of $Artist`:1.3), "
        }
    }
    
    Return $ArtistsToPrompt
}

function Get-ConceptualKeywordsToPrompt {
    # La liste d'artistes choisis au début de l'exécution
    param (
        [Parameter(Mandatory)]
        [array]
        $ConceptualKeyword
    )
foreach($Word in $ConceptualKeyword)
{
    $ConceptualKeywordsToPrompt = ""
    if($Global:PromptFormat -eq 'CLI') 
    {
        $ArtistsToPrompt+="style of $Word`:1.4, "
    }
    elseif ($Global:PromptFormat -eq 'WebUI') 
    {
        $ConceptualKeywordsToPrompt+="($Word`:1.4), "
    }
}
    
    Return $ConceptualKeywordsToPrompt
}

function Get-MoodKeywordsToPrompt {
    # La liste d'artistes choisis au début de l'exécution
    param (
        [Parameter(Mandatory)]
        [array]
        $MoodKeyword
    )

    $MoodKeywordsToPrompt = ""
    foreach($Word in $MoodKeyword)
    {
        if($Global:PromptFormat -eq 'CLI') 
        {
            $MoodKeywordsToPrompt+="$Word`:1.3, "
        }
        elseif ($Global:PromptFormat -eq 'WebUI') 
        {
            $MoodKeywordsToPrompt+="($Word`:1.3), "
        }
    }
    
    Return $MoodKeywordsToPrompt
}

if (([boolean](Get-Variable "ArtStyle" -ErrorAction SilentlyContinue)) -ne $false)
{
    $StyledPrompt = (Get-StylePromptPart -ArtStyle $ArtStyle -Prompt $Prompt)[0]
    $StyledNegativePrompt = (Get-StylePromptPart -ArtStyle $ArtStyle -Prompt $Prompt)[1]
}
else 
{
    $StyledPrompt = $Prompt
    $StyledNegativePrompt = $NegativePrompt
}

if($Checkpoint -in $Global:ModelsKeywords[0])
{
    $SelectedCheckpointKeywords = Get-ModelKeywords -Checkpoint $Checkpoint
}

if (([boolean](Get-Variable "Artists" -ErrorAction SilentlyContinue)) -ne $false)
{
    $ArtistsToPrompt = Get-ArtistsToPrompt -Artists $Artists
}

if (([boolean](Get-Variable "ConceptualKeyword" -ErrorAction SilentlyContinue)) -ne $false)
{
    $ConceptualKeywordsToPrompt = Get-ConceptualKeywordsToPrompt -ConceptualKeyword $ConceptualKeyword
}

if (([boolean](Get-Variable "MoodKeyword" -ErrorAction SilentlyContinue)) -ne $false)
{
    $MoodKeywordsToPrompt = Get-MoodKeywordsToPrompt -MoodKeyword $MoodKeyword
}

if (([boolean](Get-Variable "DirectionKeyword" -ErrorAction SilentlyContinue)) -ne $false)
{
    if($Global:PromptFormat -eq 'CLI') 
    {
        $DirectionKeywordToPrompt = "$DirectionKeyword`:1.5, "
    }
    elseif ($Global:PromptFormat -eq 'WebUI') 
    {
        $DirectionKeywordToPrompt = "($DirectionKeyword`:1.5), "
    }
}

if($Global:PromptFormat -eq 'WebUI')
{
    $FinalPromptComposition = ("$ConceptualKeywordsToPrompt"+"$DirectionKeywordToPrompt"+"$MoodKeywordsToPrompt"+"$SelectedCheckpointKeywords"+"$StyledPrompt, "+$Global:BasicPositive+"$ArtistsToPrompt"+$Global:DetailsEmbeddings)
    $FinalNegativePromptComposition = ("$StyledNegativePrompt, "+"$Global:BasicNegative"+$Global:NegativeEmbeddings)
}
elseif($Global:PromptFormat -eq 'CLI')
{
    $FinalPromptComposition = ("$ConceptualKeywordsToPrompt"+"$DirectionKeywordToPrompt"+"$MoodKeywordsToPrompt"+"$SelectedCheckpointKeywords"+"$StyledPrompt, "+$Global:BasicPositive+"$ArtistsToPrompt")
    $FinalNegativePromptComposition = ("$StyledNegativePrompt, "+"$Global:BasicNegative")
}

if (([boolean](Get-Variable "Resolution" -ErrorAction SilentlyContinue)) -eq $false)
{
    switch ($Checkpoint) {
        EpicRealismNaturalSin { $Resolution = '512','768' }
        MoonRealKo { $Resolution = '512','896' }
        RealCartoonPixar { $Resolution = '512','768' }
        Default {$Resolution = '512','512'}
    }
}

if ($Global:PromptFormat -eq 'CLI')
{
    $Global:SamplingMethodCLI = ""
    switch ($SamplingMethod) {
        Euler { $Global:SamplingMethodCLI = "k_euler" }
        "Euler A" { $Global:SamplingMethodCLI = "k_euler_a" }
        PLMS { $Global:SamplingMethodCLI = "k_plms" }
        Default { $Global:SamplingMethodCLI = "k_dpm_2" }
    }
    $FinalSamplingMethod = $SamplingMethodCLI
}
elseif ($Global:PromptFormat -eq 'WebUI')
{
    if($SamplingMethod -like "")
    {
        $SamplingMethod = "DPM++ 2M Karas"
    }
    $FinalSamplingMethod = $SamplingMethod
}

    if ($Global:PromptFormat -eq 'WebUI')
    {
        
    }


if (([boolean](Get-Variable "Seed" -ErrorAction SilentlyContinue)) -eq $false)
{
    if($Global:PromptFormat -eq 'CLI') 
    {
        $Seed = Get-Random -Minimum 1 -Maximum 9999999999
    }
    elseif ($Global:PromptFormat -eq 'WebUI') 
    {
        $Seed = "-1"
    }
}

if (([boolean](Get-Variable "CFGScale" -ErrorAction SilentlyContinue)) -eq $false)
{
    switch ($Checkpoint) {
        ArtUniverse { $CFGScale = '5' }
        BeenYou { $CFGScale = '8' }
        EpicRealismNaturalSin { $CFGScale = '4.5' }
        MoonRealKo { $CFGScale = '9.5' }
        NextPhoto { $CFGScale = '4.5' }
        OnlyRealistic { $CFGScale = '5.5' }
        ToonYou { $CFGScale = '8' }
        Default { $CFGScale = '7' }
    }
}

if (([boolean](Get-Variable "NumberOfSteps" -ErrorAction SilentlyContinue)) -eq $false)
{
    switch ($Checkpoint) {
        ArtUniverse { $NumberOfSteps = '30' }
        BeenYou { $NumberOfSteps = '30' }
        EpicRealismNaturalSin { $NumberOfSteps = '30' }
        MoonRealKo { $NumberOfSteps = '30' }
        ToonYou { $NumberOfSteps = '30' }
        VintageAnime { $NumberOfSteps = '30' }
        Default { $NumberOfSteps = '20' }
    }
}

class PromptGenerationParameters{
    [string]$CheckPoint
    [string]$Prompt
    [string]$NegativePrompt
    [array]$Resolution
    [string]$FinalSamplingMethod
    [int]$NumberOfSteps
    [double]$CFGScale
    [int]$Seed
}

$Generation = [PromptGenerationParameters]::new()
$Generation.CheckPoint = $Checkpoint
$Generation.Prompt = $FinalPromptComposition.Replace('  ',' ')
$Generation.NegativePrompt = $FinalNegativePromptComposition.Replace('  ',' ')
$Generation.Resolution = $Resolution
$Generation.FinalSamplingMethod = $FinalSamplingMethod
$Generation.NumberOfSteps = $NumberOfSteps
$Generation.CFGScale = $CFGScale
$Generation.Seed = $Seed

$ParametersOutput1 = ("Using model: "+$Generation.CheckPoint+"`nSampling with: "+$Generation.SamplingMethod+"`nStarting at seed: "+$Generation.Seed)
$ParametersOutput2 = ("Generating an image of dimensions: "+$Generation.Resolution+"`nWith an attention level of: "+$Generation.CFGScale+"`nFor: "+$Generation.NumberOfSteps+" steps")
$PromptOutput = $Generation.Prompt
$PromptNegativeOutput = $Generation.NegativePrompt

$OutputParameters = ("$ParametersOutput1"+"$ParametersOutput2"+"`n`n"+"$PromptOutput"+"`n`n"+"$PromptNegativeOutput")

$ExportFileDate = Get-Date -Format FileDateTime
Add-Content -Value $OutputParameters -Path "$OutputDirectory\$ExportFileDate.txt" -Force

if ($Global:PromptFormat -eq 'CLI')
{
    $CLIFullPrompt = $Generation.Prompt+"[["+$Generation.NegativePrompt+"]]"
    python scripts/dream.py $CLIFullPrompt --model $Generation.CheckPoint --sampler $Generation.SamplingMethod --embedding_path $Global:DetailsEmbeddingsCLI[0] --embedding_path $Global:DetailsEmbeddingsCLI[1] --embedding_path $Global:DetailsEmbeddingsCLI[2] --embedding_path $Global:NegativeEmbeddingsCLI[0] --embedding_path $Global:NegativeEmbeddingsCLI[1] --embedding_path $Global:NegativeEmbeddingsCLI[2] --width $Generation.Resolution[0] --height $Generation.Resolution[1] --steps $Generation.NumberOfSteps --cfg_scale $Generation.CFGScale --seed $Generation.Seed -o ("$OutputImageDirectory"+($Generation.Seed).ToString()+"-"+$ExportFileDate+".png")
}

elseif ($Global:PromptFormat -eq 'WebUI')
{
    Write-Host "`n"
    Write-Host "Paramètres:"
    Write-Host -ForegroundColor Cyan ("$ParametersOutput1"+"`n`n"+"$ParametersOutput2")
    Write-Host "`n"
    Write-Host "Prompt:"
    Write-Host -ForegroundColor Green $PromptOutput
    Write-Host "`n"
    Write-Host "Negative Prompt:"
    Write-Host -ForegroundColor Red $PromptNegativeOutput
    Write-Host "`n"
    Write-Host -ForegroundColor Magenta "Les paramètres ont également été exportés dans le fichier $OutputDirectory\$ExportFileDate.txt"
}

