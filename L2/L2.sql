--Zad1
/*
 Utworzyć funkcję w T-SQL, która jako parametr bierze liczbę dni, a w wyniku zwraca tabelę (PESEL, LiczbaEgzemplarzy), która zawiera listę czytelników przechowujących co najmniej jeden egzemplarz jakiekolwiek książki
niekrócej niż liczba dni określona w parametrze. W drugiej kolumnie należy dołączyć liczbę przetrzymywanych
egzemplarzy.
*/

DROP FUNCTION IF EXISTS Zad1
GO

CREATE FUNCTION Zad1(@Dni INT) RETURNS @Wynik TABLE(PESEL CHAR(11), Egzemplarze INT)
BEGIN
    DECLARE @now DATETIME
    SET @now = '2020-02-13'

    INSERT INTO @Wynik
        SELECT c.PESEL, COUNT(DISTINCT w2.Wypozyczenie_ID)
        FROM Czytelnik c
            JOIN Wypozyczenie w1 ON c.Czytelnik_ID = w1.Czytelnik_ID
            JOIN Wypozyczenie w2 ON c.Czytelnik_ID = w2.Czytelnik_ID
        WHERE
            w1.Data <= @now
            AND DATEADD(day, w1.Liczba_Dni, w1.Data) > @now
            AND DATEDIFF(day, w1.Data, @now) >= @Dni
        GROUP BY c.PESEL, c.Czytelnik_ID
    RETURN
END
GO

SELECT * FROM Zad1(4)

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

DECLARE @i INT
SET @i = 0
WHILE (@i < 50)
BEGIN
  INSERT INTO imiona VALUES (@i, NEWID())
  INSERT INTO nazwiska VALUES (@i, NEWID())
  SET @i=@i+1
END;

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
EXEC generuj_dane @n=300
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
    ( ( CAST(SUBSTRING(@PESEL,1,1) AS BIGINT)*9)
    +(CAST(SUBSTRING(@PESEL,2,1) AS BIGINT)*7)
    +(CAST(SUBSTRING(@PESEL,3,1) AS BIGINT)*3)
    +(CAST(SUBSTRING(@PESEL,4,1) AS BIGINT)*1)
    +(CAST(SUBSTRING(@PESEL,5,1) AS BIGINT)*9)
    +(CAST(SUBSTRING(@PESEL,6,1) AS BIGINT)*7)
    +(CAST(SUBSTRING(@PESEL,7,1) AS BIGINT)*3)
    +(CAST(SUBSTRING(@PESEL,8,1) AS BIGINT)*1)
    +(CAST(SUBSTRING(@PESEL,9,1) AS BIGINT)*9)
    +(CAST(SUBSTRING(@PESEL,10,1) AS BIGINT)*7) ) % 10
    = RIGHT(@PESEL,1) AND LEN(@PESEL) = 11 )
    BEGIN
        return 1
    END
    return 0
END
GO

SELECT [dbo].[validate_pesel] ('97060852597')
SELECT [dbo].[validate_pesel] ('970608525')

DROP FUNCTION IF EXISTS validate_lastname
GO

CREATE FUNCTION validate_lastname(@lastname VARCHAR(255)) RETURNS BIT AS
BEGIN
    IF(LEN(@lastname) >= 2 AND UNICODE(LEFT(@lastname, 1)) <> UNICODE(LOWER(LEFT(@lastname,1)))) RETURN 1
    RETURN 0
END
GO

SELECT [dbo].[validate_lastname] ('dabrowsk')
SELECT [dbo].[validate_lastname] ('Dabrowsk')
SELECT [dbo].[validate_lastname] ('Da')
SELECT [dbo].[validate_lastname] ('D')

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

DECLARE @MyBirthday AS DATETIME 
SET @MyBirthday = '1997/06/08'

SELECT [dbo].[validate_birthday] ('97060852597', @MyBirthday);
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

EXEC insert_reader @PESEL='97060852597', @lastname='Dabrowski', @city='Wroclaw', @birthday='1997/06/08';

SELECT * FROM Czytelnik;

--Zad4
/*
Utworzyć procedurę, która jako parametr bierze tabelę (czytelnik id) identyfikatorów czytelników, a jako wynik
zwraca tabelę o dwóch kolumnach (czytelnik id,suma dni), gdzie dla każdego przekazanego czytelnika dołączona
jest sumaryczna liczba dni, na którą dany czytelnik wypożyczył książki.
*/

DROP PROCEDURE IF EXISTS get_borrow_days
DROP TYPE IF EXISTS input_table
GO

CREATE TYPE input_table AS TABLE (reader_id INT)
GO

CREATE PROCEDURE get_borrow_days
    @input input_table READONLY
AS BEGIN
    SELECT c.Czytelnik_ID AS reader_id,
        SUM(w.Liczba_Dni) AS sum_days
    FROM Czytelnik c
    JOIN Wypozyczenie w ON c.Czytelnik_ID = w.Czytelnik_ID
    WHERE c.Czytelnik_ID IN (SELECT * FROM @input)
    GROUP BY c.Czytelnik_ID
END
GO

DECLARE @i input_table
INSERT INTO @i VALUES (1), (2), (3)
EXEC get_borrow_days @input=@i

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

CREATE TYPE products_list AS TABLE (product_id INT)
GO

CREATE PROCEDURE set_discontinued_date 
    @products_to_discontinue products_list READONLY, @discontinued_since DATE
AS BEGIN
    UPDATE SalesLT.Product
    SET Product.DiscontinuedDate = @discontinued_since
    WHERE Product.ProductID IN (SELECT * FROM @products_to_discontinue) AND Product.DiscontinuedDate IS NULL

    SELECT * FROM @products_to_discontinue
END
GO


DECLARE @products products_list
INSERT INTO @products VALUES (680), (706)
DECLARE @now DATE
SET @now = GETDATE()
EXEC set_discontinued_date @products_to_discontinue=@products, @discontinued_since=@now

SELECT * FROM SalesLT.Product;