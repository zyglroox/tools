$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$logPath = Join-Path -Path $scriptPath -ChildPath "ShutdownIssues.log"

$events = Get-WinEvent -LogName System | Where-Object {
    $_.Id -in @(203, 10001, 1073) #@(203, 1073, 1074)
}

$total = $events.Count
$current = 0

if ($events) {
    foreach ($event in $events) {
        $current++
        $percentComplete = [math]::Round(($current / $total) * 100)

        Write-Progress -Activity "Writing logs..." -Status "Processed $current of $total" -PercentComplete $percentComplete

        $time = $event.TimeCreated
        $message = $event.Message
        Add-Content -Path $logPath -Value "[$time] $message`n"
    }
}

Write-Progress -Activity "Done" -Completed