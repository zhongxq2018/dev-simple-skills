param(
    [switch]$All,
    [switch]$Local
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Determine scan locations ---
$GlobalDir = Join-Path $HOME ".claude\skills"
$LocalDir = Join-Path $ScriptDir ".claude\skills"

$ScanDirs = @()

if ($Local) {
    $ScanDirs += $LocalDir
} elseif ($All) {
    $ScanDirs += $GlobalDir
} else {
    Write-Host ""
    Write-Host "Uninstall from:"
    Write-Host "  [1] Global (~/.claude/skills)"
    Write-Host "  [2] Local  (.claude/skills)"
    Write-Host ""

    while ($true) {
        $locChoice = Read-Host "Choose (1/2) [1]"
        if (-not $locChoice) { $locChoice = "1" }
        switch ($locChoice) {
            "1" { $ScanDirs += $GlobalDir; break }
            "2" { $ScanDirs += $LocalDir; break }
            default { Write-Host "Please enter 1 or 2."; continue }
        }
        break
    }
}

# --- Collect installed skills ---
$Skills = @()
foreach ($dir in $ScanDirs) {
    if (-not (Test-Path $dir)) { continue }
    $dirs = Get-ChildItem -Path $dir -Directory
    foreach ($d in $dirs) {
        $name = $d.Name
        if ($Skills -notcontains $name) {
            $Skills += $name
        }
    }
}

if ($Skills.Count -eq 0) {
    Write-Host "No installed skills found."
    exit 0
}

# --- Select skills to uninstall ---
$SelectedIndices = @()

if ($All) {
    $SelectedIndices = 0..($Skills.Count - 1)
} elseif (-not [Console]::IsInputRedirected -or $Host.UI.SupportsUserInput) {
    Write-Host ""
    Write-Host "Installed skills:"
    Write-Host ""
    Write-Host "  [0] All"
    for ($i = 0; $i -lt $Skills.Count; $i++) {
        Write-Host "  [$($i + 1)] $($Skills[$i])"
    }
    Write-Host ""

    while ($true) {
        $input = Read-Host "Enter skill numbers to uninstall (e.g., 1 2 or 0 for all)"
        $parts = $input.Trim() -split "\s+"

        if ($parts.Count -eq 0 -or $parts[0] -eq "") {
            Write-Host "Please enter at least one number."
            continue
        }

        if ($parts -contains "0") {
            $SelectedIndices = 0..($Skills.Count - 1)
            break
        }

        $valid = $true
        $tempIndices = @()
        foreach ($num in $parts) {
            if ($num -match "^\d+$" -and [int]$num -ge 1 -and [int]$num -le $Skills.Count) {
                $tempIndices += ([int]$num - 1)
            } else {
                Write-Host "Invalid number: $num (valid range: 0-$($Skills.Count))"
                $valid = $false
                break
            }
        }

        if ($valid) {
            $SelectedIndices = $tempIndices
            break
        }
    }
} else {
    Write-Host ""
    Write-Host "Non-interactive mode detected. Use -All to uninstall all skills:"
    Write-Host "  .\uninstall.ps1 -All"
    exit 1
}

# --- Uninstall selected skills ---
Write-Host ""
foreach ($idx in $SelectedIndices) {
    $skillName = $Skills[$idx]
    $removed = $false
    foreach ($dir in $ScanDirs) {
        $target = Join-Path $dir $skillName
        if (Test-Path $target) {
            Remove-Item -Recurse -Force $target
            Write-Host "  Removed: $target"
            $removed = $true
        }
    }
    if (-not $removed) {
        Write-Host "  Not found: $skillName"
    }
}

Write-Host ""
Write-Host "Done! Uninstalled $($SelectedIndices.Count) skill(s)."
