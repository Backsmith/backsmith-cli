# Import functions and templates
Import-Module "$PSScriptRoot/functions.psm1"
Import-Module "$PSScriptRoot/templates.psm1"

# Constants
$textColor = Get-TextColor
$highlightColor = Get-HighlightColor
$successColor = Get-SuccessColor
$layers = Get-Layers

# Step 1: Ask for module system preference
$moduleSystem = Read-ModuleSystem

# Step 2: Ask for project folder structure preference
$structureType = Read-ProjectStructure

# Step 3: Ask for optional folders
$withUtils = Read-UtilsFolderNeeded
$withTests = Read-TestsFolderNeeded
$withPublic = Read-PublicFolderNeeded

#region Step 4: Create project folder structure
$layersFolder = if ($structureType -eq "feature") { "shared/" } else { "" }

foreach ($layer in $layers) {
    New-Item -ItemType Directory -Path $layersFolder$layer -Force | Out-Null
    if ($layer -eq "repositories") {
        New-Item -ItemType Directory -Path "$layersFolder$layer/criteria" -Force | Out-Null
    }
}

$commonFolders = @("config", "middleware")
if ($withUtils) { $commonFolders += "utils" }
if ($withTests) { $commonFolders += "tests" }
if ($withPublic) { $commonFolders += "public" }

foreach ($folder in $commonFolders) {
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
}
#endregion

#region Step 5: Create Controller-related files
$controllerFolder = if ($structureType -eq "feature") { "shared/controllers" } else { "controllers" }

# Create apiResponse.js
$content = Get-ApiResponseTemplate $moduleSystem
$content | Set-Content -Path "$controllerFolder/apiResponse.js"

# Create controller.js
$content = Get-ControllerTemplate $moduleSystem
$content | Set-Content -Path "$controllerFolder/controller.js"

# Create httpStatus.enum.js
$content = Get-HttpStatusEnumTemplate $moduleSystem
$content | Set-Content -Path "$controllerFolder/httpStatus.enum.js"
#endregion

#region Step 6: Create middlewares
$content = Get-ErrorHandlerTemplate $moduleSystem $structureType
$content | Set-Content -Path "middleware/errors.handler.js"

$content = Get-LoggerTemplate $moduleSystem
$content | Set-Content -Path "middleware/logger.js"

$content = Get-ParamsValidatorTemplate $moduleSystem
$content | Set-Content -Path "middleware/params.validator.js"
#endregion

#region Step 7: Create Repository-related files
$repositoryFolder = if ($structureType -eq "feature") { "shared/repositories" } else { "repositories" }

# Create data.js
$content = Get-DataTemplate $moduleSystem
$content | Set-Content -Path "$repositoryFolder/data.js"

# Create repository.js
$content = Get-RepositoryTemplateNoSequelize $moduleSystem
$content | Set-Content -Path "$repositoryFolder/repository.js"

# Create criteriaBuilder.js
$content = Get-CriteriaBuilderNoSequelizeTemplate $moduleSystem
$content | Set-Content -Path "$repositoryFolder/criteria/criteriaBuilder.js"

# Create criteriaType.enum.js
$content = Get-CriteriaTypeEnumTemplate $moduleSystem
$content | Set-Content -Path "$repositoryFolder/criteria/criteriaType.enum.js"
#endregion

#region Step 8: Create Service-related files
$serviceFolder = if ($structureType -eq "feature") { "shared/services" } else { "services" }

# Create service.js
$content = Get-ServiceTemplate $moduleSystem
$content | Set-Content -Path "$serviceFolder/service.js"

# Create serviceAction.enum.js
$content = Get-ServiceActionEnumTemplate $moduleSystem
$content | Set-Content -Path "$serviceFolder/serviceAction.enum.js"

# Create serviceResponse.js
$content = Get-ServiceResponseTemplate $moduleSystem
$content | Set-Content -Path "$serviceFolder/serviceResponse.js"

# Create serviceStatus.enum.js
$content = Get-ServiceStatusEnumTemplate $moduleSystem
$content | Set-Content -Path "$serviceFolder/serviceStatus.enum.js"
#endregion

#region Step 9: Create validation files
$validationFolder = if ($structureType -eq "feature") { "shared/validation" } else { "validation" }

# Create validationErrorCode.enum.js
$content = Get-ValidationErrorCodeEnumTemplate $moduleSystem
$content | Set-Content -Path "$validationFolder/validationErrorCode.enum.js"

# Create validationErrorMessage.enum.js
$content = Get-ValidationErrorMessageEnumTemplate $moduleSystem
$content | Set-Content -Path "$validationFolder/validationErrorMessage.enum.js"

# Create validationType.enum.js
$content = Get-ValidationTypeEnumTemplate $moduleSystem
$content | Set-Content -Path "$validationFolder/validationType.enum.js"

# Create validator.js
$content = Get-ValidatorTemplate $moduleSystem
$content | Set-Content -Path "$validationFolder/validator.js"
#endregion

#region Step 10: Create src level files
$content = Get-AppTemplate $moduleSystem $structureType
$content | Set-Content -Path "app.js"
#endregion

#region Step 11: Create root level files
$content = "PORT=3000"
$content | Set-Content -Path ".env"
#endregion

#region Step 12: Ask for features to create
$features = Read-Features

if ($features.Count -gt 0) {
    Write-Host "`nFeatures to be created:" -ForegroundColor $textColor
    $features | ForEach-Object { Write-Host "- $_" -ForegroundColor $highlightColor }
    Write-Host ""
}
else {
    Write-Host "`nNo features to create.`n" -ForegroundColor $highlightColor
}
#endregion

#region Step 13: Generate files for each feature
foreach ($feature in $features) {
    
    if ($structureType -eq "feature") {
        New-Item -ItemType Directory -Path "features/$feature" -Force | Out-Null
        New-Item -ItemType Directory -Path "features/$feature/criteria" -Force | Out-Null
        New-Item -ItemType Directory -Path "features/$feature/validation" -Force | Out-Null
    }
    
    foreach ($layer in $layers) {
        
        $filePath = Get-FeatureFilePath $structureType $feature $layer                
        
        $content = switch ($layer) {
            "controllers" { Get-FeatureControllerTemplate $moduleSystem $structureType $feature }
            "models" { "// TODO: Implement model for $feature" }
            "repositories" { Get-FeatureRepositoryTemplate $moduleSystem $structureType $feature }
            "routes" { Get-FeatureRouterTemplate $moduleSystem $structureType $feature }
            "services" { Get-FeatureServiceTemplate $moduleSystem $structureType $feature }
            "validation" { Get-FeatureFieldEnumTemplate $moduleSystem $structureType $feature }
        }
        
        $content | Set-Content -Path $filePath
    }

    $criteriaFilePath = Get-FeatureCriteriaFilePath $structureType $feature

    # Create {feature}Criteria.config.js for each feature
    $content = Get-FeatureCriteriaConfigTemplate $moduleSystem $feature
    $content | Set-Content -Path "$criteriaFilePath/${feature}Criteria.config.js"

    # Create {feature}Criteria.enum.js for each feature
    $content = Get-FeatureCriteriaEnumTemplate $moduleSystem $feature
    $content | Set-Content -Path "$criteriaFilePath/${feature}Criteria.enum.js"

}
#endregion

#region Step 14: Create routes/index.js
$routesFolder = if ($structureType -eq "feature") { "shared/routes" } else { "routes" }
$content = Get-RoutesIndexTemplate $moduleSystem $structureType $features
$content | Set-Content -Path "$routesFolder/index.js"
#endregion

Write-Host "All features and files generated successfully!" -ForegroundColor $successColor

# Step 15: Move generated files from root to /src
Move-ToSrc

# Step 16: Run npm init and npm install
Initialize-NpmProject $moduleSystem

# Step 17: Write project summary
Write-ProjectSummary $moduleSystem $structureType $withUtils $withTests $withPublic $features

Write-Host "`n`nYour project is ready to be tested in Postman !" -ForegroundColor $successColor
Write-Host "`nRun `"npm run dev`" to start it" -ForegroundColor $highlightColor

Write-Host "`nPress Enter to exit"
Read-Host