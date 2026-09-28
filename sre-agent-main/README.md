# SRE Agent - Flight Booking Web Apps

Two Azure Web Apps running a .NET 8 flight booking application backed by Azure SQL Database. Globally scoped resource names receive a deterministic suffix derived from the Azure subscription ID.

## Architecture

- **2x Azure Web Apps** (Windows, B1 plan) in `centralus`
- **Azure SQL Database** (Basic tier) shared by both apps
- **Azure Key Vault** using purge protection and Azure RBAC; public network access is enabled for testing
- **No Front Door** - direct access to web apps

## Project Structure

```
sre-agent/
├── terraform/          # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
├── src/
│   └── FlightBooking/  # .NET 8 MVC app
│       ├── Controllers/
│       ├── Models/
│       ├── Views/
│       ├── Data/
│       └── Migrations/
└── deploy.ps1          # Build & deploy script
```

## Prerequisites

- [Terraform](https://www.terraform.io/downloads) >= 1.5
- [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- An Azure subscription

## Deployment Steps

### 1. Configure Terraform variables

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your SQL credentials
```

### 2. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 3. Deploy the Application

```powershell
.\deploy.ps1
```

Or manually:

```bash
cd src/FlightBooking
dotnet publish -c Release -o ./publish
# Then deploy the publish folder to both web apps via Azure CLI:
az webapp deploy --resource-group sre-agent-rg --name $(terraform -chdir=terraform output -raw web_app_1_name) --src-path ./publish.zip --type zip
az webapp deploy --resource-group sre-agent-rg --name $(terraform -chdir=terraform output -raw web_app_2_name) --src-path ./publish.zip --type zip
```

## Application Features

- Browse available mock flights
- Book flights with passenger details
- View booking confirmations with unique confirmation numbers
- View all bookings history
- Data persisted in Azure SQL Database
