SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN Transaction

UPDATE products set ItemsInStock = 11
WHERE Id = 1

-- Billing the customer
WaitFor Delay '00:00:10'
Rollback Transaction