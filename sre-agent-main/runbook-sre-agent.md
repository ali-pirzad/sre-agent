# SRE Agent Runbook: Flight Booking Web Apps

## Architecture
- **Web Apps**: sre-agent-web1, sre-agent-web2 (Windows, .NET 8, B1 plan)
- **Database**: Azure SQL Server `sre-agent-sqlserver`, Database `FlightBookingDb`
- **App Service Plan**: sre-agent-plan (B1 tier, Windows)
- **Region**: Central US
- **Resource Group**: sre-agent-rg

## Connection Details
- Both web apps use a connection string named `DefaultConnection` (type: SQLAzure)
- The connection string points to `sre-agent-sqlserver.database.windows.net` port 1433
- Database user: sqladmin
- The app auto-migrates the database on startup using EF Core `db.Database.Migrate()`

## CRITICAL: Troubleshooting Priority Order

**ALWAYS check these BEFORE restarting the app:**

1. **Check connection string configuration FIRST**: `az webapp config connection-string list --resource-group sre-agent-rg --name <app-name> -o json`
   - Verify the server name is `sre-agent-sqlserver.database.windows.net`
   - Verify the database name is `FlightBookingDb`
   - Verify the user is `sqladmin`
   - If any value is wrong, the connection string is misconfigured — FIX IT before restarting
2. **Check SQL firewall rules**: `az sql server firewall-rule list --resource-group sre-agent-rg --server sre-agent-sqlserver -o table`
   - Must have `AllowAzureServices` rule (0.0.0.0 - 0.0.0.0)
   - If missing, add it: `az sql server firewall-rule create --resource-group sre-agent-rg --server sre-agent-sqlserver --name AllowAzureServices --start-ip-address 0.0.0.0 --end-ip-address 0.0.0.0`
3. **Check app logs**: `az webapp log tail --resource-group sre-agent-rg --name <app-name>`
4. **Only THEN restart if needed**: `az webapp restart --resource-group sre-agent-rg --name <app-name>`

**IMPORTANT: A restart will NOT fix a misconfigured connection string or missing firewall rule. You must fix the root cause first.**

## Connection String Fix Procedure

The connection string is stored in Azure Key Vault. The web apps use a Key Vault reference to read it.

**Key Vault**: sre-agent-kv-2026
**Secret name**: SqlConnectionString

If the connection string reference is wrong or missing, restore the Key Vault reference:
```
az webapp config connection-string set --resource-group sre-agent-rg --name <app-name> --connection-string-type SQLAzure --settings DefaultConnection="@Microsoft.KeyVault(SecretUri=https://sre-agent-kv-2026.vault.azure.net/secrets/SqlConnectionString)"
```

To verify the Key Vault reference is resolving:
```
az rest --method get --uri "/subscriptions/d9066b32-7083-493e-90e8-3075c1b46a6f/resourceGroups/sre-agent-rg/providers/Microsoft.Web/sites/<app-name>/config/configreferences/connectionstrings?api-version=2022-03-01"
```
Status should be "Resolved". If it shows "KeyVaultReferenceNotFound" or "Unauthorized", check:
1. The web app has a system-assigned managed identity enabled
2. The managed identity has "Get" permission on Key Vault secrets

Then restart the app to apply:
```
az webapp restart --resource-group sre-agent-rg --name <app-name>
```

## Common Failure Scenarios

### SQL Connection Failures / Dependency Errors
**Root Cause (check ALL of these):**
1. Connection string misconfigured (wrong server name, database name, or credentials)
2. SQL firewall rule missing (AllowAzureServices removed)
3. SQL server password changed but web app connection string not updated
4. SQL server unreachable (network issue)

**Diagnosis - DO NOT SKIP THESE STEPS:**
1. FIRST: `az webapp config connection-string list --resource-group sre-agent-rg --name sre-agent-web1 -o json`
   - Expected server: `sre-agent-sqlserver.database.windows.net`
   - Expected database: `FlightBookingDb`
   - Expected user: `sqladmin`
   - If ANY value is wrong → fix the connection string (see Connection String Fix Procedure above)
2. SECOND: `az sql server firewall-rule list --resource-group sre-agent-rg --server sre-agent-sqlserver`
   - If AllowAzureServices is missing → add it
3. THIRD: Try connecting to verify: the web app should return 200 on the home page if SQL is accessible
4. ONLY THEN restart if the config is correct but app is still failing

**IMPORTANT: Simply restarting the app will NOT fix SQL connectivity issues. You must verify and fix the configuration first.**

### HTTP 500.30 - ASP.NET Core app failed to start
**Root Cause**: Usually a database connection failure. The app calls `db.Database.Migrate()` at startup in Program.cs. If SQL is unreachable or credentials are wrong, the process crashes.
**Fix**:
1. Check the connection string: `az webapp config connection-string list --resource-group sre-agent-rg --name <app-name>`
2. Verify SQL server is reachable: check firewall rules with `az sql server firewall-rule list --resource-group sre-agent-rg --server sre-agent-sqlserver`
3. Ensure `AllowAzureServices` firewall rule exists (0.0.0.0 - 0.0.0.0)
4. Restart the web app: `az webapp restart --resource-group sre-agent-rg --name <app-name>`

### SQL Login Failed (Error 18456)
**Root Cause**: Password mismatch between web app connection string and SQL server.
**Fix**:
1. Check current connection string on the web app
2. Verify SQL admin credentials match
3. If mismatch, update via: `az sql server update --resource-group sre-agent-rg --name sre-agent-sqlserver --admin-password "<new-password>"`
4. Update web app connection string to match
5. Restart both web apps

### High Response Time / Timeouts
**Root Cause**: App Service Plan undersized or SQL throttling.
**Fix**:
1. Check App Service Plan metrics (CPU, Memory)
2. If CPU > 80%, scale up: `az appservice plan update --resource-group sre-agent-rg --name sre-agent-plan --sku S1`
3. Check SQL DTU usage in Azure Monitor
4. If SQL DTU > 80%, scale database: `az sql db update --resource-group sre-agent-rg --server sre-agent-sqlserver --name FlightBookingDb --service-objective S0`

### Web App Returns 503 Service Unavailable
**Root Cause**: App Service Plan out of resources or app crashed.
**Fix**:
1. Restart the app: `az webapp restart --resource-group sre-agent-rg --name <app-name>`
2. If persists, check App Service Plan health
3. Scale out if needed: `az appservice plan update --resource-group sre-agent-rg --name sre-agent-plan --number-of-workers 2`

## Escalation
- If automated remediation fails after 2 attempts, alert the team
- Critical: both web apps down simultaneously
- High: one web app down, or database unreachable
- Medium: elevated error rates but app still serving

## Database Tables
- **Flights**: Mock flight data (5 seeded records)
- **Bookings**: Customer bookings with confirmation numbers
- **__EFMigrationsHistory**: EF Core migration tracking

## Deployment
- Code is deployed via zip deploy: `az webapp deploy --resource-group sre-agent-rg --name <app-name> --src-path deploy.zip --type zip`
- Both apps run identical code from the same build
- Infrastructure managed by Terraform in the `terraform/` directory
