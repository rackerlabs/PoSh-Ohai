#requires -Version 1
$provides = 'filesystem'

function Collect-Data 
{
    $output = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $fs = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $disks = Get-WmiObject -Class Win32_LogicalDisk
    
    
    foreach ($disk in $disks) 
    {
        $filesystem = $disk.DeviceID
        $fs[$filesystem] = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
        $fs[$filesystem]['kb_size'] = $disk.Properties['size'].value / 1KB
        $fs[$filesystem]['kb_available'] = $disk.Properties['FreeSpace'].value / 1KB
        $fs[$filesystem]['kb_used'] = $fs[$filesystem]['kb_size'] - $fs[$filesystem]['kb_available']
        $fs[$filesystem]['percent_used'] = if ($fs[$filesystem]['kb_size'] -ne 0) 
        {
            [math]::Round($fs[$filesystem]['kb_used'] * 100 / $fs[$filesystem]['kb_size'],2) 
        }
        else 
        {
            0
        }
        $fs[$filesystem]['mount'] = $disk.Properties['name'].value
        $fs[$filesystem]['fs_type'] = ($disk.Properties['FileSystem'].value)
        $fs[$filesystem]['volume_name'] = $disk.Properties['VolumeName'].value
    }
    $output.Add('filesystem',$fs)
    $output
}
