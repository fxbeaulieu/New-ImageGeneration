[CmdletBinding()]
param (
    #### Options du script
    ####

    # Pour lancer la génération d'un nouveau prompt
    [Parameter(ParameterSetName="Generate")]
    [switch]
    $Generate,

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
[int]$Global:RandomStyleSelectorMaxValue = 40

class PromptGenerationParameters{
    [string]$Prompt
    [string]$NegativePrompt
    [string]$PictureArtStyle
    [array]$ConceptualKeywords
    [string]$DirectionKeyword
    [array]$MoodKeywords
    [array]$Artists
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

function Get-UserChoices {
    param (
        [Parameter(ParameterSetName="Prompt")][switch]$Prompt,[Parameter(ParameterSetName="NegPrompt")][switch]$NegativePrompt,[Parameter(ParameterSetName="PictureStyle")][switch]$PictureArtStyle,[Parameter(ParameterSetName="Conceptual")][switch]$ConceptualKeywords,[Parameter(ParameterSetName="Direction")][switch]$DirectionKeyword,[Parameter(ParameterSetName="Mood")][switch]$MoodKeywords,[Parameter(ParameterSetName="Artists")][switch]$Artists
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
            $UserInputValue = $Host.UI.PromptForChoice($Title, $Hint, $Options, 0)
            $UserInput = $Styles[$UserInputValue]
        }
        ConceptualKeywords {
            [int]$CountKeywords = Read-Host -Prompt "Concept de l'image : Combien de mots-clefs voulez-vous sélectionner ? (0-3)"
            if($CountKeywords -ne 0)
            {
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
                While ($Count -lt $CountKeywords) {
                    $UserInputValue = $Host.UI.PromptForChoice($Title, $Hint, $Options, 0)
                    $UserInput += $ConceptualKeywords[$UserInputValue]
                    ++$Count
                }
            }
        }
        DirectionKeyword {
            $Title = "La direction artistique que doit prendre le modèle pour générer l'image: "
            $Hint = "Faire votre choix parmi les options affichées"
            $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Global:DirectionKeywords)
            $UserInputValue = $Host.UI.PromptForChoice($Title, $Hint, $Options, 0)
            $UserInput = $DirectionKeywords[$UserInputValue]
        }
        MoodKeywords {
            [int]$CountKeywords = Read-Host -Prompt "Émotions de l'image : Combien de mots-clefs voulez-vous sélectionner ? (0-3)"
            if($CountKeywords -ne 0)
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
                While ($Count -lt $CountKeywords) {
                    $UserInputValue = $Host.UI.PromptForChoice($Title, $Hint, $Options, 0)
                    $UserInput += $MoodKeywords[$UserInputValue]
                    ++$Count
                }
            }
        }
        Artists {
            [int]$CountArtists = Read-Host -Prompt "Combien d'artistes voulez-vous sélectionner ? (0-3)"
            if($CountArtists -ne 0)
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
                while ($Count -lt $CountArtists) {
                    $UserInputValue = $Host.UI.PromptForChoice($Title, $Hint, $Options, 0)
                    $UserInput += $Artists[$UserInputValue]
                    ++$Count
                }
            }
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

function Invoke-PromptGenerator {
    [string]$UserPrompt = Get-UserChoices -Prompt
    [string]$UserNegativePrompt = Get-UserChoices -NegativePrompt
    [string]$UserPictureArtStyle = Get-UserChoices -PictureArtStyle
    [array]$UserConceptualKeywords = Get-UserChoices -ConceptualKeywords
    [string]$UserDirectionKeyword = Get-UserChoices -DirectionKeyword
    [array]$UserMoodKeywords = Get-UserChoices -MoodKeywords
    [array]$UserArtists = Get-UserChoices -Artists

    [string]$ConceptualKeywordsToPrompt = Format-ConceptualKeywordsToPrompt -ConceptualKeywords $UserConceptualKeywords
    [string]$DirectionKeywordToPrompt = Format-DirectionKeywordToPrompt -DirectionKeyword $UserDirectionKeyword
    [string]$MoodKeywordsToPrompt = Format-MoodKeywordsToPrompt -MoodKeywords $UserMoodKeywords

    [string]$SelectedArtStylePrompt,[string]$SelectedArtStyleNegativePrompt = Format-StyleToPrompt -ArtStyle $UserPictureArtStyle

    [string]$StyledPrompt = $SelectedArtStylePrompt.Replace('<<PROMPT HERE>>', $UserPrompt)

    [string]$ArtistsToPrompt = Format-ArtistsToPrompt -Artists $UserArtists

    [string]$FinalPromptComposition = (
        "$ConceptualKeywordsToPrompt of "+
        $DirectionKeywordToPrompt+
        $MoodKeywordsToPrompt+
        "$StyledPrompt, "+
        $ArtistsToPrompt+
        $Global:BasicPositive+
        $Global:DetailsEmbeddings
        )

    [string]$StyledNegativePrompt = ($SelectedArtStyleNegativePrompt+", "+$UserNegativePrompt)

    [string]$FinalNegativePromptComposition = (
        "$StyledNegativePrompt, "+
        $Global:BasicNegative+
        $Global:NegativeEmbeddings
        )

    [string]$OutputPrompt = $FinalPromptComposition
    [string]$OutputNegativePrompt = $FinalNegativePromptComposition
    [string]$OutputToFileFormatParameters=($OutputPrompt+"`n`n"+$OutputNegativePrompt)

    Write-Host "`n"
    Set-Clipboard -Value $OutputPrompt
    Write-Host -ForegroundColor Green "Prompt copié dans le clipboard. Le coller dans SD WebUI puis faire ENTER pour obtenir le negative prompt."
    Read-Host
    Write-Host "`n"
    Set-Clipboard -Value $OutputNegativePrompt
    Write-Host -ForegroundColor Red "Negative Prompt copié dans le clipboard. Le coller dans SD WebUI puis faire ENTER pour terminer l'exécution."
    Read-Host
    $ExportFileDate = Get-Date -Format FileDateTime
    Add-Content -Value $OutputToFileFormatParameters -Path "$Global:OutputDirectory\$ExportFileDate.txt" -Force
    Write-Host -ForegroundColor Cyan "Fin de l'exécution.`nNote : Les prompts générés ont également été exportés dans le fichier $Global:OutputDirectory\$ExportFileDate.txt"
    Start-Sleep -Seconds 10
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
        Invoke-PromptGenerator
    }