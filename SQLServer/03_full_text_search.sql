
---------------------------------------------------------------
-- Full-Text Search konfiguracja
---------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.fulltext_catalogs WHERE name = N'CoffeeCat')
    CREATE FULLTEXT CATALOG CoffeeCat;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = N'UX_ArticlesAboutCoffee_Id')
    CREATE UNIQUE INDEX UX_ArticlesAboutCoffee_Id ON dbo.ArticlesAboutCoffee(id);
GO

IF NOT EXISTS (SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'dbo.ArticlesAboutCoffee'))
BEGIN
    CREATE FULLTEXT INDEX ON dbo.ArticlesAboutCoffee
    (
        title LANGUAGE 1045,
        body  LANGUAGE 1045
    )
    KEY INDEX UX_ArticlesAboutCoffee_Id
    ON CoffeeCat
    WITH CHANGE_TRACKING AUTO;
END
GO



---------------------------------------------------------------
-- FULL-TEXT, semantyczne wyszukiwanie
---------------------------------------------------------------
PRINT N'FTS: zawiera słowo kawa';
SELECT d.id, d.title, k.rank
FROM CONTAINSTABLE(dbo.ArticlesAboutCoffee, (title, body), N'kawa') AS k
JOIN dbo.ArticlesAboutCoffee d ON d.id = k.[KEY]
ORDER BY k.rank DESC;

PRINT N'FTS: espresso OR kawa';
SELECT  d.id, d.title,k.rank
FROM CONTAINSTABLE(dbo.ArticlesAboutCoffee, (title, body), N'("espresso" OR "kawa")') AS k
JOIN dbo.ArticlesAboutCoffee d ON d.id = k.[KEY];

PRINT N'FTS: zapytanie naturalne';
SELECT d.id, d.title,k.rank
FROM FREETEXTTABLE(dbo.ArticlesAboutCoffee, (title, body), N'jak zaparzyć kawę') AS k
JOIN dbo.ArticlesAboutCoffee d ON d.id = k.[KEY]
ORDER BY k.rank DESC;


SELECT TOP 10 d.id, d.title, k.rank
FROM CONTAINSTABLE(
    dbo.ArticlesAboutCoffee, (title, body),
    N'"jak prawidłowo parzyć kawę"'
) AS k
JOIN dbo.ArticlesAboutCoffee d ON d.id = k.[KEY]
ORDER BY k.rank DESC;

-- FTS: zapytanie naturalne 
SELECT TOP 10 d.id, d.title, k.rank
FROM FREETEXTTABLE(
    dbo.ArticlesAboutCoffee, (title, body),
    N'jak prawidłowo parzyć kawę'
) AS k
JOIN dbo.ArticlesAboutCoffee d ON d.id = k.[KEY]
ORDER BY k.rank DESC;