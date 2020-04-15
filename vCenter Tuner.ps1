
# Clear the screen
Clear-Host

# Include required
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
  
  try {
    . ("$ScriptDirectory\functions.ps1")

  }
  catch {
      Write-Host "Error while loading required files" -ForegroundColor red

      exit
  }

# print some graphics
CreateTitle

# This sould be used in scripts run in a windows environment
# [System.Net.ServicePointManager]::SecurityProtocol =  [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'

 while ($true){
    # First we chose a vCenter server
    $serverChosed = VCSelector
    
    # If the connection succedes...
    # [TODO] Use try / catch instead
    if(Connect-VIServer -Server $serverChosed){
        UserActions -server $serverChosed
    } else {
        Write-Host "Retry..."
        Start-Sleep -s 3

        Clear-Host
        CreateTitle
    }
}

exit
