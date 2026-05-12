$e = [char]0x1b

# Required: without this, PowerShell writes using the system codepage (cp1252/cp850)
# which cannot represent non-ASCII Unicode symbols - they appear as question marks
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Single-width BMP symbols only - no wide emoji, so no cursor drift
$emoji_robot  = [char]0x25C6  # ◆  model marker
$emoji_brain  = [char]0x03A9  # Ω  context capacity
$emoji_folder = [char]0x00BB  # »  folder
$emoji_money  = ""            #    cost: $ sign already present in the value
$emoji_rich   = "$$"          #    high cost indicator
$emoji_bolt   = [char]0x21AF  # ↯  cache lightning
$emoji_branch = [char]0x2387  # ⎇  branch (unchanged)
$emoji_tag    = [char]0x0023  # #  session name tag
$emoji_clock  = [char]0x25F7  # ◷  time

$stdin_data = [Console]::In.ReadToEnd()

try {

$data = $stdin_data | ConvertFrom-Json

$model = $data.model.display_name

if (-not $model) { $model = "Unknown" }

$short_model = $model -replace 'Claude [0-9.]+ ', '' -replace '^Claude ', ''

$cost = 0

if ($data.cost.total_cost_usd) { $cost = [math]::Floor($data.cost.total_cost_usd * 100) / 100 }

$duration_ms = 0

if ($data.cost.total_duration_ms) { $duration_ms = [int]$data.cost.total_duration_ms }

$ctx_used = $null

if ($null -ne $data.context_window.remaining_percentage) {

$ctx_used = 100 - [math]::Floor($data.context_window.remaining_percentage)

}

$session_name = $data.session_name

$current_dir = $data.workspace.current_dir

if (-not $current_dir) { $current_dir = "unknown" }

$folder_name = Split-Path $current_dir -Leaf

# Git info

$git_branch = ""

try {

Push-Location $current_dir 2>$null

$git_branch = git branch --show-current 2>$null

Pop-Location

} catch {}

# Cache hit percentage

$cache_pct = 0

try {

$input_tokens = [int]($data.context_window.current_usage.input_tokens)

$cache_read = [int]($data.context_window.current_usage.cache_read_input_tokens)

if (($input_tokens + $cache_read) -gt 0) {

$cache_pct = [math]::Floor($cache_read * 100 / ($input_tokens + $cache_read))

}

} catch {}

# Session time

$session_time = ""

if ($duration_ms -gt 0) {

$total_sec = [math]::Floor($duration_ms / 1000)

$hours = [math]::Floor($total_sec / 3600)

$minutes = [math]::Floor(($total_sec % 3600) / 60)

$seconds = $total_sec % 60

if ($hours -gt 0) { $session_time = "${hours}h ${minutes}m" }

elseif ($minutes -gt 0) { $session_time = "${minutes}m ${seconds}s" }

else { $session_time = "${seconds}s" }

}

# ANSI color codes

$reset = "${e}[0m"

$dim = "${e}[2m"

$white = "${e}[37m"

$blue = "${e}[94m"

$cyan = "${e}[96m"

$yellow = "${e}[33m"

$teal = "${e}[36m"

$green = "${e}[32m"

$red = "${e}[31m"

$magenta = "${e}[95m"

$sep = "${dim}|${reset}"

# Progress bar for context usage

$progress_bar = ""

$ctx_pct = ""

$bar_width = 12

if ($null -ne $ctx_used) {

$filled = [math]::Floor($ctx_used * $bar_width / 100)

$empty = $bar_width - $filled

if ($ctx_used -lt 50) { $bar_color = $green }

elseif ($ctx_used -lt 80) { $bar_color = $yellow }

else { $bar_color = $red }

$filled_chars = "#" * $filled

$empty_chars = "-" * $empty

$progress_bar = "${bar_color}[${filled_chars}${dim}${empty_chars}${bar_color}]${reset}"

$ctx_pct = "${bar_color}${ctx_used}%${reset}"

}

# Line 1: [Model] folder | branch

$line1 = "${magenta}${emoji_robot} [${short_model}]${reset} ${blue}${emoji_folder} $folder_name${reset}"

if ($git_branch) {

$line1 += " ${sep} ${cyan}$emoji_branch $git_branch${reset}"

}

if ($session_name) {

$line1 += " ${sep} ${magenta}${emoji_tag} $session_name${reset}"

}

# Line 2: Progress bar | Context % | cost | duration | cache

$line2_parts = @()

if ($progress_bar -and $ctx_pct) { $line2_parts += "${bar_color}${emoji_brain}${reset} $progress_bar $ctx_pct" }

elseif ($progress_bar) { $line2_parts += "${bar_color}${emoji_brain}${reset} $progress_bar" }

elseif ($ctx_pct) { $line2_parts += "${bar_color}${emoji_brain}${reset} $ctx_pct" }

if ($cost -ge 1) { $line2_parts += "${yellow}${emoji_rich}`$${cost}${reset}" }

else { $line2_parts += "${yellow}`$${cost}${reset}" }

if ($session_time) { $line2_parts += "${teal}${emoji_clock} $session_time${reset}" }

if ($cache_pct -gt 0) { $line2_parts += "${green}${emoji_bolt} cache:${cache_pct}%${reset}" }

$line2 = $line2_parts -join " ${sep} "

Write-Host $line1

Write-Host $line2

} catch {

Write-Host "statusline error: $_"

}
