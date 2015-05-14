#requires -Version 1
$provides = 'softwares'
function Collect-Data 
{
    $output = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $softwares = New-Object -TypeName System.Collections.Specialized.OrderedDictionary

    $list_softwares = Get-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |
    Select-Object -Property DisplayName, DisplayVersion, Publisher, InstallDate

    $output.Add('softwares' , $list_softwares)
    $output
}
