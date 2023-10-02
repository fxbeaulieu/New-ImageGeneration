param(
    [Parameter(Mandatory)]
    [ParameterType]
    $MonsterGeneratedPrompt,
    [Parameter()]
    [ParameterType]
    $MonsterGeneratedNegativePrompt,
    [Parameter(Mandatory)]
    [ValidateSet('SD','XL')]
    [string]
    $SDVersion
)

$IP = @{
    XL = '192.168.4.254'
    SD = '192.168.4.32'
}

$Global:Samplers = (Get-Content -Path "$PSScriptRoot\samplers.json" | ConvertFrom-Json).Name

$GetModels = 'http://<IP>:64640/sdapi/v1/sd-models'
$GetActiveModel = 'http://<IP>:64640/sdapi/v1/options?sd_model_checkpoint'
$SetModel = 'http://<IP>:64640/sdapi/v1/options?sd_model_checkpoint='

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

function Get-UserSettingsChoice {
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

    Write-Host "Voulez-vous changer les paramètres de génération par défaut"
    While($ChangeSettings -notlike "o" -and $ChangeSettings -notlike "n")
    {
        $ChangeSettings = Read-Host -Prompt "(O/N) ?"
    }
    if($ChangeSettings -like "o")
    {
        Write-Host "Liste des samplers :"+$Global:Samplers
    }
    else
    {
        $SamplerName="default"
        $Attention="default"
        $ResolutionW="default"
        $ResolutionH="default"
        $Seed="default"
        $Steps="default"
        $NumberIteration="default"
    }
    Return $ModelFileName,$SamplerName,$Attention,$ResolutionW,$ResolutionH,$Seed,$Steps,$NumberIteration
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

function Invoke-TxtToImage{
    param(
    [Parameter(Mandatory)]
    [string]
    $MonsterGeneratedPrompt,
    [Parameter()]
    [string]
    $MonsterGeneratedNegativePrompt,
    [Parameter()]
    [Int64]
    $SeedFromMonster,
    [Parameter()]
    [string]
    $SamplerFromMonster,
    [Parameter()]
    [Int]
    $NumberOfGenerationsFromMonster,
    [Parameter()]
    [Int]
    $NumberOfStepsFromMonster,
    [Parameter()]
    [Int]
    $AttentionStrengthFromMonster,
    [Parameter()]
    [Int]
    $GenerationWidthFromMonster,
    [Parameter()]
    [Int]
    $GenerationHeightFromMonster,
    [Parameter()]
    [string]
    $RequestIP
    )

    $RequestBody = (Get-Content -Path "$PSScriptRoot\txttoimg-request-body.json" | ConvertFrom-Json)
    $RequestBody.prompt = $MonsterGeneratedPrompt
    $RequestBody.negative_prompt = $MonsterGeneratedNegativePrompt
    $RequestBody.seed = $SeedFromMonster
    $RequestBody.sampler_index = $SamplerFromMonster
    $RequestBody.n_iter = $NumberOfGenerationsFromMonster
    $RequestBody.steps = $NumberOfStepsFromMonster
    $RequestBody.cfg_scale = $AttentionStrengthFromMonster
    $RequestBody.width = $GenerationWidthFromMonster
    $RequestBody.height = $GenerationHeightFromMonster

    $GenerationDataBody = ($RequestBody | ConvertTo-Json)
    $TxtGeneration = 'http://<IP>:64640/sdapi/v1/txt2img'
    $TxtGeneration = $TxtGeneration.Replace('<IP>',$RequestIP)

    $DataGeneratedPicture = (Invoke-WebRequest -Uri $TxtGeneration -Method Post -Body $GenerationDataBody)
    Return $DataGeneratedPicture
}

$Global:ActiveModelInfos = Get-ActiveModel -RequestURL $GetActiveModel.Replace('<IP>',$RequestIP)
$Global:ModelsInfos = Get-Models -RequestURL $GetModels.Replace('<IP>',$RequestIP)

$GenerationSettings = Get-UserSettingsChoice

Set-Model -RequestURL ($SetModel.Replace('<IP>',$RequestIP)+$ModelFileName)

Invoke-TxtToImage -MonsterGeneratedPrompt $MonsterGeneratedPrompt -MonsterGeneratedNegativePrompt $MonsterGeneratedNegativePrompt -SamplerFromMonster $GenerationSettings[1] -AttentionStrengthFromMonster $GenerationSettings[2] -GenerationWidthFromMonster $GenerationSettings[3] -GenerationHeightFromMonster $GenerationSettings[4] -SeedFromMonster $GenerationSettings[5] -NumberOfStepsFromMonster $GenerationSettings[6] -NumberOfGenerationsFromMonster $GenerationSettings[7] -RequestIP $RequestIP