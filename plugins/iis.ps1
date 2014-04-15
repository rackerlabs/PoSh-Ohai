$provides = "iis_pools", "iis_sites"

function Collect-Data {
    #Import-Module WebAdministration
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")
   
    $iis = New-Object Microsoft.Web.Administration.ServerManager
    
    $app_conf = [ordered]@{}
    foreach ($iis_pool in $iis.ApplicationPools) {
        $pool = $iis_pool.name
        $app_conf[$pool] = [ordered]@{}
        # General pool settings
        $app_conf[$pool]["State"] = $iis_pool.state
        $app_conf[$pool]["ManagedRuntimeVersion"] = $iis_pool.ManagedRuntimeVersion
        $app_conf[$pool]["Enable32BitAppOnWin64"] = $iis_pool.Enable32BitAppOnWin64
        $app_conf[$pool]["ManagedPipelineMode"] = $iis_pool.ManagedPipelineMode
        $app_conf[$pool]["QueueLength"] = $iis_pool.QueueLength
        $app_conf[$pool]["AutoStart"] = $iis_pool.AutoStart
        $app_conf[$pool]["StartMode"] = $iis_pool.StartMode
        # CPU settings
        $app_conf.$pool['CPU'] = [ordered]@{}
        $app_conf.$pool.CPU["CpuLimit"] = $iis_pool.cpu.Limit
        $app_conf.$pool.CPU["CpuLimitAction"] = $iis_pool.cpu.Action
        $app_conf.$pool.CPU["CpuResetInterval"] = ($iis_pool.cpu.ResetInterval).ToString()
        $app_conf.$pool.CPU["CpuAffinityEnabled"] = $iis_pool.cpu.SmpAffinitized
        $app_conf.$pool.CPU["CpuAffinityMask"] = $iis_pool.cpu.SmpProcessorAffinityMask
        $app_conf.$pool.CPU["CpuAffinityMask64"] = $iis_pool.cpu.SmpProcessorAffinityMask2
        # Process Model
        $app_conf.$pool['ProcessModel'] = [ordered]@{}
        $app_conf.$pool.ProcessModel["LogEventOnProcessModel"] = $iis_pool.ProcessModel.LogEventOnProcessModel
        $app_conf.$pool.ProcessModel["IdentityType"] = $iis_pool.ProcessModel.IdentityType
        $app_conf.$pool.ProcessModel["IdentityUserName"] = $iis_pool.ProcessModel.UserName
        $app_conf.$pool.ProcessModel["IdentityPassword"] = $iis_pool.ProcessModel.rawattributes.password
        $app_conf.$pool.ProcessModel["LoadUserProfile"] = $iis_pool.ProcessModel.LoadUserProfile
        $app_conf.$pool.ProcessModel["IdleTimeout"] = ($iis_pool.ProcessModel.IdleTimeout).ToString()
        $app_conf.$pool.ProcessModel["MaxProcesses"] = $iis_pool.ProcessModel.MaxProcesses
        $app_conf.$pool.ProcessModel["PingingEnabled"] = $iis_pool.ProcessModel.PingingEnabled
        $app_conf.$pool.ProcessModel["PingInterval"] = ($iis_pool.ProcessModel.PingInterval).ToString()
        $app_conf.$pool.ProcessModel["PingResponseTime"] = ($iis_pool.ProcessModel.PingResponseTime).ToString()
        $app_conf.$pool.ProcessModel["ShutdownTimeLimit"] = ($iis_pool.ProcessModel.ShutdownTimeLimit).ToString()
        $app_conf.$pool.ProcessModel["StartupTimeLimit"] = ($iis_pool.ProcessModel.StartupTimeLimit).ToString()
        $app_conf.$pool.ProcessModel["LogEventOnProcessModel"] = $iis_pool.ProcessModel.LogEventOnProcessModel
        # Rapid-failure protection
        $app_conf.$pool['RapidFailProtection'] = [ordered]@{}
        $app_conf.$pool.RapidFailProtection["RapidFailEnabled"] = $iis_pool.failure.RapidFailProtection
        $app_conf.$pool.RapidFailProtection["ServiceUnavailableResponce"] = $iis_pool.failure.LoadBalancerCapabilities
        $app_conf.$pool.RapidFailProtection["RapidFailProtectionInterval"] = ($iis_pool.failure.RapidFailProtectionInterval).ToString()
        $app_conf.$pool.RapidFailProtection["RapidFailProtectionMaxCrashes"] = $iis_pool.failure.RapidFailProtectionMaxCrashes
        $app_conf.$pool.RapidFailProtection["AutoShutdownExe"] = $iis_pool.failure.AutoShutdownExe
        $app_conf.$pool.RapidFailProtection["AutoShutdownParams"] = $iis_pool.failure.AutoShutdownParams
        $app_conf.$pool.RapidFailProtection["OrphanWorkerProcess"] = $iis_pool.failure.OrphanWorkerProcess
        $app_conf.$pool.RapidFailProtection["OrphanActionExe"] = $iis_pool.failure.OrphanActionExe
        # Recycling
        $app_conf.$pool['Recycling'] = [ordered]@{}
        $app_conf.$pool.Recycling["DisallowOverlappingRotation"] = $iis_pool.recycling.DisallowOverlappingRotation
        $app_conf.$pool.Recycling["DisallowRotationOnConfigChange"] = $iis_pool.recycling.DisallowRotationOnConfigChange
        $app_conf.$pool.Recycling["VirtMemoryLimit"] = $iis_pool.recycling.childelements.rawattributes.memory
        $app_conf.$pool.Recycling["PrivateMemorylimit"] = $iis_pool.recycling.childelements.rawattributes.privateMemory
        $app_conf.$pool.Recycling["RequestLimit"] = ($iis_pool.recycling.childelements.rawattributes.requests).ToString()
        $app_conf.$pool.Recycling["RegularTimeLimit"] = ($iis_pool.recycling.childelements.rawattributes.time).ToString()
        $app_conf.$pool.Recycling.ReriodicRestartTimes = @(
            foreach ($recycletime in $iis_pools.Recycling.periodicRestart.schedule) {
                ($recycletime.Time).ToString()
            }
        )
        $app_conf.$pool.Recycling["LogEvenOnRecycle"] = ($iis_pool.recycling.logeventonrecycle).ToString()
    }

    [ordered]@{"iis_pools"=$app_conf}


    $site_conf = [ordered]@{}

    foreach ($site in $iis.Sites) {
        $site_name = $site.name
        $site_conf[$site_name] = [ordered]@{}
        
        $site_conf.$site_name["AppPoolName"] = $site.Applications.ApplicationPoolName
        $site_conf.$site_name["State"] = $site.state
        $site_conf.$site_name["ID"] = $site.id

        $site_conf.$site_name['Bindings'] = [ordered]@{}
        foreach ($binding in $site.bindings) {
            $bindInfo = $binding.BindingInformation

            $site_conf.$site_name.Bindings[$bindInfo] = [ordered]@{}
            foreach ($bindItem in $bindInfo) {
                $site_conf.$site_name.Bindings.$bindInfo['HostName'] = $binding.host
                $site_conf.$site_name.Bindings.$bindInfo['Protocol'] = $binding.Protocol
                $site_conf.$site_name.Bindings.$bindInfo['EndPoint'] = $binding.EndPoint
                $site_conf.$site_name.Bindings.$bindInfo['SslFlags'] = $binding.SslFlags
                $site_conf.$site_name.Bindings.$bindInfo['CertificateHash'] = $binding.CertificateHash
                $site_conf.$site_name.Bindings.$bindInfo['CertificateStoreName'] = $binding.CertificateStoreName
            }
        }
    }

    [ordered]@{"iis_sites"=$site_conf}
}