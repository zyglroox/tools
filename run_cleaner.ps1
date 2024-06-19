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
