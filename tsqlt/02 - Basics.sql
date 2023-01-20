-- Примеры на основе https://www.sqlshack.com/sql-unit-testing-with-the-tsqlt-framework-for-beginners/

USE WideWorldImporters
GO

-- Тесты группируются в "классы" TestClass
EXEC tSQLt.NewTestClass 'DemoUnitTestClass';

-- Список классов:
SELECT * FROM tSQLt.TestClasses;


-- Класс - это схема в БД, в которой создаются тесты в виде хранимых процедур
-- <DB> \ Security \ Schemas

SELECT SCHEMA_NAME, objtype, name, value 
FROM INFORMATION_SCHEMA.SCHEMATA SC
CROSS APPLY fn_listextendedproperty (NULL, 'schema', NULL, NULL, NULL, NULL, NULL) OL
WHERE OL.objname = SC.SCHEMA_NAME COLLATE Latin1_General_CI_AI;

-- Удаление класса и связанных тестов
-- EXEC tSQLt.DropClass 'DemoUnitTestClass'

-- Функция, которую тестируем
CREATE OR ALTER FUNCTION CalculateTaxAmount(@amt MONEY)
RETURNS MONEY
AS BEGIN
  RETURN (@amt /100) * 18;
END;
GO
 
-- Проверим работу
SELECT dbo.CalculateTaxAmount(100) AS TaxAmount
GO

-- Пишем тест
-- Паттерн AAA (Arrange, Act, Assert)
CREATE OR ALTER PROC DemoUnitTestClass.[Test tax amount]
AS
BEGIN
    -- Arrange (инициализация)
	DECLARE @TestedAmount AS MONEY = 100;
	DECLARE @Expected AS MONEY = 18;
	DECLARE @Actual AS MONEY;

	-- Act (выполнение действий)
	SET @Actual = dbo.CalculateTaxAmount(100);
 
	-- Assert (проверка)
	EXEC tSQLt.AssertEquals @Expected, @Actual;
END


-- Запуск всех тестов
EXEC tSQLt.Run

-- Запуск всех тестов в классе
EXEC tSQLt.Run 'DemoUnitTestClass';

-- Запуск конкретного теста
EXEC tSQLt.Run 'DemoUnitTestClass.[Test tax amount]';

-- Результаты выполнения тестов записываются в таблицу
SELECT * FROM tSQLt.TestResult;

-- В виде XML
EXEC tSQLt.XmlResultFormatter;

-- Сломаем тестируемую функцию
CREATE OR ALTER FUNCTION CalculateTaxAmount(@amt MONEY)
RETURNS MONEY
AS BEGIN
  RETURN (@amt /1000) * 18;
END;

-- Запускаем тест
EXEC tSQLt.Run;
SELECT * FROM tSQLt.TestResult;