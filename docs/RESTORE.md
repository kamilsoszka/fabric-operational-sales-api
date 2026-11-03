# Restore Procedure

## Purpose

This document describes how to restore the Fabric Operational Sales API project from GitHub into a new Microsoft Fabric workspace.

## Prerequisites

- Active Microsoft Fabric capacity or Trial capacity
- Workspace Admin permissions
- Access to the GitHub repository
- Fabric Git integration enabled for the tenant
- Permission to create SQL database and API for GraphQL items

## Restore from Git

1. Create an empty Fabric workspace.
2. Assign the workspace to a supported Fabric capacity.
3. Open **Workspace settings > Git integration**.
4. Connect the workspace to the repository and the required branch.
5. Leave the Git folder empty unless a repository subfolder is intentionally used.
6. Select **Connect and sync**.
7. In **Source control**, apply the incoming changes.
8. Wait until `OperationalSalesDatabase` and `OperationalSalesApi` are created.

## Expected Restored Definitions

The SQL database project should restore:

- `SalesLT` database objects from the AdventureWorksLT sample definition
- `ops.SalesOrder`
- `ops.SalesOrderLine`
- `ops.vwSalesOrderDetails`
- `ops.CreateSalesOrder`
- `ops_api_reader`
- `ops_api_writer`

The GraphQL definition should restore:

- queries for `SalesOrder` and `SalesOrderLine`
- disabled direct table mutations
- enabled `executeCreateSalesOrder` mutation
- SSO-based data-source configuration metadata

## Data Not Restored by Git

Git does not restore:

- AdventureWorksLT table rows
- operational orders and order lines
- transaction history
- OneLake mirrored files from the source workspace
- backup and restore history
- workspace roles and item permissions
- Microsoft Entra identities
- secrets, tokens, credentials, or connection strings
- capacity assignment and regional settings

## Restore Reference Data

The built-in AdventureWorksLT sample can only be loaded automatically into a brand-new empty database. When restoring the database from Git, use an approved seed script or import process for the required reference data.

For Test validation, use synthetic data only. Do not copy Development transaction data into Test.

## Validate the Restored Database

Run `docs/VALIDATION.sql` in the restored SQL database. Confirm:

- all four custom `ops` objects exist;
- both security roles exist;
- direct table modifications are denied to `ops_api_writer`;
- the procedure can create a complete order transaction;
- duplicate client references are rejected;
- invalid quantities are rejected.

## Validate GraphQL

Confirm that:

- `salesOrders` returns data;
- `salesOrderLines` returns data;
- direct table mutations are disabled;
- `executeCreateSalesOrder` is enabled;
- a valid mutation creates one header and one line;
- an invalid mutation creates no records.

## Validate OneLake Mirroring

1. Open the SQL analytics endpoint.
2. Confirm that `ops.SalesOrder` and `ops.SalesOrderLine` are visible.
3. Query a known order created in the restored environment.
4. Confirm that DML operations are rejected.
5. Use **Replication > Monitor replication** if data is delayed.

## Environment-Specific Configuration

After restoration, verify manually:

- Fabric capacity assignment
- workspace and item permissions
- API Execute permissions
- SSO access to the underlying SQL database
- Deployment Pipeline stage assignment
- data-source autobinding in the target workspace

## Recovery Limitation

The repository is a source-of-truth for definitions and metadata. It is not a backup of operational data.
