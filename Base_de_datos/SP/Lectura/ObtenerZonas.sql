/*
    Procedimiento que retorna los tipos de zona de una propiedad
*/

/* Resumen de los códigos de salida de este procedimiento
-- Éxito --
        0: Correcto

-- Error --
    50000: Ocurrió un error desconocido
    50001: Credenciales inválidas
*/

ALTER PROCEDURE [dbo].[ObtenerZonas]
    -- Para determinar quién está haciendo la consulta
    @inUsername VARCHAR(32)
AS
BEGIN
    -- Se define la variable donde se guarda el código de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (éxito)

    SET NOCOUNT ON;         -- Para evitar interferencias

    BEGIN TRY

        -- Verificamos que el usuario sea administrador
        IF NOT EXISTS(  -- ¿Es administrador?
					  SELECT 1 FROM [dbo].[Usuario] U
					  INNER JOIN [dbo].[TipoUsuario] T
					  ON U.idTipoUsuario = T.id
					  WHERE U.nombreDeUsuario = @inUsername
					  AND T.nombre = 'Administrador'
					 )
        BEGIN
            -- Si llega acá, el usuario no puede ver las categorías
            SET @outResultCode = 50001;     -- Credenciales inválidas
            SELECT NULL AS 'Nombre';
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega acá, ya se hicieron las verificaciones
        SELECT TZ.[nombre] AS 'Nombre'
        FROM [dbo].[TipoZona] TZ
        ORDER BY TZ.[nombre] ASC;
        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Si llega acá, es porque ocurrió un error

        SET @outResultCode = 50000;     -- Error desconocido
        SELECT NULL AS 'Nombre';
        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;
END;