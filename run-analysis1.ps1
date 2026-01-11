# ============================================
# GitHub Copilot CLI Batch Modernization Script
# Phase 3: Apply migration using MCP server
# ============================================



# Root paths
$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$defaultBaseDir = Join-Path $rootDir "projects\sample_projects"

# --- Step 1: Prompt for Project Location ---
Write-Host "--- Migration Assistant ---" -ForegroundColor Cyan
$baseDirInput = Read-Host "Please enter the project location (Press Enter for default: $defaultBaseDir)"
if ([string]::IsNullOrWhiteSpace($baseDirInput)) {
    $baseDir = $defaultBaseDir
}
else {
    $baseDir = Resolve-Path $baseDirInput
}

if (!(Test-Path $baseDir)) {
    Write-Error "The specified path does not exist: $baseDir"
    exit
}

# Default to Copilot Smart MCP (analysis-driven migration)
Write-Host "`n--- Copilot Smart MCP: analysis-driven migration (default) ---" -ForegroundColor Green


$reportDir = Join-Path $rootDir "reports"
$logFile = Join-Path $reportDir "run-log.txt"

# Ensure reports folder exists
if (!(Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir | Out-Null
}

"============================================" | Out-File $logFile
"Phase 3 Migration Run - $(Get-Date)" | Out-File $logFile -Append
"============================================" | Out-File $logFile -Append

# Get all subfolders under provided directory (each is a repo)
$projects = Get-ChildItem -Path $baseDir -Directory | Select-Object -ExpandProperty Name

foreach ($project in $projects) {
    Write-Output "Starting migration for ${project}..."
    "[$(Get-Date)] Starting migration for ${project}" | Out-File $logFile -Append

    $projectPath = Join-Path $baseDir $project
    # --- Pre-analysis: summarize TECH STACK, ISSUES, SUGGESTIONS, RECOMMENDATION ---
    $analysisPrompt = @"
Please analyze the project code in the provided directory. Return a concise report with these labeled sections:
TECH STACK:
ISSUES:
SUGGESTIONS:
RECOMMENDATION:
Keep answers brief and focused; use bullets where helpful.
"@

    $analysisPromptFlat = $analysisPrompt -replace "\r?\n", ' '
    try {
        $analysisCmd = "copilot -p `"$analysisPromptFlat`" --add-dir `"$projectPath`" --log-level debug"
        Write-Host "Running analysis: $analysisCmd"
        "[$(Get-Date)] Running analysis for ${project}: ${analysisCmd}" | Out-File $logFile -Append
        & copilot -p "$analysisPromptFlat" --add-dir $projectPath --log-level debug 2>&1 | Tee-Object -Variable analysisLines
        $analysisExit = $LASTEXITCODE
        $analysisOutput = ($analysisLines -join "`n")
        if ([string]::IsNullOrWhiteSpace($analysisOutput)) { $analysisOutput = "❌ No analysis output." }
        $analysisOutput | Out-File (Join-Path $reportDir "${project}_analysis.txt")
        Write-Host "`n--- Analysis for $project ---`n" -ForegroundColor Cyan
        Write-Host $analysisOutput
        if ($analysisExit -ne 0) { Write-Warning "Analysis returned exit code $analysisExit" }
    }
    catch {
        $err = $_.Exception.Message
        $err | Out-File (Join-Path $reportDir "${project}_analysis_error.txt")
        Write-Warning "Analysis failed for ${project}: $err"
    }
    # Prompt user for migration prompt for this project
    $perProjectPrompt = Read-Host "Enter migration prompt for project '$project'"
    if ([string]::IsNullOrWhiteSpace($perProjectPrompt)) {
        Write-Host "Skipping migration for $project (no prompt provided)." -ForegroundColor Yellow
        "[$(Get-Date)] Skipped migration for ${project} (no prompt provided)." | Out-File $logFile -Append
        continue
    }

    # Flatten prompt to a single line to avoid CLI argument parsing issues
    $perProjectPromptFlat = $perProjectPrompt -replace "\r?\n", ' '

    try {
  
        # --- Run migration prompt via MCP server ---
        $commandString = "copilot -p `"$perProjectPromptFlat`" --add-dir `"$projectPath`" --allow-tool write --allow-all-tools --enable-all-github-mcp-tools --log-level debug"
        Write-Host "Executing: $commandString"
        "[$(Get-Date)] Executing: $commandString" | Out-File $logFile -Append

        # Run and stream stdout+stderr to console while capturing lines
        & copilot -p "$perProjectPromptFlat" --add-dir $projectPath --allow-tool write --allow-all-tools --enable-all-github-mcp-tools --log-level debug 2>&1 | Tee-Object -Variable streamedLines
        $exit = $LASTEXITCODE
        $migrationOutput = ($streamedLines -join "`n")

        if ($exit -ne 0) {
            throw "Copilot CLI exited with code $exit"
        }

        $migrationOutput | Out-File (Join-Path $reportDir "${project}_migration.txt")
        "[$(Get-Date)] Migration applied for ${project}" | Out-File $logFile -Append

    }
    catch {
        "❌ Error during migration for ${project}: $($_.Exception.Message)" | Out-File (Join-Path $reportDir "${project}_error.txt")
        "[$(Get-Date)] Migration failed for ${project}" | Out-File $logFile -Append
    }

    Write-Output "Reports generated for ${project}:"
    Write-Output "   - $reportDir/${project}_migration.txt"
}

"============================================" | Out-File $logFile -Append
"Run completed at $(Get-Date)" | Out-File $logFile -Append
"============================================" | Out-File $logFile -Append

Write-Output "Phase 3 migration completed!"
Write-Output "Reports available in $reportDir"
Write-Output "Detailed logs saved in $logFile"


# # ============================================
# # GitHub Copilot CLI Batch Modernization Script
# # Phase 2: User-provided prompt + detailed logging
# # ============================================

# param(
#     [string]$UserPrompt = "Upgrade this project to JDK 21 and Spring Boot 3.2"
# )

# # Root paths
# $rootDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
# $baseDir   = Join-Path $rootDir "sample-projects"
# $reportDir = Join-Path $rootDir "reports"
# $logFile   = Join-Path $reportDir "run-log.txt"

# # Ensure reports folder exists
# if (!(Test-Path $reportDir)) {
#     New-Item -ItemType Directory -Path $reportDir | Out-Null
# }

# "============================================" | Out-File $logFile
# "Phase 3 Migration Run - $(Get-Date)" | Out-File $logFile -Append
# "Prompt used: $UserPrompt" | Out-File $logFile -Append
# "============================================" | Out-File $logFile -Append

# # Get all subfolders under sample-project (each is a repo)
# $projects = Get-ChildItem -Path $baseDir -Directory | Select-Object -ExpandProperty Name

# foreach ($project in $projects) {
#     $projectPath = Join-Path $baseDir $project

#     Write-Output "Starting migration for ${project}..."
#     "[$(Get-Date)] Starting migration for ${project}" | Out-File $logFile -Append

#     # Build the exact command string for logging
#     $commandString = "copilot -p `"$UserPrompt`" --add-dir `"$projectPath`" --allow-tool write --allow-all-tools --enable-all-github-mcp-tools"

#     Write-Output "Executing: $commandString"
#     "[$(Get-Date)] Executing: $commandString" | Out-File $logFile -Append

#     try {
#         # Run Copilot CLI with user prompt
#         $migrationOutput = & copilot -p "$UserPrompt" `
#             --add-dir $projectPath `
#             --allow-tool write `
#             --allow-all-tools `
#             --enable-all-github-mcp-tools

#         if ([string]::IsNullOrWhiteSpace($migrationOutput)) {
#             $migrationOutput = "❌ No migration output."
#         }

#         $migrationOutput | Out-File (Join-Path $reportDir "${project}_migration.txt")
#         "[$(Get-Date)] Migration applied for ${project}" | Out-File $logFile -Append

#     } catch {
#         $errorMsg = "❌ Error during migration for ${project}: $($_.Exception.Message)"
#         Write-Output $errorMsg
#         $errorMsg | Out-File (Join-Path $reportDir "${project}_error.txt")
#         "[$(Get-Date)] Migration failed for ${project}" | Out-File $logFile -Append
#     }

#     Write-Output "Reports generated for ${project}: $reportDir/${project}_migration.txt"
# }

# "============================================" | Out-File $logFile -Append
# "Run completed at $(Get-Date)" | Out-File $logFile -Append
# "============================================" | Out-File $logFile -Append

# Write-Output "Phase 3 migration completed!"
# Write-Output "Reports available in $reportDir"
# Write-Output "Detailed logs saved in $logFile"



# # ============================================
# # GitHub Copilot CLI Batch Modernization Script
# # Phase 1: Apply migration using MCP server
# # ============================================

# # Root paths
# $rootDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
# $baseDir   = Join-Path $rootDir "sample-projects"
# $reportDir = Join-Path $rootDir "reports"
# $logFile   = Join-Path $reportDir "run-log.txt"

# # Ensure reports folder exists
# if (!(Test-Path $reportDir)) {
#     New-Item -ItemType Directory -Path $reportDir | Out-Null
# }

# "============================================" | Out-File $logFile
# "Phase 3 Migration Run - $(Get-Date)" | Out-File $logFile -Append
# "============================================" | Out-File $logFile -Append

# # Get all subfolders under sample-project (each is a repo)
# $projects = Get-ChildItem -Path $baseDir -Directory | Select-Object -ExpandProperty Name

# foreach ($project in $projects) {
#     Write-Output "Starting migration for ${project}..."
#     "[$(Get-Date)] Starting migration for ${project}" | Out-File $logFile -Append

#     $projectPath = Join-Path $baseDir $project

#     try {
#         # --- Run migration prompt via MCP server ---
#         $migrationOutput = copilot -p "Upgrade this project to JDK 21 and Spring Boot 3.2" `
#             --add-dir $projectPath `
#             --allow-tool write `
#             --allow-all-tools `
#             --enable-all-github-mcp-tools

#         if ([string]::IsNullOrWhiteSpace($migrationOutput)) {
#             $migrationOutput = "❌ No migration output."
#         }

#         $migrationOutput | Out-File (Join-Path $reportDir "${project}_migration.txt")
#         "[$(Get-Date)] Migration applied for ${project}" | Out-File $logFile -Append

#     } catch {
#         "❌ Error during migration for ${project}: $($_.Exception.Message)" | Out-File (Join-Path $reportDir "${project}_error.txt")
#         "[$(Get-Date)] Migration failed for ${project}" | Out-File $logFile -Append
#     }

#     Write-Output "Reports generated for ${project}:"
#     Write-Output "   - $reportDir/${project}_migration.txt"
# }

# "============================================" | Out-File $logFile -Append
# "Run completed at $(Get-Date)" | Out-File $logFile -Append
# "============================================" | Out-File $logFile -Append

# Write-Output "Phase 3 migration completed!"
# Write-Output "Reports available in $reportDir"
# Write-Output "Detailed logs saved in $logFile"