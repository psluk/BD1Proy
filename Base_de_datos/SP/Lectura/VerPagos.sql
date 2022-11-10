/*
    Procedimiento que retorna todos los pagos
*/

/* Resumen de los c�digos de salida de este procedimiento
-- �xito --
        0: Correcto

-- Error --
    50000: Ocurri� un error desconocido
    50001: Credenciales inv�lidas
*/

ALTER PROCEDURE [dbo].[VerPagos]
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
					   INNER JOIN [dbo].[TipoUsuario] T
					   ON U.idTipoUsuario = T.id
					   WHERE U.nombreDeUsuario = @inUsername
					   AND T.nombre = 'Administrador'
					 )
        BEGIN
            -- Si llega ac�, el usuario no es administrador
            -- Entonces no retornamos nada
            SET @outResultCode = 50001;     -- Credenciales inv�lidas
            SELECT  NULL AS 'fecha',
                    NULL AS 'medio',
                    NULL AS 'numeroReferencia',
                    NULL AS 'total';

            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega ac�, se retorna la informaci�n
        SELECT  P.[fechaPago] AS 'fecha',
                TMP.[descripcion] AS 'medio',
                [numeroReferencia] AS 'numeroReferencia',
                (SELECT SUM(F.[totalActual])
                 FROM [dbo].[Factura] F
                 INNER JOIN [dbo].[Pago] P2
                    ON P2.[id] = F.[idPago]
                 WHERE P2.[id] = P.[id]) AS 'total'
        FROM    [dbo].[Pago] P
        INNER JOIN [dbo].[TipoMedioPago] TMP
            ON  P.[idTipoMedioPago] = TMP.[id]
        ORDER BY P.[fechaPago] DESC;

        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Ocurri� un error desconocido
        SET @outResultCode = 50000;     -- Error
        SELECT  NULL AS 'fecha',
                    NULL AS 'medio',
                    NULL AS 'numeroReferencia',
                    NULL AS 'total';

        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;

END;