CREATE TABLE [ops].[SalesOrderLine] (
    [SalesOrderLineID]  INT             IDENTITY (1, 1) NOT NULL,
    [SalesOrderID]      INT             NOT NULL,
    [ProductID]         INT             NOT NULL,
    [OrderQuantity]     SMALLINT        NOT NULL,
    [UnitPrice]         DECIMAL (19, 4) NOT NULL,
    [UnitPriceDiscount] DECIMAL (9, 4)  CONSTRAINT [DF_ops_SalesOrderLine_UnitPriceDiscount] DEFAULT ((0)) NOT NULL,
    [LineTotal]         AS              (CONVERT([decimal](19,4),([OrderQuantity]*[UnitPrice])*((1)-[UnitPriceDiscount]))) PERSISTED,
    [ModifiedDate]      DATETIME2 (3)   CONSTRAINT [DF_ops_SalesOrderLine_ModifiedDate] DEFAULT (sysutcdatetime()) NOT NULL,
    CONSTRAINT [PK_ops_SalesOrderLine] PRIMARY KEY CLUSTERED ([SalesOrderLineID] ASC),
    CONSTRAINT [CK_ops_SalesOrderLine_OrderQuantity] CHECK ([OrderQuantity]>(0)),
    CONSTRAINT [CK_ops_SalesOrderLine_UnitPrice] CHECK ([UnitPrice]>=(0)),
    CONSTRAINT [CK_ops_SalesOrderLine_UnitPriceDiscount] CHECK ([UnitPriceDiscount]>=(0) AND [UnitPriceDiscount]<=(1)),
    CONSTRAINT [FK_ops_SalesOrderLine_Product] FOREIGN KEY ([ProductID]) REFERENCES [SalesLT].[Product] ([ProductID]),
    CONSTRAINT [FK_ops_SalesOrderLine_SalesOrder] FOREIGN KEY ([SalesOrderID]) REFERENCES [ops].[SalesOrder] ([SalesOrderID]),
    CONSTRAINT [UQ_ops_SalesOrderLine_Order_Product] UNIQUE NONCLUSTERED ([SalesOrderID] ASC, [ProductID] ASC)
);


GO

