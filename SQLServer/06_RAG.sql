


---------------------------------------------------------------
--    RAG do OpenAI, prosty i użyteczny
--    Buduje kontekst z Vector Search i wysyła do chat completions
---------------------------------------------------------------


    --DECLARE @question NVARCHAR(MAX) =  N'Jak prawidlowo parzyc kawe?';
    DECLARE @question NVARCHAR(MAX) =  N'Opowiedz mi cos o Bielsku?';

    DECLARE @qvec VECTOR(1536) = AI_GENERATE_EMBEDDINGS(@question USE MODEL OpenAIEmbedding);

    --SELECT @qvec

    DROP TABLE IF EXISTS #ctx
    -- 1. top 5 dokumentów z wektorów
    SELECT TOP 5 t.id, t.title, t.short_description, t.body
    INTO #ctx
    FROM VECTOR_SEARCH(
        TABLE = dbo.ArticlesAboutCoffee AS t,
        COLUMN = embedding,
        SIMILAR_TO = @qvec,
        METRIC = 'cosine',
        TOP_N = 5
    ) s

    --select * from #ctx

    -- 2. budowa kontekstu
    DECLARE @context NVARCHAR(MAX) = (
        SELECT STRING_AGG(
            CONCAT(
                N'Tytuł: ', title, N' | Opis: ', short_description, N' | Treść: ',body,' #',id  
            ),
            N'\n---\n'
        )
        FROM #ctx
    );

   -- select @context

    -- Payload JSON do wywołania modelu chat
    DECLARE @payload NVARCHAR(MAX);
    SET @context = STRING_ESCAPE(@context, 'json');
    SET @question = STRING_ESCAPE(@question, 'json');
    -- 3. payload do OpenAI chat completions
    SET @payload = N'{
      "messages": [
        { "role": "system",
          "content": "Jesteś pomocnym asystentem. Odpowiadasz po polsku na podstawie dostarczonego kontekstu. Jeśli brakuje danych, powiedz konkretnie czego brakuje. Na wstepie wskaz na bazie jakiego kontekstu bazujesz przywolujace jego id" },
        { "role": "user", "content": "Pytanie: ' + REPLACE(@question, '"', '\"') + N'" },
        { "role": "user", "content": "Kontekst: ' + REPLACE(@context, '"', '\"') + N'" }
      ],
      "temperature": 0.2,
      "max_tokens": 500
    }'

    --select @payload

    DECLARE @resp NVARCHAR(MAX);

EXEC sys.sp_invoke_external_rest_endpoint
     @url = N'https://ai-copilot-sql-srv.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2025-01-01-preview',
     @method = 'POST',
     @credential = [https://ai-copilot-sql-srv.openai.azure.com/],
     @payload = @payload,
     @response = @resp OUTPUT;

    -- 4. parsowanie odpowiedzi
   SELECT 
       message_content,
       @question AS question,
       @context  AS used_context
FROM OPENJSON(@resp, '$.result.choices')
WITH ( message_content NVARCHAR(MAX) '$.message.content' );


