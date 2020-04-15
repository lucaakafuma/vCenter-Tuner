function GetRequiredFiles{
 [TODO]
}
function VCSelector{
    
  $vCenterPrompt= 'Scegli il vcenter:
    1) Asia
    2) vCenter InAsset Vecchio
    3) vCenter CloudCerved
    4) Autostar (VPN)
    5) Cerved (VPN)
    6) Kedrion
    7) Kedrion DR
    8) CGR
    9) Riel (VPN)
    10) Yoroi
    11) InAsset Corp
    12) Sissa
    q) EXIT
  '
  # [TODO] Don't wanto to set them as global but i need to to pass them into another function. To be fixed
  $global:userSelection = Read-Host -Prompt $vCenterPrompt
  
  $global:vCenters = @{
    '1' = 'vc-asia.services.inasset.net'; 
    '2' = 'vcenter.inasset.net'; 
    '3' = 'pdp1srv-vvcl002.services.inasset.net'; 
    '4' = 'vcenter.autostar.net';
    '5' = 'cccvcvv01-m.cervedcredit.it';
    '6' = 'vc-kedrion.services.inasset.net';
    '7' = 'vc-kedrion-dr.services.inasset.net';
    '8' = 'vc-cigierre.services.inasset.net';
    '9' = 'vcenter.riel.net';
    '10' = 'vc-yoroi.services.inasset.net';
    '11' = 'cud01srv-vvcl01.corp.inasset.net';
    '12' = 'vc-sissa.services.inasset.net'

  }  

  if($vCenters.ContainsKey($userSelection)){
    $server = $vCenters.$userSelection
  
  } elseif($userSelection -eq 'q'){
    Write-Host "Exiting Program...`nBye!!"
        
    Break 

  } else {
    Write-Host "Selezione errata...!"
  }

  return $server

}

function UserActions($server){
  # Reset Screen For more readibility
  Clear-Host
  CreateTitle

  # Add some text to get the situation clearer
  servedIdentificator -server $server

  while ($true){
    $vCenterPrompt= "
      Azioni:
        1) Cerca e cancella snapshot di FollowmeVM
        2) Consolida le VMs
        q) Disconnettiti da $server
    "
    $userAction = Read-Host -Prompt $vCenterPrompt
    
    if($userAction -eq 1){
      # Reset Screen For more readibility
      Clear-Host
      CreateTitle

      Write-Host "`n>>> Browsing '$server' searching for snapshots.`n>>> Could take some time...`n***`n" -ForegroundColor yellow
      GetSnappy -server $server

    } elseif($userAction -eq 2){
	Clear-Host
        CreateTitle
	Write-Host "`n>>> Browsing $server searching for virtual machines to consolidate.`n>>> Could take some time...`n***`n" 
        Consolidate -server $server

    } elseif($userAction -eq 'q'){
        Write-Host "Now Quitting..."

        Disconnect-VIServer -Confirm:$false $server
        Write-Host "Disconnesso da $server`n`n`n"

        Start-Sleep -s 3

        Clear-Host
        CreateTitle
        Break 

    } else {
       Write-Host "Selezione errata..."
    }
  }
}

function GetSnappy($server){
  # Add some text to get the situation clearer
  servedIdentificator -server $server
  
  # This is the string we are looking for in the descriprion of the snapshot. Should match the followme made snapshot for our script to remove it.
  $Match = "followmevm"
  
  $vmSnappy = Get-VM | Get-Snapshot | Select-Object VM,Name,Description,@{Label="Size";Expression={"{0:N2} GB" -f ($_.SizeGB)}},Created
  
  If (-not $vmSnappy){
    Write-Host ">>> No snapshots found on any VM's controlled by '$server'" -ForegroundColor yellow

  } else {
    $($vmSnappy) | ForEach-Object -Process {
      # If we found a snapshot made by FollowmeVM...
      if ($_.Description -Match $($Match)){
        Write-Host "`n@@@ Found a snapshot named: '$($_.Name) ( $($_.Description) )' on the VM: '$($_.VM)' Created: $($_.Created)" -ForegroundColor red
        Write-Host "`n@@@ Do you want to remove it? (y/n)"  -ForegroundColor yellow
        
        $Option = Read-Host
        
        If($Option -eq 'n'){
          Write-Host "`n@@@ Ok, i will not delete the Snapshot '$($_.Name) - $($_.Description)' !!!`n" -ForegroundColor green
        
        } elseif ($Option -eq 'y'){
          Write-Host "Deleting snapshot. Wait...`n"
          
          Get-Snapshot $($_.VM) | Remove-Snapshot -confirm:$false
          Write-Host "`n@@@ Snapshot '$($_.Name) - $($_.Description)' removed correctly from the VM '$($_.VM)'" -ForegroundColor yellow
        }
      } else {
        # If thw snapshot is not made by Followmevm then we will not delete it.
        Write-Host ">>> Found a handmade snapshot: '$($_.Name) - $($_.Description)' on the VM: $($_.VM); Will not take any action.`n" -ForegroundColor yellow
      }
    }

    # [TODO] Maybe we need this implementation to write the snapshot log down. To do if necessary.
    # We need to fix the path of the log files since this is taken fron another script.
        ## Write log file
    #    $Log = $vmSnappy | Select-Object VM,Name,Description,Size,Created | ConvertTo-Html -title "$($vCenterPrettyNames.$userSelection) - SnapLog " -Head $head -PreContent $($preHTMLContent) -PostContent $postHTMLContent
    #
    #    ## Make a backup if the former log for comparison
    #    Copy-Item "/scripts/vmware/vcenter tuner/logs/$($vCenterPrettyNames.$userSelection)/new_snapshot_report.html" -Destination "/scripts/vmware/vcenter tuner/logs/$($vCenterPrettyNames.$userSelection)/old_snapshot_report.html"
    #
    #    ## Then write the log down
    #    $Log | Out-File "/scripts/vmware/vcenter tuner/logs/$($vCenterPrettyNames.$userSelection)/new_snapshot_report.html"
    #
    #    Write-Host ">>>You can find the log file at /scripts/vmware/vcenter tuner/logs/$($vCenterPrettyNames.$userSelection)/new_snapshot_report.html" -ForegroundColor yellow
  }
  Write-Host "All Work Done Here!`nWhats next??...`n"
}

function Consolidate($server){
<#
  .SYNOPSIS
    Searches for machines which need consolidation.
  .DESCRIPTION
    Searches for machines which need consolidation and permits consolidation actions.
#>
  $TargetVMs = Get-VM | Where-Object {$_.Extensiondata.Runtime.ConsolidationNeeded} | Select-Object -ExpandProperty Name
  
  # Implement this...
  #param ([string]$server)

  # Add some text to get the situation clearer
  servedIdentificator -server $server
  
  if(-not $TargetVMs){
    Write-Host ">>> No VMs need consolidation!" -Separator "`n" -ForegroundColor yellow

  } else {
    ForEach($TargetVM in $TargetVMs){
      # Write-Host ">>> Found: $TargetVM" -Separator "`n" -ForegroundColor yellow

      $answer = Read-Host "Found the vm: $TargetVM which needs to be consolidate. Do you want to Proceed?? [y (Yes) | n (No)]`n"

      if($answer -eq 'y'){
        (Get-VM -Name "$($TargetVM)").ExtensionData.ConsolidateVMDisks()
        Write-Host "Consolidation of the vm $($TargetVM) SUCCESSFUL!!`n"

      } else {
        Write-Host "Ignoring consolidation for the VM $($TargetVM)"

      }
    
    }

  } 

}



function CreateTitle{
  Write-Host
"======================================================================
        ___           _              _____                       
__   __/ __\___ _ __ | |_ ___ _ __  /__   \_   _ _ __   ___ _ __ 
\ \ / / /  / _ \ '_ \| __/ _ \ '__|   / /\/ | | | '_ \ / _ \ '__|
 \ V / /__|  __/ | | | ||  __/ |     / /  | |_| | | | |  __/ |   
  \_/\____/\___|_| |_|\__\___|_|     \/    \__,_|_| |_|\___|_|   
                                                                 
                        Version 0.9           
=======================================================================                                       
                        " 
}

function other{
   Get-VM | Select-Object Name, NumCpu, MemoryGB,UsedSpaceGB,ProvisionedSpaceGB,@{N="Folder";E={$_.Folder.Name}},@{N="Folder Parent";E={$_.Folder.Parent}} | Export-Csv "ExportVM.csv" -NoTypeInformation -delimiter ';'
}

function servedIdentificator($server){
  Write-Host "*********************************************************************"
  Write-Host "*** Workin on the vCenter '$server'" -ForegroundColor yellow
  Write-Host "*********************************************************************"
}