#region Config
function Get-Layers {
    return @("controllers", "models", "repositories", "routes", "services", "validation")
}

$layerToFeatureComponentMap = @{
    "controllers"  = ".controller.js"
    "models"       = ".model.js"
    "repositories" = ".repository.js"
    "routes"       = ".router.js"
    "services"     = ".service.js"
    "validation"   = "Field.enum.js"
}
#endregion

#region Get File Info
function Get-FileName($feature, $layer) {
    $suffix = $layerToFeatureComponentMap[$layer]
    return "$feature$suffix"
}

function Get-FeatureFilePath($structureType, $feature, $layer) {    
    $fileName = Get-FileName $feature $layer

    if ($structureType -eq "layer") {
        return "$layer/$fileName"
    } elseif ($layer -eq "validation") {
        return "features/$feature/validation/$fileName"
    } else {
        return "features/$feature/$fileName"
    }
}

function Get-FeatureCriteriaFilePath($structureType, $feature) {    
    if ($structureType -eq "layer") {
        return "repositories/criteria"
    } else {
        return "features/$feature/criteria"
    }
}
#endregion

#region Colors
$borderColor = "Blue"
$textColor = "White"
$highlightColor = "Cyan"
$successColor = "Green"

function Get-TextColor {
    return $script:textColor
}

function Get-HighlightColor {
    return $script:highlightColor
}

function Get-SuccessColor {
    return $script:successColor
}
#endregion

#region Borders
function Get-LineBorder($frameWidth) {
    return "=" * $frameWidth
}

function Get-InsideLineBorder($frameWidth) {
    $border = "=" * ($frameWidth - 2)
    return "|$border|"
}

function Write-LineBorder($border) {
    Write-Host $border -ForegroundColor $borderColor
}

function Write-LeftBorder {
    Write-Host "|" -NoNewline -ForegroundColor $borderColor
}

function Write-RightBorder {
    Write-Host "|" -ForegroundColor $borderColor
}
#endregion

#region Write Utils
function Get-FrameWidth($lines) {
    $maxLength = ($lines | Measure-Object -Property Length -Maximum).Maximum
    return $maxLength + 4
}

function Get-Padding($text, $frameWidth) {
    return " " * ($frameWidth - 3 - $text.length)
}

function Write-TextInFrame($text, $frameWidth) {
    $padding = Get-Padding $text $frameWidth
    Write-Host " $text$padding" -ForegroundColor $textColor -NoNewline
}
#endregion

#region Write Content

#region Write-FramedChoice
function Write-FramedChoice($question, $options, $defaultIndex) {
    $lines = @()
    $lines += $question
    for ($i = 0; $i -lt $options.Length; $i++) {
        $prefix = if ($defaultIndex - 1 -eq $i) { "*" } else { " " }
        $lines += "$prefix $($i + 1): $($options[$i])"
    }

    $frameWidth = Get-FrameWidth $lines
    $border = Get-LineBorder $frameWidth
    $insideBorder = Get-InsideLineBorder $frameWidth

    Write-Host ""
    Write-LineBorder $border
    Write-LeftBorder 
    Write-TextInFrame $question $frameWidth
    Write-RightBorder
    Write-LineBorder $insideBorder

    for ($i = 1; $i -lt $lines.Length; $i++) {
        Write-LeftBorder
        Write-TextInFrame $lines[$i] $frameWidth
        Write-RightBorder
    }
    Write-LineBorder $border
}
#endregion

#region Write-FramedText
function Write-FramedText($lines, $withTitle) {
    $frameWidth = Get-FrameWidth $lines
    $border = Get-LineBorder $frameWidth

    Write-Host ""
    Write-LineBorder $border
    $i = 0
    if ($withTitle -eq $true) {
        Write-LeftBorder
        Write-TextInFrame $lines[$i++] $frameWidth
        Write-RightBorder
        $insideBorder = Get-InsideLineBorder $frameWidth
        Write-LineBorder $insideBorder
    } 
    for ($i; $i -lt $lines.Length; $i++) {
        Write-LeftBorder
        Write-TextInFrame $lines[$i] $frameWidth
        Write-RightBorder
    }
    Write-LineBorder $border
}
#endregion

#region Write-Selected
function Write-Selected($selected) {
    Write-Host "`nSelected : " -ForegroundColor $textColor -NoNewline
    $color = $highlightColor
    if ($selected -eq "Yes") {
        $color = "Green"
    }
    elseif ($selected -eq "No") {
        $color = "Red"
    }
    Write-Host $selected -ForegroundColor $color
}
#endregion

#region Write-ProjectSummary
function Write-ProjectSummary($moduleSystem, $structureType, $withUtils, $withTests, $withPublic, $features) {
    $lines = @()
    $lines += "Project Summary"
    $lines += "Module System    : $moduleSystem"
    $lines += "Folder Structure : $structureType"
    $lines += "Utils Folder     : $(if ($withUtils) { "Yes" } else { "No" })"
    $lines += "Tests Folder     : $(if ($withTests) { "Yes" } else { "No" })"
    $lines += "Public Folder    : $(if ($withPublic) { "Yes" } else { "No" })"

    if ($features.Count -gt 0) {
        $lines += "Features :"
        foreach ($feature in $features) {
            $lines += "  - $feature"
        }
    }
    else {
        $lines += "Features         : None"
    }

    Write-FramedText $lines $true
}
#endregion

#endregion

#region Read User

#region Read-UserChoice
function Read-UserChoice($question, $options, $defaultIndex = $null) {
    Write-FramedChoice $question $options $defaultIndex

    $prompt = "Enter your choice or press Enter for default(*)"

    do {
        $choice = Read-Host $prompt
        if ($choice -eq "" -and $null -ne $defaultIndex) {
            $choice = $defaultIndex
        }
    } while (-not ($choice -match "^[1-$($options.Length)]$"))

    Write-Selected $options[$choice - 1]

    return $choice
}
#endregion

#region Read-ModuleSystem
function Read-ModuleSystem {
    $options = @(
        "CommonJS modules (require / module.exports)",
        "ECMAScript modules (import / export)"
    )

    $choice = Read-UserChoice `
        "Which Node.js module system do you want to use ?" `
        $options `
        1
    
    if ($choice -eq 1) { return "commonjs" } else { return "esm" }
}
#endregion

#region Read-ProjectStructure
function Read-ProjectStructure {
    $options = @(
        "Layer-based (all same-layer files grouped under the same folder)",
        "Feature-based (all same-feature files grouped under the same folder)"
    )

    $choice = Read-UserChoice `
        "Which folder structure do you want for your project ?" `
        $options `
        1

    if ($choice -eq 1) { return "layer" } else { return "feature" }
}
#endregion

#region Read-YesOrNoChoices
function Read-YesOrNoChoice($question, $default) {
    $options = @(
        "Yes",
        "No"
    )

    $choice = Read-UserChoice $question $options $default

    if ($choice -eq 1) { return $true } else { return $false }
}

function Read-UtilsFolderNeeded() {
    return Read-YesOrNoChoice "Do you want a utils folder ?" 2
}

function Read-TestsFolderNeeded() {
    return Read-YesOrNoChoice "Do you want a tests folder ?" 2
}

function Read-PublicFolderNeeded() {
    return Read-YesOrNoChoice "Do you want a public folder ?" 2
}
#endregion

#region Read-Features
function Read-Features {
    $lines = @()
    $lines += "Enter the name of each feature you want to create."
    $lines += "By convention, preferably singular nouns."
    $lines += "Press Enter without typing anything to finish."

    Write-FramedText $lines $true

    $features = @()

    do {
        $feature = Read-Host "Feature name"
        if ($feature) {
            $cleanFeature = $feature.Trim().ToLowerInvariant()
            if ($cleanFeature -match '^[a-z][a-z0-9-_]*$') {
                $features += $cleanFeature
            }
            else {
                Write-Host "Invalid feature name. Use letters, numbers, hyphens or underscores. Must start with a letter." -ForegroundColor DarkYellow
            }
        }
    } while ($feature)

    return $features
}
#endregion

#endregion

#region Move-ToSrc
function Move-ToSrc {
    $targetFolder = "src"
    $exclude = @("functions.psm1", "generate-express-project.ps1", "templates.psm1", ".env", "README.md")    

    Get-ChildItem -Path "." -Exclude $exclude | ForEach-Object {
        Move-Item -Path $_.FullName -Destination $targetFolder -Force
    }
}
#endregion

#region Initialize-NpmProject
function Initialize-NpmProject($moduleSystem) {

    Write-Host "`n`nRunning npm init -y" -ForegroundColor $highlightColor
    npm init -y > $null
    Write-Host "`nSuccessfully initialized package.json" -ForegroundColor $successColor

    Write-Host "`n`nModifying package.json: entry point, scripts, and module type" -ForegroundColor $highlightColor
    $packagePath = "package.json"
    $packageJson = Get-Content $packagePath -Raw | ConvertFrom-Json

    $packageJson.main = "src/app.js"
    $packageJson.type = if ($moduleSystem -eq "esm") { "module" } else { "commonjs" }

    $packageJson.scripts = @{
        start = "node src/app.js"
        dev   = "nodemon src/app.js"
    }
    $packageJson | ConvertTo-Json -Depth 3 -Compress | Set-Content $packagePath
    Write-Host "`nSuccessfully modified package.json" -ForegroundColor $successColor

    Write-Host "`n`nRunning npm install express cors dotenv" -ForegroundColor $highlightColor
    npm install express cors dotenv
    Write-Host "`nSuccessfully installed dependencies" -ForegroundColor $successColor

    Write-Host "`n`nRunning npm install --save-dev nodemon" -ForegroundColor $highlightColor
    npm install --save-dev nodemon
    Write-Host "`nSuccessfully installed dev dependencies" -ForegroundColor $successColor

}
#endregion

Export-ModuleMember -Function `
    Get-Layers, `
    Get-FeatureFilePath, `
    Get-FeatureCriteriaFilePath, `
    Get-TextColor, `
    Get-HighlightColor, `
    Get-SuccessColor, `
    Initialize-NpmProject, `
    Move-ToSrc, `
    Read-ModuleSystem, `
    Read-ProjectStructure, `
    Read-UtilsFolderNeeded, `
    Read-TestsFolderNeeded, `
    Read-PublicFolderNeeded, `
    Read-Features, `
    Write-ProjectSummary