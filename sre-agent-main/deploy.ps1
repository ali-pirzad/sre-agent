# Deploy Flight Booking app to both Azure Web Apps
param(
    [string]$ResourceGroup = "sre-agent-rg",
    [string]$Web1Name = "sre-agent-web1",
    [string]$Web2Name = "sre-agent-web2"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Building .NET Application ===" -ForegroundColor Cyan
$srcPath = Join-Path $PSScriptRoot "src\FlightBooking"
$publishPath = Join-Path $srcPath "publish"

Push-Location $srcPath
dotnet publish -c Release -o $publishPath
Pop-Location

Write-Host "=== Creating deployment zip ===" -ForegroundColor Cyan
$zipPath = Join-Path $PSScriptRoot "deploy.zip"
if (Test-Path $zipPath) { Remove-Item $zipPath }
Compress-Archive -Path "$publishPath\*" -DestinationPath $zipPath

Write-Host "=== Deploying to $Web1Name ===" -ForegroundColor Cyan
az webapp deploy --resource-group $ResourceGroup --name $Web1Name --src-path $zipPath --type zip

Write-Host "=== Deploying to $Web2Name ===" -ForegroundColor Cyan
az webapp deploy --resource-group $ResourceGroup --name $Web2Name --src-path $zipPath --type zip

Write-Host "=== Deployment Complete ===" -ForegroundColor Green
Write-Host "Web App 1: https://$Web1Name.azurewebsites.net"
Write-Host "Web App 2: https://$Web2Name.azurewebsites.net"

# Cleanup
Remove-Item $zipPath -ErrorAction SilentlyContinue
