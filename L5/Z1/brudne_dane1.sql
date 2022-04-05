SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; -- NOK
--SET TRANSACTION ISOLATION LEVEL READ COMMITTED; - OK
--SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; - OK
--SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; - OK

BEGIN Transaction

UPDATE products set ItemsInStock = 11
WHERE Id = 1

-- Billing the customer
WaitFor Delay '00:00:10'
Rollback Transaction