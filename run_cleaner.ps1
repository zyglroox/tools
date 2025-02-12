# Define the path to the project folder
$projectPath = ".\CleanTools"

# Define the path to the output executable
$exePath = ".\CleanTools\bin\Debug\net8.0\CleanTools.exe"

# Build the project
Write-Host "Building the project..."
dotnet build $projectPath

# Check if the build was successful
if (Test-Path $exePath) {
    Write-Host "Build successful. Running the application..."
    # Run the executable
    & $exePath
} else {
    Write-Host "Build failed or executable not found: $exePath"
}

# Ask the user if they want to prune Docker system
$dockerPrune = Read-Host "Do you want to perform 'docker system prune -a'? (y/n)"

# If the user agrees, execute the Docker prune command
if ($dockerPrune -eq 'y' -or $dockerPrune -eq 'yes') {
    Write-Host "Performing docker system prune..."
    docker system prune -a -f
} else {
    Write-Host "Skipping docker system prune."
}

# Remove dangling Docker volumes
Write-Host "Removing dangling Docker volumes..."
docker volume rm $(docker volume ls -q -f dangling=true)

# Shutdown WSL
Write-Host "Shutting down WSL..."
wsl --shutdown

# Optimize the VHD (virtual hard disk)
$VHDPath = "\docker_data.vhdx"
Write-Host "Optimizing VHD at $VHDPath..."
Optimize-VHD -Path $VHDPath -Mode Full

Write-Host "Cleanup and optimization complete."
