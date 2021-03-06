##################################################################################

<# Code Purpose: To automate the configuration of a end user machine, or atleast
    as much as possible.        
  Script Updated on: 3/23/2016                                                  
      Created By: Thomas Peffers, Systems Engineer / Code Ninja                 
#>

##################################################################################

###################################################################################################################################
#Load all commandlets/programs then call for execution. 
###################################################################################################################################


Function Rename-PC-Internal
{
    #Rename PC
    
    [CmdletBinding()]
    Param ($SiteLocation)
    $Serial = (Get-WmiObject -Class Win32_Bios).SerialNumber
    $NewPCName = "$($SiteLocation)-$($Serial)"
    $PCName = Get-WmiObject -Class Win32_ComputerSystem 
    $PCName.Rename($NewPCName)
}


Function Rename-LocalAdminAccount-Internal
{
    #Change local local admin account name from Administrator -> to value in $NewAdminName.
    $NewAdminName = "PSAdmin" 
    $AdministratorAccount = Get-WmiObject Win32_UserAccount -filter "LocalAccount=True AND Name='Administrator'" 
    $AdministratorAccount.Rename($NewAdminName) 
}

Function Add-MachineToDomain-Internal
{
    [CmdletBinding()]
    Param ($Creds,$SiteLocation)


    If($SiteLocation -eq "1")
    {
        Add-Computer -DomainName "corp.domain.ninja" -Credential $Creds -OUPath "OU=California,OU=PSComputers,DC=Corp,DC=domain,DC=Ninja"
    }

    If($SiteLocation -eq "2")
    {
        Add-Computer -DomainName "corp.domain.ninja" -Credential $Creds -OUPath "OU=Washington,OU=PSComputers,DC=Corp,DC=domain,DC=ninja"

    }

    If($SiteLocation -eq "3")
    {
        Add-Computer -DomainName "corp.domain.ninja" -Credential $Creds -OUPath "OU=Idaho,OU=PSComputers,DC=Corp,DC=domain,DC=ninja"

    }
    

}

Function Install-Items-Internal
{
    Remove-Item -Recurse "C:\Users\Public\Desktop\*"

    cd "c:\temp\CleanDell"
    .\AutomatedFixUnattended.ps1 -AutomatedFixPackage "O15CTRRemove.diagcab"
    Start-Sleep 180

    cd "C:\Temp\Office Installs\+2013Source" 
    .\setup.exe /configure .\InstallO365ProPlusRetail_en_us.xml



}

Function Uninstall-Items-Internal
{
    cd C:\temp\SAVSCFXP
    wmic product "Dell Command | Update" call uninstall
    Start-Sleep 30
    wmic product "Dell Protected Workspace" call uninstall
    Start-Sleep 30
    wmic product "Dell Foundation Services" call uninstall
    Start-Sleep 30
    wmic product "Dell Digital Delivery" call uninstall
    Start-Sleep 30

}

Function Connect-ToNetworkDrive-Internal
{
    $uname = Read-Host 'Enter a username with admin priviledges (i.e. corp\adminuser)'
    net use t: "\\dhjc8v.corp.domain.ninja\Shares" /USER:$uname *
    copy-item -recurse "t:\InformationTechnology\CleanDell\" C:\Temp
    net use /delete t:



}


###################################################################################################################################
#     Call all commandlets/programs written above for actual execution.
###################################################################################################################################

[int]$SiteLocation = Read-Host "Please enter your desired location [1-3] [Default 1]:
1. California
2. Washington
3. Idaho
 [Enter Value]"

$Creds = Get-Credential 

Rename-PC-Internal -SiteLocation $SiteLocation
Write-Host "PC Rename command completed." 
Rename-LocalAdminAccount-Internal
Write-Host "Local admin account rename command completed."
Add-MachineToDomain-Internal -Creds $Creds -SiteLocation $SiteLocation