#requires -Version 2
$provides = 'pending_reboot'

function Collect-Data 
{
    $output = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $pending_reboot = New-Object -TypeName System.Collections.Specialized.OrderedDictionary

    $PendFileRename, $Pending, $SCCM = $false, $false, $false
    $Computer = $env:COMPUTERNAME
    $CBSRebootPend = $null

    $WMI_OS = Get-WmiObject -Class Win32_OperatingSystem -Property BuildNumber, CSName -ComputerName $Computer
    $RegCon = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]'LocalMachine',$Computer)

    # If Vista/2008 & Above query the CBS Reg Key
    If ($WMI_OS.BuildNumber -ge 6001) 
    {
        $RegSubKeysCBS = $RegCon.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\').GetSubKeyNames()
        $CBSRebootPend = $RegSubKeysCBS -contains 'RebootPending'
    }#End If ($WMI_OS.BuildNumber -ge 6001)

    # Query WUAU from the registry
    $RegWUAU = $RegCon.OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\')
    $RegWUAURebootReq = $RegWUAU.GetSubKeyNames()
    $WUAURebootReq = $RegWUAURebootReq -contains 'RebootRequired'

    # Query PendingFileRenameOperations from the registry
    $RegSubKeySM = $RegCon.OpenSubKey('SYSTEM\CurrentControlSet\Control\Session Manager\')
    $RegValuePFRO = $RegSubKeySM.GetValue('PendingFileRenameOperations',$null)

    # Closing registry connection
    $RegCon.Close()

    # If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true
    If ($RegValuePFRO) 
    {
        $PendFileRename = $true
    }#End If ($RegValuePFRO)

    # Determine SCCM 2012 Client Reboot Pending Status
    # To avoid nested 'if' statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0
    $CCMClientSDK = $null
    $CCMSplat = @{
        NameSpace    = 'ROOT\ccm\ClientSDK'
        Class        = 'CCM_ClientUtilities'
        Name         = 'DetermineIfRebootPending'
        ComputerName = $Computer
        ErrorAction  = 'SilentlyContinue'
    }
    $CCMClientSDK = Invoke-WmiMethod @CCMSplat
    If ($CCMClientSDK) 
    {
        If ($CCMClientSDK.ReturnValue -ne 0) 
        {
            Write-Warning "Error: DetermineIfRebootPending returned error code $($CCMClientSDK.ReturnValue)"
        }#End If ($CCMClientSDK -and $CCMClientSDK.ReturnValue -ne 0)
        If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending) 
        {
            $SCCM = $true
        }#End If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending)
    }#End If ($CCMClientSDK)
    Else 
    {
        $SCCM = $false
    }

    # If any of the variables are true, set $Pending variable to $true
    If ($CBSRebootPend -or $WUAURebootReq -or $SCCM -or $PendFileRename) 
    {
        $Pending = $true
    }#End If ($CBS -or $WUAU -or $PendFileRename)

    # Creating Custom PSObject and Select-Object Splat
    $SelectSplat = @{
        Property = ('CBServicing', 'WindowsUpdate', 'CCMClientSDK', 'PendFileRename', 'RebootPending')
    }

    $pending_reboot = New-Object -TypeName PSObject -Property @{
        CBServicing    = $CBSRebootPend
        WindowsUpdate  = $WUAURebootReq
        CCMClientSDK   = $SCCM
        PendFileRename = $PendFileRename
        RebootPending  = $Pending
    }

    $output.Add('pending_reboot' , $pending_reboot)
    $output
}

