CREATE TABLE [ops].[SalesOrder] (
    [SalesOrderID]         INT              IDENTITY (1, 1) NOT NULL,
    [ClientOrderReference] UNIQUEIDENTIFIER NOT NULL,
    [CustomerID]           INT              NOT NULL,
    [OrderDate]            DATETIME2 (3)    CONSTRAINT [DF_ops_SalesOrder_OrderDate] DEFAULT (sysutcdatetime()) NOT NULL,
    [DueDate]              DATETIME2 (3)    NOT NULL,
    [OrderStatus]          VARCHAR (20)     CONSTRAINT [DF_ops_SalesOrder_OrderStatus] DEFAULT ('Pending') NOT NULL,
    [SubTotal]             DECIMAL (19, 4)  CONSTRAINT [DF_ops_SalesOrder_SubTotal] DEFAULT ((0)) NOT NULL,
    [ModifiedDate]         DATETIME2 (3)    CONSTRAINT [DF_ops_SalesOrder_ModifiedDate] DEFAULT (sysutcdatetime()) NOT NULL,
    CONSTRAINT [PK_ops_SalesOrder] PRIMARY KEY CLUSTERED ([SalesOrderID] ASC),
    CONSTRAINT [CK_ops_SalesOrder_DueDate] CHECK ([DueDate]>=[OrderDate]),
    CONSTRAINT [CK_ops_SalesOrder_OrderStatus] CHECK ([OrderStatus]='Cancelled' OR [OrderStatus]='Confirmed' OR [OrderStatus]='Pending'),
    CONSTRAINT [CK_ops_SalesOrder_SubTotal] CHECK ([SubTotal]>=(0)),
    CONSTRAINT [FK_ops_SalesOrder_Customer] FOREIGN KEY ([CustomerID]) REFERENCES [SalesLT].[Customer] ([CustomerID]),
    CONSTRAINT [UQ_ops_SalesOrder_ClientOrderReference] UNIQUE NONCLUSTERED ([ClientOrderReference] ASC)
);


GO

