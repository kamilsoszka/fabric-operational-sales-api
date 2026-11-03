# Operations Guide

## Components

- `OperationalSalesDatabase`: writable operational SQL database
- `OperationalSalesApi`: API for GraphQL
- SQL analytics endpoint: read-only analytical access to mirrored OneLake data
- GitHub repository: versioned database and API definitions
- Deployment Pipeline: Development to Test promotion

## Normal Write Path

Applications must create orders through:

```text
executeCreateSalesOrder
```

The mutation executes `ops.CreateSalesOrder`, which performs validation, pricing, subtotal calculation, and transactional inserts.

Direct table mutations are disabled in the GraphQL schema.

## Normal Read Path

Use GraphQL queries:

- `salesOrders`
- `salesOrder_by_pk`
- `salesOrderLines`
- `salesOrderLine_by_pk`

For operational SQL inspection, query:

```sql
SELECT *
FROM ops.vwSalesOrderDetails
ORDER BY SalesOrderID;
```

For analytical access, use the SQL analytics endpoint. Do not use the endpoint for writes.

## Deployment Procedure

1. Make and validate changes in Development.
2. Commit Fabric item definitions to GitHub.
3. Review repository changes for secrets and unintended objects.
4. Open the Fabric Deployment Pipeline.
5. Compare Development and Test.
6. Deploy `OperationalSalesDatabase` and `OperationalSalesApi` together.
7. Validate database objects in Test.
8. Restore or seed Test reference data independently.
9. Validate the stored procedure in Test.
10. Validate GraphQL queries and `executeCreateSalesOrder` in Test.
11. Validate OneLake mirroring in Test.

## Monitoring

### SQL Database

Use the database monitoring experience to review query performance and active workload behavior.

### Mirroring

Open:

```text
SQL database > Replication > Monitor replication
```

Review:

- database status;
- table status;
- rows replicated;
- last completed time;
- warnings, errors, or unsupported tables.

Mirroring is asynchronous. A committed row may not appear immediately in the SQL analytics endpoint.

### GraphQL

Use the API editor execution result to review:

- success or failure;
- total duration;
- data-source execution duration;
- returned GraphQL errors.

Some stored-procedure errors may be returned as generic data-source failures.

## Security Operations

- Keep GitHub personal access tokens outside the repository.
- Use a fine-grained token restricted to this repository.
- Keep direct table mutations disabled.
- Grant API callers only the required GraphQL Execute permission.
- With SSO, grant the caller the required permissions on the SQL database.
- Use `ops_api_reader` for controlled reads.
- Use `ops_api_writer` for procedure execution only.
- Review exported GraphQL definitions for passwords, tokens, secrets, connection strings, and credentials before public commits.

## Failure Handling

### Duplicate Request

A duplicate `ClientOrderReference` is rejected by the unique constraint. Confirm that one order and one line remain.

### Invalid Quantity

Quantity less than or equal to zero is rejected before the transaction begins.

### Missing Customer

A nonexistent customer is rejected before write operations begin.

### Missing or Unavailable Product

A product that does not exist or is not currently available for sale is rejected.

### Partial Write Concern

The procedure uses a transaction with `XACT_ABORT`, `TRY...CATCH`, rollback, and `THROW`. Validate the target tables after any failed request.

## Data Management

Git and Deployment Pipelines manage definitions, not operational data.

- Do not treat Git as a database backup.
- Do not copy Development transaction data into Test.
- Use synthetic Test data.
- Document seed operations and make them repeatable.
- Automatic backups and point-in-time restore are managed separately from Git.

## Known Operational Limitations

- OneLake mirroring is asynchronous.
- Computed columns are skipped during mirroring.
- SQL analytics endpoint is read-only.
- GraphQL does not automatically refresh after source schema changes.
- Database-level settings are not fully represented in Git integration.
- SQL database deployment is marked Preview in the Deployment Pipeline interface.
