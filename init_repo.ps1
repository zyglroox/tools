#Set username and email
$username = ""
$email = ""

# Ask for folder name
$folderName = Read-Host "Enter folder name"

# Check if the folder exists
if (-Not (Test-Path -Path $folderName -PathType Container)) {
    # Create the folder if it doesn't exist
    New-Item -ItemType Directory -Path $folderName
}

# Change location to the specified folder
Set-Location $folderName

# Check if the .git folder exists
if (Test-Path -Path ".git" -PathType Container) {
    # Warn the user and ask whether they want to proceed
    $userResponse = Read-Host "The folder already contains a .git directory. Do you want to proceed? (Y/N)"

    if ($userResponse -eq "N") {
        Write-Host "Exiting script as per user request."
        exit
    }		
}

# Initialize a new git repository if .git folder doesn't exist
git init

# Ask for repository URL
$repoUrl = Read-Host "Enter repository URL"

# Add remote origin
git remote add origin $repoUrl

# Function to get and optionally set git configuration
function Set-GitConfig {
    param (
        [string]$configKey,
        [string]$newValue,
        [string]$displayName
    )
    
    $currentValue = git config --get $configKey

    if ([string]::IsNullOrEmpty($currentValue)) {
        git config $configKey $newValue
        Write-Host "Set ${displayName} to $newValue"
    } else {        
        if (-not $currentValue -eq $newValue) {
			$userResponse = Read-Host "Update git $displayName from $currentValue to $newValue? (Y/N)"
            if ($userResponse -eq "Y") {
                git config $configKey $newValue
                Write-Host "Set $displayName to $newValue"
            } else {
                Write-Host "$displayName remains unchanged."
            }
        } else {
            Write-Host "$displayName is already set to $newValue"
        }
    }
}

# Check and set user.name
Set-GitConfig -configKey "user.name" -newValue $username -displayName "user.name"

# Check and set user.email
Set-GitConfig -configKey "user.email" -newValue $email -displayName "user.email"

# Ask the user whether they want to create an initial commit with .gitignore or checkout an existing branch
$userResponse = Read-Host "Do you want to create an initial commit with .gitignore? (Y/N)"

if ($userResponse -eq "Y") {
    # Create .gitignore file
    @"
# Extensions
*.suo
*.user
*.dbmdl
*.nupkg
*.bin

#Folders
**/.vs/
**/obj/
**/bin/
**/.vscode/
**/.idea/
"@ | Out-File -FilePath .gitignore -Encoding utf8

    # Rename default branch to 'main' (Git 2.28+)
    git branch -M main

    # Add all files to staging area
    git add .

    # Commit changes with initial message
    git commit -m "added gitignore"

    # Ask if the user wants to push the changes
    $pushResponse = Read-Host "Do you want to push the changes to the remote repository? (Y/N)"
    if ($pushResponse -eq "Y") {
        git push --set-upstream origin main
    }
} else {
    # Ask for branch name to checkout
    $branchName = Read-Host "Enter the branch name you want to checkout"
    git checkout $branchName
}