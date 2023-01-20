-- Для примеров используется БД WideWorldImporters 
-- https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

-- -------------------------------------------------
-- tSQLt install
-- -------------------------------------------------

-- 1) Скачать https://tsqlt.org/downloads/ 

-- 2) Разрешить CLR и включить свойство TRUSTWORTHY

EXEC sp_configure 'clr enabled', 1;
RECONFIGURE;

GO
EXEC sp_configure 'clr enabled';

ALTER DATABASE WideWorldImporters SET TRUSTWORTHY ON;
GO

-- 3) Выполнить из скачанного архива файл tSQLt.class.sql 


-- ХП в схеме tSQLt

-- SSMS: <DB> \ Programmability \ Stored Procedures \ tSQLt.*

USE WideWorldImporters;

SELECT * 
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_SCHEMA = 'tSQLt'
ORDER BY ROUTINE_NAME;
