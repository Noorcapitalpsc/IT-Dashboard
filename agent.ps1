[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$PUSHGATEWAY = "https://it-dashboard-sgkf.onrender.com"
$PORT = 9182
$JOB = "windows"
$INSTANCE = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*"} | Select-Object -First 1).IPAddress

while ($true) {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $cpu = [math]::Round((Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue, 1)
        $os = Get-CimInstance Win32_OperatingSystem
        $mem = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 1)
        $disk = Get-PSDrive C
        $diskUsed = [math]::Round(($disk.Used / ($disk.Used + $disk.Free)) * 100, 1)
        $body = "server_up 1`ncpu_usage $cpu`nmemory_usage $mem`ndisk_usage $diskUsed`n"
        $uri = "$PUSHGATEWAY/metrics/job/$JOB/instance/$INSTANCE`:$PORT"
        Invoke-WebRequest -Uri $uri -Method POST -Body $body -ContentType "text/plain" -UseBasicParsing | Out-Null
        Write-Host "$(Get-Date -Format 'HH:mm:ss') Pushed: CPU=$cpu% MEM=$mem% DISK=$diskUsed%"
    } catch {
        Write-Host "$(Get-Date -Format 'HH:mm:ss') Push failed: $_"
    }
    Start-Sleep -Seconds 15
}
