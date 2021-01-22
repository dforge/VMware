# VMware powercli useful scripts.
Just uncomment section you needed.
This repository contains as-is samples, be careful by using on production systems.
---

#### Cloning virtual machine with specified guest customizstion file, do not forget to enable cloned virtaul machine
```powershell
#
$vm_count               = <INT_CLONNED_VM_COUNT>;
$source_vm              = '<TEMPLATE_VM>';
$destination_host       = '<DESTINATION_HOST_NAME>';
$destination_datastore  = '<DESTINATION_DATASTORE_NAME>';
$guest_spec             = '<GUEST_SPECIFICATION_NAME>';


#
For ($i=1; $i -lt $vm_count; $i++) {
    #
    $clone_name = "w-lab10-00$($i)";

    #
    $clonnned_vm = New-VM `
        -VM $source_vm `
        -Datastore $destination_datastore `
        -DiskStorageFormat Thin `
        -DrsAutomationLevel FullyAutomated `
        -HAIsolationResponse AsSpecifiedByCluster `
        -HARestartPriority ClusterRestartPriority `
        -Name $clone_name `
        -OSCustomizationSpec $guest_spec `
        -VMHost $destination_host `
        -RunAsync
};
```

#### Adding port-groups from another host to other (source/destination). Acceptable only for standard port group.
```powershell
# 20.04.2015
$source_hosts       = "<source>";
$destination_host   = "<destionation>";

$pgs                = Get-VirtualPortGroup -VMHost $source_hosts;
$vss                = Get-VirtualSwitch -VMHost $destination_host;

foreach($pg in $pgs) {
    New-VirtualPortGroup -VirtualSwitch $vss -Name $pg.Name -VLanId $pg.VLanId
};
```

#### Get iscsi initiator from hosts in specified cluster and add iscsi target to all hosts in specified cluster
```powershell
# 20.04.2014

#
$target_address = "<iscsi target>";
$target_port    = "<iscsi target port>";
$vCLuster       = "<cluster>";

#
Get-Cluster -name $vCluster | Get-VMHost | Get-VMHostHba -type iscsi | ft IScsiName;
Get-VMHost -Location $vCluster | Get-VMHostHba -type iscsi | New-IScsiHbaTarget -Address $target_address -Port $target_port;
```

#### Migrate poweredoff virtaul machines to specified storage and host groups with removing network adpater (also with write info about network to vm notes) also remove unwanted virtual machine hardware.

```powershell
# TODO: Also need tool to migrate vm on storage group only (formally detach mode). It's allow keep vm on separate storage without using standalone separated host.
#
$vCluster       = '<CLUSTER_WHERE_FIND_POWEREDOFF_VMS>';
$vms            = Get-VM -Location $vCluster | Where-Object {$_.PowerState -eq 'PoweredOff'};
$target_storage = '<ARCHIVE_STORAGE>';
$target_host    = '<TARGET_HOST_WITH_ARCHIVE_STORAGE>';

#
foreach($vm in $vms) {
    #
    $network = Get-NetworkAdapter -VM $vm.Name;
    $pgn     = Get-VirtualPortGroup -VM $vm.Name;
    
    #
    $name        = $vm.Name;
    $owner       = $vm.CustomFields['vm_owner'];
    $description = $vm.CustomFields['vm_description'];
    $portgroup   = $pgn.Name;
    $vmportgroup = $network.Name
    $vlanid      = $pgn.VLanId;
    $macaddress  = $network.MacAddress;
    $annotation  = $annotation.Notes;
    $annotation  = "$($annotation)`r`n--- name: $($name)`n owner: $($owner)`n descritpion: $($description)`n vm portgroup: $($vmportgroup)`n vds port group: $($portgroup)`n vlanid: $($vlanid)`n mac: $($macaddress)"

    # 1. set annotation for VM
    Set-VM $vm -Notes $annotation;

    # 2. remove network adapter
    Get-NetworkAdapter -VM $vM | Remove-NetworkAdapter -Confirm:$false;

    # 3. migrate
    Move-VM -Datastore $target_storage -Destination $target_host -DiskStorageFormat Thin -VM $vm -VMotionPriority High -Confirm:$false

    # 4. Configure VM Hardware
    $NotWantedHardware = "USB|Parallel|Serial|Floppy" 
    $ConfigureVM       = $false 
    $VMs               = $vM

    foreach ($vmx in $VMs) {
        $vUnwantedHw = @()
        $vmxv        = $vmx | Get-View
        $vmxv.Config.Hardware.Device | where {$_.DeviceInfo.Label -match $NotWantedHardware} | %{
            #
            $myObj          = "" | select Hardware, Key, RemoveDev, Dev
            $myObj.Hardware = $_.DeviceInfo.Label
            $myObj.Key      = $_.Key
            $myObj.Dev      = $_

            if ($vmx.powerstate -notmatch "PoweredOn" -or $_.DeviceInfo.Label -match "USB") {
                $MyObj.RemoveDev = $true;
            } else {
                $MyObj.RemoveDev = $false;
            };

            $vUnwantedHw += $myObj | Sort Hardware;
        };

        #
        Write-Host "VM Hardware:----$($VMX)";

        #
        $vUnwantedHw | Select Hardware, @{N="Can be Removed";E="RemoveDev"} | ft -AutoSize #Output for display        
    };
};
```

#### Get iSCSI HBA IQN of hosts in selected cluster.
Working for both hba type(software or hardware iscsi). You may change $_.Type for fcoe or something else.

```powershell
Get-Cluster -Name '<!CLUSTER NAME!>' | Get-VMhost | Get-VMHostHba | Where {$_.Type -eq 'IScsi'} | ft -AutoSize #IScsiName
```

#### Enter host to Maintenance mode and then reboot.
Do not forget about vm migration before putin host in maintenance.
```powershell
Get-VMHost -Name <HOSTNAME> | Set-VMHost -State Maintenance # Maintenance
Get-VMHost -Name <HOSTNAME> | Restart-VMHost                # Reboot
```

#### Set log severity to info-level and restart vpxa service. This option will be applied for every availbable host in vCenter server.
```powershell
Get-VMHost -Server <vCenter_SERVER> | Get-AdvancedSetting -Name Vpx.Vpxa.config.log.level | Set-AdvancedSetting -Value info -Confirm:$false
Get-VMHost -Server <vCenter_SERVER> | Get-VMHostService | where {$_.Key -eq "vpxa"}  | Restart-VMHostService -Confirm:$false
```

#### Set DomainName on VMhostNetwork in cluster.
```powershell
Get-VMHost -Location '<CLUSTER NAME>' | Get-VMHostNetwork | Set-VMHostNetwork -DomainName <dns domain>
Get-VMHost -Location '<CLUSTER NAME>' | Get-VMHostNetwork | ft -AutoSize
```

#### Remove all standart port groups from hosts in cluster.
Why need to do that? When migrating from standard vswitch to distributed vswitch, you may leave an empty port groups, without uplinks and when you will create a new virtual machine you may select a wrong port group.
Be sure you are migrate vmk interfaces to dvs before execute this.
```powershell
Get-VMHost -Location '<CLUSTER NAME>' | Get-VirtualPortGroup -Standard | Remove-VirtualPortGroup -Confirm:$false
```

#### Configure syslog server on each host in cluster.
```powershell 
Get-VMHost -Location '<CLUSTER NAME>' | Set-VMHostSysLogServer '<SYSLOG SERVER>:<SYSLOG PORT>'
```

#### Get hba wwn for each host in cluster
```powershell
Get-VMHost -Location '<CLUSTER NAME>' | Get-VMHostHBA -Type FibreChannel | Select VMHost,Device,@{N="WWN";E={"{0:X}" -f $_.PortWorldWideName}} | Sort VMhost,Device
```

#### Get poweredon virtual machines in cluster. Select hostname,guest hostname, ip address if vmtools installed.
VMtools must be instaled for define guest name and IP. If virtual machine have multiplie NICs, first NIC address wil be displayed.
```powershell
Get-VM -Location '<CLUSTER>' | Where-Object {$_.PowerState -eq "PoweredOn"} | ft Name, @{e={$($_.Guest).HostName};l="GuestName"}, @{e={$($_.Guest).IPAddress[0]};l="GuestIP"}
```

#### Get log bundle from selected host
```powershell
Get-VMHost -Name <HOSTNAME> | Get-Log -Bundle -DestinationPath <LOG_PATH>
```

#### Get VM by mask(prefix/suffix/etc...)
```powershell
Get-VM -Name *<NAME MASK WITH WILDCARD>* | Where-Object {$_.PowerState -eq "PoweredOn"} | ft Name, @{e={$($_.Guest).HostName};l="GuestName"}, @{e={$($_.Guest).IPAddress[0]};l="GuestIP"}
```

#### Set RoundRoubin policy on whole cluster with auto-rescan (Warning, this may affect local storage).
```powershell
Get-Cluster "<CLUSTER NAME>" | Get-VMHost | Get-ScsiLun -LunType disk | Where {$_.MultipathPolicy -ne "RoundRobin"} | Set-ScsiLun -MultipathPolicy "RoundRobin"
Get-Cluster "<CLUSTER NAME>" | Get-VMHost | Get-VMHostStorage -RescanAllHba
```

#### Open virtual machine console (VMware Remote console requering - https://cutt.ly/lhRGKP3)
```powershell
Get-Cluster -Server $vCenter | Get-VM | Where {$_.Name -eq '<VIRTUAL_MACHINE_NAME>'} | Open-VMConsoleWindow
```

#### Get host iSCSI HBA IQN in selected vCluster
```powershell
Get-Cluster -Name '<CLUSTER NAME>' | Get-VMhost | Get-VMHostHba | Where {$_.Type -eq 'IScsi'} | ft IScsiName
```

#### Rescan hba for new datastore(or changes) on all hosts in vCenter server (Just remove -Server for Get-Cluster and add option -Name for rescan hba on single cluster)
```powershell
Get-Cluster -Server $vCenter | Get-VMhost | Get-VMHostStorage -RescanVmfs -RescanAllHba -Refresh
```

#### Find virtual machine by MAC Address
```powershell
Get-VM | Get-NetworkAdapter | Where {$_.MacAddress -eq "00:50:56:9b:XX:XX"} | Select-Object Parent
```