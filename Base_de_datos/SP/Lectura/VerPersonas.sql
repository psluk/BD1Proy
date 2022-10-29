/*
    Procedimiento que retorna todas las personas
*/

/* Resumen de los c�digos de salida de este procedimiento
-- �xito --
        0: Correcto

-- Error --
    50000: Ocurri� un error desconocido
    50001: Credenciales inv�lidas
*/

ALTER PROCEDURE [dbo].[VerPersonas]
    -- Para determinar qui�n est� haciendo la consulta
    @inUsername VARCHAR(32)
AS
BEGIN
    -- Se define la variable donde se guarda el c�digo de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (�xito)

    SET NOCOUNT ON;         -- Para evitar interferencias

    BEGIN TRY

        -- Verificamos que el usuario sea administrador
        IF NOT EXISTS( SELECT 1 
					   FROM [dbo].[Usuario] U
					   INNER JOIN [dbo].[TipoUsuario] T ON U.idTipoUsuario = T.id
					   WHERE U.nombreDeUsuario = @inUsername
					   AND T.nombre = 'Administrador'
					 )
        BEGIN
            -- Si llega ac�, el usuario no es administrador
            -- Entonces no retornamos nada
            SET @outResultCode = 50001;     -- Credenciales inv�lidas
            SELECT NULL AS 'Nombre', 
				   NULL AS 'ID', 
				   NULL AS 'Inicio';

            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega ac�, se retorna la informaci�n
        SELECT P.nombre AS 'Nombre', 
			   P.valorDocumentoId AS 'ID',
			   TDI.nombre AS 'Tipo', 
			   P.telefono1 AS 'Telefono 1',
			   P.telefono2 AS 'Telefono2', 
			   P.email AS 'Correo'
        FROM [dbo].[Persona] P
        INNER JOIN [dbo].[TipoDocumentoId] TDI ON P.[idTipoDocumentoId] = TDI.[id];

        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Ocurri� un error desconocido
        SET @outResultCode = 50000;     -- Error desconocido
        SELECT NULL AS 'Nombre', 
			   NULL AS 'ID', 
			   NULL AS 'Inicio';

        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;

END;