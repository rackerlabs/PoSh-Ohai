$provides = "mycerts" #,"allcerts"

function Collect-Data {
    $LMMyCerts = (Get-ChildItem -path Cert:\LocalMachine\My)
    
    $mycerts = [ordered]@{}
    
    foreach ($cert in $LMMyCerts){
        $certhash = $cert.Thumbprint
        $mycerts[$certhash] = [ordered]@{}
        $mycerts[$certhash]["SubjectName"] = $cert.SubjectName.name
        $mycerts[$certhash]["DnsNameList"] = $cert.DnsNameList.Unicode
        $mycerts[$certhash]["Subject"] = $cert.Subject
        $mycerts[$certhash]["Issuer"] = $cert.Issuer
        $mycerts[$certhash]["FriendlyName"] = $cert.FriendlyName
        $mycerts[$certhash]["HasPrivateKey"] = $cert.HasPrivateKey
        $mycerts[$certhash]["NotBefore"] = ($cert.NotBefore).ToString("dd-MMM-yyyy")
        $mycerts[$certhash]["NotAfter"] = ($cert.NotAfter).ToString("dd-MMM-yyyy")
        $mycerts[$certhash]["PSPath"] = $cert.PSPath
<#
        These make the ConvertTo-JSON main function crash :(
        
        DO NOT ENABLE without further testing!

        $mycerts[$certhash]["PSProvider"] = $cert.PSProvider
        $mycerts[$certhash]["PSDrive"] = $cert.PSDrive
#>
        $mycerts[$certhash]["PSChildName"] = $cert.PSChildName
        $mycerts[$certhash]["SerialNumber"] = $cert.SerialNumber
        $mycerts[$certhash]["Thumbprint"] = $cert.Thumbprint
    }

    [ordered]@{"MyCerts" = $mycerts}

<#
    #Work in progress#

    $LMCerts = (Get-ChildItem -path Cert:\LocalMachine -Recurse)

    foreach ($cert in $LMCerts){
        $certhash = $cert.Thumbprint
        $allcerts[$certhash] = [ordered]@{}
        $allcerts[$certhash]["SubjectName"] = $cert.SubjectName.name
        $allcerts[$certhash]["DnsNameList"] = $cert.DnsNameList.Unicode
        $allcerts[$certhash]["Subject"] = $cert.Subject
        $allcerts[$certhash]["Issuer"] = $cert.Issuer
        $allcerts[$certhash]["FriendlyName"] = $cert.FriendlyName
        $allcerts[$certhash]["HasPrivateKey"] = $cert.HasPrivateKey
        $allcerts[$certhash]["NotBefore"] = ($cert.NotBefore).ToString("dd-MMM-yyyy")
        $allcerts[$certhash]["NotAfter"] = ($cert.NotAfter).ToString("dd-MMM-yyyy")
        $allcerts[$certhash]["PSPath"] = $cert.PSPath
        $allcerts[$certhash]["PSChildName"] = $cert.PSChildName
        $allcerts[$certhash]["SerialNumber"] = $cert.SerialNumber
        $allcerts[$certhash]["Thumbprint"] = $cert.Thumbprint
    }


    [ordered]@{"AllCerts" = $allcerts}

#>
}