-- Create an operational order view for GraphQL queries
CREATE   VIEW ops.vwSalesOrderDetails
AS
SELECT
    h.SalesOrderID,
    h.ClientOrderReference,
    h.OrderDate,
    h.DueDate,
    h.OrderStatus,
    h.CustomerID,
    CONCAT(c.FirstName, N' ', c.LastName) AS CustomerName,
    c.CompanyName,
    l.SalesOrderLineID,
    l.ProductID,
    p.Name AS ProductName,
    p.ProductNumber,
    l.OrderQuantity,
    l.UnitPrice,
    l.UnitPriceDiscount,
    l.LineTotal,
    h.SubTotal,
    h.ModifiedDate
FROM ops.SalesOrder AS h
INNER JOIN ops.SalesOrderLine AS l
    ON l.SalesOrderID = h.SalesOrderID
INNER JOIN SalesLT.Customer AS c
    ON c.CustomerID = h.CustomerID
INNER JOIN SalesLT.Product AS p
    ON p.ProductID = l.ProductID;

GO

