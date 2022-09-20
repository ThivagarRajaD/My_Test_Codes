
#variable_initialization

$VerbosePreference = "Continue"
$startPeakTime = '08:00:00'
$endPeakTime = '18:00:00'
$timeZone = "Eastern Standard Time"

Get-AzSubscription | ForEach-Object {
    $subscriptionName = $_.Name
    Set-AzContext -SubscriptionId $_.SubscriptionId
    (Get-AzResourceGroup).ResourceGroupName | ForEach-Object {     
        [PSCustomObject] @{
            Subscription = $subscriptionName
            ResourceGroup = $_
        }
    }
}

#Machine_count

$allHostPools = @(
    [PSCustomObject]@{
        Id = 1
        HostPool = 'Office-HP'
        HostPoolRG = 'Office-RG'
        VmName = 'Office-VM-1'
        
    },
    [PSCustomObject]@{
        Id = 2
        HostPool = 'HP'
        HostPoolRG = 'Test-South'
        VmName = 'TEST-VDI-0'
    }
    
)
Write-Host ($ResourceGroupName | Format-Table | Out-String)
$ResourceGroupName = $allHostPools.HostPoolRG
$VmName = $allHostPools.VmName
$hostPoolName = $allHostPools.HostPool


#Date Finder
    $utcDate = ((get-date).ToUniversalTime())
    $tZ = Get-TimeZone $timeZone
    $date = [System.TimeZoneInfo]::ConvertTimeFromUtc($utcDate, $tZ)
    write-verbose "Date and Time"
    write-verbose $date

# Get the current day of the week adjusted for the time zone
    $utcOffset = $tz.BaseUtcOffset.TotalHours
    $dateDay = (((get-date).ToUniversalTime()).AddHours($utcOffset)).dayofweek
    Write-Verbose $dateDay   

# Slice and dice to get the peak start and end time adjusted for the time zone
     $startPeakTimeSplit = $startPeakTime.Split(":")
     $startPeakTime = (get-date $date -Hour $startPeakTimeSplit[0] -minute $startPeakTimeSplit[1] -second $startPeakTimeSplit[2])
     #Write-Verbose $startPeakTime
     $endPeakTimeSplit = $endPeakTime.Split(":")
     $endPeakTime = (get-date $date -Hour $endPeakTimeSplit[0] -minute $endPeakTimeSplit[1] -second $endPeakTimeSplit[2])   
     #Write-Verbose $endPeakTime

#Machine Size founding
    $machine_size = $allHostPools.Count
    Write-Verbose "machine size is $machine_size"

#Hostpools

    try {
        for ($i = 0; $i -lt $hostPoolName.Count; $i++) {
            $hostPool = Get-AzWvdHostPool -ResourceGroupName $ResourceGroupName[$i] -Name $hostPoolName[$i]
            Write-Verbose $hostPool.Name
            Write-Verbose $hostPool.Count
        }
    }
    catch {
        $ErrorMessage = $_.Exception.message
        Write-Error ("Error getting host pool details: " + $ErrorMessage)
        Break
    }

#Find session hosts count

try {
    for ($i = 0; $i -lt $hostPoolName.Count; $i++) {
        $sessionHostsName = Get-AzWvdSessionHost -ResourceGroupName $ResourceGroupName[$i] -HostPoolName $hostPoolName[$i]
        Write-Verbose $sessionHostsName.Name
        Write-Verbose $sessionHostsName.Count
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ("Error getting session hosts details: " + $ErrorMessage)
    Break
}

#Get No of running session hosts
    $runningSessionHosts = $sessionHostsName.count | Where-Object { $_.Status -eq "Available" }
    $runningSessionHostsCount = $runningSessionHosts.count
    Write-Verbose "Running Session Host $runningSessionHostsCount"
    Write-Verbose ($runningSessionHosts | Out-string)

Write-Verbose $startPeakTime
Write-Verbose $endPeakTime

for ($i = 0; $i -lt $vmName.Count; $i++) {
    $Statuses=(Get-AzVM -ResourceGroupName $ResourceGroupName[$i] -Name $VmName[$i] -Status).Statuses
    Write-Verbose $Statuses[1].Code

    if (("$Env:Offpeaktime"[$i] -eq $endPeakTime[$i]) -and ($Statuses[1].Code -eq "PowerState/Running"))
    {
        for ($i = 0; $i -lt $VmName.Count; $i++) {
            Write-Verbose "$Env:peaktime"
            Write-Verbose "Condition not met to Start"
            Write-Verbose "Stopping the Virtual machines"
            Stop-AzVM -ResourceGroupName $ResourceGroupName[$i] -Name $VmName[$i] -Force -NoWait
        }
    }
    elseif (("$Env:peaktime"[$i] -eq $startPeakTime[$i]) -and ($Statuses[1].Code -eq "PowerState/deallocated"))
    {
        for ($i = 0; $i -lt $VmName.Count; $i++) {
            Write-Verbose "Condition met to Strat"
            Write-Verbose "Starting the Virtual machines"
            Start-AzVM -ResourceGroupName $ResourceGroupName[$i] -Name $VmName[$i] -NoWait
        }
    }
}
