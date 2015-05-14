#requires -Version 1
$provides = 'processes'

function Collect-Data 
{
    $output = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $processes = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $list_processes = Get-WmiObject -Class Win32_Process |
    Select-Object -Property Caption, CommandLine, CreationClassName, CreationDate, ExecutablePath, Handle, HandleCount, InstallDate, KernelModeTime, MaximumWorkingSetSize, MinimumWorkingSetSize, ParentProcessId, PeakPageFileUsage, PeakVirtualSize, PeakWorkingSetSize, Priority, PrivatePageCount, ProcessId, QuotaNonPagedPoolUsage, QuotaPagedPoolUsage, QuotaPeakNonPagedPoolUsage , QuotaPeakPagedPoolUsage, ReadOperationCount, ReadTransferCount, SessionId, ThreadCount, UserModeTime, VirtualSize, WorkingSetSize, WriteOperationCount, WriteTransferCount, ProcessName, Handles, VM, WS, Path
    
    $output.Add('processes' , $list_processes)
    $output
}
