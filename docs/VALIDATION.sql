-- Fabric Operational Sales API validation script
-- Run in the operational SQL database, not the SQL analytics endpoint.

SET NOCOUNT ON;

-- 1. Validate custom database objects
SELECT
    s.name AS [SchemaName],
    o.name AS [ObjectName],
    o.type_desc AS [ObjectType]
FROM sys.objects AS o
INNER JOIN sys.schemas AS s
    ON s.schema_id = o.schema_id
WHERE s.name = N'ops'
  AND o.type IN ('U', 'V', 'P')
ORDER BY
    o.type_desc,
    o.name;

-- 2. Validate table row counts
SELECT
    (SELECT COUNT_BIG(*) FROM ops.SalesOrder) AS [SalesOrderCount],
    (SELECT COUNT_BIG(*) FROM ops.SalesOrderLine) AS [SalesOrderLineCount];

-- 3. Validate reference data availability
SELECT
    (SELECT COUNT_BIG(*) FROM SalesLT.Customer) AS [CustomerCount],
    (SELECT COUNT_BIG(*) FROM SalesLT.Product) AS [ProductCount];

-- 4. Validate operational API roles and permissions
SELECT
    dp.name AS [RoleName],
    perm.state_desc AS [PermissionState],
    perm.permission_name AS [PermissionName],
    OBJECT_SCHEMA_NAME(perm.major_id) AS [SchemaName],
    OBJECT_NAME(perm.major_id) AS [ObjectName]
FROM sys.database_principals AS dp
LEFT JOIN sys.database_permissions AS perm
    ON perm.grantee_principal_id = dp.principal_id
WHERE dp.name IN
(
    N'ops_api_reader',
    N'ops_api_writer'
)
ORDER BY
    dp.name,
    perm.state_desc,
    perm.permission_name,
    [SchemaName],
    [ObjectName];

-- 5. Validate stored-procedure result metadata
SELECT
    column_ordinal AS [ColumnOrdinal],
    name AS [ColumnName],
    system_type_name AS [SystemType],
    is_nullable AS [IsNullable],
    error_number AS [ErrorNumber],
    error_message AS [ErrorMessage]
FROM sys.dm_exec_describe_first_result_set_for_object
(
    OBJECT_ID(N'ops.CreateSalesOrder'),
    0
)
ORDER BY column_ordinal;

-- 6. Validate order consistency
SELECT
    h.SalesOrderID,
    h.ClientOrderReference,
    h.CustomerID,
    h.OrderStatus,
    h.SubTotal,
    COUNT_BIG(l.SalesOrderLineID) AS [LineCount],
    SUM(l.LineTotal) AS [CalculatedSubTotal],
    CASE
        WHEN h.SubTotal = SUM(l.LineTotal) THEN 'PASS'
        ELSE 'FAIL'
    END AS [SubtotalValidation]
FROM ops.SalesOrder AS h
INNER JOIN ops.SalesOrderLine AS l
    ON l.SalesOrderID = h.SalesOrderID
GROUP BY
    h.SalesOrderID,
    h.ClientOrderReference,
    h.CustomerID,
    h.OrderStatus,
    h.SubTotal
ORDER BY h.SalesOrderID;

-- 7. Identify orphaned order lines; expected result: zero rows
SELECT
    l.SalesOrderLineID,
    l.SalesOrderID
FROM ops.SalesOrderLine AS l
LEFT JOIN ops.SalesOrder AS h
    ON h.SalesOrderID = l.SalesOrderID
WHERE h.SalesOrderID IS NULL;

-- 8. Identify duplicate client request identifiers; expected result: zero rows
SELECT
    ClientOrderReference,
    COUNT_BIG(*) AS [DuplicateCount]
FROM ops.SalesOrder
GROUP BY ClientOrderReference
HAVING COUNT_BIG(*) > 1;
