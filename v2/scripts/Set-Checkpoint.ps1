[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]
    $InputCkpt,
    [Parameter()]
    [string]
    $Instance
)

$Global:SetModelsOptions=(Get-Content -Path "$PSScriptRoot\templates\set-checkpoint-body.txt")

if($Instance -eq  'XL')
{
    $Global:URLSetModels="http://192.168.4.254:64640/sdapi/v1/options"
}
if($Instance -eq 'SD')
{
    $Global:URLSetModels="http://localhost:64640/sdapi/v1/options"
}
if($Instance -eq 'XLT')
{
    $Global:URLSetModels="http://localhost:64669/sdapi/v1/options"
}

function Set-Model
{
    $Global:ModelNameString = "`"$InputCkpt`""
    $Global:SetModelsOptions = $Global:SetModelsOptions.Replace('""',$Global:ModelNameString)
    Invoke-WebRequest -Uri $Global:URLSetModels -ContentType "application/json" -Body $Global:SetModelsOptions -Method POST
}

Set-Model