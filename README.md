# VMware powercli useful scripts.
Just uncomment section you needed.
This repository contains as-is samples, be careful by using on production systems.
---
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