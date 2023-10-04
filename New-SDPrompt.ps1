#Options à dev
#$GetEmbeds = 'http://<IP>:64640/sdapi/v1/embeddings'
#$GetLoras = 'http://<IP>:64640/sdapi/v1/loras'
#$GetStyles = 'http://<IP>:64640/sdapi/v1/prompt-styles'
#$CtrllNetTypes = 'http://<IP>:64640/sdapi/v1/control_types'
#$GetExt = 'http://<IP>:64640/sdapi/v1/extensions'
#$ImgGeneration = 'http://<IP>:64640/sdapi/v1/img2img'
#$CtrlNetImageInput = 'http://<IP>:64640/controlnet/detect'
#$ExtraSingle = 'http://<IP>:64640/sdapi/v1/extra-single-image'
#$ExtraBatch = 'http://<IP>:64640/sdapi/v1/extra-batch-images'
#$PngInfo = 'http://<IP>:64640/sdapi/v1/png-info'
#$GetThumbnail = 'http://<IP>:64640/sdapi/v1/sd_extra_networks/thumb'
#$GetStatus = 'http://<IP>:64640/queue/status'
#$GetProgress = 'http://<IP>:64640/sdapi/v1/progress?skip_current_image=false'
[CmdletBinding()]
param (
    #### Options du script
    ####

    # Pour lancer la génération d'un nouveau prompt
    [Parameter(ParameterSetName="Generate")]
    [switch]
    $Generate,

    [Parameter(ParameterSetName="Generate")]
    [switch]
    $WebUI,

    [Parameter(ParameterSetName="Generate")]
    [switch]
    $API,

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

$Global:OutputDirectory = "$ENV:USERPROFILE\Documents\sd_generation_parameters_saved"

if (! (Test-Path -Path $Global:OutputDirectory))
{
    New-Item -Path (Split-Path -Path $Global:OutputDirectory -Parent) -Name (Split-Path -Path $Global:OutputDirectory -LeafBase) -ItemType Directory -Force
}

$Global:BasicNegative = "mutation, deformed, deformed iris, duplicate, morbid, mutilated, disfigured, poorly drawn hand, poorly drawn face, bad proportions, gross proportions, extra limbs, cloned face, long neck, malformed limbs, missing arm, missing leg, extra arm, extra leg, fused fingers, too many fingers, extra fingers, mutated hands, blurry, bad anatomy, out of frame, contortionist, contorted limbs, exaggerated features, disproportionate, twisted posture, unnatural pose, disconnected, disproportionate, warped, misshapen, out of scale, "
$Global:BasicPositive = "4k, 8k, uhd, hd, very detailed, high level of detail, rendered as masterpiece, very smooth, sharp, global illumination, ray tracing, stunning, masterpiece, best quality, "

$Global:DetailsEmbeddings = "fFaceDetail EyeDetail OverallDetail"
$Global:NegativeEmbeddings = "HandNeg-neg CyberRealistic_Negative-neg easynegative ng_deepnegative_v1_75t"

$Global:DirectionKeywords = @("Cel shaded","Detailed illustration","Realistic","Masterpiece","Screen print","Rough sketch","Technical illustration","Ultra detailed","Ultrarealistic","Visual novel")

$Global:StylesDetails = Get-Content -Path "$PSScriptRoot\styles.json" | ConvertFrom-Json
[int]$Global:RandomStyleSelectorMaxValue = (Get-Content "$PSScriptRoot\Styles.txt" | Measure-Object)-1

class PromptGenerationParameters{
    [string]$Prompt
    [string]$NegativePrompt
    [string]$PictureArtStyle
    [array]$ConceptualKeywords
    [string]$DirectionKeyword
    [array]$MoodKeywords
    [array]$Artists
}

class GenerationParameters{
    [string]$Sampler
    [ValidateRange(1,30)]
    [int]$Attention
    [ValidateRange(512,1920)]
    [int]$ResolutionW
    [ValidateRange(512,1920)]
    [int]$ResolutionH
    [ValidateRange(0,18446744073709551616)]
    [Int64]$Seed
    [ValidateRange(20, 150)]
    [int]$Steps
    [ValidateRange(1,100)]
    [int]$NumberIteration
}

function Show-Guides {
    param (
        [Parameter(Mandatory)]
        [ValidateSet('Styles','Conceptually','Mood','Artists')]
        [string]
        $Guide
    )
    $ItemList = @("")
    $ListToDisplay = Get-Content -Path "$PSScriptRoot\$Guide.txt"
    foreach($Item in $ListToDisplay)
    {
        $ItemList+=$Item
    }
    Start-Process 'pwsh.exe' -ArgumentList "Write-Host $ItemList; Read-Host"
    exit
}

function Get-UserPromptInput {
    param (
        [Parameter(ParameterSetName="Prompt")][switch]$Prompt,[Parameter(ParameterSetName="NegPrompt")][switch]$NegativePrompt,[Parameter(ParameterSetName="PictureStyle")][switch]$PictureArtStyle,[Parameter(ParameterSetName="Conceptual")][switch]$ConceptualKeywords,[Parameter(ParameterSetName="Direction")][switch]$DirectionKeyword,[Parameter(ParameterSetName="Mood")][switch]$MoodKeywords,[Parameter(ParameterSetName="Artists")][switch]$Artists,[Parameter(ParameterSetName="Generation")][switch]$Generation
    )

    Add-Type -AssemblyName Microsoft.VisualBasic

    switch ($PSBoundParameters.Keys) {
        Prompt
        {
            $Hint = "Entrez la description de ce que vous voulez voir dans votre image"
            [string]$Prompt = [Microsoft.VisualBasic.Interaction]::InputBox("Votre prompt: ", 'UserInput', "$Hint")
            $UserInput = $Prompt
        }
        NegativePrompt {
            $Hint = "Entrez la description de ce que vous ne voulez spécifiquement pas voir dans votre image (optionnel, peut être vide)"
            [string]$NegativePrompt = [Microsoft.VisualBasic.Interaction]::InputBox("Votre negative prompt: ", 'UserInput', "$Hint")
            $UserInput = $NegativePrompt
        }
        PictureArtStyle {
            $Title = "Style de l'image: "
            $Hint = "Faire votre choix parmi les options affichées"
            [array]$Styles = @()
            Foreach($Style in (Get-Content -Path "$PSscriptRoot\Styles.txt"))
            {
                $Styles+=$Style
            }
            $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Styles)
            $UserInputValue = $Host.UI.PromptForChoice($Title, $Hint, $Options)
            $UserInput = $Styles[$UserInputValue]
        }
        ConceptualKeywords {
            [array]$ConceptualKeywords = @()
            foreach($Keyword in (Get-Content -Path "$PSScriptRoot\Conceptually.txt"))
            {
                $ConceptualKeywords += $Keyword
            }
            $Title = "Mot-Clef pour décrire le concept général que doit représenter votre image: "
            $Hint = "Faire votre choix parmi les options affichées"
            $Options = [System.Management.Automation.Host.ChoiceDescription[]]($ConceptualKeywords)
            [int]$Count = 0
            $UserInput = @()
            While ($Count -lt 3)
            {
                Read-Host -Prompt "Ajouter un mot-clef conceptuel ? (O/N)"
                while ($UserStopped -notlike "o" -or $UserStopped -notlike "n")
                {
                    Read-Host -Prompt "Ajouter un mot-clef conceptuel ? (O/N)"
                }
                if($UserStopped -like "n")
                {
                    Return $UserInput
                }
                $UserInputValue = $Host.IHostUISupportsMultipleChoiceSelection.PromptForChoice($Title, $Hint, $Options)
                $UserInput += $ConceptualKeywords[$UserInputValue]
                ++$Count
            }
        }
        DirectionKeyword {
            $Title = "La direction artistique que doit prendre le modèle pour générer l'image: "
            $Hint = "Faire votre choix parmi les options affichées"
            $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Global:DirectionKeywords)
            $UserInputValue = $Host.UI.PromptForChoice($Title, $Hint, $Options)
            $UserInput = $DirectionKeywords[$UserInputValue]
        }
        MoodKeywords
        {
            [array]$MoodKeywords = @()
            foreach($Keyword in (Get-Content -Path "$PSScriptRoot\Mood.txt"))
            {
                $MoodKeywords += $Keyword
            }
            $Title = "Mot-Clef pour décrire l'émotion générale que doit représenter votre image: "
            $Hint = "Faire votre choix parmi les options affichées"
            $Options = [System.Management.Automation.Host.ChoiceDescription[]]($MoodKeywords)
            [int]$Count = 0
            $UserInput = @()
            While ($Count -lt 3)
            {
                Read-Host -Prompt "Ajouter un mot-clef émotif ? (O/N)"
                while ($UserStopped -notlike "o" -or $UserStopped -notlike "n")
                {
                    Read-Host -Prompt "Ajouter un mot-clef émotif ? (O/N)"
                }
                if($UserStopped -like "n")
                {
                    Return $UserInput
                }
                $UserInputValue = $Host.UI.IHostUISupportsMultipleChoiceSelection.PromptForChoice($Title, $Hint, $Options)
                $UserInput += $MoodKeywords[$UserInputValue]
                ++$Count
            }
        }
        Artists
        {
            [array]$Artists = @()
            foreach($Artist in (Get-Content -Path "$PSScriptRoot\Artists.txt"))
            {
                $Artists+=$Artist
            }
            $Title = "Artiste : "
            $Hint = "Faire votre choix parmi les options affichées"
            $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Artists)
            [int]$Count = 0
            $UserInput = @()
            while ($Count -lt 3)
            {
                Read-Host -Prompt "Ajouter un artiste ? (O/N)"
                while ($UserStopped -notlike "o" -or $UserStopped -notlike "n")
                {
                    Read-Host -Prompt "Ajouter un artiste ? (O/N)"
                }
                if($UserStopped -like "n")
                {
                    Return $UserInput
                }
                $UserInputValue = $Host.IHostUISupportsMultipleChoiceSelection.PromptForChoice($Title, $Hint, $Options)
                $UserInput += $Artists[$UserInputValue]
                ++$Count
            }
        }
        Generation
        {
            $GeneralParameters = [GenerationParameters]::new()
            $SamplersList = (Get-Content -Path .\samplers.json | ConvertFrom-Json).name
            $Title = "Sampler qui doit être utilisé: "
            $Hint = "Faire votre choix parmi les options affichées"
            $Options = [System.Management.Automation.Host.ChoiceDescription[]]($SamplersList)
            $UserInputValue = $Host.UI.PromptForChoice($Title, $Hint, $Options)
            $GeneralParameters.Sampler = $SamplersList[$UserInputValue]
            $GeneralParameters.Attention = Read-Host -Prompt "Niveau d'attention que doit avoir le modèle par rapport au contenu de votre prompt durant la génération ? (Nombre entre 1 et 30)"
            $GeneralParameters.ResolutionW = Read-Host -Prompt "Largeur de l'image à générer (Taille en pixels entre 512 et 1920) ?"
            $GeneralParameters.ResolutionH = Read-Host -Prompt "Hauteur de l'image à générer (Taille en pixels entre 512 et 1920) ?"
            $GeneralParameters.Steps = Read-Host -Prompt "Le nombre d'étapes de génération utilisées pour concevoir votre image (Nombre entre 20 et 150)"
            $GeneralParameters.NumberIteration = Read-Host -Prompt "Le nombre d'images à générer avec vos paramètres (Nombre entre 1 et 100) ?"
            if($GeneralParameters.NumberIteration -eq 1)
            {
                $GeneralParameters.Seed = Read-Host -Prompt "Le seed pour débuter la génération de l'image (Nombre entier entre 1 et 2^64, vous pouvez inscrire 0 pour «aléatoire»)"
                Return $GeneralParameters
            }
            $GeneralParameters.Seed = 0
            Return $GeneralParameters
        }
        Default {}
    }

    Return $UserInput
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
        [string]$ConceptualKeywordsToPrompt+="($Word`:1.4), "
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
        [string]$MoodKeywordsToPrompt+="($Word`:1.3), "
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
        [string]$ArtistsToPrompt+="(style of $Artist`:1.3), "
    }

    Return $ArtistsToPrompt
}

function Get-PromptComponents {
    $Global:PromptParameters = [PromptGenerationParameters]::new()
    $Global:PromptParameters.Prompt = (Get-UserPromptInput -Prompt)
    $Global:PromptParameters.NegativePrompt = (Get-UserPromptInput -NegativePrompt)
    $Global:PromptParameters.PictureArtStyle = (Get-UserPromptInput -PictureArtStyle)
    $Global:PromptParameters.ConceptualKeywords = (Get-UserPromptInput -ConceptualKeywords)
    $Global:PromptParameters.DirectionKeyword = (Get-UserPromptInput -DirectionKeyword)
    $Global:PromptParameters.MoodKeywords = (Get-UserPromptInput -MoodKeywords)
    $Global:PromptParameters.Artists = (Get-UserPromptInput -Artists)
}

function Format-PromptComponents {
    [string]$ConceptualKeywordsToPrompt = Format-ConceptualKeywordsToPrompt -ConceptualKeywords $Global:PromptParameters.ConceptualKeywords
    [string]$DirectionKeywordToPrompt = Format-DirectionKeywordToPrompt -DirectionKeyword $Global:PromptParameters.DirectionKeyword
    [string]$MoodKeywordsToPrompt = Format-MoodKeywordsToPrompt -MoodKeywords $Global:PromptParameters.MoodKeywords
    [string]$SelectedArtStylePrompt,[string]$SelectedArtStyleNegativePrompt = Format-StyleToPrompt -ArtStyle $Global:PromptParameters.PictureArtStyle
    [string]$StyledPrompt = $SelectedArtStylePrompt.Replace('<<PROMPT HERE>>', $Global:PromptParameters.Prompt)
    [string]$ArtistsToPrompt = Format-ArtistsToPrompt -Artists $Global:PromptParameters.Artists
    $StyledNegativePrompt = ($SelectedArtStyleNegativePrompt+", "+$Global:PromptParameters.NegativePrompt+", ")
    $FullUserPrompt = ($ConceptualKeywordsToPrompt+$DirectionKeywordToPrompt+$MoodKeywordsToPrompt+$StyledPrompt+$ArtistsToPrompt)
    Return $FullUserPrompt,$StyledNegativePrompt
}

function Out-WebUI {
    param(
        [Parameter()]
        [string]
        $FinalPromptComposition,
        [Parameter()]
        [string]
        $FinalNegativePromptComposition,
        [Parameter()]
        [string]
        $OutputToFileFormatParameters
    )
    Write-Host "`n"
    Set-Clipboard -Value $FinalPromptComposition
    Write-Host -ForegroundColor Green "Prompt copié dans le clipboard. Le coller dans SD WebUI puis faire ENTER pour obtenir le negative prompt."
    Read-Host
    Write-Host "`n"
    Set-Clipboard -Value $FinalNegativePromptComposition
    Write-Host -ForegroundColor Red "Negative Prompt copié dans le clipboard. Le coller dans SD WebUI puis faire ENTER pour terminer l'exécution."
    Read-Host
    $ExportFileDate = Get-Date -Format FileDateTime
    Add-Content -Value $OutputToFileFormatParameters -Path "$Global:OutputDirectory\$ExportFileDate.txt" -Force
    Write-Host -ForegroundColor Cyan "Fin de l'exécution.`nNote : Les prompts générés ont également été exportés dans le fichier $Global:OutputDirectory\$ExportFileDate.txt"
    Start-Sleep -Seconds 10
}

function Invoke-SDAPI {
    param (
        [Parameter(Mandatory)]
        [string]
        $Prompt,
        [Parameter(Mandatory)]
        [string]
        $NegativePrompt,
        [Parameter(Mandatory)]
        [GenerationParameters]
        $Parameters,
        [Parameter(Mandatory)]
        [ValidateSet('SD','XL')]
        [string]
        $SDVersion
    )

    $IP = @{
    XL = '192.168.4.254'
    SD = '192.168.4.32'
    }

    if($SDVersion -eq 'SD')
    {
        $RequestIP = $IP.SD
    }
    elseif($SDVersion -eq 'XL')
    {
        $RequestIP = $IP.XL
    }

    function Get-Models {
        param (
            [Parameter(Mandatory)]
            [string]
            $RequestURL
        )
        $Models=((Invoke-WebRequest -Uri $RequestURL).Content|ConvertFrom-Json).title
        Return $Models
    }

    function Get-ActiveModel {
        param (
            [Parameter(Mandatory)]
            [string]
            $RequestURL
        )
        $ActiveModel=((Invoke-WebRequest -Uri $RequestURL).Content|ConvertFrom-Json)
        Return $ActiveModel
    }

    function Get-UserModelChoice {
    #####
        Write-Host "Modèle actif présentement: "+$Global:ActiveModelInfos
        While($ChangeModel -notlike "o" -and $ChangeModel -notlike "n")
        {
            $ChangeModel = Read-Host -Prompt "Changer le modèle actif ? (O/N)"
        }
        if($ChangeModel -like "o")
        {
            Write-Host "Liste des modèles: "+$Global:ModelsInfos
        }
        elseif($ChangeModel -like "n")
        {
            $ModelFileName = $Global:ActiveModelInfos
        }
        Return $ModelFileName
    }
    function Set-Model {
        param (
            [Parameter(Mandatory)]
            [string]
            $RequestURL
        )
        $SetModelResult = ((Invoke-WebRequest -Uri $RequestURL -Method Post).Content|ConvertFrom-Json)
        Return $SetModelResult
    }

    $GetModels = 'http://<IP>:64640/sdapi/v1/sd-models'
    $GetActiveModel = 'http://<IP>:64640/sdapi/v1/options?sd_model_checkpoint'
    $SetModel = 'http://<IP>:64640/sdapi/v1/options?sd_model_checkpoint='
    function Invoke-TxtToImage{
        param(
        [Parameter(Mandatory)]
        [string]
        $Prompt,
        [Parameter()]
        [string]
        $NegativePrompt,
        [Parameter()]
        [GenerationParameters]
        $Parameters,
        [Parameter()]
        [string]
        $RequestIP
        )

        if($Parameters.Seed -eq 0)
        {
            $Parameters.Seed = [int64](Get-Random -Minimum 1 -Maximum ([Math]::Pow(2, 64)))
        }
        $RequestBody = (Get-Content -Path "$PSScriptRoot\txttoimg-request-body.json" | ConvertFrom-Json)
        $RequestBody.prompt = $Prompt
        $RequestBody.negative_prompt = $NegativePrompt
        $RequestBody.seed = $Parameters.Seed
        $RequestBody.sampler_index = $Parameters.Sampler
        $RequestBody.n_iter = $Parameters.NumberIteration
        $RequestBody.steps = $Parameters.Steps
        $RequestBody.cfg_scale = $Parameters.Attention
        $RequestBody.width = $Parameters.ResolutionW
        $RequestBody.height = $Parameters.ResolutionH
        $GenerationDataBody = ($RequestBody | ConvertTo-Json)
        $TxtGeneration = 'http://<IP>:64640/sdapi/v1/txt2img'
        $TxtGeneration = $TxtGeneration.Replace('<IP>',$RequestIP)
        $DataGeneratedPicture = (Invoke-WebRequest -Uri $TxtGeneration -Method Post -Body $GenerationDataBody)
        Return $DataGeneratedPicture
    }

    $Global:ActiveModelInfos = Get-ActiveModel -RequestURL $GetActiveModel.Replace('<IP>',$RequestIP)
    $Global:ModelsInfos = Get-Models -RequestURL $GetModels.Replace('<IP>',$RequestIP)
    $ModelFileName = Get-UserModelChoice
    $SetModelResult = Set-Model -RequestURL ($SetModel.Replace('<IP>',$RequestIP)+$ModelFileName)

    $GeneratedPicture = (Invoke-TxtToImage -Prompt $Prompt -NegativePrompt $NegativePrompt -Parameters $Parameters -RequestIP $RequestIP)
    Set-Content -Value $GeneratedPicture -Path ("$PSScriptRoot\txttoimg"+(Get-Date -Format FileDateTime)+".png")
}

function Invoke-PromptGenerator {
    Get-PromptComponents
    $FormatedPrompt = Format-PromptComponents

    [string]$Global:FinalPromptComposition = ($FormatedPrompt[0]+$Global:BasicPositive+$Global:DetailsEmbeddings)
    [string]$Global:FinalNegativePromptComposition = ($FormatedPrompt[1]+$Global:BasicNegative+$Global:NegativeEmbeddings)
    $Global:OutputToFileFormatParameters=($Global:FinalPromptComposition+"`n`n"+$Global:FinalNegativePromptComposition)
    if($PSBoundParameters.ContainsKey('WebUI'))
    {
        Out-WebUI -FinalPromptComposition $Global:FinalPromptComposition -FinalNegativePromptComposition $Global:FinalNegativePromptComposition -OutputToFileFormatParameters $Global:OutputToFileFormatParameters
    }
    if($PSBoundParameters.ContainsKey('API'))
    {
        $SDVersion = Read-Host -Prompt "Version de StableDiffusion pour la génération ? (SD/XL)"
        While($SDVersion -notlike "SD" -and $SDVersion -notlike "XL")
        {$SDVersion = Read-Host -Prompt "Version de StableDiffusion pour la génération ? (SD/XL)"}
        $UserSettings = Get-UserPromptInput -Generation
        Invoke-SDAPI -Prompt $Global:FinalPromptComposition -NegativePrompt $Global:FinalNegativePromptComposition -Parameters $UserSettings -SDVersion $SDVersion
    }
}
##################################################################################################

    if ($PSBoundParameters.ContainsKey('ShowStylesList')) {
        Show-Guides -Guide Styles
    }

    elseif ($PSBoundParameters.ContainsKey('ShowMoodKeywordsList')) {
        Show-Guides -Guide Mood
    }

    elseif ($PSBoundParameters.ContainsKey('ShowConceptualKeywordsList')) {
        Show-Guides -Guide Conceptually
    }

    elseif ($PSBoundParameters.ContainsKey('ShowArtistsList')) {
        Show-Guides -Guide Artists
    }

    elseif ($PSBoundParameters.ContainsKey('Generate'))
    {
        function Test-Parameters {
            if ($WebUI -and $API) {
                throw "-WebUI and -API ne peuvent être utilisés en même temps."
                exit
            }
        }
        Test-Parameters
        Invoke-PromptGenerator
    }