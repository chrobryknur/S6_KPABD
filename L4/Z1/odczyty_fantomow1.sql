SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
--SET TRANSACTION ISOLATION LEVEL READ REPEATABLE;

BEGIN TRANSACTION
SELECT * FROM products WHERE Id=1
WAITFOR DELAY '00:00:10'
SELECT * FROM products WHERE Id=1
COMMIT