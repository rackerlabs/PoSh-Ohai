#requires -Version 1
$provides = 'ServerFeatures', 'OptionalFeatures'

function Collect-Data 
{
    $ServerFeatures = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $OptionalFeatures = New-Object -TypeName System.Collections.Specialized.OrderedDictionary

    $list_ServerFeatures = Get-WmiObject -Class Win32_ServerFeature | Select-Object -Property ParentId, Id, Name
    $list_OptionalFeatures = Get-WmiObject -Class Win32_OptionalFeature | Select-Object -Property Name, InstallState

    $ServerFeatures.Add('ServerFeatures', $list_ServerFeatures)
    $OptionalFeatures.Add('OptionalFeatures', $list_OptionalFeatures)
    $ServerFeatures
    $OptionalFeatures
}
