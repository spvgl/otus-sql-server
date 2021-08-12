CREATE DATABASE otus_demo;
GO

USE otus_demo;
GO

CREATE TABLE Products (
    ID INT PRIMARY KEY IDENTITY,
    Name nvarchar(100)
);
GO