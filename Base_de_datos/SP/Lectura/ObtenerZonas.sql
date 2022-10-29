/*
    Procedimiento que retorna los tipos de zona de una propiedad
*/

/* Resumen de los c�digos de salida de este procedimiento
-- �xito --
        0: Correcto

-- Error --
    50000: Ocurri� un error desconocido
    50001: Credenciales inv�lidas
*/

ALTER PROCEDURE [dbo].[ObtenerZonas]
    -- Para determinar qui�n est� haciendo la consulta
    @inUsername VARCHAR(32)
AS
BEGIN
    -- Se define la variable donde se guarda el c�digo de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (�xito)

    SET NOCOUNT ON;         -- Para evitar interferencias

    BEGIN TRY

        -- Verificamos que el usuario sea administrador
        IF NOT EXISTS(  -- �Es administrador?
					  SELECT 1 FROM [dbo].[Usuario] U
					  INNER JOIN [dbo].[TipoUsuario] T
					  ON U.idTipoUsuario = T.id
					  WHERE U.nombreDeUsuario = @inUsername
					  AND T.nombre = 'Administrador'
					 )
        BEGIN
            -- Si llega ac�, el usuario no puede ver las categor�as
            SET @outResultCode = 50001;     -- Credenciales inv�lidas
            SELECT NULL AS 'Nombre';
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega ac�, ya se hicieron las verificaciones
        SELECT TZ.[nombre] AS 'Nombre'
        FROM [dbo].[TipoZona] TZ
        ORDER BY TZ.[nombre] ASC;
        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Si llega ac�, es porque ocurri� un error

        SET @outResultCode = 50000;     -- Error desconocido
        SELECT NULL AS 'Nombre';
        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;
END;