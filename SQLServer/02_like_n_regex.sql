---------------------------------------------------------------
-- LIKE, proste dopasowania
---------------------------------------------------------------
PRINT N'LIKE: espresso w treści';
SELECT id, title FROM dbo.ArticlesAboutCoffee WHERE body LIKE N'%espresso%';

PRINT N'LIKE: słowo kawa w tytule';
SELECT id, title FROM dbo.ArticlesAboutCoffee WHERE title LIKE N'%kawa%';

PRINT N'LIKE: mielenie w treści';
SELECT id, title FROM dbo.ArticlesAboutCoffee WHERE body LIKE N'%mielen%';

-- Wyszukiwanie frazy: Jak prawidlowo parzyc kawe ?

PRINT N'LIKE: szukamy w body';
SELECT id, title FROM dbo.ArticlesAboutCoffee 
WHERE body COLLATE Latin1_General_CI_AS LIKE N'%jak%prawidłowo%parzyć%kawę%';

PRINT N'LIKE: szukamy w tytule';
SELECT id, title FROM dbo.ArticlesAboutCoffee 
WHERE title COLLATE Latin1_General_CI_AS LIKE N'%jak%prawidłowo%parzyć%kawę%';





---------------------------------------------------------------
-- 3. REGEXP, wyrażenia regularne
---------------------------------------------------------------
PRINT N'REGEXP: dokładne słowo espresso (granice słów)';
SELECT id, title,
       REGEXP_SUBSTR(body, N'\bespresso\b', 1, 1, 'i') AS first_espresso
FROM dbo.ArticlesAboutCoffee
WHERE REGEXP_LIKE(body, N'\bespresso\b', 'i');

PRINT N'REGEXP: zestaw metod parzenia (pierwsze dopasowanie)';
SELECT id, title,
       REGEXP_SUBSTR(body, N'(espresso|aeropress|french press|chemex|v60|moka)', 1, 1, 'i') AS first_method
FROM dbo.ArticlesAboutCoffee
WHERE REGEXP_LIKE(body, N'(espresso|aeropress|french press|chemex|v60|moka)', 'i');

PRINT N'REGEXP: policz liczbę wystąpień słowa kawa';
SELECT id, title,
       (LEN(body) - LEN(REGEXP_REPLACE(body, N'kawa', N''))) / LEN(N'kawa') AS coffee_mentions
FROM dbo.ArticlesAboutCoffee;


-- REGEXP: body, odporne na nowe linie i ogonki
SELECT id, title
FROM dbo.ArticlesAboutCoffee
WHERE REGEXP_LIKE(body, N'(jak|prawidlowo|parzyc|kawe|)', 'i');


-- REGEXP: title, to samo podejście
-- dokładna fraza w tytule
SELECT id, title
FROM dbo.ArticlesAboutCoffee
WHERE REGEXP_LIKE(
    title COLLATE Polish_100_CI_AI,
    N'Jak prawidłowo parzyć kawę'
);

