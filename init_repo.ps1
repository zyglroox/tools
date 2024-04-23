#Set username and email
$username = ""
$email = ""

# Ask for folder name
$folderName = Read-Host "Enter folder name"

# Change directory to the specified folder
Set-Location $folderName

# Initialize Git repository
git init
git config user.name $username
Write-Host "Set user.name to $username"
git config user.email $email
Write-Host "Set user.email to $email"

# Ask for repository URL
$repoUrl = Read-Host "Enter repository URL"

# Add remote origin
git remote add origin $repoUrl

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

#Push changes
git push --set-upstream origin main