

$Resource=(Get-AzResource -Name $ResourceName).ResourceId
Write-Verbose "Name $Resource"

# First we are creating an action group that will be attached to the alert rule

$ResourceGroupName="Test-South"
$ActionGroupName="AdminGroup"
$ReceiverGroupName="Thivagar Raja D"
$ReceiverGroupEmail="thivagarrajad@boweryfarming.com"

$Receiver=New-AzActionGroupReceiver -Name $ReceiverGroupName -EmailReceiver -EmailAddress $ReceiverGroupEmail
Write-Verbose $Receiver.Name

$ActionGroup=Set-AzActionGroup -Name $ActionGroupName -ResourceGroupName $ResourceGroupName -ShortName $ActionGroupName -Receiver $Receiver
Write-Verbose $ActionGroup.Name

# Then finally we can create an alert rule
# The alert rule will check for the CPU Usage utilization of TEST-VDI-0
# If the CPU Utilization goes beyond 70% in the last 5 minutes , then the alert will be raised

$ResourceName="TEST-VDI-0"
$AlertName="CPUAlert"
$Threshold=70
$MetricName="Percentage CPU"
$Description="Alert when CPU percentage goes beyond 70%"
$WindowSize=New-TimeSpan -Minutes 5
$Frequency=New-TimeSpan -Minutes 5

$Condition=New-AzMetricAlertRuleV2Criteria -MetricName $MetricName -TimeAggregation Average -Operator GreaterThanOrEqual -Threshold $Threshold

Add-AzMetricAlertRuleV2 -Name $AlertName -ResourceGroupName $ResourceGroupName -Severity 3 -TargetResourceId $Resource -Description $Description -Condition $Condition -WindowSize $WindowSize -Frequency $Frequency -ActionGroupId $ActionGroup.Id

