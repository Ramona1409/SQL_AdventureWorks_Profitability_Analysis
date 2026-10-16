
-- PASUL 1: Generam baza de date pentru analiza profitabilitatii
-- Include informatii despre produse, categorii, preturi, discounturi si profitabilitate


SELECT
    h.SalesOrderID,
    p.ProductID,
    pc.[Name] AS CategoryName,
    p.[Name] AS ProductName,
    YEAR(h.OrderDate) AS OrderYear,
    MONTH(h.OrderDate) AS OrderMonth,
    d.OrderQty,
    -- Preturi utilizate in calculul profitului
    d.UnitPrice,
    d.UnitPriceDiscount,
    p.StandardCost,
    -- Venit total obtinut dupa aplicarea discountului
    (d.UnitPrice * (1 - d.UnitPriceDiscount) * d.OrderQty) AS Revenue,
    -- Marja bruta = (pret vanzare - cost produs) * cantitate
    -- Indicator principal pentru profitabilitate
    ((d.UnitPrice * (1 - d.UnitPriceDiscount) - p.StandardCost) * d.OrderQty) AS GrossMargin
FROM Sales.SalesOrderHeader h
JOIN Sales.SalesOrderDetail d 
    ON h.SalesOrderID = d.SalesOrderID
JOIN Production.Product p 
    ON d.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps 
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc 
    ON ps.ProductCategoryID = pc.ProductCategoryID;

--VERIFICARE DE INTEGRITATE A DATELOR

-- Verificam duplicate la nivel de linie de comanda
SELECT 
    SalesOrderID,
    ProductID,
    COUNT(*) AS NrInregistrari
FROM Sales.SalesOrderDetail
GROUP BY SalesOrderID, ProductID
HAVING COUNT(*) > 1;

--Verificam daca exista valori NULL in campurile cu valori numerice
SELECT *
FROM Sales.SalesOrderDetail d
JOIN Production.Product p 
    ON d.ProductID = p.ProductID
WHERE 
    d.UnitPrice IS NULL OR
    d.UnitPriceDiscount IS NULL OR
    d.OrderQty IS NULL OR
    p.StandardCost IS NULL;

--Verificam daca exista cantitati invalide
SELECT *
FROM Sales.SalesOrderDetail
WHERE OrderQty <= 0;

-- Verificam daca exista valori invalide pentru discount
SELECT *
FROM Sales.SalesOrderDetail
WHERE UnitPriceDiscount < 0 
   OR UnitPriceDiscount > 1;



-- PASUL 2: Analiza sezonalitatii si impactului discounturilor asupra profitabilitatii
-- Obiectiv: Identificarea variatiilor lunare ale marjei brute si corelatia cu discounturile


SELECT 
    YEAR(h.OrderDate) AS OrderYear,
    MONTH(h.OrderDate) AS OrderMonth,
    pc.[Name] AS CategoryName,
    -- Discount mediu aplicat pe categorie si luna (in procente)
    ROUND(AVG(d.UnitPriceDiscount) * 100, 2) AS AvgDiscount,
    -- Marja bruta totala pe categorie si perioada
    SUM((d.UnitPrice * (1 - d.UnitPriceDiscount) - p.StandardCost) * d.OrderQty) AS TotalGrossMargin
FROM Sales.SalesOrderHeader h
JOIN Sales.SalesOrderDetail d 
    ON h.SalesOrderID = d.SalesOrderID
JOIN Production.Product p 
    ON d.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps 
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc 
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    YEAR(h.OrderDate), 
    MONTH(h.OrderDate), 
    pc.[Name]
ORDER BY 
    CategoryName,
    OrderYear, 
    OrderMonth;



-- PASUL 3: Analiza evolutiei veniturilor si a marjei brute in timp
-- Obiectiv: Compararea performantei financiare pe categorii si ani


SELECT 
    pc.[Name] AS CategoryName,
    YEAR(h.OrderDate) AS OrderYear,
    -- Profit total generat pe categorie si an
    SUM((d.UnitPrice * (1 - d.UnitPriceDiscount) - p.StandardCost) * d.OrderQty) AS TotalGrossMargin,
    -- Venit total generat pe categorie si an
    SUM(d.UnitPrice * (1 - d.UnitPriceDiscount) * d.OrderQty) AS TotalRevenue
FROM Sales.SalesOrderHeader h
JOIN Sales.SalesOrderDetail d 
    ON h.SalesOrderID = d.SalesOrderID
JOIN Production.Product p 
    ON d.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps 
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc 
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    pc.[Name], 
    YEAR(h.OrderDate)
ORDER BY 
    pc.[Name], 
    OrderYear;


-- PASUL 4: Analiza impactului discounturilor asupra profitabilitatii pe categorii
-- Obiectiv: Intelegerea relatiei dintre nivelul discountului si marja bruta


SELECT 
    pc.[Name] AS CategoryName,
    -- Discount mediu pe categorie
    AVG(d.UnitPriceDiscount) AS AvgDiscount,
    -- Profit total pe categorie
    SUM((d.UnitPrice * (1 - d.UnitPriceDiscount) - p.StandardCost) * d.OrderQty) AS TotalGrossMargin,
    -- Volumul total vandut (cantitate)
    SUM(d.OrderQty) AS TotalQuantity
FROM Sales.SalesOrderDetail d
JOIN Production.Product p 
    ON d.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps 
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc 
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.[Name]
ORDER BY AvgDiscount DESC;



-- PASUL 5: Identificarea produselor profitabile vs neprofitabile
-- Obiectiv: Clasificarea produselor in functie de contributia lor la profit


SELECT 
    p.ProductID,
    pc.[Name] AS CategoryName,
    p.[Name] AS ProductName,
    -- Discount mediu aplicat pe produs
    AVG(d.UnitPriceDiscount) AS AvgDiscount,
    -- Profit total generat de fiecare produs
    SUM((d.UnitPrice * (1 - d.UnitPriceDiscount) - p.StandardCost) * d.OrderQty) AS TotalGrossMargin
FROM Sales.SalesOrderDetail d
JOIN Production.Product p 
    ON d.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps 
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc 
    ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY 
    p.ProductID, 
    pc.[Name], 
    p.[Name]
ORDER BY TotalGrossMargin ASC;

