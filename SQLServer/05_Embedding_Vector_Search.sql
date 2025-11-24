
---------------------------------------------------------------
-- Embeddings i Vector Search
---------------------------------------------------------------
-- Aktywacja funkcji preview na poziomie bazy
ALTER DATABASE SCOPED CONFIGURATION SET PREVIEW_FEATURES = ON;
GO

-- Utworzenie Master Key (tylko raz na bazę), wymagany dla credentials
IF NOT EXISTS (SELECT 1 FROM sys.symmetric_keys WHERE name='##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = N'ZmienToNaSilneHaslo#2025!';
    ALTER MASTER KEY ADD ENCRYPTION BY SERVICE MASTER KEY;
END
GO


IF EXISTS (SELECT 1 FROM sys.database_scoped_credentials
           WHERE name = N'https://ai-copilot-sql-srv.openai.azure.com/')
    DROP DATABASE SCOPED CREDENTIAL [https://ai-copilot-sql-srv.openai.azure.com/];
GO


CREATE DATABASE SCOPED CREDENTIAL [https://ai-copilot-sql-srv.openai.azure.com/]
WITH IDENTITY = 'HTTPEndpointHeaders',
     SECRET   = '{"api-key":"<YOUR_API_KEY>"}';
GO


CREATE EXTERNAL MODEL OpenAIEmbedding
WITH (
  LOCATION   = 'https://ai-copilot-sql-srv.openai.azure.com/openai/deployments/text-embedding-ada-002/embeddings?api-version=2023-05-15',
  API_FORMAT = 'Azure OpenAI',
  MODEL_TYPE = EMBEDDINGS,
  MODEL      = 'text-embedding-ada-002',
  CREDENTIAL = [https://ai-copilot-sql-srv.openai.azure.com/]
);
GO


WITH todo AS (
        SELECT TOP 15
               a.id,
              CONCAT(
                     'title:', a.title, ' | ',
                     'type:', a.type, ' | ',
                     'name:', a.name, ' | ',
                     'short_description:', a.short_description, ' | ',
                     'body:', a.body, ' | ',
                     'website:', a.website
                    ) AS doc_text
        FROM dbo.ArticlesAboutCoffee a
        WHERE a.embedding IS NULL
        ORDER BY a.id
    )
    UPDATE a
       SET a.embedding = AI_GENERATE_EMBEDDINGS(todo.doc_text USE MODEL OpenAIEmbedding)
    FROM dbo.ArticlesAboutCoffee AS a
    JOIN todo ON todo.id = a.id
 






PRINT N'Generuję embeddingi dla rekordów bez wektora';

SELECT * FROM dbo.ArticlesAboutCoffee

-- Podgląd dokumentu wejściowego (opcjonalnie):
SELECT 
       CONCAT(
         'title:', title, ' | ',
         'type:', type, ' | ',
         'name:', name, ' | ',
         'short_description:', short_description, ' | ',
         'body:', body, ' | ',
         'website:', website
       ) AS doc_text,embedding
FROM dbo.ArticlesAboutCoffee
WHERE embedding is null


WITH todo AS (
        SELECT 
               a.id,
              CONCAT(
                     'title:', a.title, ' | ',
                     'type:', a.type, ' | ',
                     'name:', a.name, ' | ',
                     'short_description:', a.short_description, ' | ',
                     'body:', a.body, ' | ',
                     'website:', a.website
                    ) AS doc_text
        FROM dbo.ArticlesAboutCoffee a
        WHERE a.embedding IS NULL
    )
    UPDATE a
       SET a.embedding = AI_GENERATE_EMBEDDINGS(todo.doc_text USE MODEL OpenAIEmbedding)
    FROM dbo.ArticlesAboutCoffee AS a
    JOIN todo ON todo.id = a.id
 

CREATE VECTOR INDEX VX_Articles_Embedding
    ON dbo.ArticlesAboutCoffee(embedding)
    WITH (METRIC = 'cosine', TYPE = 'diskann');
GO

DECLARE @q NVARCHAR(MAX) = N'Jak prawidlowo zaparzyć kawę ?';
DECLARE @qvec VECTOR(1536) = AI_GENERATE_EMBEDDINGS(@q USE MODEL OpenAIEmbedding);

SELECT @q,@qvec


PRINT N'VECTOR exact';
SELECT TOP 5 id, title, VECTOR_DISTANCE('cosine', embedding, @qvec) AS dist
FROM dbo.ArticlesAboutCoffee
ORDER BY dist ASC;


PRINT N'VECTOR ANN';
SELECT t.id,t.title,s.distance
FROM VECTOR_SEARCH(
    TABLE = dbo.ArticlesAboutCoffee AS t,
    COLUMN = embedding,
    SIMILAR_TO = @qvec,
    METRIC = 'cosine',
    TOP_N = 5
) AS s

