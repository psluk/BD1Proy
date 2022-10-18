/*
    Procedimiento que retorna todas las propiedades
*/

/* Resumen de los c�digos de salida de este procedimiento
-- �xito --
        0: Correcto

-- Error --
    50000: Ocurri� un error desconocido
    50001: Credenciales inv�lidas
*/

ALTER PROCEDURE [dbo].[VerPropiedades]
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
                INNER JOIN [dbo].[TipoUsuario] T
                ON U.idTipoUsuario = T.id
                WHERE U.nombreDeUsuario = @inUsername
                    AND T.nombre = 'Administrador'
                )
        BEGIN
            -- Si llega ac�, el usuario no es administrador
            -- Entonces no retornamos nada
            SET @outResultCode = 50001;     -- Credenciales inv�lidas
            SELECT NULL AS 'Finca',
                NULL AS 'Uso',
                NULL AS 'Zona',
                NULL AS 'Area',
                NULL AS 'Fiscal',
                NULL AS 'Registro'
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega ac�, se buscan las propiedades
        SELECT P.numeroFinca AS 'Finca',
            TU.nombre AS 'Uso',
            TZ.nombre AS 'Zona',
            P.area AS 'Area',
            P.valorFiscal AS 'Fiscal',
            P.fechaRegistro AS 'Registro'
        FROM [dbo].[Propiedad] P
        INNER JOIN [dbo].[TipoUsoPropiedad] TU
        ON TU.id = P.idTipoUsoPropiedad
        INNER JOIN [dbo].[TipoZona] TZ
        ON TZ.id = P.idTipoZona;

        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Ocurri� un error desconocido
        SET @outResultCode = 50000;     -- Error
        SELECT NULL AS 'Finca',
                NULL AS 'Uso',
                NULL AS 'Zona',
                NULL AS 'Area',
                NULL AS 'Fiscal',
                NULL AS 'Registro'
        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;

END;