-- Problem 01. Create Databse
CREATE DATABASE Bank
COLLATE Cyrillic_General_100_CI_AI

USE Bank


-- Problem 02. Create Tables
CREATE TABLE Clients (
	ClientId INT IDENTITY(1, 1),
	FirstName NVARCHAR(50) NOT NULL,
	LastName NVARCHAR(50) NOT NULL,

	CONSTRAINT PK_ClientId
	PRIMARY KEY (ClientId)
)

CREATE TABLE AccountTypes (
	AccountTypeId INT IDENTITY(1, 1),
	Name NVARCHAR(50) NOT NULL,

	CONSTRAINT PK_AccountTypeId
	PRIMARY KEY (AccountTypeId)
)

CREATE TABLE Accounts (
	AccountId INT IDENTITY(1, 1),
	AccountTypeId INT,
	ClientId INT,
	Balance DECIMAL(15, 2) NOT NULL DEFAULT(0),

	CONSTRAINT PK_AccountId
	PRIMARY KEY (AccountId),

	CONSTRAINT FK_Accounts_AccountTypes
	FOREIGN KEY (AccountTypeId)
	REFERENCES AccountTypes(AccountTypeId),

	CONSTRAINT PK_Accounts_Clients
	FOREIGN KEY (ClientId)
	REFERENCES Clients(ClientId)
)


-- Problem 03. Insert Data
INSERT INTO Clients (FirstName, LastName) VALUES
('Gosho', 'Ivanov'),
('Pesho', 'Petrov'),
('Ivan', 'Iliev'),
('Merry', 'Ivanova')

INSERT INTO AccountTypes (Name) VALUES
('Checking'),
('Savings')

INSERT INTO Accounts (ClientId, AccountTypeId, Balance) VALUES
(1, 1, 175),
(2, 1, 275.56),
(3, 1, 138.01),
(4, 1, 40.30),
(4, 2, 375.50)
GO


-- Problem 04. Create View
CREATE VIEW v_ClientBalances 
AS
		SELECT (c.FirstName + ' ' + c.LastName) AS [Name], 
			   act.Name AS [Account Type],
			   a.Balance
		  FROM Clients AS c
	INNER JOIN Accounts AS a
			ON a.ClientId = c.ClientId
	INNER JOIN AccountTypes AS act
			ON act.AccountTypeId = a.AccountTypeId
GO


-- Problem 05. Create Function
CREATE FUNCTION f_CalculateTotalBalance (@ClientId INT)
RETURNS DECIMAL(15, 2)
BEGIN
	DECLARE @Result AS DECIMAL (15, 2) = (
		SELECT SUM(Balance)
		  FROM Accounts
		 WHERE ClientId = @ClientId
	)
	RETURN @Result
END
GO


-- Problem 06. Create Procedures
CREATE PROC p_AddAccount @ClientId INT, @AccountTypeId INT 
AS
INSERT INTO Accounts (ClientId, AccountTypeId)
	 VALUES (@ClientId, @AccountTypeId)
GO

CREATE PROC p_Deposit @AccountId INT, @Amount DECIMAL(15, 2)
AS
UPDATE Accounts
   SET Balance += @Amount
 WHERE AccountId = @AccountId
GO

CREATE PROC p_Withdraw @AccountId INT, @Amount DECIMAL(15, 2)
AS
BEGIN
	DECLARE @OldBalance DECIMAL(15, 2)

	SELECT @OldBalance = Balance
	  FROM Accounts
	 WHERE ClientId = @AccountId
	IF (@OldBalance - @Amount >= 0)
	BEGIN
		UPDATE Accounts
		   SET Balance -= @Amount
		 WHERE AccountId = @AccountId
	END
	ELSE
	BEGIN
		RAISERROR('Insufficient funds', 10, 1)
	END
END
GO


-- Problem 07. Create Transactions Table and a Trigger
CREATE TABLE Transactions (
	Id INT IDENTITY(1, 1),
	AccountId INT,
	OldBalance DECIMAL(15, 2) NOT NULL,
	NewBalance DECIMAL(15, 2) NOT NULL,
	Amount AS NewBalance - OldBalance,
	DateTime DATETIME2,

	CONSTRAINT PK_Id
	PRIMARY KEY (Id),

	CONSTRAINT FK_Transactions_Accounts
	FOREIGN KEY (AccountId)
	REFERENCES Accounts(AccountId)
)
GO

CREATE TRIGGER tr_Transaction ON Accounts
AFTER UPDATE
AS
	INSERT INTO Transactions (AccountId, OldBalance, NewBalance, DateTime)
		 SELECT inserted.ClientId, 
				deleted.Balance, 
				inserted.Balance, 
				GETDATE()
		   FROM inserted
		   JOIN deleted 
		     ON inserted.AccountId = deleted.AccountId
GO

EXEC p_Deposit 1, 25
EXEC p_Deposit 1, 40.00
EXEC p_Withdraw 2, 200.00
EXEC p_Deposit 4, 180.00