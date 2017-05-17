# https://github.com/dforge/VMware.git
#

####################################################
clear

####################################################
$vModule     = "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\"
$vCenter     = Read-Host -Prompt 'Input vCenter server name'
$vDC         = ""
$currentDate = get-date -uformat '%d.%m.%y %T'
$vLogs       = "C:\Docs\logs\$vCenter.$date.log"
$vWorkPath   = "C:\Docs\data"

####################################################
$moduleList = @(
    "VMware.VimAutomation.Core",
    "VMware.VimAutomation.Vds",
    "VMware.VimAutomation.Cloud",
    "VMware.VimAutomation.PCloud",
    "VMware.VimAutomation.Cis.Core",
    "VMware.VimAutomation.Storage",
    "VMware.VimAutomation.HorizonView",
    "VMware.VimAutomation.HA",
    "VMware.VimAutomation.vROps",
    "VMware.VumAutomation",
    "VMware.DeployAutomation",
    "VMware.ImageBuilder",
    "VMware.VimAutomation.License"
    )

####################################################
function LoadModules() {
   
   $loaded     = Get-Module -Name $moduleList -ErrorAction Ignore | % {$_.Name}
   $registered = Get-Module -Name $moduleList -ListAvailable -ErrorAction Ignore | % {$_.Name}
   $notLoaded  = $registered | ? {$loaded -notcontains $_}
   
   
   foreach ($module in $registered) {
      if ($loaded -notcontains $module) {
		 Import-Module $module
      }
   }
}

####################################################
cd $vModule
LoadModules
Connect-VIServer -Server $vCenter | Out-Null
cd $vWorkPath

#///////////////////////////////////////////////////

<####
$vms = Get-VM -Server $vCenter
$vms.Count
####>

#Get-VM -Server $vCenter | Where {$_.Name -like '*s-siovm-n0*'} | New-Snapshot -Name b4 -Description "SElinux disabled" -Memory
#Get-VM -Server $vCenter | Where {$_.Name -like '*s-siovm-n0*'} | VMware.VimAutomation.Core\Set-VM -Snapshot b4 -Confirm


###################################################
#
#  Desc: Execute some powershell command on vm over vm tools(using vm tools or something like that).
#  Tags: #$clone, #$vm
#  Note: --
#
###################################################

<####
Invoke-VMScript -Confirm -ScriptText '<SOME POWERSHELL COMMAND>' -ScriptType Powershell -VM <VIRTUAL MACHINE NAME>
####>


###################################################
#
#  Desc: Clone virtual machine
#  Tags: #$clone, #$vm
#  Note: --
#
###################################################

#VMware.VimAutomation.Core\New-VM -VM <EXISTING_VM> -Confirm -DiskStorageFormat Thin -DrsAutomationLevel Manual -HAIsolationResponse DoNothing -HARestartPriority Medium -WhatIf
#VMware.VimAutomation.Core\New-VM -VM <EXISTING_VM> -Confirm -VMHost <HOST> -WhatIf
#VMware.VimAutomation.Core\New-VM -VM <EXISTING_VM> -Confirm -Name ubuntu1604 -VMHost <HOST>



###################################################
#
#  Desc: Copy Standart port groups from standart VS to another vSwitch with Vlans ID's.
#  Tags: #$copy, #$vlan
#  Note: --
#
###################################################

<####
$srcHost = "<SOURCE HOST>"
$dstHost = "<DESTINATION HOST>"
$pgs     = Get-VirtualPortGroup -VMHost $srcHost
$vss     = Get-VirtualSwitch -VMHost $dstHost

foreach($pg in $pgs) {
    New-VirtualPortGroup -VirtualSwitch $vss -Name $pg.Name -VLanId $pg.VLanId
}
####>




###################################################
#
#  Desc: Get VM by mask name
#  Tags: #$vm, #$get
#  Note: --
#
###################################################

<####
Get-VM -Name *<NAME MASK WITH WILDCARD>* | Where-Object {$_.PowerState -eq "PoweredOn"} | ft Name, @{e={$($_.Guest).HostName};l="GuestName"}, @{e={$($_.Guest).IPAddress[0]};l="GuestIP"}
####>



###################################################
#
#  Desc: Get log bundle from selected host
#  Tags: #$log, #$get, #$esxi
#  Note: --
#
###################################################

<####
Get-VMHost -Name <HOSTNAME> | Get-Log -Bundle -DestinationPath $vWorkPath
####>

#Get-VMHost -Server $vCenter


###################################################
#
#  Desc: Get information about esxi hosts.
#  Tags: #$info, #$get, #$esxi
#  Note: --
#
###################################################


#!!!!!!!!!!!!!!!!!!!!!!!!! FIXIT

#Get-VMHost -Server $vCenter | ft Name, Version, Parent
#Get-VMHost -Server $vCenter | Group-Object -Property ProcessorType
#Get-VMHost -Server $vCenter | ft -AutoSize
#$Mem = @{e={[math]::round($_.MemoryTotalGB, 0)};l='Memory'}
#$Cpu = @{e={$_.ProcessorType.Substring(31, 5)};l='CPU'}


#Get-VMHost -Server $vCenter | Where-Object {$_.Name -notlike 's-esxi-c*'} | Where-Object {$_.Name -notlike '10.19*'} |ft Name, Version, $Cpu, $Mem -AutoSize

#Get-VMhost -Name 's-esxi60-j-3-7' | Get-Member
#Intel(R) Xeon(R) CPU           X5650  @ 2.67GHz



###################################################
#
#  Desc: Get Virtual Machine Name, GuestName and IP.
#  Tags: #$ip, #$get, #$name
#  Note: VMtools must be instaled. If VM have multiplie NIC, first NIC address wil be displayed.
#
###################################################

<####
Get-VM -Location '<CLUSTER>' | Where-Object {$_.PowerState -eq "PoweredOn"} | ft Name, @{e={$($_.Guest).HostName};l="GuestName"}, @{e={$($_.Guest).IPAddress[0]};l="GuestIP"}
####>




###################################################
#
#  Desc: Get Host hab wwn in cluster.
#  Tags: #$hba, #$wwn
#  Note: --
#
###################################################

<####
Get-VMHost -Location '<CLUSTER>' | Get-VMHostHBA -Type FibreChannel | Select VMHost,Device,@{N="WWN";E={"{0:X}" -f $_.PortWorldWideName}} | Sort VMhost,Device
####>



###################################################
#
#  Desc: Remove all standart port groups from hosts in cluster.
#  Tags: #$posrtgroup, #$network, #$remove
#  Note: --
#
###################################################

<####
Get-VMHost -Location '<CLUSTER NAME>' | Set-VMHostSysLogServer '<SYSLOG SERVER>:<SYSLOG PORT>'
####>




###################################################
#
#  Desc: Remove all standart port groups from hosts in cluster.
#  Tags: #$posrtgroup, #$network, #$remove
#  Note: --
#
###################################################

<####
Get-VMHost -Location '<CLUSTER NAME>' | Get-VirtualPortGroup -Standard | Remove-VirtualPortGroup -Confirm:$false
####>




###################################################
#
#  Desc: Set DomainName on VMhostNetwork in cluster.
#  Tags: #$DomainName, #$network, #$set
#  Note: --
#
###################################################

<####
Get-VMHost -Location '<CLUSTER NAME>' | Get-VMHostNetwork | Set-VMHostNetwork -DomainName <dns domain>
Get-VMHost -Location '<CLUSTER NAME>' | Get-VMHostNetwork | ft -AutoSize
####>




###################################################
#
#  Desc: Set log severity to info and restarting vpxa service.
#  Tags: #$set, #$vpxa, #$severity
#  Note: --
#
###################################################

<####
VMware.VimAutomation.Core\Get-VMHost -Server $vCenter | Get-AdvancedSetting -Name Vpx.Vpxa.config.log.level | Set-AdvancedSetting -Value info -Confirm:$false
VMware.VimAutomation.Core\Get-VMHost -Server $vCenter | Get-VMHostService | where {$_.Key -eq "vpxa"}  | Restart-VMHostService -Confirm:$false
####>




###################################################
#
#  Desc: Get host Name, Cluster and state by name mask (*).
#  Tags: #$get, #$host, #$mask
#  Note: --
#
###################################################

<####
VMware.VimAutomation.Core\Get-VMHost -Server $vCenter | Where {$_.Name -like '*a-9*'} | Sort-Object Name -CaseSensitive | ft -Auto Name, Parent, ConnectionState
####>



###################################################
#
#  Desc: Enter host to maintenance and then reboot.
#  Tags: #$maintenance, #$reboot
#  Note: WARNIGN, Make sure that all VM has been migrated from selected host
#
###################################################

<####
Get-VMHost -Name <HOSTNAME> | Set-VMHost -State Maintenance
Get-VMHost -Name <HOSTNAME> | Restart-VMHost
####>



###################################################
#
#  Desc: Rescan hba for new datastore in whole vCenter server.
#  Tags: #$rescan
#  Note: You may change -Server option to -Name of cluster
#        fore rescan only in cluster. Also you may delete
#        get cluster section and add option -Name for Get-VMhost to rescan on single host.
#
###################################################

<####
VMware.VimAutomation.Core\Get-Cluster -Server $vCenter | Get-VMhost | Get-VMHostStorage -RescanVmfs -RescanAllHba -Refresh
####>




###################################################
#
#  Desc: Get iSCSI HBA IQN of host in selected cluster.
#  Tags: #$get, #$iqn
#  Note: Working for both hba type(software or hardware iscsi). You may change $_.Type for fcoe or something else.
#
###################################################

<####
VMware.VimAutomation.Core\Get-Cluster -Name '<CLUSTER NAME>' | Get-VMhost | Get-VMHostHba | Where {$_.Type -eq 'IScsi'} | ft IScsiName
####>



###################################################
#
#  Desc: Open virtual machine console
#  Tags: #$console, #$open
#  Note: VMware remote console (https://my.vmware.com/web/vmware/details?downloadGroup=VMRC90&productId=491) must be installed.
#
###################################################

<####
VMware.VimAutomation.Core\Get-Cluster -Server $vCenter | VMware.VimAutomation.Core\Get-VM | Where {$_.Name -eq '<VIRTUAL_MACHINE_NAME>'} | Open-VMConsoleWindow
####>



###################################################
#
#  Desc: Set RoundRoubin policy on whole cluster then rescan.
#  Tags: #$policy, #$set
#  Note: Warning, this may affect local storage.
#
###################################################

<####
VMware.VimAutomation.Core\Get-Cluster "<CLUSTER NAME>" | Get-VMHost | Get-ScsiLun -LunType disk | Where {$_.MultipathPolicy -ne “RoundRobin”} | Set-ScsiLun -MultipathPolicy “RoundRobin”
VMware.VimAutomation.Core\Get-Cluster "<CLUSTER NAME>" | Get-VMHost | Get-VMHostStorage -RescanAllHba
####>

#VMware.VimAutomation.Core\Get-Cluster "VDI-4" | Get-VMHost | Get-ScsiLun -LunType disk | Where {$_.MultipathPolicy -ne “RoundRobin”} | Set-ScsiLun -MultipathPolicy “RoundRobin”

#VMware.VimAutomation.Core\Get-VMHost -Server $vCenter | Get-ScsiLun -LunType disk | Where {$_.MultipathPolicy -ne “RoundRobin” -and $_.Vendor -eq 'HP' -and $_.CapacityMB -gt 300000} | ft -AutoSize

#$vHosts = VMware.VimAutomation.Core\Get-VMHost -Server $vCenter

#foreach($vHost in $vHosts) {
#    Write-Host $vHost.Name
#    $vHost | Get-ScsiLun -LunType disk | Where {$_.MultipathPolicy -ne “RoundRobin”} | ft -AutoSize 
#}

#$vhost = s-e


###################################################
#
#  Desc: Check VAAI State in whole DC, show where vaai do not work
#  Tags: #$vaai, #$dc, #$get
#  Note: --
#
###################################################

<####
$vCluster = VMware.VimAutomation.Core\Get-Cluster -Server $vCenter

foreach($vCluster in $vClusters) {

    Write-Host $vCluster.Name –foregroundcolor "Yellow"
    $vHosts = Get-VMHost -Location $vCluster
    foreach($vHost in $vHosts) {
        $hal = (Get-AdvancedSetting -Entity $vHost -Name VMFS3.HardwareAcceleratedLocking).Value
        $hai = (Get-AdvancedSetting -Entity $vHost -Name DataMover.HardwareAcceleratedInit).Value
        $ham = (Get-AdvancedSetting -Entity $vHost -Name DataMover.HardwareAcceleratedMove).Value
        if($hai -ne 1 -and $hal -ne 1 -and $ham -ne 1) {
            Write-Host $vHost.Name –foregroundcolor "Red"
        }
    }
}
####>

#///////////////////////////////////////////////////

####################################################
disconnect-viserver -confirm:$false -Server $vCenter