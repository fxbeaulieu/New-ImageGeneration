[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $InputCkpt
)

$Global:SetModelsOptions=(Get-Content -Path "$PSScriptRoot\..\templates\set-checkpoint-body.txt")

$Global:URLSetModels="http://localhost:64640/sdapi/v1/options"

function Set-Model
{
    $Global:ModelNameString = "`"$InputCkpt`""
    $Global:SetModelsOptions = $Global:SetModelsOptions.Replace('""',$Global:ModelNameString)
    Invoke-WebRequest -Uri $Global:URLSetModels -ContentType "application/json" -Body $Global:SetModelsOptions -Method POST
}

Set-Model