/* Procedimiento que permite consultar un comprobante de pago */

ALTER PROCEDURE [dbo].[VerPago]
    -- Se definen las variables de entrada
    @inNumeroReferencia BIGINT,

    -- Para determinar quién está haciendo la consulta
    @inUsername VARCHAR(32)
AS
BEGIN
    -- Se define la variable donde se guarda el código de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (éxito)
	DECLARE @idPago AS INT;

    SET NOCOUNT ON;                 -- Para evitar interferencias

    BEGIN TRY

        -- Verificamos que el usuario sea administrador
        -- o esté tratando de procesar el pago de una propiedad suya
        IF NOT EXISTS(  -- ¿Es administrador?
					  SELECT 1 FROM [dbo].[Usuario] U
					  INNER JOIN [dbo].[TipoUsuario] T ON U.idTipoUsuario = T.id
					  WHERE U.nombreDeUsuario = @inUsername
					  AND T.nombre = 'Administrador'
		   ) AND NOT EXISTS( -- ¿Es un no administrador que consulta algo propio?
					  SELECT 1 FROM [dbo].[Usuario] U
					  INNER JOIN [dbo].[UsuarioDePropiedad] UdP ON U.id = UdP.idUsuario
					  INNER JOIN [dbo].[Propiedad] P ON UdP.idPropiedad = P.id
                      INNER JOIN [dbo].[Factura] F ON F.[idPropiedad] = P.[id]
                      INNER JOIN [dbo].[Pago] Pa ON F.[idPago] = Pa.[id]
					  WHERE U.nombreDeUsuario = @inUsername
					  AND UdP.fechaFin IS NULL    -- NULL = relación activa
					  AND Pa.[numeroReferencia] = @inNumeroReferencia
            )
        BEGIN
            -- Si llega acá, el usuario no puede ver ese pago
            -- Entonces no retornamos nada
            SET @outResultCode = 50001;     -- Credenciales inválidas
            SELECT  NULL AS 'fecha',
                    NULL AS 'medio',
                    NULL AS 'numeroReferencia',
                    NULL AS 'total';
            SELECT  NULL AS 'Finca',
                    NULL AS 'fechaGenerada',
                    NULL AS 'fechaVencimiento',
                    NULL AS 'total';
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Verificamos que exista el pago y obtenemos el ID
        IF EXISTS ( SELECT 1 
					FROM [dbo].[Pago] P
				    WHERE P.numeroReferencia = @inNumeroReferencia
				  )
        BEGIN
            -- Sí existe
            SET @idPago = ( SELECT [id]
					              FROM [dbo].[Pago] P
				                  WHERE P.numeroReferencia = @inNumeroReferencia
							   );
        END
        ELSE
        BEGIN 
            -- No existe
            -- Entonces no retornamos nada
            SET @outResultCode = 50002;     -- Pago inexistente
            SELECT  NULL AS 'fecha',
                    NULL AS 'medio',
                    NULL AS 'numeroReferencia',
                    NULL AS 'total';
            SELECT  NULL AS 'Finca',
                    NULL AS 'fechaGenerada',
                    NULL AS 'fechaVencimiento',
                    NULL AS 'total';
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega acá, sí existe el pago
        SELECT  P.[fechaPago] AS 'fecha',
                TMP.[descripcion] AS 'medio',
                [numeroReferencia] AS 'numeroReferencia',
                (SELECT SUM(F.[totalActual])
                 FROM [dbo].[Factura] F
                 INNER JOIN [dbo].[Pago] P2
                    ON P2.[id] = F.[idPago]
                 WHERE P2.[id] = @idPago) AS 'total'
        FROM    [dbo].[Pago] P
        INNER JOIN [dbo].[TipoMedioPago] TMP
            ON  P.[idTipoMedioPago] = TMP.[id]
        WHERE   @idPago = P.[id];

        -- Se buscan las facturas pagadas con ese pago
        SELECT  P.[numeroFinca] AS 'Finca',
                F.[fechaGeneracion] AS 'fechaGenerada',
                F.[fechaVencimiento] AS 'fechaVencimiento',
                F.[totalActual] AS 'total'
        FROM    [dbo].[Factura] F
        INNER JOIN [dbo].[EstadoFactura] EF
            ON  F.[idEstadoFactura] = EF.[id]
        INNER JOIN [dbo].[Pago] Pa
            ON  F.[idPago] = Pa.[id]
        INNER JOIN [dbo].[Propiedad] P
            ON  F.[idPropiedad] = P.[id]
        WHERE   Pa.[id] = @idPago
        ORDER BY F.[fechaGeneracion] DESC;

        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Ocurrió un error desconocido
        SET @outResultCode = 50000;     -- Error desconocido
        SELECT  NULL AS 'fecha',
                NULL AS 'medio',
                NULL AS 'numeroReferencia',
                NULL AS 'total';
        SELECT  NULL AS 'Finca',
                NULL AS 'fechaGenerada',
                NULL AS 'fechaVencimiento',
                NULL AS 'total';
        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;
END;