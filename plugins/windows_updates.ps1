#requires -Version 1
$provides = 'windows_updates'

function Collect-Data 
{
    $output = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $windows_updates = New-Object -TypeName System.Collections.Specialized.OrderedDictionary

    $patchlist = Get-HotFix | Select-Object @{name='Article';expression={$_.HotFixId}}, @{name='DateInstalled';expression={$_.InstalledOn}}

    $output.Add('windows_updates' , $patchlist)
    $output
}
Collect-Data