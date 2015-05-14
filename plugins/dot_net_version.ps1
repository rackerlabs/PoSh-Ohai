#requires -Version 1
$provides = 'dot_net_version'
function Collect-Data 
{
    $output = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $dot_net_version = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    
    $list_versions = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse |
    Get-ItemProperty -Name Version -EA 0 |
    Where-Object -FilterScript {
        $_.PSChildName -match '^(?!S)\p{L}'
    } |
    Select-Object -Property @{
        Name       = 'Name'
        Expression = {
            $_.PSChildName
        }
    }, Version

    #(Get-ChildItem -Path $Env:windir\Microsoft.NET\Framework |
    #      Where-Object {$_.PSIsContainer -eq $true } |
    #      Where-Object {$_.Name -match 'v\d\.\d'} |
    #      Sort-Object -Property Name -Descending |
    #      Select-Object -First 1).Name

    $output.Add('dot_net_version',$list_versions)
    $output
}
