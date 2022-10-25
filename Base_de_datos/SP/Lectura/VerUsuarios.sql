/*
    Procedimiento que retorna todos los usuarios
*/

/* Resumen de los c�digos de salida de este procedimiento
-- �xito --
        0: Correcto

-- Error --
    50000: Ocurri� un error desconocido
    50001: Credenciales inv�lidas
*/

ALTER PROCEDURE [dbo].[VerUsuarios]
    -- Para determinar qui�n est� haciendo la consulta
    @inUsername VARCHAR(32)
AS
BEGIN
    -- Se define la variable donde se guarda el c�digo de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (�xito)

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
            -- Si llega ac�, el usuario no es administrador
            -- Entonces no retornamos nada
            SET @outResultCode = 50001;     -- Credenciales inv�lidas
            SELECT NULL AS 'Usuario', 
				   NULL AS 'Tipo', 
				   NULL AS 'Nombre', 
				   NULL AS 'Identificacion';
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega ac�, se retorna la informaci�n
        SELECT U.nombreDeUsuario AS 'Usuario', 
			   TU.[nombre] AS 'Tipo', 
			   P.nombre AS 'Nombre', 
			   P.[valorDocumentoId] AS 'Identificacion'
        FROM [dbo].[Usuario] U
        INNER JOIN [dbo].[Persona] P ON U.[idPersona] = P.[id]
        INNER JOIN [dbo].[TipoUsuario] TU ON U.[idTipoUsuario] = TU.[id];

        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Ocurri� un error desconocido
        SET @outResultCode = 50000;     -- Error
        SELECT NULL AS 'Usuario', 
			   NULL AS 'Tipo', 
			   NULL AS 'Nombre', 
			   NULL AS 'Identificacion';
        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;

END;