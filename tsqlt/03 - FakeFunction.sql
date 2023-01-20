-- -------------------------------------------------
-- tSQLt.FakeFunction
-- -------------------------------------------------
-- На основе https://www.sqlshack.com/how-to-use-fake-functions-with-sql-unit-testing/

-- Таблица для примера, в которую будем вставлять записи
DROP TABLE IF EXISTS OrderOnline;
GO

CREATE TABLE OrderOnline
(
    Id INT PRIMARY KEY IDENTITY(1,1),
    OrderName VARCHAR(100),
    CustomerName VARCHAR(100)
);
GO

-- Функция, для которой потом напишем заглушку
CREATE OR ALTER FUNCTION dbo.UDefFuncOddorEven (@n int)
 RETURNS bit
 AS
 BEGIN
    DECLARE @ModuleRes INT;
    SET @ModuleRes = (@n % 9);
   
    RETURN (@ModuleRes % 2);
 END
 
-- Хранимая процедура, которую надо протестировать
CREATE OR ALTER PROCEDURE SetOrders
  @OName AS VARCHAR(100),
  @CName AS VARCHAR(100)
AS
BEGIN
  DECLARE @RandomVal AS INT;
  SET @RandomVal = FLOOR(RAND()*1000);
  DECLARE @ufResult AS BIT;
  SELECT @ufResult = dbo.UDefFuncOddorEven(@RandomVal);
  IF @ufResult = 1
  BEGIN
   -- Надо протестировать этот INSERT,
   -- но попадем мы в него или нет зависит от dbo.UDefFuncOddorEven()
   INSERT INTO OrderOnline (OrderName, CustomerName) VALUES (@OName,@CName);
  END
END
GO

-- Пишем обычный тест 
EXECUTE tSQLt.NewTestClass 'TestFakeFunction';
GO

CREATE OR ALTER PROCEDURE TestFakeFunction.[Test SetOrders_StoredProcedure_InsertFunction]
AS
BEGIN

  DROP TABLE IF EXISTS expected;
  DROP TABLE IF EXISTS actual;
  
  EXEC tSQLt.FakeTable 'OrderOnline';
  
  SELECT TOP(0) * INTO expected FROM OrderOnline;
  SELECT TOP(0) * INTO actual FROM OrderOnline;

  INSERT INTO expected(OrderName , CustomerName)
  VALUES ('Pizza','Ryan Romero');

  EXECUTE SetOrders 'Pizza' ,'Ryan Romero';

  INSERT INTO actual
  SELECT * FROM OrderOnline;

  EXEC tSQLt.AssertEqualsTable expected, actual;

END
GO

-- Запускаем тест (то выполняется успешно, то падает)
EXEC tSQLt.Run 'TestFakeFunction.[Test SetOrders_StoredProcedure_InsertFunction]';
GO

-- Фейковая функция (заглушка)
CREATE OR ALTER FUNCTION dbo.UDefFuncOddorEven_Fake_Return_1 (@n int)
RETURNS bit
AS
BEGIN
  RETURN 1
END

-- Используем FakeFunction
CREATE OR ALTER PROCEDURE TestFakeFunction.[Test SetOrders_StoredProcedure_InsertFunction]
AS
BEGIN

	DROP TABLE IF EXISTS expected;
	DROP TABLE IF EXISTS actual;
 
	EXEC tSQLt.FakeTable 'OrderOnline';
 
	SELECT TOP(0) * INTO expected FROM OrderOnline;
	SELECT TOP(0) * INTO actual FROM OrderOnline;

	-- Добавили FakeFunction: 
	EXEC tSQLt.FakeFunction 'dbo.UDefFuncOddorEven', 'dbo.UDefFuncOddorEven_Fake_Return_1';

	INSERT INTO expected(OrderName , CustomerName)
	VALUES ('Pizza','Ryan Romero');

	EXECUTE SetOrders 'Pizza' ,'Ryan Romero';

	INSERT INTO actual
	SELECT * FROM OrderOnline;

	EXEC tSQLt.AssertEqualsTable expected, actual;

END
GO

-- Запускаем тест с фейковой функцией
EXEC tSQLt.Run 'TestFakeFunction.[Test SetOrders_StoredProcedure_InsertFunction]'
GO

-- Подчищать ничего не надо.
-- Тесты запускаются в рамках транзакции и все откатывается, 
-- в т.ч. FakeFunction

-- Попробуем сломать ХП и проверим тестом
CREATE OR ALTER PROCEDURE SetOrders
  @OName AS VARCHAR(100),
  @CName AS VARCHAR(100)
AS
BEGIN
  DECLARE @RandomVal AS INT 
  SET @RandomVal = FLOOR(RAND()*1000)
  DECLARE @ufResult AS BIT
  SELECT @ufResult = dbo.UDefFuncOddorEven(@RandomVal)
  IF @ufResult = 11
  BEGIN
   INSERT INTO OrderOnline (OrderName, CustomerName) VALUES (@OName,@CName)
  END
END
GO

EXEC tSQLt.Run 'TestFakeFunction.[Test SetOrders_StoredProcedure_InsertFunction]'
GO

-- -------------------------------------------------
-- tSQLt.ExpectException 
-- -------------------------------------------------

-- Успешное завершение теста - должна быть ошибка
-- Например, функция UDefFuncOddorEven должна работать только с числами больше нуля,
-- если передается меньше нуля, то должна быть ошибка.

-- Так мы проверим отсутсвие ошибок
CREATE OR ALTER PROCEDURE TestFakeFunction.[Test UDefFuncOddorEven_ErrorIfLessZero]
AS
BEGIN
  SELECT dbo.UDefFuncOddorEven(-10);
END
GO

EXECUTE tSQLt.Run 'TestFakeFunction.[Test UDefFuncOddorEven_ErrorIfLessZero]';
GO

-- Если ожидаем ошибку, то используем ExpectException
CREATE OR ALTER PROCEDURE TestFakeFunction.[Test UDefFuncOddorEven_ErrorIfLessZero]
AS
BEGIN
  EXEC tSQLt.ExpectException @ExpectedMessagePattern = '%Parameter @n must be > 0%';
  SELECT dbo.UDefFuncOddorEven(-10);
END
GO

-- Тест упадет "Expected an error to be raised"
EXEC tSQLt.Run 'TestFakeFunction.[Test UDefFuncOddorEven_ErrorIfLessZero]';
GO

-- Исправляем функцию
CREATE OR ALTER FUNCTION dbo.UDefFuncOddorEven (@n int)
 RETURNS bit
 AS
 BEGIN
    IF (@n < 0)
		 -- хак для выброса ошибки, т.к. в функции нельзя использовать RAISERROR, THROW
		 RETURN CAST('Parameter @n must be > 0' as int);

    DECLARE @ModuleRes INT;
    SET @ModuleRes = (@n % 9);
   
    RETURN (@ModuleRes % 2);
 END

-- Запускаем тест
EXEC tSQLt.Run 'TestFakeFunction.[Test UDefFuncOddorEven_ErrorIfLessZero]';
GO