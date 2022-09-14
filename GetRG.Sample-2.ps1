$allHostPools = @(
    [PSCustomObject]@{
        Id = 1
        HostPool = 'Office-HP'
        HostPoolRG = 'Office-RG'
    },
    [PSCustomObject]@{
        Id = 2
        HostPool = 'HP'
        HostPoolRG = 'Test-South'
    }
)
Write-Host ($allHostPools | Format-Table | Out-String)

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

try {
    for ($i = 0; $i -lt $allHostPools.Count; $i++) 
    {
        Write-Verbose $allHostPools[$i]
        $sessionHostsName = Get-AzWvdSessionHost -ResourceGroupName $allHostPools[$i].HostPoolRG -HostPoolName $allHostPools[$i].HostPool | Where-Object { $_.AllowNewSession -eq $true }
        Write-Verbose $sessionHostsName
    } 
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ("Error getting session hosts details: " + $ErrorMessage)
    Break
}

try {
    for ($i = 0; $i -lt $allHostPools.Count; $i++) {
        $hostPool = Get-AzWvdHostPool -ResourceGroupName $allHostPools[$i].HostPoolRG -Name $allHostPools[$i].HostPool
        Write-Verbose "HostPool Name"
        Write-Verbose $hostPool.Name
    }
}
catch {
    $ErrorMessage = $_.Exception.message
    Write-Error ("Error getting host pool details: " + $ErrorMessage)
    Break
}
