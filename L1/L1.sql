--Zad1
/*Utworzyć zapytanie, które na podstawie SalesOrderHeader.ShipToAddressID zwróci listę miast, do których
towary zostały już dostarczone. Lista ma być posortowana i bez powtarzających się wartości.*/

SELECT DISTINCT City
FROM SalesLT.SalesOrderHeader
JOIN SalesLT.Address ON SalesLT.SalesOrderHeader.ShipToAddressID = SalesLT.Address.AddressID
WHERE Status = 5
ORDER BY City;

--Zad2
/*Utworzyć zapytanie, które w wyniku zwróci dwie kolumny: nazwę modelu produktu (ProductModel.Name) oraz
liczbę produktów tego modelu, przy czym w wyniku chcemy widzieć tylko te, dla których ta liczba jest większa
niż 1. Zastanowić się, jakie konsekwencje rodzi fakt wyboru nazwy jako wartości grupującej.*/

SELECT SalesLT.ProductModel.Name AS Name, COUNT(SalesLT.Product.ProductID) AS NumberOfProducts
FROM SalesLT.ProductModel
/*LEFT*/ JOIN SalesLT.Product ON SalesLT.ProductModel.ProductModelID = SalesLT.Product.ProductModelID
GROUP BY SalesLT.ProductModel.ProductModelID, SalesLT.ProductModel.Name
/*-- żeby 0 też działały*/HAVING COUNT (SalesLT.Product.ProductID) > 1;
-- Wybór nazwy jako wartości grupującej może spowodować, że wyniki będą błędne, ponieważ nie jest ona kluczem głównym tabeli ProductModel, więc mogłby być dwa różne produkty o tej samej nazwie i zostałyby policzone razem

--Zad3
/*Utworzyć zapytanie, które w wyniku zwróci trzy kolumny: nazwę miasta (z tabeli Address), liczbą klientów z
tego miasta, liczbą SalesPerson obsługujących klientów z tego miasta.*/

SELECT COUNT( DISTINCT SalesLT.Customer.SalesPerson) AS NumberOfSalesPersons, COUNT(SalesLT.Customer.CustomerID) AS NumberOfCustomers, SalesLT.Address.City AS City
FROM SalesLT.Customer
RIGHT JOIN SalesLT.CustomerAddress ON SalesLT.Customer.CustomerID = SalesLT.CustomerAddress.CustomerID
RIGHT JOIN SalesLT.Address ON SalesLT.CustomerAddress.AddressID = SalesLT.Address.AddressID
GROUP BY SalesLT.Address.City;

--Zad4
/* Kategorie produktów są w strukturze drzewa. Możemy oczekiwać, że wszystkie produkty będą przypisane tylko
do kategorii będących w liściach tego drzewa. Utworzyć zapytanie, które zwróci dwie kolumny: nazwę kategorii
i nazwę produktu dla produktów będących przypisanych do kategorii nie będących w liściach.*/

UPDATE SalesLT.Product SET ProductCategoryID=1 WHERE SalesLT.Product.ProductID = 680;

SELECT Product.Name, NotLeafs.ProductCategoryName
FROM SalesLT.Product
JOIN
    (SELECT SalesLT.ProductCategory.Name AS ProductCategoryName, Parents.ParentID AS ProductCategoryID
    FROM    (SELECT DISTINCT SalesLT.ProductCategory.ParentProductCategoryID AS ParentID
            FROM SalesLT.ProductCategory) AS Parents
    JOIN SalesLT.ProductCategory ON SalesLT.ProductCategory.ProductCategoryID = Parents.ParentID) AS NotLeafs
ON SalesLT.Product.ProductCategoryID = NotLeafs.ProductCategoryID;

--Zad5
/*Utworzyć zapytanie, który w wyniku zwróci trzy kolumny: nazwisko i imię klienta (Customer) oraz kwotę, którą
ten klient zaoszczędził dzięki udzielonym rabatom (SalesOrderDetail.UnitPriceDiscount).*/

DROP VIEW IF EXISTS Discounts;

GO
CREATE VIEW Discounts
AS
SELECT SalesLT.Customer.FirstName, SalesLT.Customer.LastName, (SalesLT.SalesOrderDetail.UnitPriceDiscount * SalesLT.SalesOrderDetail.UnitPrice) AS Mult
FROM SalesLT.Customer
JOIN SalesLT.SalesOrderHeader ON SalesLT.SalesOrderHeader.CustomerID = SalesLT.Customer.CustomerID
JOIN SalesLT.SalesOrderDetail ON SalesLT.SalesOrderDetail.SalesOrderID = SalesLT.SalesOrderHeader.SalesOrderID
GROUP BY SalesLT.Customer.CustomerID, SalesLT.Customer.FirstName, SalesLT.Customer.LastName, (SalesLT.SalesOrderDetail.UnitPriceDiscount * SalesLT.SalesOrderDetail.UnitPrice)
GO

SELECT FirstName, LastName, SUM(Mult) AS DiscountsSum
FROM Discounts
GROUP BY FirstName, LastName
ORDER BY FirstName, LastName;

--Zad6
/*Utworzyć tabelę OrdersToProcess(SalesOrderID INT, Delayed BIT), w której będą przechowywane zamówienia
jeszcze nie dostarczone, a flaga Delayed określa czy DueDate nie został przekroczony. Przygotować zapytanie,
które zaktualizuje tę tabelę w oparciu o tabelę SalesOrderHeader i należy skorzystać z konstrukcji MERGE. Aby
przetestować działanie tej metody, warto dogenerować trochę danych (w bazie testowej jest ich niewiele).*/

DROP TABLE IF EXISTS  OrdersToProcess;
CREATE TABLE OrdersToProcess (SalesOrderID INT primary key, Delayed BIT);

DECLARE @OrderDate datetime = GETDATE();
DECLARE @ShipDate datetime = DATEADD(day, 10, @OrderDate);
DECLARE @DueDate datetime =  DATEADD(day, 7, @OrderDate);

INSERT INTO SalesLT.SalesOrderHeader(CustomerID ,DueDate, ShipDate, Status, OrderDate, ShipMethod)
Values  (1, @DueDate, @ShipDate, 4, @OrderDate, 'xyz'),
        (2, @DueDate, @ShipDate, 3, @OrderDate, 'xyz'),
        (3, @DueDate, @ShipDate, 4, @OrderDate, 'qwe'),
        (4, @DueDate, @ShipDate, 4, @OrderDate, 'www');

SELECT * FROM OrdersToProcess;

MERGE OrdersToProcess AS Target
USING SalesLT.SalesOrderHeader AS Source
ON Target.SalesOrderID = Source.SalesOrderID
WHEN MATCHED AND Source.ShipDate <= GETDATE()
    THEN DELETE
WHEN NOT MATCHED AND Source.ShipDate > GETDATE() OR Source.ShipDate IS NULL
    THEN
    INSERT(SalesOrderID, Delayed)
    VALUES(Source.SalesOrderID, CASE WHEN Source.DueDate < GETDATE() THEN 0 ELSE 1 END);

SELECT * FROM OrdersToProcess;

--Zad7
/*Utwórz tabelę Test z kolumną IDENTITY, gdzie identyfikatory mają się zaczynać od 1000 i przesuwać o 10.
Zademonstruj różnicę pomiędzy @@IDENTITY i IDENT CURRENT.*/

DROP TABLE IF EXISTS Test;
DROP TABLE IF EXISTS Test2;
CREATE TABLE Test (Id INT IDENTITY(1000, 10), cosik INT);
CREATE TABLE Test2(Id INT IDENTITY(100, 1), cosik INT);
INSERT INTO Test VALUES(5);
INSERT INTO Test2 VALUES(5);
SELECT @@IDENTITY
SELECT IDENT_CURRENT('Test');

-- @@IDENTITY - ostatnie ID nadane globalnie (do jakiejkolwiek tabeli)
-- IDENT_CURRENT('Test') - ostatnie ID nadane w tabeli Test

--Zad8
/*Zapoznać się z ograniczeniem (constraint) SalesOrderHeader.CK SalesOrderHeader ShipDate, zaprezentować
instrukcję jego utworzenia. Spróbować dodać wiersz (lub zmodyfikować istniejący) naruszając to ograniczenie.
Jaki będzie efekt? Następnie wyłączyć ogranicznie i spróbować ponownie. Na koniec włączyć ograniczenie i
wylistować bieżące naruszenia.*/

/*USE [AdventureWorksLT2019]
GO

ALTER TABLE [SalesLT].[SalesOrderHeader]  WITH NOCHECK ADD  CONSTRAINT [CK_SalesOrderHeader_ShipDate] CHECK  (([ShipDate]>=[OrderDate] OR [ShipDate] IS NULL))
GO

ALTER TABLE [SalesLT].[SalesOrderHeader] CHECK CONSTRAINT [CK_SalesOrderHeader_ShipDate]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Check constraint [ShipDate] >= [OrderDate] OR [ShipDate] IS NULL' , @level0type=N'SCHEMA',@level0name=N'SalesLT', @level1type=N'TABLE',@level1name=N'SalesOrderHeader', @level2type=N'CONSTRAINT',@level2name=N'CK_SalesOrderHeader_ShipDate'
GO*/

DECLARE @MAX_ID AS INT;
SELECT @MAX_ID = MAX(SalesOrderID) FROM SalesLT.SalesOrderHeader;
UPDATE SalesLT.SalesOrderHeader SET OrderDate=GETDATE()
WHERE SalesLT.SalesOrderHeader.SalesOrderID = @MAX_ID; -- nie działa

DECLARE @MAX_ID AS INT;
SELECT @MAX_ID = MAX(SalesOrderID) FROM SalesLT.SalesOrderHeader;
ALTER TABLE SalesLT.SalesOrderHeader NOCHECK CONSTRAINT CK_SalesOrderHeader_ShipDate;
UPDATE SalesLT.SalesOrderHeader SET OrderDate=GETDATE()
WHERE SalesLT.SalesOrderHeader.SalesOrderID = @MAX_ID; -- nie działa, ponieważ nie działa Constraint dla DueDate

DECLARE @MAX_ID AS INT;
SELECT @MAX_ID = MAX(SalesOrderID) FROM SalesLT.SalesOrderHeader;
ALTER TABLE SalesLT.SalesOrderHeader NOCHECK CONSTRAINT CK_SalesOrderHeader_ShipDate;
ALTER TABLE SalesLT.SalesOrderHeader NOCHECK CONSTRAINT CK_SalesOrderHeader_DueDate;
UPDATE SalesLT.SalesOrderHeader SET OrderDate=GETDATE()
WHERE SalesLT.SalesOrderHeader.SalesOrderID = @MAX_ID; --działa

DBCC CHECKCONSTRAINTS WITH ALL_CONSTRAINTS;

DECLARE @MAX_ID AS INT;
SELECT @MAX_ID = MAX(SalesOrderID) FROM SalesLT.SalesOrderHeader;
DELETE FROM SalesLT.SalesOrderHeader
WHERE SalesLT.SalesOrderHeader.SalesOrderID = @MAX_ID;

ALTER TABLE SalesLT.SalesOrderHeader CHECK CONSTRAINT CK_SalesOrderHeader_ShipDate;
ALTER TABLE SalesLT.SalesOrderHeader CHECK CONSTRAINT CK_SalesOrderHeader_DueDate;