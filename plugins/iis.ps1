$provides = "iis_pools" #, "iis_sites"

function Collect-Data {
    Import-Module WebAdministration
    [void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")

    $iis_conf = [ordered]@{}

    $iis = New-Object Microsoft.Web.Administration.ServerManager
    $iis_pools = $iis.ApplicationPools
    $iis_sites = $iis.Sites

    foreach ($iis_pool in $iis_pools) {
        $pools = $iis_pool.name
        $iis_conf[$pools] = [ordered]@{}
        # General pool settings
        $iis_conf[$pools]["State"] = $iis_pool.state
        $iis_conf[$pools]["ManagedRuntimeVersion"] = $iis_pool.ManagedRuntimeVersion
        $iis_conf[$pools]["Enable32BitAppOnWin64"] = $iis_pool.Enable32BitAppOnWin64
        $iis_conf[$pools]["ManagedPipelineMode"] = $iis_pool.ManagedPipelineMode
        $iis_conf[$pools]["QueueLength"] = $iis_pool.QueueLength
        $iis_conf[$pools]["AutoStart"] = $iis_pool.AutoStart
        $iis_conf[$pools]["StartMode"] = $iis_pool.StartMode
        # CPU settings
        $iis_conf.$pools['CPU'] = [ordered]@{}
        $iis_conf.$pools.CPU["CpuLimit"] = $iis_pool.cpu.Limit
        $iis_conf.$pools.CPU["CpuLimitAction"] = $iis_pool.cpu.Action
        $iis_conf.$pools.CPU["CpuResetInterval"] = $iis_pool.cpu.ResetInterval
        $iis_conf.$pools.CPU["CpuAffinityEnabled"] = $iis_pool.cpu.SmpAffinitized
        $iis_conf.$pools.CPU["CpuAffinityMask"] = $iis_pool.cpu.SmpProcessorAffinityMask
        $iis_conf.$pools.CPU["CpuAffinityMask64"] = $iis_pool.cpu.SmpProcessorAffinityMask2
        # Process Model
        $iis_conf.$pools['ProcessModel'] = [ordered]@{}
        $iis_conf.$pools.ProcessModel["LogEventOnProcessModel"] = $iis_pool.ProcessModel.LogEventOnProcessModel
        $iis_conf.$pools.ProcessModel["IdentityType"] = $iis_pool.ProcessModel.IdentityType
        $iis_conf.$pools.ProcessModel["IdentityUserName"] = $iis_pool.ProcessModel.UserName
        $iis_conf.$pools.ProcessModel["IdentityPassword"] = $iis_pool.ProcessModel.rawattributes.password
        $iis_conf.$pools.ProcessModel["LoadUserProfile"] = $iis_pool.ProcessModel.LoadUserProfile
        $iis_conf.$pools.ProcessModel["IdleTimeout"] = $iis_pool.ProcessModel.IdleTimeout
        $iis_conf.$pools.ProcessModel["MaxProcesses"] = $iis_pool.ProcessModel.MaxProcesses
        $iis_conf.$pools.ProcessModel["PingingEnabled"] = $iis_pool.ProcessModel.PingingEnabled
        $iis_conf.$pools.ProcessModel["PingInterval"] = $iis_pool.ProcessModel.PingInterval
        $iis_conf.$pools.ProcessModel["PingResponseTime"] = $iis_pool.ProcessModel.PingResponseTime
        $iis_conf.$pools.ProcessModel["ShutdownTimeLimit"] = $iis_pool.ProcessModel.ShutdownTimeLimit
        $iis_conf.$pools.ProcessModel["StartupTimeLimit"] = $iis_pool.ProcessModel.StartupTimeLimit
        #$iis_conf.$pools['ProcessModel'] = [ordered]@{}
        $iis_conf.$pools.ProcessModel["LogEventOnProcessModel"] = $iis_pool.ProcessModel.LogEventOnProcessModel
        # Rapid-failure protection
        $iis_conf.$pools['RapidFailProtection'] = [ordered]@{}
        $iis_conf.$pools.RapidFailProtection["RapidFailEnabled"] = $iis_pool.failure.RapidFailProtection
        $iis_conf.$pools.RapidFailProtection["ServiceUnavailableResponce"] = $iis_pool.failure.LoadBalancerCapabilities
        $iis_conf.$pools.RapidFailProtection["RapidFailProtectionInterval"] = $iis_pool.failure.RapidFailProtectionInterval
        $iis_conf.$pools.RapidFailProtection["RapidFailProtectionMaxCrashes"] = $iis_pool.failure.RapidFailProtectionMaxCrashes
        $iis_conf.$pools.RapidFailProtection["AutoShutdownExe"] = $iis_pool.failure.AutoShutdownExe
        $iis_conf.$pools.RapidFailProtection["AutoShutdownParams"] = $iis_pool.failure.AutoShutdownParams
        $iis_conf.$pools.RapidFailProtection["OrphanWorkerProcess"] = $iis_pool.failure.OrphanWorkerProcess
        $iis_conf.$pools.RapidFailProtection["OrphanActionExe"] = $iis_pool.failure.OrphanActionExe
        # Recycling
        $iis_conf.$pools['Recycling'] = [ordered]@{}
        $iis_conf.$pools.Recycling["DisallowOverlappingRotation"] = $iis_pool.recycling.DisallowOverlappingRotation
        $iis_conf.$pools.Recycling["DisallowRotationOnConfigChange"] = $iis_pool.recycling.DisallowRotationOnConfigChange
        $iis_conf.$pools.Recycling["VirtMemoryLimit"] = $iis_pool.recycling.childelements.rawattributes.memory
        $iis_conf.$pools.Recycling["PrivateMemorylimit"] = $iis_pool.recycling.childelements.rawattributes.privateMemory
        $iis_conf.$pools.Recycling["RequestLimit"] = $iis_pool.recycling.childelements.rawattributes.requests
        $iis_conf.$pools.Recycling["RegularTimeLimit"] = $iis_pool.recycling.childelements.rawattributes.time
        $iis_conf.$pools.Recycling['SpecificTimes'] = [ordered]@{}
        $recycletimes = $pools.recycling.childelements.childelements
        foreach () {
        $recycletimes
        }$iis_conf.$pools.Recycling.SpecificTimes[$recycletimes] = $iis_pool.recycling.childelements.childelements
        
        
        #Recycling logging


#        $iis_conf[$pools]["Apps"] = [ordered]@{}
       
#        foreach ($app in $iis_pool.Applications) {
#        }
    }

    [ordered]@{"iis_pools"=$iis_conf}
}