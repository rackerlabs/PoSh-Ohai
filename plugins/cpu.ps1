$provides = 'cpu'

function Collect-Data {
    $output = New-Object System.Collections.Specialized.OrderedDictionary
    $cpuinfo = New-Object System.Collections.Specialized.OrderedDictionary
    $cpuNumber = 0
    $index = 0
    foreach ($processor in Get-WmiObject Win32_Processor) {
        $numberOfCores = $processor.numberofcores
        $cpuNumber += $numberOfCores

        $current_cpu = [string]$index
        $index += 1

        $cpuinfo[$current_cpu] = New-Object System.Collections.Specialized.OrderedDictionary
        $cpuinfo[$current_cpu]['vendor_id'] = $processor.manufacturer
        $cpuinfo[$current_cpu]['family'] = [string]$processor.family
        $cpuinfo[$current_cpu]['model'] = [string]$processor.revision
        $cpuinfo[$current_cpu]['stepping'] = $processor.stepping
        $cpuinfo[$current_cpu]['physical_id'] = $processor.deviceid
        #cpuinfo[current_cpu]["core_id"] = XXX
        $cpuinfo[$current_cpu]['cores'] = $numberOfCores
        $cpuinfo[$current_cpu]['model_name'] = $processor.description
        $cpuinfo[$current_cpu]['mhz'] = [string]$processor.maxclockspeed
        $cpuinfo[$current_cpu]['cache_size'] = "$($processor.l2cachesize) KB"
        #cpuinfo[current_cpu]["flags"] = XXX
    }

    $cpuinfo['total'] = if ($cpuNumber -eq 0) {$null} else {$cpuNumber}
    $cpuinfo['real'] = $index

    $output.Add('cpu' , $cpuinfo)
    $output
}
