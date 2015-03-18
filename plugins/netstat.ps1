$provides = "netstat"

function Collect-Data {

    $rawNetstat = netstat -ano | Select-String -Pattern '\s+(TCP|UDP)'
    $psObjNetstat = @()

    ForEach($connection in $rawNetstat){

        $item = $connection.line.split(' ',[System.StringSplitOptions]::RemoveEmptyEntries)
        $psitem = New-Object System.Object

        #parse the netstat line for local address and port
        if (($la = $item[1] -as [ipaddress]).AddressFamily -eq 'InterNetworkV6'){
            $psitem | Add-Member -type NoteProperty -Name LocalAddress -Value $la.IPAddressToString
            $psitem | Add-Member -type NoteProperty -Name LocalPort -Value $item[1].split('\]:')[-1]
        }
        else {
            $psitem | Add-Member -type NoteProperty -Name LocalAddress -Value  $item[1].split(':')[0]
            $psitem | Add-Member -type NoteProperty -Name LocalPort -Value $item[1].split(':')[-1]
        }

        #parse the netstat line for remote address and port
        if (($ra = $item[2] -as [ipaddress]).AddressFamily -eq 'InterNetworkV6'){
            $psitem | Add-Member -type NoteProperty -Name RemoteAddress -Value $ra.IPAddressToString
            $psitem | Add-Member -type NoteProperty -Name RemotePort -Value $item[2].split('\]:')[-1]
        }
        else {
            $psitem | Add-Member -type NoteProperty -Name RemoteAddress -Value $item[2].split(':')[0]
            $psitem | Add-Member -type NoteProperty -Name RemotePort -Value $item[2].split(':')[-1]
        }

        $psitem | Add-Member -type NoteProperty -Name Protocol -Value $item[0]

        if ($item[0] -eq 'tcp'){
            $status = $item[3]
        }
        else{
            $status = $null
        }

        $psitem | Add-Member -type NoteProperty -Name State -PassThru -Value $status

        #$psitem | Add-Member -type NoteProperty -Name State -Value | if($item[0] -eq 'tcp') {$item[3]} else {$null}
        $psitem | Add-Member -type NoteProperty -Name ProcessID -Value $item[-1]
        $psitem | Add-Member -type NoteProperty -Name ProcessName -Value (Get-Process -Id $item[-1] -ErrorAction SilentlyContinue).Name


        $psObjNetstat += $psitem
    }

    [ordered]@{"netstat" = $psObjNetstat}
}