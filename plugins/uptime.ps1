#requires -Version 1
$provides = 'uptime', 'uptime_seconds'

function Collect-Data 
{
    $uptimeSeconds = (Get-WmiObject -Class Win32_PerfFormattedData_PerfOS_System).SystemUpTime
    $TimeSpan = New-TimeSpan -Seconds $uptimeSeconds
    $uptimeString = '{0} days {1} hours {2} minutes {3} seconds' -f $TimeSpan.Days, $TimeSpan.Hours, $TimeSpan.Minutes, $TimeSpan.Seconds
    $uptime = @{
        'uptime' = $uptimeString
    }
    $uptime_seconds = @{
        'uptime_seconds' = $uptimeSeconds
    }
    $uptime_seconds + $uptime
}
