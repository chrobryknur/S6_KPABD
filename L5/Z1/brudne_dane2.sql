SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- NOK
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED; - OK
-- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; - OK
-- SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; - OK

SELECT * FROM products
WHERE Id = 1;