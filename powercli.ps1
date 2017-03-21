# https://github.com/dforge/VMware.git
#

####################################################
clear

####################################################
$vModule     = "C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\"
$vCenter     = ""
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
###>


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