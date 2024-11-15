# Variables for container names
$esContainerName = "elasticsearch"
$kibanaContainerName = "kibana"

# Function to wait for a container to be running
function Wait-ForContainer {
    param (
        [string]$ContainerName,
        [int]$TimeoutInSeconds = 120
    )
    $startTime = Get-Date
    while ((Get-Date) - $startTime -lt (New-TimeSpan -Seconds $TimeoutInSeconds)) {
        $status = docker inspect -f '{{.State.Status}}' $ContainerName 2>$null
        if ($status -eq 'running') {
            Write-Host "Container '$ContainerName' is healthy."
            return $true
        }
        Write-Host "Waiting for container '$ContainerName' to become healthy..."
        Start-Sleep -Seconds 5
    }
    Write-Host "Timeout waiting for container '$ContainerName' to become healthy."
    return $false
}

# Step 1: Wait for Elasticsearch container to be ready
if (-not (Wait-ForContainer -ContainerName $esContainerName)) {
    Write-Host "Elasticsearch container is not ready. Exiting script."
    exit 1
}

# Step 1: Create enrollment token
Write-Host "Creating enrollment token..."
$tokenOutput = docker exec $esContainerName bin/elasticsearch-create-enrollment-token -s kibana
$enrollmentToken = $tokenOutput | Select-Object -Last 1
Write-Host "Enrollment Token: $enrollmentToken"

# Step 2: Wait for Kibana container to be ready
if (-not (Wait-ForContainer -ContainerName $kibanaContainerName)) {
    Write-Host "Kibana container is not ready. Exiting script."
    exit 1
}

# Step 2: Fetch OTP code from Kibana logs
Write-Host "Fetching OTP code from Kibana logs..."
$otpCode = $null
$maxAttempts = 12
for ($i = 1; $i -le $maxAttempts; $i++) {
    $kibanaLogs = docker logs $kibanaContainerName --since 5m
    $otpLine = $kibanaLogs | Where-Object { $_ -match "Go to" }
    if ($otpLine -match 'code=([^\s]+)') {
        $otpCode = $Matches[1]
        Write-Host "OTP Code: $otpCode"
        break
    } else {
        Write-Host "OTP code not found yet. Retrying in 5 seconds... ($i/$maxAttempts)"
        Start-Sleep -Seconds 5
    }
}

if (-not $otpCode) {
    Write-Host "Failed to extract OTP code from Kibana logs after multiple attempts."
}

# Step 3: Reset password for user 'elastic'
Write-Host "Resetting password for user 'elastic'..."
$confirmationInput = "y`n"
$resetPasswordOutput = echo $confirmationInput | docker exec -i $esContainerName bin/elasticsearch-reset-password -u elastic -s -a
$newPassword = $resetPasswordOutput | Select-Object -Last 1
Write-Host "New 'elastic' user password: $newPassword"

# Step 4: Display collected data
Write-Host "`n========================"
Write-Host "Enrollment Token: $enrollmentToken"
Write-Host "OTP Code: $otpCode"
Write-Host "New 'elastic' user password: $newPassword"
Write-Host "========================"
