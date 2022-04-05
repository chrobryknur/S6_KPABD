--Zad 1
/*
Dane są tabele:
• Towary(ID, NazwaTowaru),
• Ceny(TowarID REF Towary(ID), Waluta REF Kursy(Waluta), Cena),
• Kursy(Waluta, CenaPLN).
Należy zwrócić uwagę, że towar może nie mieć podanej ceny we wszystkich walutach, ale zawsze ma podaną cenę
w PLN (jest to punkt odniesienia). Zadaniem jest przygotowanie wsadu, który zaktualizuje ceny w tabeli Ceny
na podstawie tabeli Kursy, przy czym może się zdarzyć, że w tabeli Ceny będzie odniesienie do waluty, której
kursu w tabeli Kursy już nie ma, i o taką sytuację również należy zadbać.
Przy realizacji tego zadania należy wykorzystać mechanizm kursorów.
*/

DROP TABLE IF EXISTS Ceny
DROP TABLE IF EXISTS Towary
DROP TABLE IF EXISTS Kursy
DROP PROCEDURE IF EXISTS update_prices

CREATE TABLE Towary
(
    ID INT PRIMARY KEY,
    NazwaTowaru VARCHAR(64) NOT NULL
)

INSERT INTO Towary VALUES
    (1, 'Laptop'),
    (2, 'Telefon'),
    (3, 'Lodówka')

CREATE TABLE Kursy
(
    Waluta VARCHAR(8) PRIMARY KEY,
    CenaPLN MONEY NOT NULL
)

INSERT INTO Kursy VALUES
    ('PLN', 1.00),
    ('EUR', 4.60),
    ('USD', 3.95),
    ('RUB', 0.01)

CREATE TABLE Ceny
(
    TowarID INT NOT NULL,
    Waluta VARCHAR(8) NOT NULL,
    Cena MONEY NOT NULL,

    CONSTRAINT FK_Ceny_TowarID
        FOREIGN KEY (TowarID)
        REFERENCES Towary (ID),
)

INSERT INTO Ceny VALUES
    (1, 'PLN', 5000),
    (1, 'EUR', 1100),
    (2, 'PLN', 800),
    (2, 'USD', 200),
    (3, 'PLN', 200),
    (3, 'RUB', 15000)
GO

CREATE PROCEDURE update_prices AS BEGIN
    DECLARE C_Ceny CURSOR FOR SELECT TowarID, Waluta, Cena FROM Ceny
    DECLARE @ID INT, @WALUTA VARCHAR(8), @CENA MONEY, @KURS_PLN MONEY, @CENA_PLN MONEY
    OPEN C_Ceny
    FETCH NEXT FROM C_Ceny INTO @ID, @WALUTA, @CENA
    WHILE (@@FETCH_STATUS = 0)
    BEGIN
        IF (@WALUTA = 'PLN')
        BEGIN
            FETCH NEXT FROM C_Ceny INTO @ID, @WALUTA, @CENA
            CONTINUE
        END

        IF (@WALUTA NOT IN (SELECT Waluta FROM Kursy))
        BEGIN
            PRINT 'Brak waluty ' + @WALUTA + ' w tabeli Kursy, Cena zostanie usunięta'
            DELETE FROM Ceny WHERE CURRENT OF C_Ceny
            FETCH NEXT FROM C_Ceny INTO @ID, @WALUTA, @CENA
            CONTINUE
        END

        SET @KURS_PLN = (SELECT CenaPLN
            FROM Kursy
            WHERE Kursy.Waluta = @WALUTA)

        SET @CENA_PLN = NULL
        SELECT @CENA_PLN = Cena
            FROM Ceny
            WHERE Ceny.TowarID = @ID AND Ceny.Waluta = 'PLN'
        IF (@CENA_PLN IS NULL) THROW 50000, 'Nie podano ceny w PLN', 0

        UPDATE Ceny SET Cena=(@CENA_PLN / @KURS_PLN) WHERE CURRENT OF C_Ceny

        FETCH NEXT FROM C_Ceny INTO @ID, @WALUTA, @CENA
    END

    CLOSE C_Ceny
    DEALLOCATE C_Ceny
END
GO

SELECT * FROM Ceny

EXEC [dbo].[update_prices]
SELECT * FROM Ceny

DELETE FROM Kursy WHERE Waluta = 'RUB'
EXEC [dbo].[update_prices]
SELECT * FROM Ceny

--Zad2

/*
Utworzyć tabele Employees(ID, SalaryGros) oraz SalaryHistory(ID, EmployeeID, Year, Month, SalaryNet, SalaryGros). Napisać procedurę, która jako parametr dostaje nr miesiąca, a następnie dla podanego miesiąca roku
wylicza pensje do wypłaty. Wyliczenie pensji do wypłaty powinno uwzględnić następujące elementy:
• bieżącą pensję (Employees.SalaryGros),
• wszystkie poprzednie pensje w danym roku, aby wyliczyć zaliczkę na podatek, którą trzeba odprowadzić,
• podatek uzględniający odpowiedni próg podatkowy: 17% dla dochodów do 120000 zł rocznie, 15300 + 32%
od nadwyżki ponad 120000 zł dla dochodów wyższych.
Dodatkowo powinna być utworzona tabela z logiem, w której będzie informacja o przypadkach, dla których
pensji nie udało się policzyć (np. z powodu braku pensji w jednym z miesięcy w roku).
Przy realizacji tego zadania należy wykorzystać mechanizm kursorów.
Uwaga: należy się zastanowić, czy nie warto w tabeli SalaryHistory zmienić nieco schematu.
*/

DROP TABLE IF EXISTS SalaryHistory;
DROP TABLE IF EXISTS Exceptions;
DROP TABLE IF EXISTS Employees;

CREATE TABLE Employees
(
    EmployeeID INT PRIMARY KEY,
    SalaryGross MONEY
);

CREATE TABLE SalaryHistory
(
    ID INT IDENTITY(1,1) PRIMARY KEY,
    EmployeeID INT,
    Year INT,
    Month INT,
    SalaryNet MONEY,
    SalaryGross MONEY

    CONSTRAINT FK_SalaryHistory_Employees
        FOREIGN KEY (EmployeeID)
        REFERENCES Employees(EmployeeID)
);

CREATE TABLE Exceptions
(
    EmployeeID INT,
    Month INT,
    Year INT

    CONSTRAINT FK_Exceptions_Employees
        FOREIGN KEY (EmployeeID)
        REFERENCES Employees(EmployeeID)
)

DROP PROCEDURE IF EXISTS calculate_salary
GO

CREATE PROCEDURE calculate_salary @MONTH INT, @YEAR INT AS
BEGIN
    DECLARE @EMPLOYEE_ID INT, @SALARY_GROSS MONEY

    DECLARE C_Employee CURSOR FOR SELECT EmployeeID, SalaryGross FROM Employees
    OPEN C_Employee
    FETCH NEXT FROM C_Employee INTO @EMPLOYEE_ID, @SALARY_GROSS
    WHILE (@@FETCH_STATUS = 0)
    BEGIN
        DECLARE @CURRENT_SALARY MONEY, @SALARY_SUM MONEY, @MONTH_COUNT INT, @TAX MONEY
        SET @CURRENT_SALARY = (SELECT SalaryGross FROM Employees WHERE EmployeeID = @EMPLOYEE_ID);

        SELECT @SALARY_SUM = SUM(SalaryGross), @MONTH_COUNT = COUNT(ISNULL(Month, 0)) 
        FROM SalaryHistory
        WHERE EmployeeID = @EMPLOYEE_ID AND Month < @MONTH AND Year = @YEAR;

		SET @SALARY_SUM = ISNULL(@SALARY_SUM, 0)
        
        SET @SALARY_SUM = @SALARY_SUM + @CURRENT_SALARY

        IF (@MONTH_COUNT <> @MONTH - 1)
        BEGIN
            PRINT 'Calculating salary for an employee failed'
            INSERT INTO Exceptions VALUES (@EMPLOYEE_ID, @MONTH, @YEAR)
            FETCH NEXT FROM C_Employee INTO @EMPLOYEE_ID, @SALARY_GROSS
            CONTINUE;
        END

        IF (@SALARY_SUM <= 120000)
        BEGIN
            SET @TAX = @CURRENT_SALARY * 0.17
        END
        ELSE BEGIN
            SET @TAX = 120000 * 0.17 + (@SALARY_SUM - 120000) * 0.32
        END

        UPDATE SalaryHistory SET SalaryNet = @CURRENT_SALARY - @TAX, SalaryGross = @CURRENT_SALARY
        WHERE Month = @MONTH AND Year = @YEAR AND EmployeeID = @EMPLOYEE_ID

        FETCH NEXT FROM C_Employee INTO @EMPLOYEE_ID, @SALARY_GROSS
    END
    CLOSE C_Employee
    DEALLOCATE C_Employee
END
GO

INSERT INTO Employees VALUES
    (1, 2000),
    (2, 500000)

INSERT INTO SalaryHistory
    (EmployeeId, Year, Month, SalaryNet, SalaryGross)
VALUES
    (1, 2022, 1, 2500, 3000),
    (1, 2022, 2, null, null),
    (1, 2022, 3, null, null),
    (1, 2022, 4, null, null),

    (2, 2022, 1, null, 30000),
    (2, 2022, 3, null, null),
    (2, 2022, 4, null, null)

EXEC [dbo].[calculate_salary] @MONTH=2, @YEAR=2022
SELECT * FROM SalaryHistory;
EXEC [dbo].[calculate_salary] @MONTH=3, @YEAR=2022
SELECT * FROM SalaryHistory;
EXEC [dbo].[calculate_salary] @MONTH=4, @YEAR=2022

SELECT * FROM SalaryHistory;
SELECT * FROM Exceptions;
