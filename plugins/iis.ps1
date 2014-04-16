$provides = "iis_pools", "iis_apps"

function Collect-Data {
    #Import-Module WebAdministration
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")
   
    $iis = New-Object Microsoft.Web.Administration.ServerManager
    
    $app_pool = [ordered]@{}
    foreach ($iis_pool in $iis.ApplicationPools) {
        $pool = $iis_pool.name
        $app_pool[$pool] = [ordered]@{}
        # General pool settings
        $app_pool[$pool]["State"] = $iis_pool.state
        $app_pool[$pool]["ManagedRuntimeVersion"] = $iis_pool.ManagedRuntimeVersion
        $app_pool[$pool]["Enable32BitAppOnWin64"] = $iis_pool.Enable32BitAppOnWin64
        $app_pool[$pool]["ManagedPipelineMode"] = $iis_pool.ManagedPipelineMode
        $app_pool[$pool]["QueueLength"] = $iis_pool.QueueLength
        $app_pool[$pool]["AutoStart"] = $iis_pool.AutoStart
        $app_pool[$pool]["StartMode"] = $iis_pool.StartMode
        # CPU settings
        $app_pool.$pool['CPU'] = [ordered]@{}
        $app_pool.$pool.CPU["CpuLimit"] = $iis_pool.cpu.Limit
        $app_pool.$pool.CPU["CpuLimitAction"] = $iis_pool.cpu.Action
        $app_pool.$pool.CPU["CpuResetInterval"] = ($iis_pool.cpu.ResetInterval).ToString()
        $app_pool.$pool.CPU["CpuAffinityEnabled"] = $iis_pool.cpu.SmpAffinitized
        $app_pool.$pool.CPU["CpuAffinityMask"] = $iis_pool.cpu.SmpProcessorAffinityMask
        $app_pool.$pool.CPU["CpuAffinityMask64"] = $iis_pool.cpu.SmpProcessorAffinityMask2
        # Process Model
        $app_pool.$pool['ProcessModel'] = [ordered]@{}
        $app_pool.$pool.ProcessModel["LogEventOnProcessModel"] = $iis_pool.ProcessModel.LogEventOnProcessModel
        $app_pool.$pool.ProcessModel["IdentityType"] = $iis_pool.ProcessModel.IdentityType
        $app_pool.$pool.ProcessModel["IdentityUserName"] = $iis_pool.ProcessModel.UserName
        $app_pool.$pool.ProcessModel["IdentityPassword"] = $iis_pool.ProcessModel.rawattributes.password
        $app_pool.$pool.ProcessModel["LoadUserProfile"] = $iis_pool.ProcessModel.LoadUserProfile
        $app_pool.$pool.ProcessModel["IdleTimeout"] = ($iis_pool.ProcessModel.IdleTimeout).ToString()
        $app_pool.$pool.ProcessModel["MaxProcesses"] = $iis_pool.ProcessModel.MaxProcesses
        $app_pool.$pool.ProcessModel["PingingEnabled"] = $iis_pool.ProcessModel.PingingEnabled
        $app_pool.$pool.ProcessModel["PingInterval"] = ($iis_pool.ProcessModel.PingInterval).ToString()
        $app_pool.$pool.ProcessModel["PingResponseTime"] = ($iis_pool.ProcessModel.PingResponseTime).ToString()
        $app_pool.$pool.ProcessModel["ShutdownTimeLimit"] = ($iis_pool.ProcessModel.ShutdownTimeLimit).ToString()
        $app_pool.$pool.ProcessModel["StartupTimeLimit"] = ($iis_pool.ProcessModel.StartupTimeLimit).ToString()
        $app_pool.$pool.ProcessModel["LogEventOnProcessModel"] = $iis_pool.ProcessModel.LogEventOnProcessModel
        # Rapid-failure protection
        $app_pool.$pool['RapidFailProtection'] = [ordered]@{}
        $app_pool.$pool.RapidFailProtection["RapidFailEnabled"] = $iis_pool.failure.RapidFailProtection
        $app_pool.$pool.RapidFailProtection["ServiceUnavailableResponce"] = $iis_pool.failure.LoadBalancerCapabilities
        $app_pool.$pool.RapidFailProtection["RapidFailProtectionInterval"] = ($iis_pool.failure.RapidFailProtectionInterval).ToString()
        $app_pool.$pool.RapidFailProtection["RapidFailProtectionMaxCrashes"] = $iis_pool.failure.RapidFailProtectionMaxCrashes
        $app_pool.$pool.RapidFailProtection["AutoShutdownExe"] = $iis_pool.failure.AutoShutdownExe
        $app_pool.$pool.RapidFailProtection["AutoShutdownParams"] = $iis_pool.failure.AutoShutdownParams
        $app_pool.$pool.RapidFailProtection["OrphanWorkerProcess"] = $iis_pool.failure.OrphanWorkerProcess
        $app_pool.$pool.RapidFailProtection["OrphanActionExe"] = $iis_pool.failure.OrphanActionExe
        # Recycling
        $app_pool.$pool['Recycling'] = [ordered]@{}
        $app_pool.$pool.Recycling["DisallowOverlappingRotation"] = $iis_pool.recycling.DisallowOverlappingRotation
        $app_pool.$pool.Recycling["DisallowRotationOnConfigChange"] = $iis_pool.recycling.DisallowRotationOnConfigChange
        $app_pool.$pool.Recycling["VirtMemoryLimit"] = $iis_pool.recycling.childelements.rawattributes.memory
        $app_pool.$pool.Recycling["PrivateMemorylimit"] = $iis_pool.recycling.childelements.rawattributes.privateMemory
        $app_pool.$pool.Recycling["RequestLimit"] = ($iis_pool.recycling.childelements.rawattributes.requests).ToString()
        $app_pool.$pool.Recycling["RegularTimeLimit"] = ($iis_pool.recycling.childelements.rawattributes.time).ToString()
        $app_pool.$pool.Recycling.ReriodicRestartTimes = @(
            foreach ($recycletime in $iis_pools.Recycling.periodicRestart.schedule) {
                ($recycletime.Time).ToString()
            }
        )
        $app_pool.$pool.Recycling["LogEvenOnRecycle"] = ($iis_pool.recycling.logeventonrecycle).ToString()
    }

    [ordered]@{"iis_pools"=$app_pool}


    $app_conf = [ordered]@{}

    foreach ($site in $iis.Sites) {
        $site_name = $site.name
        $app_conf[$site_name] = [ordered]@{}
        $app_conf.$site_name["ID"] = $site.id
        $app_conf.$site_name["State"] = ($site.state)
        $app_conf.$site_name["AppPoolName"] = $site.Applications.ApplicationPoolName
        $app_conf.$site_name["ServerAutoStart"] = $site.ServerAutoStart
        $app_conf.$site_name["ConnectionTimeout"] = $site.limits.ConnectionTimeout.TotalSeconds
        $app_conf.$site_name["Path"] = $site.applications.VirtualDirectories.Path
        $app_conf.$site_name["Physicalpath"] = $site.applications.VirtualDirectories.Physicalpath
        $app_conf.$site_name["LogDirectory"] = $site.LogFile.Directory

        $app_conf.$site_name['Bindings'] = [ordered]@{}
        foreach ($binding in $site.bindings) {
            $bindInfo = $binding.BindingInformation

            $app_conf.$site_name.Bindings[$bindInfo] = [ordered]@{}
            foreach ($bindItem in $bindInfo) {
                $app_conf.$site_name.Bindings.$bindInfo['HostName'] = $binding.host
                $app_conf.$site_name.Bindings.$bindInfo['Protocol'] = $binding.Protocol
                #$app_conf.$site_name.Bindings.$bindInfo['Address'] = ($binding.EndPoint | select address -ExpandProperty address)
                $app_conf.$site_name.Bindings.$bindInfo['Address'] = $binding.EndPoint.address.IPAddressToString
                $app_conf.$site_name.Bindings.$bindInfo['Port'] = $binding.EndPoint.Port
                $app_conf.$site_name.Bindings.$bindInfo['EndPoint'] = $binding.EndPoint
                $app_conf.$site_name.Bindings.$bindInfo['SslFlags'] = $binding.SslFlags
                $app_conf.$site_name.Bindings.$bindInfo['CertificateHash'] = $binding.CertificateHash
                $app_conf.$site_name.Bindings.$bindInfo['CertificateStoreName'] = $binding.CertificateStoreName
            }
        }

        $app_conf.$site_name['LogFile'] = [ordered]@{}
        $app_conf.$site_name.LogFile["Enabled"] = $site.LogFile.Enabled
        $app_conf.$site_name.LogFile["Period"] = ($site.LogFile.Period).Tostring()
        $app_conf.$site_name.LogFile["LocalTimeRollover"] = $site.LogFile.LocalTimeRollover
        $app_conf.$site_name.LogFile["LogFormat"] = ($site.LogFile.LogFormat).Tostring()
        $app_conf.$site_name.LogFile["Directory"] = $site.LogFile.Directory
        $app_conf.$site_name.LogFile["LogExtFileFlags"] = ($site.LogFile.LogExtFileFlags).Tostring()

    }

    [ordered]@{"iis_apps"=$app_conf}
}