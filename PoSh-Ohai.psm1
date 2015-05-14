#requires -Version 2
<##################################################################################################

    __________       _________.__              ________  .__           .__
    \______   \____ /   _____/|  |__           \_____  \ |  |__ _____  |__|
    |     ___/  _ \\_____  \ |  |  \   ______  /   |   \|  |  \\__  \ |  |
    |    |  (  <_> )        \|   Y  \ /_____/ /    |    \   Y  \/ __ \|  |
    |____|   \____/_______  /|___|  /         \_______  /___|  (____  /__|
    \/      \/                  \/     \/     \/
    Module Manifest
    Version 0.1


###################################################################################################>


function Get-ComputerConfiguration 
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory = $false)]
        [ValidateScript({
                    Test-Path $_ -PathType 'Container'
                }
        )]
        [string]$Directory = ([string](Split-Path -Path (Get-Variable -Name MyInvocation -Scope 1).Value.MyCommand.Path) + '\plugins'),
        [parameter(Mandatory = $false,Position = 0)]
        [string[]]$Filter
    )
    $allPlugins = @()
    foreach ($file in (Get-ChildItem $Directory -Filter *.ps1)) 
    {
        $plugin = @{}
        $plugin['code']  = Get-Content -Path $file.FullName
        $plugin['provides'] = [scriptblock]::Create(($plugin['code'] + "`$provides") -join "`n").Invoke()
        $allPlugins += New-Object -TypeName psobject -Property $plugin
        
    }
    $usedPlugins = if ($Filter -ne $null) 
    {
        foreach ($f in $Filter) 
        {
            $allPlugins | Where-Object -FilterScript {
                $_.provides -contains $f
            }
        }
    }
    else 
    {
        $allPlugins
        
    }

    $result = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    foreach ($plugin in $usedPlugins) 
    {
        $pluginCollectedData = Invoke-Command -ScriptBlock (
            [scriptblock]::Create(($plugin.code + "`Collect-Data") -join "`n"))
        foreach ($prov in $plugin.provides) 
        {

            If ($Filter -contains $prov) 
            {
                $result[$prov] = $pluginCollectedData.$prov
                $result[$prov]
            }
        }
        $result += $pluginCollectedData
    }
    $ErrorActionPreference = $oldErrorActionPreference
    
    # Different output depending on the powershell version
    $PowershellVersion = $PSVersionTable.PSVersion.Major
        if ($PowershellVersion -le 2){
            $result | ConvertTo-Xml -Depth 10 -NoTypeInformation -As String
        }
        else{
            $result | ConvertTo-Json -Depth 10 -Compress
    }



    <#
        .SYNOPSIS
        The Get-ComputerConfiguration cmdlet is the main and only cmdlet that gets exported from this module.
        It will pick up the ps1 plugins from the specified folder or the default folder if no specific directory is set.

        .DESCRIPTION
        See the synopsis field.

        .PARAMETER Directory
        Use this parameter to specify a directory other than the default (which is the plugin folder in the module directory) to pick plugins from.

        .EXAMPLE
        PS C:\Users\Administrator> Get-ComputerConfiguration
        This example shows how to run the cmdlet with default settings, this will grab plugins from the plugins subfolder in the module directory and run all plugins it finds.

    #>
}


function Insert-WMIUnderscore 
{
    param(
        [parameter(Mandatory = $true)]
        [string]$name
    )

    ($name -replace [regex]'::', '/' -replace [regex]'([A-Z]+)([A-Z][a-z])', '$1_$2' -replace [regex]'([a-z\d])([A-Z])', '$1_$2').ToLower()

    <#
        .SYNOPSIS
        The Get-ComputerConfiguration cmdlet is the main and only cmdlet that gets exported from this module.
        It will pick up the ps1 plugins from the specified folder or the default folder if no specific directory is set.

        .DESCRIPTION
        See the synopsis field.

        .PARAMETER Directory
        Use this parameter to specify a directory other than the default (which is the plugin folder in the module directory) to pick plugins from.

        .EXAMPLE
        PS C:\Users\Administrator> Get-ComputerConfiguration
        This example shows how to run the cmdlet with default settings, this will grab plugins from the plugins subfolder in the module directory and run all plugins it finds.

    #>
}


Function ConvertTo-MaskLength 
{
    [CmdLetBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [Alias('Mask')]
        [String]$SubnetMask
    )

    Process {
        if (!$SubnetMask.Contains('.')) 
        {
            Return $SubnetMask
        }
        $Bits = (([ipaddress]$SubnetMask).GetAddressBytes() | ForEach-Object -Process {
                [Convert]::ToString($_, 2)
            }
        ) -join '' -replace '[s0]'

        Return $Bits.Length
    }

    <#
        .Synopsis
        Returns the length of a subnet mask.
        .Description
        ConvertTo-MaskLength accepts any IPv4 address as input, however the output value
        only makes sense when using a subnet mask.
        .Parameter SubnetMask
        A subnet mask to convert into length
    #>
}
