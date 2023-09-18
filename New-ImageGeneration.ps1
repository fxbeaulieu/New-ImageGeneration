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
    [ValidateSet({Get-Content -Path "$PSScriptRoot\Models.txt"})]
    [string]
    $Checkpoint,

    # Tableau de 2 valeurs : Hauteur et Largeur de l'image. En pixels. Si aucune valeur n'est entrée, 512x512 sera utilisé.
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateCount(2,2)]
    [array]
    $Resolution,

    # La méthode de sampling utilisée dans la génération de l'image. Si aucun n'est indiqué, DPM++ 2M Karas est utilisé.
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateSet('DPM++ 2M Karas','DPM++ 2M SDE Karas','DPM++ 2M SDE Exponential','DPM++ 3M SDE Karas','DPM++ 3M SDE Exponential','Euler A','Euler','PLMS')]
    [string]
    $SamplingMethod,

    # Le nombre d'étapes de génération. Valeur en chiffre (entre 10 et 150). Si aucun n'est indiqué, 20 est utilisé.
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateRange(10,150)]
    [int]
    $NumberOfSteps,

    # Le niveau d'attention à votre description que le modèle doit garder durant la génération. Valeur en chiffre (entre 1 et 30). Plus le nombre est bas, moins le modèle prendra en compte votre description et plus il «improvisera». Si aucun n'est choisi, 8.5 sera sélectionné.
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateSet(1,30)]
    [int]
    $CFGScale,

    # La valeur utilisée dans la génération de nombre aléatoire pour débuter la génération. Si rien n'est indiqué, -1 est utilisé (génération complètement aléatoire).
    [Parameter(ParameterSetName="GenerationParameters")]
    [int]
    $Seed,

    # Le style artistique particulier que vous voulez pour votre image. Si rien n'est sélectionné uniquement votre prompt et negative prompt sont utilisés comme instructions de style par le modèle. Vous pouvez spécifier 'Random' pour qu'un choix soit fait automatiquement parmi les styles disponibles. Pour afficher la liste complète de styles disponibles lancer le script avec le paramètre -ShowStylesList
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateSet({Get-Content -Path "$PSScriptRoot\Artists.txt"})]
    [string]
    $ArtStyle,

    #Choix du keyword directif pour amplifier le style désiré dans l'image.
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateSet('Cel shading','Detailed illustration','Realistic','Masterpiece','Screen print','Rough sketch','Technical illustration','Ultra detailed','Ultrarealistic','Visual novel')]
    [string]
    $DirectionKeyword,

    # Choix des keywords conceptuels (maximum de 3) pour diriger le concept général de l'image. Pour afficher la liste complète de noms disponibles, lancer le script avec le paramètre -ShowConceptualKeywordsList
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateSet({Get-Content -Path "$PSScriptRoot\ConceptualKeyword.txt"})]
    [ValidateCount(0, 3)]
    [array]
    $ConceptualKeyword,

    #Choix des keywords émotifs (maximum de 3) pour diriger l'apparence générale du sujet de l'image. Pour afficher la liste complète de noms disponibles, lancer le script avec le paramètre -ShowMoodKeywordsList
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateSet({Get-Content -Path "$PSScriptRoot\MoodKeyword.txt"})]
    [ValidateCount(0, 3)]
    [array]
    $MoodKeyword,

    # Choix d'artistes (maximum de 3) à utiliser comme inspiration pour le modèle durant la génération. Pour afficher la liste complète de noms disponibles lancer le script avec le paramètre -ShowArtistsList
    [Parameter(ParameterSetName="GenerationParameters")]
    [ValidateSet({Get-Content -Path "$PSScriptRoot\Artists.txt"})]
    [ValidateCount(0, 3)]
    [array]
    $Artists,

    #### Options du script
    ####
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

if ($PSBoundParameters.ContainsKey('ShowModelsList')) {
    Get-Content -Path "$PSScriptRoot\Models.txt"
    exit
}

if ($PSBoundParameters.ContainsKey('ShowArtistsList')) {
    Get-Content -Path "$PSScriptRoot\Artists.txt"
    exit
}

if ($PSBoundParameters.ContainsKey('ShowStylesList')) {
    Get-Content -Path "$PSScriptRoot\Styles.txt"
    exit
}

if ($PSBoundParameters.ContainsKey('ShowConceptualKeywordsList')) {
    Get-Content -Path "$PSScriptRoot\ConceptualKeyword.txt"
    exit
}

if ($PSBoundParameters.ContainsKey('ShowMoodKeywordsList')) {
    Get-Content -Path "$PSScriptRoot\MoodKeyword.txt"
    exit
}

if (! (Test-Path -Path "$PSScriptRoot\generations_parameters_saved"))
{
    New-Item -Path "$PSScriptRoot" -Name "generations_parameters_saved" -ItemType Directory -Force
}

$Global:BasicNegative = "mutation, deformed, deformed iris, duplicate, morbid, mutilated, disfigured, poorly drawn hand, poorly drawn face, bad proportions, gross proportions, extra limbs, cloned face, long neck, malformed limbs, missing arm, missing leg, extra arm, extra leg, fused fingers, too many fingers, extra fingers, mutated hands, blurry, bad anatomy, out of frame, contortionist, contorted limbs, exaggerated features, disproportionate, twisted posture, unnatural pose, disconnected, disproportionate, warped, misshapen, out of scale, "

$Global:DetailsEmbeddings = "fFaceDetail EyeDetail OverallDetail"
$Global:NegativeEmbeddings = "HandNeg-neg CyberRealistic_Negative-neg easynegative ng_deepnegative_v1_75t"

$Global:Styles = Get-Content -Path "$PSScriptRoot\styles.json" | ConvertFrom-Json -Depth 3
$Global:RandomStyleSelectorMaxValue = 40

$Global:ModelsKeywords = (@("Deliberate","mj,cozy,cinematic, "), @("SmokeyDreams","dense smoke fetish, "), @("NextPhoto","photo,photograph, "), @("Niji3D","3D model, "), @("ToonYou","flat color, "))

function Get-StylePromptPart {
    param (
        # Le style sélectionné au lancement de l'exécution
        [Parameter(Mandatory)]
        [string]
        $ArtStyle
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

        $StyledPrompt = $SelectedArtStylePrompt.ToString().Replace('{prompt}', $Prompt)
        $StyledNegativePrompt = ($SelectedArtStyleNegativePrompt.ToString()+", "+"$NegativePrompt")

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
        $ArtistsToPrompt+="style of $Artist, "
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

    $ConceptualKeywordsToPrompt = ""
    foreach($Word in $ConceptualKeyword)
    {
        $ConceptualKeywordsToPrompt+="$Word, "
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
        $MoodKeywordsToPrompt+="$Word, "
    }
    
    Return $MoodKeywordsToPrompt
}

if (([boolean](Get-Variable "ArtStyle" -ErrorAction SilentlyContinue)) -ne $false)
{
    $StyledPrompt = (Get-StylePromptPart -ArtStyle $ArtStyle)[0]
    $StyledNegativePrompt = (Get-StylePromptPart -ArtStyle $ArtStyle)[1]
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
    $DirectionKeyword = "$DirectionKeyword, "
}

$FinalPromptComposition = ("$ConceptualKeywordsToPrompt"+"$DirectionKeyword"+"$MoodKeywordsToPrompt"+"$SelectedCheckpointKeywords"+"$StyledPrompt, "+"$ArtistsToPrompt"+"$Global:DetailsEmbeddings")
$FinalNegativePromptComposition = ("$StyledNegativePrompt, "+"$Global:BasicNegative"+"$Global:NegativeEmbeddings")

if (([boolean](Get-Variable "Resolution" -ErrorAction SilentlyContinue)) -eq $false)
{
    $Resolution = '512','512'
}

if (([boolean](Get-Variable "SamplingMethod" -ErrorAction SilentlyContinue)) -eq $false)
{
    $SamplingMethod = "DPM++ 2M Karas"
}

if (([boolean](Get-Variable "Seed" -ErrorAction SilentlyContinue)) -eq $false)
{
    $Seed = '-1'
}

if (([boolean](Get-Variable "CFGScale" -ErrorAction SilentlyContinue)) -eq $false)
{
    $CFGScale = '8.5'
}

if (([boolean](Get-Variable "NumberOfSteps" -ErrorAction SilentlyContinue)) -eq $false)
{
    $NumberOfSteps = "20"
}

class PromptGenerationParameters{
    [string]$CheckPoint
    [string]$Prompt
    [string]$NegativePrompt
    [array]$Resolution
    [string]$SamplingMethod
    [int]$NumberOfSteps
    [int]$CFGScale
    [int]$Seed
}

$Generation = [PromptGenerationParameters]::new()
$Generation.CheckPoint = $Checkpoint
$Generation.Prompt = $FinalPromptComposition
$Generation.NegativePrompt = $FinalNegativePromptComposition
$Generation.Resolution = $Resolution
$Generation.SamplingMethod = $SamplingMethod
$Generation.NumberOfSteps = $NumberOfSteps
$Generation.CFGScale = $CFGScale
$Generation.Seed = $Seed

$ExportFileDate = Get-Date -UnixTimeSeconds
Add-Content -Value $Generation -Path "$PSScriptRoot\generations_parameters_saved\$ExportFileDate.txt" -Force

