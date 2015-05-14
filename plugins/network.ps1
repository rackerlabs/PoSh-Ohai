#requires -Version 1
$provides = 'network'

function Collect-Data 
{
    $output = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $iface = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $iface_config = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
    $iface_instance = New-Object -TypeName System.Collections.Specialized.OrderedDictionary

    $adapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration
    foreach ($adapter in $adapters) 
    {
        $i = $adapter.Index
        $iface_config[$i] = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
        foreach ($p in $adapter.properties) 
        {
            $iface_config[$i][(Insert-WMIUnderscore $p.name)] = $adapter[$p.name]
        }
    }

    $adapters = Get-WmiObject -Class Win32_NetworkAdapter
    foreach ($adapter in $adapters) 
    {
        $i = $adapter.Index
        $iface_instance[$i] = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
        foreach ($p in $adapter.properties) 
        {
            $iface_instance[$i][(Insert-WMIUnderscore $p.name)] = $adapter[$p.name]
        }
    }

    foreach ($i in $iface_instance.Keys) 
    {
        if ($iface_config[$i]['ip_enabled'] -and $iface_instance[$i]['net_connection_id']) 
        {
            $cint = '0x' + [System.Convert]::ToString($(if ($iface_instance[$i]['interface_index']) 
                    {
                        $iface_instance[$i]['interface_index']
                    }
                    else 
                    {
                        $iface_instance[$i]['index']
                    }
            ),16)
            $iface[$cint] = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
            $iface[$cint]['configuration'] = $iface_config[$i]
            $iface[$cint]['instance'] = $iface_instance[$i]

            $iface[$cint]['counters'] = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
            $iface[$cint]['addresses'] = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
            $i = 0
            foreach ($ip in $iface[$cint]['configuration']['ip_address']) 
            {
                $prefixlen = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
                $iface[$cint]['addresses'][$ip] = $prefixlen.Add('prefixlen' , (ConvertTo-MaskLength $iface[$cint]['configuration']['ip_subnet'][$i]))
                
                $i += 1
            }
        }
    }

    $output.Add('network' , $iface)
    $output
}

