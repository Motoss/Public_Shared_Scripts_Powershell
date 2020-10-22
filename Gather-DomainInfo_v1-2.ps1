##################################################################################

<# Code Purpose: To run a health check on Active Directory and output the results to a
        specified location.     

       All information was changed to protect previous client. Some information may be not be accurate or work as is.

       This Script was written to be used with PowerShell version 2 and 3. 
  Script Updated on: 9/30/2015                                                  
      Created By: Thomas Peffers, Senior Systems Engineer / Self Described Code Ninja                 
#>

##################################################################################

$Location = Read-Host "Please enter location you would like to save the report. Ex 'C:\' without quotes, but include a '\' at the end."
$PathTest = Test-Path $Location
If($PathTest -eq $true)
{
    $date = Get-Date 
    $DateFormatted = $date.ToShortDateString().Replace('/','_')

    $AllDomainControllerInfo = Get-ADDomainController -Filter *

    Foreach($DC in $AllDomainControllerInfo)
    {

        $test = Test-Connection -ComputerName $DC.hostname -Quiet -Count 1

        IF($test -eq $true)
        {
            Write-Host "################### $($DC.hostname) #############################"

            $results = dcdiag /s:$($DC.hostname) /v

            $results 

            Write-Host "################### End Report Results: $($DC.hostname) #################################"

            Write-Output "################### $($DC.hostname) #############################" | Out-File "$($Location)DC-Diag-Report_$($DateFormatted)-v.txt" -Append

            $results | Out-File "$($Location)DC-Diag-Report_$($DateFormatted)-v.txt" -Append

            Write-Output "################### End Report Results: $($DC.hostname) #################################" | Out-File "$($Location)DC-Diag-Report_$($DateFormatted)-v.txt" -Append

        }

    }


}
