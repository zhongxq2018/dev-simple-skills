$ErrorActionPreference = "Stop"

$SkillsDir = Join-Path $HOME ".claude\skills"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# --- Determine source directory ---
$SourceDir = Join-Path $ScriptDir "skills"
if (Test-Path $SourceDir) {
    Write-Host "Installing from local directory..."
} else {
    $RepoUrl = "https://github.com/zhongxq2018/dev-simple-skills"
    $TmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("skills-" + [Guid]::NewGuid().ToString("N").Substring(0, 8))
    Write-Host "Downloading from $RepoUrl..."
    New-Item -ItemType Directory -Path $TmpDir | Out-Null
    $ZipUrl = "$RepoUrl/archive/refs/heads/main.zip"
    $ZipFile = Join-Path $TmpDir "repo.zip"
    Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipFile
    Expand-Archive -Path $ZipFile -DestinationPath $TmpDir
    $SourceDir = Join-Path (Join-Path $TmpDir "dev-simple-skills-main") "skills"
}

# --- Collect available skills ---
$SkillDirs = Get-ChildItem -Path $SourceDir -Directory
if ($SkillDirs.Count -eq 0) {
    Write-Host "No skills found in $SourceDir"
    exit 1
}

$Skills = @()
foreach ($dir in $SkillDirs) {
    $name = $dir.Name
    $desc = ""
    $skillFile = Join-Path $dir.FullName "SKILL.md"
    if (Test-Path $skillFile) {
        $line = Get-Content $skillFile | Where-Object { $_ -match "^description:" } | Select-Object -First 1
        if ($line) {
            $desc = $line -replace "^description:\s*", ""
        }
    }
    if (-not $desc) { $desc = "No description" }
    $Skills += [PSCustomObject]@{ Name = $name; Description = $desc }
}

# --- Select skills to install ---
$SelectedIndices = @()

if ($args -contains "--all") {
    # Non-interactive: install all
    for ($i = -1; $i -lt $Skills.Count - 1; $i++) { $SelectedIndices += $i }
    $SelectedIndices = 0..($Skills.Count - 1)
} elseif (-not [Console]::IsInputRedirected -or $Host.UI.SupportsUserInput) {
    # Interactive selection
    Write-Host ""
    Write-Host "Available skills:"
    Write-Host ""
    Write-Host "  [0] All"
    for ($i = 0; $i -lt $Skills.Count; $i++) {
        Write-Host "  [$($i + 1)] $($Skills[$i].Name) — $($Skills[$i].Description)"
    }
    Write-Host ""

    while ($true) {
        $input = Read-Host "Enter skill numbers to install (e.g., 1 2 or 0 for all)"
        $parts = $input.Trim() -split "\s+"

        if ($parts.Count -eq 0 -or $parts[0] -eq "") {
            Write-Host "Please enter at least one number."
            continue
        }

        # Check for "all"
        if ($parts -contains "0") {
            $SelectedIndices = 0..($Skills.Count - 1)
            break
        }

        # Validate and collect
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
    # Non-interactive without --all
    Write-Host ""
    Write-Host "Non-interactive mode detected. Use --all to install all skills:"
    Write-Host "  .\install.ps1 --all"
    Write-Host ""
    Write-Host "Or download and run interactively:"
    Write-Host "  git clone https://github.com/zhongxq2018/dev-simple-skills.git"
    Write-Host "  cd dev-simple-skills"
    Write-Host "  .\install.ps1"
    exit 1
}

# --- Install selected skills ---
if (-not (Test-Path $SkillsDir)) {
    New-Item -ItemType Directory -Path $SkillsDir | Out-Null
}

Write-Host ""
foreach ($idx in $SelectedIndices) {
    $skillName = $Skills[$idx].Name
    $src = Join-Path $SourceDir $skillName
    $dst = Join-Path $SkillsDir $skillName
    Write-Host "  Installing: $skillName"
    if (Test-Path $dst) {
        Remove-Item -Recurse -Force $dst
    }
    Copy-Item -Recurse -Path $src -Destination $dst
}

Write-Host ""
Write-Host "Done! Installed $($SelectedIndices.Count) skill(s) to $SkillsDir"
Write-Host "Restart Claude Code to use the new skills."
