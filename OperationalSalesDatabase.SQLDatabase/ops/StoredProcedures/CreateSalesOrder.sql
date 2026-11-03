-- Create a safe transactional procedure for a single-line order
CREATE   PROCEDURE ops.CreateSalesOrder
    @ClientOrderReference uniqueidentifier,
    @CustomerID int,
    @ProductID int,
    @OrderQuantity smallint,
    @DueDate datetime2(3),
    @UnitPriceDiscount decimal(9, 4) = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE
        @SalesOrderID int,
        @UnitPrice decimal(19, 4),
        @SubTotal decimal(19, 4);

    IF @ClientOrderReference IS NULL
        THROW 50001, 'Client order reference is required.', 1;

    IF @OrderQuantity <= 0
        THROW 50002, 'Order quantity must be greater than zero.', 1;

    IF @UnitPriceDiscount < 0 OR @UnitPriceDiscount > 1
        THROW 50003, 'Unit price discount must be between zero and one.', 1;

    IF @DueDate < SYSUTCDATETIME()
        THROW 50004, 'Due date cannot be in the past.', 1;

    IF NOT EXISTS
    (
        SELECT 1
        FROM SalesLT.Customer
        WHERE CustomerID = @CustomerID
    )
        THROW 50005, 'Customer does not exist.', 1;

    SELECT
        @UnitPrice = CONVERT(decimal(19, 4), p.ListPrice)
    FROM SalesLT.Product AS p
    WHERE p.ProductID = @ProductID
      AND p.ListPrice > 0
      AND p.SellStartDate <= SYSUTCDATETIME()
      AND
      (
          p.SellEndDate IS NULL
          OR p.SellEndDate >= SYSUTCDATETIME()
      );

    IF @UnitPrice IS NULL
        THROW 50006, 'Product does not exist or is not available for sale.', 1;

    SET @SubTotal = CONVERT(
        decimal(19, 4),
        @OrderQuantity * @UnitPrice * (1 - @UnitPriceDiscount)
    );

    BEGIN TRY
        BEGIN TRANSACTION;

        INSERT INTO ops.SalesOrder
        (
            ClientOrderReference,
            CustomerID,
            DueDate,
            SubTotal
        )
        VALUES
        (
            @ClientOrderReference,
            @CustomerID,
            @DueDate,
            @SubTotal
        );

        SET @SalesOrderID = CONVERT(int, SCOPE_IDENTITY());

        INSERT INTO ops.SalesOrderLine
        (
            SalesOrderID,
            ProductID,
            OrderQuantity,
            UnitPrice,
            UnitPriceDiscount
        )
        VALUES
        (
            @SalesOrderID,
            @ProductID,
            @OrderQuantity,
            @UnitPrice,
            @UnitPriceDiscount
        );

        COMMIT TRANSACTION;

        SELECT
            @SalesOrderID AS [SalesOrderID],
            @ClientOrderReference AS [ClientOrderReference],
            @CustomerID AS [CustomerID],
            @ProductID AS [ProductID],
            @OrderQuantity AS [OrderQuantity],
            @UnitPrice AS [UnitPrice],
            @UnitPriceDiscount AS [UnitPriceDiscount],
            @SubTotal AS [SubTotal],
            'Created' AS [Result];
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
        BEGIN
            ROLLBACK TRANSACTION;
        END;

        THROW;
    END CATCH;
END;

GO

