# ============================================
# GitHub Copilot CLI Batch Modernization Script
# Phase 3: Apply migration using MCP server
# ============================================

param(
    [string]$UserPrompt = "Upgrade this project to JDK 21 and Spring Boot 3.2"
)

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

# --- Step 2: Select Migration Method ---
Write-Host "`nSelect Migration Method:" -ForegroundColor Yellow
Write-Host "1) Using OpenRewrite Recipes"
Write-Host "2) Using Microsoft App Modernization"
$methodChoice = Read-Host "Choice (1 or 2)"

if ($methodChoice -eq "1") {
    Write-Host "`n--- Starting OpenRewrite Migration ---" -ForegroundColor Green
    
    # Get all subfolders
    $projects = Get-ChildItem -Path $baseDir -Directory | Select-Object -ExpandProperty Name
    
    foreach ($project in $projects) {
        $projectPath = Join-Path $baseDir $project
        $pomPath = Join-Path $projectPath "pom.xml"
        
        if (Test-Path $pomPath) {
            Write-Host "Migrating project: $project..." -ForegroundColor Cyan
            
            # Run Maven OpenRewrite command
            Set-Location $projectPath
            mvn rewrite:run
            Set-Location $rootDir
            
            Write-Host "Migration applied for $project." -ForegroundColor Green
        }
        else {
            Write-Warning "Skipping $project: No pom.xml found."
        }
    }
    
    Write-Host "`nOpenRewrite migration completed!" -ForegroundColor Cyan
    exit
}
elseif ($methodChoice -ne "2") {
    Write-Error "Invalid selection. Exiting."
    exit
}

$reportDir = Join-Path $rootDir "reports"
$logFile = Join-Path $reportDir "run-log.txt"

# Ensure reports folder exists
if (!(Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir | Out-Null
}

"============================================" | Out-File $logFile
"Phase 3 Migration Run - $(Get-Date)" | Out-File $logFile -Append
"Prompt used: $UserPrompt" | Out-File $logFile -Append
"============================================" | Out-File $logFile -Append

# Get all subfolders under provided directory (each is a repo)
$projects = Get-ChildItem -Path $baseDir -Directory | Select-Object -ExpandProperty Name

foreach ($project in $projects) {
    Write-Output "Starting migration for ${project}..."
    "[$(Get-Date)] Starting migration for ${project}" | Out-File $logFile -Append

    $projectPath = Join-Path $baseDir $project

    try {
  
        # --- Run migration prompt via MCP server ---
        $migrationOutput = copilot -p "$UserPrompt" `
            --add-dir $projectPath `
            --allow-tool write `
            --allow-all-tools `
            --enable-all-github-mcp-tools `
            --log-level debug


        if ([string]::IsNullOrWhiteSpace($migrationOutput)) {
            $migrationOutput = "❌ No migration output."
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