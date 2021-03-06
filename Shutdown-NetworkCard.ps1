##################################################################################

<# Code Purpose: As requested by a Client, this script will disable a target 
       machine's NIC card that is on the network. This was created for the 
       purpose of blocking a user from the network if it was found that they 
       had a virus on their machine.                                               
       Note: Script will loop until aborted.     

       All information was changed to protect previous client. Some information may be not be accurate or work as is.

       This Script was written to be used with PowerShell version 2 and 3. 
  Script Updated on: 9/30/2015                                                  
      Created By: Thomas Peffers, Senior Systems Engineer / Self Described Code Ninja                 
#>

##################################################################################

Function Get-NetworkCards-Internal
{

Param ($TargetMachine) 

Begin
    {
        
        
        #Scan machine for all Network Cards with a valid IP address/Network Connection. 
        $IPAddresses = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $TargetMachine | Where-Object { $_.IPAddress -like "11.*" } 
        
    }

Process
    { 
        #Process each valid IPaddress to get the matching network adapter. 
        ForEach ( $NetworkServiceName in $IPAddresses) 
        {
            $NetworkServiceName = $IPAddresses
            $NetCard = Get-WmiObject -Class Win32_NetworkAdapter -ComputerName $TargetMachine | Where-Object { $_.ServiceName -match "$($NetworkServiceName.ServiceName)" } 
            
            Write-Host "Do you wish to continue with disabling NetworkCard:" -NoNewline; Write-Host " $($NetCard.Name)" -ForegroundColor Yellow -NoNewline; Write-Host " on machine:" -NoNewline; Write-Host " $($TargetMachine)?" -ForegroundColor Yellow
            $Confirmation = Read-Host "Please enter 'y' for yes or 'n' for No." 
            
            
            
            If ($Confirmation -like "y" -or $Confirmation -like "Y")
                {
                    $NetCard.Disable()
                    Write-Host "Disabling" -ForegroundColor Green -NoNewline; Write-Host " NetworkCard:" -NoNewline; Write-Host " $($NetCard.Name)" -ForegroundColor Green -NoNewline; Write-Host " on machine:" -NoNewline; Write-Host " $($TargetMachine)." -ForegroundColor Green
                }
            If ($Confirmation -like "n" -or $Confirmation -like "N")
                {
                    Write-Host "Aborting" -ForegroundColor Red -NoNewline; Write-Host " operation for Network card: " -NoNewline; Write-Host "$($NetCard.Name)" -ForegroundColor Red -NoNewline; Write-Host " on machine:" -NoNewline; Write-Host " $($TargetMachine)." -ForegroundColor Red
                }
        }
    
    
    
    }

End
    {
        Write-Host "If card was disabled you must log onto the machine as a local admin to re-enable the card normally through 'Network and Sharing Center' under adapter settings. Press any key to exit" 
        Pause
        
    }

}

Function Shutdown-NetworkCard 
{
    [String]$TargetMachine = Read-Host "Please enter the target machine name that you would like to disable all Network Cards for: (Ex: My-PC )"
    
    
    #Ping target machine to verify that it is actually online before continuing 
    $NetTest = Test-Connection -ComputerName $TargetMachine -Quiet -Count 1 
    
    #This part of the test defines what occurs when the machine is online, aka test returns 'true'. If true then it passes the target machine onto the function that will locate and disable the network card.    
    If ($NetTest -match "True") 
        {
            Get-NetworkCards-Internal ($TargetMachine)
        
        }
    
    
    If ($NetTest -match "False")
        {
            #Inform user of error reaching target machine. 
            Write-Host "Sorry target machine:" -ForegroundColor Red -NoNewline; Write-Host " $($TargetMachine) " -NoNewline; Write-Host "is not online/Reachable!" -ForegroundColor Red
            
            #Allow user to decide what to do next. 
            
            [String]$UserAction = "" #Set variable type to string for handling later and clear to prevent issues. 
            
            #Sets up the looping function that will not abort the script unless 'exit' is typed. This is provided to make it easier for someone to work with this script on multiple machines.
            $UserAction = Read-Host "Would you like to try again? (Hit Enter for Yes or type 'exit' to Exit)" 
            
            If ($UserAction.Length -eq "0") 
            
                {
                    Write-Host "###########################################################" -ForegroundColor Blue 
                    Shutdown-NetworkCard
                }
                
            #If user types 'exit' then script terminates. 
            If ($UserAction -like "exit" -or $UserAction -like "Exit")
            
                {
                    Write-Host "Closing Program" -ForegroundColor Yellow
                    exit
                }
        
        }
        
    
    
    
    

}

Shutdown-NetworkCard 


