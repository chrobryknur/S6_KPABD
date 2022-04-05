DROP TABLE IF EXISTS products
CREATE TABLE products
(
	Id INT PRIMARY KEY,
	Name VARCHAR(50) NOT NULL,
	ItemsinStock INT NOT NULL

)

INSERT into products

VALUES 
(1, 'Laptop', 12),
(2, 'iPhone', 15),
(3, 'Tablets', 10)


SELECT * FROM products
