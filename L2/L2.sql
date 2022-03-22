--Zad1
/*
 Utworzyć funkcję w T-SQL, która jako parametr bierze liczbę dni, a w wyniku zwraca tabelę (PESEL, LiczbaEgzemplarzy), która zawiera listę czytelników przechowujących co najmniej jeden egzemplarz jakiekolwiek książki
niekrócej niż liczba dni określona w parametrze. W drugiej kolumnie należy dołączyć liczbę przetrzymywanych
egzemplarzy.
*/

DROP FUNCTION IF EXISTS get_prolonging_readers
GO

CREATE FUNCTION get_prolonging_readers(@days INT) RETURNS @result TABLE(PESEL CHAR(11), no_of_books INT)
BEGIN
    DECLARE @now DATETIME
    SET @now = '2020-02-13'

    INSERT INTO @result
        SELECT c.PESEL, COUNT(DISTINCT w2.Wypozyczenie_ID)
        FROM Czytelnik AS c
            JOIN Wypozyczenie AS w1 ON c.Czytelnik_ID = w1.Czytelnik_ID
            JOIN Wypozyczenie AS w2 ON c.Czytelnik_ID = w2.Czytelnik_ID
        WHERE
            w1.Data <= @now -- DATEDIFF(10.01 - 08.01) = DATEDIFF(08.01 - 10.01) 
            AND DATEDIFF(day, w1.Data, @now) >= @days
        GROUP BY c.PESEL, c.Czytelnik_ID
    RETURN
END
GO

SELECT * FROM [dbo].[get_prolonging_readers](4)

--Zad2
/*
Utworzyć tabele imiona(id, imie), nazwiska(id, nazwisko) oraz dane(imie, nazwisko). Wstawić testowe dane
do tabel imiona i nazwiska, a następnie utworzyć procedurę, która dla zadanego parametru n do tabeli dane
wstawi n losowo dobranych par (imię, nazwisko) uprzednio usuwając jej zawartość. Jeśli n będzie większe od
połowy wszystkich możliwych kombinacji, należy to zakomunikować poprzez odpowiednie wywołanie instrukcji
THROW. Klucz główny tabeli dane tworzą kolumny (imię,nazwisko), dlatego trzeba zadbać o to, żeby podczas
generowania danych każdą parę (imię,nazwisko) wygenerować co najwyżej raz.
*/

DROP TABLE dane;
DROP TABLE imiona;
DROP TABLE nazwiska;

CREATE TABLE imiona (id INT PRIMARY KEY, imie VARCHAR(255));
CREATE TABLE nazwiska (id INT PRIMARY KEY, nazwisko VARCHAR(255));
CREATE TABLE dane (imie VARCHAR(255), nazwisko VARCHAR(255), CONSTRAINT klucz PRIMARY KEY (imie, nazwisko));

INSERT INTO imiona VALUES (1, 'Antoni'),
                        (2, 'Jan'),
                        (3, 'Jakub'),
                        (4, 'Aleksander'),
                        (5, 'Franciszek'),
                        (6, 'Julia'),
                        (7, 'Zuzanna'),
                        (8, 'Zofia'),
                        (9, 'Hanna'),
                        (10, 'Maja')

INSERT INTO nazwiska VALUES (1, 'Nowak'),
                            (2, 'Kowalski'),
                            (3, 'Wiśniewski'),
                            (4, 'Wójcik'),
                            (5, 'Kowalczyk'),
                            (6, 'Kamiński'),
                            (7, 'Lewandowski'),
                            (8, 'Zieliński'),
                            (9, 'Szymański'),
                            (10, 'Woźniak')

DROP PROCEDURE IF EXISTS generuj_dane
GO
CREATE PROCEDURE generuj_dane @n INT
AS BEGIN
  DECLARE @all_possible TABLE(imie VARCHAR(255), nazwisko VARCHAR(255));
  INSERT INTO @all_possible SELECT imie, nazwisko FROM imiona CROSS JOIN nazwiska;
  IF ((SELECT COUNT(*) FROM @all_possible) / 2 < @n)
    THROW 50000, 'Zażądano zbyt wielu kombinacji', 0;
  DELETE FROM dane;
  INSERT INTO dane SELECT TOP(@n) * FROM @all_possible ORDER BY NEWID();
END
GO
EXEC generuj_dane @n=44
GO

SELECT * FROM dane;

--Zad3
/*
Zaimplementować procedurę do tworzenia nowego czytelnika przyjmującą odpowiednie parametry. W ramach
procedury należy zaimplementować następujące walidacje: poprawność formatu PESEL, nazwisko z wielkiej
litery i co najmniej dwuliterowe, poprawną datę urodzenia, zgodną z PESELem. Wszystkie niezgodności należy
zakomunikować poprzez odpowiednie wywołanie instrukcji THROW.
*/

DROP FUNCTION IF EXISTS validate_pesel
GO

CREATE FUNCTION validate_pesel(@PESEL VARCHAR(255)) RETURNS BIT AS
BEGIN
    IF (
    ( ( CAST(SUBSTRING(@PESEL,1,1) AS INT)*9)
    +(CAST(SUBSTRING(@PESEL,2,1) AS INT)*7)
    +(CAST(SUBSTRING(@PESEL,3,1) AS INT)*3)
    +(CAST(SUBSTRING(@PESEL,4,1) AS INT)*1)
    +(CAST(SUBSTRING(@PESEL,5,1) AS INT)*9)
    +(CAST(SUBSTRING(@PESEL,6,1) AS INT)*7)
    +(CAST(SUBSTRING(@PESEL,7,1) AS INT)*3)
    +(CAST(SUBSTRING(@PESEL,8,1) AS INT)*1)
    +(CAST(SUBSTRING(@PESEL,9,1) AS INT)*9)
    +(CAST(SUBSTRING(@PESEL,10,1) AS INT)*7) ) % 10
    = RIGHT(@PESEL,1) AND LEN(@PESEL) = 11 )
    BEGIN
        return 1
    END
    return 0
END
GO

DROP FUNCTION IF EXISTS validate_lastname
GO

CREATE FUNCTION validate_lastname(@lastname VARCHAR(255)) RETURNS BIT AS
BEGIN
    IF(LEN(@lastname) >= 2 AND UNICODE(LEFT(@lastname, 1)) <> UNICODE(LOWER(LEFT(@lastname,1)))) RETURN 1
    RETURN 0
END
GO

DROP FUNCTION IF EXISTS validate_birthday;
GO

CREATE FUNCTION validate_birthday(@PESEL VARCHAR(255), @birthday DATE) RETURNS BIT AS
BEGIN
    DECLARE @Day VARCHAR(2)
    SET @Day = SUBSTRING(@PESEL, 5, 2)

    DECLARE @Year VARCHAR(4)
    SET @Year = SUBSTRING(@PESEL, 1, 2)

    DECLARE @MonthInt INT
    SET @MonthInt = CAST(SUBSTRING(@PESEL, 3, 2) AS INT)

    IF @MonthInt > 20 
    BEGIN
        SET @MonthInt = @MonthInt - 20
        SET @Year = CONCAT('20', @Year)
    END
    ELSE
    BEGIN
        SET @Year = CONCAT('19', @Year)
    END

    DECLARE @Month VARCHAR(2)
    SET @Month = CAST(@MonthInt AS VARCHAR(2))
    IF (@MonthInt < 10) SET @Month = CONCAT('0', @Month)

    DECLARE @Date VARCHAR(255)
    SET @Date = CONCAT(@Year, '.', @Month, '.', @Day)

    DECLARE @BirthdayInANSI VARCHAR(255)
    SET @BirthdayInANSI = CONVERT(VARCHAR, @birthday, 102)

    IF (@Date = @BirthdayInANSI) RETURN 1
    RETURN 0
END
GO

GO

CREATE OR ALTER PROCEDURE insert_reader @PESEL VARCHAR(255), @lastname VARCHAR(255), @city VARCHAR(255), @birthday DATE
AS BEGIN
    IF ([dbo].[validate_pesel](@PESEL) = 0)
        THROW 50000, 'Bledny PESEL', 0

    IF ([dbo].[validate_lastname](@lastname) = 0)
        THROW 50000, 'Bledne nazwisko', 0

    IF ([dbo].[validate_birthday](@PESEL, @birthday) = 0)
        THROW 50000, 'Bledna data urodzenia', 0

    INSERT INTO Czytelnik VALUES (@PESEL, @lastname, @city, @birthday, NULL)

END
GO

SELECT [dbo].[validate_pesel] ('97060852597')
SELECT [dbo].[validate_pesel] ('970608525')
SELECT [dbo].[validate_pesel] ('00252362352');

SELECT [dbo].[validate_lastname] ('dabrowsk')
SELECT [dbo].[validate_lastname] ('Dabrowsk')
SELECT [dbo].[validate_lastname] ('Da')
SELECT [dbo].[validate_lastname] ('D');

DECLARE @MyBirthday AS DATETIME 
SET @MyBirthday = '1997/06/08'

SELECT [dbo].[validate_birthday] ('97060852597', @MyBirthday)

SET @MyBirthday = '2000/05/23'
SELECT [dbo].[validate_birthday] ('00252362352', @MyBirthday);
SELECT [dbo].[validate_birthday] ('00252462352', @MyBirthday);
SET @MyBirthday = '2000/05/24'
SELECT [dbo].[validate_birthday] ('00252362352', @MyBirthday);


EXEC insert_reader @PESEL='97060852597', @lastname='Dabrowski', @city='Wroclaw', @birthday='1997/06/08';

SELECT * FROM Czytelnik;

DELETE FROM Czytelnik WHERE PESEL = '97060852597';

--Zad4
/*
Utworzyć procedurę, która jako parametr bierze tabelę (czytelnik id) identyfikatorów czytelników, a jako wynik
zwraca tabelę o dwóch kolumnach (czytelnik id,suma dni), gdzie dla każdego przekazanego czytelnika dołączona
jest sumaryczna liczba dni, na którą dany czytelnik wypożyczył książki.
*/

DROP PROCEDURE IF EXISTS get_no_borrow_days
DROP TYPE IF EXISTS input_table
GO

CREATE TYPE input_table AS TABLE (reader_id INT)
GO

CREATE PROCEDURE get_no_borrow_days
    @input input_table READONLY
AS BEGIN
    SELECT c.Czytelnik_ID AS reader_id,
        SUM(w.Liczba_Dni) AS no_days
    FROM Czytelnik AS c
    JOIN Wypozyczenie AS w ON c.Czytelnik_ID = w.Czytelnik_ID
    WHERE c.Czytelnik_ID IN (SELECT * FROM @input)
    GROUP BY c.Czytelnik_ID
END
GO

DECLARE @i input_table
INSERT INTO @i VALUES (1), (2), (3)
EXEC get_no_borrow_days @input=@i

--Zad6
/*
Wykorzystując typ tabelowy, utworzyć procedurę, która jako parametr bierze listę identyfikatorów produktów
oraz datę, a następnie w tabeli SalesLT.Product dla wskazanych produktów ustawia pole DiscontinuedDate na
zadaną wartość. Dodatkowo sprawdza, czy wśród wskazanych produktów nie ma już jakiegoś z ustawioną datą
- jeśli jakiś istnieje, nic w danych nie zmienia, tylko kończy działanie z odpowiednim komunikatem.
Uwaga: zadanie do realizacji na bazie AdventureWorksLT.
*/

DROP PROCEDURE IF EXISTS set_discontinued_date
DROP TYPE IF EXISTS products_list
GO

CREATE TYPE products_list AS TABLE (ProductID INT)
GO

CREATE PROCEDURE set_discontinued_date @products_to_discontinue products_list READONLY, @discontinued_since DATE
AS BEGIN
    DECLARE @number_of_products_with_discontinued_date_set INT =
    (
        SELECT COUNT(Products.ProductID) 
        FROM @products_to_discontinue AS Products
           JOIN SalesLT.Product ON SalesLT.Product.ProductID = Products.ProductID
        WHERE SalesLT.Product.DiscontinuedDate IS NOT NULL
    )

    IF @number_of_products_with_discontinued_date_set > 0 BEGIN;
        THROW 50000, 'Some products have DiscontinuedDate set, changes will not be applied', 0
    END

    ELSE BEGIN
        UPDATE SalesLT.Product
        SET Product.DiscontinuedDate = @discontinued_since
        WHERE Product.ProductID IN (SELECT * FROM @products_to_discontinue) AND Product.DiscontinuedDate IS NULL
    END
END
GO


DECLARE @products products_list
INSERT INTO @products VALUES (707)
DECLARE @now DATE
SET @now = GETDATE()
EXEC set_discontinued_date @products_to_discontinue=@products, @discontinued_since=@now

SELECT * FROM SalesLT.Product;