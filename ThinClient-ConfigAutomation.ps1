##################################################################################

<# Code Purpose: The purpose of this script is to automate as many tasks as  
       possible during the thin client pc configuration/deployment process. 
       Script loads all custom written functions before calling for execution 
       at the end.                                                       
  Script Updated on: 9/30/2015                                                  
      Created By: Thomas Peffers, Senior Systems Engineer / Code Ninja                 
#>

##################################################################################


Function Rename-PC 
{
    #Rename PC
    
    [CmdletBinding()]
    Param ($NewPCName)
    $PCName = Get-WmiObject -Class Win32_ComputerSystem 
    $PCName.Rename($NewPCName)
}


Function Rename-LocalAdminAccount
{
    #Change local local admin account name from Administrator -> Value in $NewAdminName.
    $NewAdminName = "MasterAdmin" 
    $AdministratorAccount = Get-WmiObject Win32_UserAccount -filter "LocalAccount=True AND Name='Administrator'" 
    $AdministratorAccount.Rename($NewAdminName) 
}


Function Change-NicSettings
{
 <#
   Purpose: Change Speed and Duplex to 100 Full and change powersettings on the active nic card to disallow it from power throtting unit.
    
   Notes:
	Find only physical network,if value of properties of adaptersConfigManagerErrorCode is 0,  it means device is working properly. 
	This will locate devices whether they are enabled or disconnected.
	If the value of properties of configManagerErrorCode is 22, it means the adapter was disabled. 
 #>  
	$PhysicalAdapters = Get-WmiObject -Class Win32_NetworkAdapter|Where-Object{$_.PNPDeviceID -notlike "ROOT\*" `
	-and $_.Manufacturer -ne "Microsoft" -and $_.ConfigManagerErrorCode -eq 0 -and $_.ConfigManagerErrorCode -ne 22} 
	
	Foreach($PhysicalAdapter in $PhysicalAdapters)
	{
		$PhysicalAdapterName = $PhysicalAdapter.Name
		#check the unique device id number of network adapter in the currently environment.
		$DeviceID = $PhysicalAdapter.DeviceID
		If([Int32]$DeviceID -lt 10)
		{
			$AdapterDeviceNumber = "000"+$DeviceID
		}
		Else
		{
			$AdapterDeviceNumber = "00"+$DeviceID
		}
		
		#check whether the registry path exists.
		$KeyPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\$AdapterDeviceNumber"
		If(Test-Path -Path $KeyPath)
		{
			$PnPCapabilitiesValue = (Get-ItemProperty -Path $KeyPath).PnPCapabilities
			If($PnPCapabilitiesValue -eq 24)
			{
				Write-Warning """$PhysicalAdapterName"" - The option ""Allow the computer to turn off this device to save power"" has been disabled already."
			}
			If($PnPCapabilitiesValue -eq 0)
			{
				#check whether change value was successed.
				Try
				{	
					#setting the value of properties of PnPCapabilites to 24, it will disable save power option.
					Set-ItemProperty -Path $KeyPath -Name "PnPCapabilities" -Value 24 | Out-Null
					Write-Host """$PhysicalAdapterName"" - The option ""Allow the computer to turn off this device to save power"" was disabled."
					
				
				}
				Catch
				{
					Write-Host "Setting the value of properties of PnpCapabilities failed." -ForegroundColor Red
				}
			}
			If($PnPCapabilitiesValue -eq $null)
			{
				Try
				{
					New-ItemProperty -Path $KeyPath -Name "PnPCapabilities" -Value 24 -PropertyType DWord | Out-Null
					Write-Host """$PhysicalAdapterName"" - The option ""Allow the computer to turn off this device to save power"" was disabled."
					
				}	
				Catch
				{
					Write-Host "Setting the value of properties of PnpCapabilities failed." -ForegroundColor Red
				}
			}
		}
		
        
        If(Test-Path -Path $KeyPath)
		{
			$KeyPathDuplex = "*SpeedDuplex" 
            $NicDuplexSetting = (Get-ItemProperty -Path $KeyPath).$($KeyPathDuplex)
			If($NicDuplexSetting -eq 4)
    			{
    				Write-Warning """$PhysicalAdapterName"" - Speed and Duplex setting ""has been already set to 100 Full."
    			}
        
            If($NicDuplexSetting -eq 0 -or $NicDuplexSetting -eq 1)
			{
				#check whether change value was successed.
				Try
				{	
					#setting the value of properties of PnPCapabilites to 24, it will disable save power option.
					Set-ItemProperty -Path $KeyPath -Name "*SpeedDuplex" -Value 4 | Out-Null
					Write-Host """$PhysicalAdapterName"" - Speed and Duplex setting "" has been set to 100 Full."
					
					
				}
				Catch
				{
					Write-Host "Setting the value of properties of Speed Duplex failed." -ForegroundColor Red
				}
             }
             
        }
        
        Else
		{
			Write-Warning "The path ($KeyPath) not found."
		}
        
        
        
        
	}
}


Function Change-CitrixClientICA
{
    [CmdletBinding()]
    Param ($IPAddress)
        
        
		#check whether the registry path exists.
		$KeyPath = "HKLM:\Software\Citrix\ICA Client"
        $PathTest = Test-Path -Path $KeyPath
		If($PathTest -eq $True)
		{
            $KeyName = "Client Name"
			$CitrixICAClient = (Get-ItemProperty -Path $KeyPath).$($KeyName)
				#check whether change value was successed.
				Try
				{	
					#setting the value of properties of PnPCapabilites to 24, it will disable save power option.
					Set-ItemProperty -Path $KeyPath -Name "Client Name" -Value $IPAddress | Out-Null
					Write-Host "Citrix ICA Client address has been changed to $($IPAddress)"
					#Read-Host "Press any key to continue/exit"
				
				}
				Catch
				{
					Write-Host "Setting the value of ICA Client has Failed." -ForegroundColor Red
                    #Read-Host "Press any key to continue/exit" 
				}
			
		
        
        IF ($PathTest -eq $False)
		{
			Write-Warning "The path ($KeyPath) not found."
		}
        
        
        
        
	}
}

Function Remove-IEStartMenuItem
{
        #Code Purpose: Remove IE ShortCut from User profile start menu. 
        
        
		#check whether the account/icon exists
		$ItemPath = "C:\Users\user\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Internet Explorer.lnk"
        $ActualItemPathTest = Test-Path -Path $ItemPath 
		If($ActualItemPathTest -eq $True)
		{
  
				#check whether change value was successed.
				Try
				{	
					
                           DEL -Path $ItemPath -Force 
                           
                           $SystemConfirmation = Test-Path -Path $ItemPath
                           IF ($SystemConfirmation -eq $False)
                           {
                                Write-Host "Success! IE Shortcut has been deleted." -ForegroundColor Green
                           }
                           
                           Else 
                           {
                                Write-Host "Failed to delete IE Shortcut!" -ForegroundColor Red
                           }
                        
                   
				
				}
				Catch
				{
					Write-Host "Deleting the IE shortcut has failed." -ForegroundColor Red
                    
				}
			
		}
        
        Else 
		{
			Write-Warning "The path ($ItemPath) not found."
		}
        
        
        
	    
}

###################################################################################################################################
#             The script below needs to be tested and is not verified yet 

Function Change-TcpIPNicSettings
{


    [CmdletBinding()]
    Param ($IPAddress)
    
    
    #IPAddress breakdown to grab the correct information for configuring Gateways. 
    
    
    $IPArrayPool = @($IPAddress.Split(".")) 
    
    $IP_Octet_1 = $IPArrayPool.GetValue(0)
    $IP_Octet_2 = $IPArrayPool.GetValue(1)
    $IP_Octet_3 = $IPArrayPool.GetValue(2)
    $IP_Octet_4 = $IPArrayPool.GetValue(3)
      
 <#
   Purpose: Change Speed and Duplex to 100 Full and change powersettings on the active nic card to disallow it from power throtting unit.
    
   Notes:
	Find only physical network,if value of properties of adaptersConfigManagerErrorCode is 0,  it means device is working properly. 
	This will locate devices whether they are enabled or disconnected.
	If the value of properties of configManagerErrorCode is 22, it means the adapter was disabled. 
    
    All information was changed to protect previous clients. Some information may be not be accurate or work as is.
 #>  
	$PhysicalAdapters = Get-WmiObject -Class Win32_NetworkAdapter|Where-Object{$_.PNPDeviceID -notlike "ROOT\*" `
	-and $_.Manufacturer -ne "Microsoft" -and $_.ConfigManagerErrorCode -eq 0 -and $_.ConfigManagerErrorCode -ne 22} 
	
    $DnsDomain = "DNSDomain.Ninja" 
	Foreach($PhysicalAdapter in $PhysicalAdapters)
	{
		   $PhysicalAdapterMac = $PhysicalAdapter.MACAddress
				
				Try
				{	
					$AdapterConfiguration = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter "MacAddress ='$PhysicalAdapterMac'" 
                    
					#All information was changed to protect previous clients. Some information may be not be accurate or work as is.
                    $IPSubnetMask = "255.255.255.0"
                    $IPDefaultIPGateway = "$($IP_Octet_1).$($IP_Octet_2).$($IP_Octet_3).1"
                    $DnsSearchOrder = @("288.0.0.1", "288.0.0.2")
                    
                    $AdapterConfiguration.EnableStatic($IPAddress, $IPSubnetMask)
                    $AdapterConfiguration.SetDNSDomain($DnsDomain)
                    $AdapterConfiguration.SetDNSServerSearchOrder($DnsSearchOrder)
                    $AdapterConfiguration.SetGateways($IPDefaultIPGateway, 1)
                    
                    
				
				}
				Catch
				{
					Write-Host "Setting the TCPIP addresses failed." -ForegroundColor Red
				}
	}
			
       
        

}

###################################################################################################################################
#     Call all commandlets/programs written above for actual execution.
###################################################################################################################################


$NewPCName = Read-Host "Please enter the name that you wish to set this PC's name to"
$IPAddress = Read-Host "Please enter the IP Address that you wish to assign to this machine"

Rename-PC -NewPCName $NewPCName
Write-Host "PC Rename command completed." 
Rename-LocalAdminAccount
Write-Host "Local admin account rename command completed."
Remove-IEStartMenuItem
Write-Host "IE Start Menu shortcut command completed."
Change-CitrixClientICA -IPAddress $IPAddress
Write-Host "Citrix Client ICA command completed."
Change-NicSettings
Write-Host "Nic settings command completed."
Change-TcpIPNicSettings -IPAddress $IPAddress
Write-Host "Static Nic Settings command completed."