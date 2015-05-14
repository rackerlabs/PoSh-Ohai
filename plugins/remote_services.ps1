$provides = 'remote_services'

Function Collect-Data {
    $dynamicStart = (netsh.exe int ipv4 show dynamicport tcp)
    $ns = netstat -ano
    $remoteServices = @()

    if (($dynamicStart -eq $null) -or($ns -eq $null) ){
        $remoteServices
    }
    else{
        $dynamicStartTrim = [Int]($dynamicStart | Select-String 'Start Port').ToString().Split(':')[1].Trim()
    
    
    $Headers = [regex]::Split($ns[3].Trim(), '\s{2,}').Replace(' ','')

    $netstatList = @()
    foreach ($line in $ns[4..($ns.count-1)]) {
        $items = [regex]::Split($line.Trim(), '\s+')
        $obj = New-Object -TypeName System.Collections.Specialized.OrderedDictionary
        $i = 0
        foreach ($header in $Headers) {
            $obj | Add-Member -MemberType NoteProperty -Name $header -Value $items[$i]
            $i++
        }
        $netstatList += $obj
    }


    $listening = $netstatList | Where-Object { $_.State -eq 'LISTENING' }
    foreach ($listener in $listening) {
        if ($listener.LocalAddress.StartsWith('[::]')) {
            $ip = '::'
            $port = $listener.LocalAddress.Replace('[::]:','')
        } Else {
            $ip = $listener.LocalAddress.Split(':')[0]
            $port = $listener.LocalAddress.Split(':')[1]
        }
        if ( [int]$port -ge [int]$dynamicStartTrim) { Continue }
        $process = (Get-Process -Id $listener.PID).ProcessName
        $path = "$($listener.PID)/$process"
        $protocol = $listener.Proto.ToLower()
        $remoteServices += @{
                             'ip'=$ip;
                             'path' = $path;
                             'pid'=$listener.PID;
                             'port'=$port;
                             'process'=$process;
                             'protocol'=$protocol}
    }
}
    @{'remote_services'=$remoteServices}
}
