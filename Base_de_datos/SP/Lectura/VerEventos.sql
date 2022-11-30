/*
    Procedimiento que permite consultar las entradas de la tabla de eventos
*/

/* Resumen de los códigos de salida de este procedimiento
-- Éxito --
        0: Correcto

-- Error --
    50000: Ocurrió un error desconocido
    50001: Credenciales inválidas
*/

ALTER PROCEDURE [dbo].[VerEventos]
    -- Variables de entrada
    @inFechaInicio DATE = NULL,
    @inFechaFinal DATE = NULL,

    -- Para determinar quién está haciendo la consulta
    @inUsername VARCHAR(32)
AS
BEGIN
    -- Se define la variable donde se guarda el código de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (éxito)

    SET NOCOUNT ON;         -- Para evitar interferencias

    BEGIN TRY
        
        -- Verificamos que el usuario sea administrador
        IF NOT EXISTS(
					    SELECT 1 FROM [dbo].[Usuario] U
					    INNER JOIN [dbo].[TipoUsuario] T ON U.idTipoUsuario = T.id
					    WHERE U.nombreDeUsuario = @inUsername
					    AND T.nombre = 'Administrador'
					    )
        BEGIN
            -- Si llega acá, el usuario no es administrador
            -- Entonces no retornamos nada
            SET @outResultCode = 50001;     -- Credenciales inválidas

            SELECT  NULL AS 'Entidad',
                    NULL AS 'ID',
                    NULL AS 'jsonAntes',
                    NULL AS 'jsonDespues',
                    NULL AS 'Time',
                    NULL AS 'Usuario',
                    NULL AS 'IP';

            SELECT  NULL AS 'fechaInicial',
                    NULL AS 'fechaFinal';

            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si no se brindó una fecha, se establecen las variables de entrada
        -- en los valores límite (mínimo y máximo) de la tabla de eventos
        IF  @inFechaInicio IS NULL
            OR @inFechaInicio < (SELECT  MIN(EL.[insertedAt])
                                FROM    [dbo].[EventLog] EL )
            OR @inFechaInicio > (SELECT  MAX(EL.[insertedAt])
                                FROM    [dbo].[EventLog] EL )
        BEGIN
            SET @inFechaInicio = (  SELECT  MIN(EL.[insertedAt])
                                    FROM    [dbo].[EventLog] EL );
        END;

        IF  @inFechaFinal IS NULL
            OR @inFechaFinal < (SELECT  MIN(EL.[insertedAt])
                                FROM    [dbo].[EventLog] EL )
            OR @inFechaFinal > (SELECT  MAX(EL.[insertedAt])
                                FROM    [dbo].[EventLog] EL )
        BEGIN
            SET @inFechaFinal = (  SELECT  MAX(EL.[insertedAt])
                                    FROM    [dbo].[EventLog] EL );
        END;

        -- Retornamos la información
        SELECT  ET.nombre AS 'Entidad',
                EL.entityId AS 'ID',
                EL.jsonAntes AS 'jsonAntes',
                EL.jsonDespues AS 'jsonDespues',
                EL.insertedAt AS 'Time',
                U.nombreDeUsuario AS 'Usuario',
                EL.insertedInIp AS 'IP'
        FROM    [dbo].[EventLog] EL
        INNER JOIN [dbo].[EntityType] ET
            ON  EL.[idEntityType] = ET.[id]
        INNER JOIN [dbo].[Usuario] U
            ON  U.[id] = EL.[insertedByUser]
        WHERE   EL.[insertedAt] >= @inFechaInicio
            AND EL.[insertedAt] < DATEADD(DAY, 1, @inFechaFinal)
        ORDER BY EL.[insertedAt] DESC;

        IF (    SELECT  COUNT(EL.[id])
                FROM    [dbo].[EventLog] EL) > 0
        BEGIN
            SELECT  @inFechaInicio AS 'fechaInicial',
                    @inFechaFinal  AS 'fechaFinal';
        END
        ELSE
        BEGIN
            SELECT  NULL AS 'fechaInicial',
                    NULL  AS 'fechaFinal';
        END;

        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        
        SET @outResultCode = 50000;

        SELECT  NULL AS 'Entidad',
                NULL AS 'ID',
                NULL AS 'jsonAntes',
                NULL AS 'jsonDespues',
                NULL AS 'Time',
                NULL AS 'Usuario',
                NULL AS 'IP';

        SELECT  NULL AS 'fechaInicial',
                NULL  AS 'fechaFinal';

        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;
END;