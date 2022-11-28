/* Procedimiento que permite hacer un pago */

ALTER PROCEDURE [dbo].[PagarFacturas]
    -- Se definen las variables de entrada
    @inFechaInicial DATE,
    @inFechaFinal DATE,
    @inNumeroFinca INT,

    -- Para determinar quién está haciendo la consulta
    @inUsername VARCHAR(32),
    @inUserIp VARCHAR(64)
AS
BEGIN
    -- Se define la variable donde se guarda el código de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (éxito)
	DECLARE @idPropiedad AS INT;
    DECLARE @ID_PAGO_CON_TARJETA AS INT = 2;
    DECLARE @FECHA_ACTUAL AS DATE = GETDATE();
    DECLARE @ID_FACTURA_PAGADA AS INT = 2;

    -- Se genera un número de referencia concantenando la fecha de pago,
    -- el número de finca y la fecha de la factura pagada
    DECLARE @NUMERO_DE_REFERENCIA AS BIGINT = CONVERT(VARCHAR, @FECHA_ACTUAL, 12)
                    + CONVERT(VARCHAR(5), @inNumeroFinca)
                    + CONVERT(VARCHAR, @inFechaInicial, 12);

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
                        INNER JOIN [dbo].[UsuarioDePropiedad] UdP
                        ON U.id = UdP.idUsuario
                        INNER JOIN [dbo].[Propiedad] P
                        ON UdP.idPropiedad = P.id
                        WHERE U.nombreDeUsuario = @inUsername
                            AND UdP.fechaFin IS NULL    -- NULL = relación activa
                            AND P.numeroFinca = @inNumeroFinca
            )
        BEGIN
            -- Si llega acá, el usuario no puede ver hacer ese pago
            -- Entonces no retornamos nada
            SET @outResultCode = 50001;     -- Credenciales inválidas
            SELECT NULL AS 'numeroReferencia';
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Verificamos si el pago existe
        IF EXISTS ( SELECT  1
                    FROM    [dbo].[Pago] P
                    WHERE   P.[numeroReferencia] = @NUMERO_DE_REFERENCIA
                  )
        BEGIN
            -- Sí, entonces solo retornamos el número de referencia y nos salimos
            SELECT @NUMERO_DE_REFERENCIA AS 'numeroReferencia';
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Verificamos que exista la propiedad y obtenemos el ID
        IF EXISTS ( SELECT 1 
					FROM [dbo].[Propiedad] P
				    WHERE P.numeroFinca = @inNumeroFinca
				  )
        BEGIN
            -- Sí existe
            SET @idPropiedad = ( SELECT id 
								 FROM [dbo].[Propiedad] P
								 WHERE P.numeroFinca = @inNumeroFinca
							   );
        END
        ELSE
        BEGIN 
            -- Propiedad no existe
            -- Entonces no retornamos nada
            SET @outResultCode = 50002;
            SELECT  NULL AS 'numeroReferencia';
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        BEGIN TRANSACTION tPagarFacturas

            -- Si llega acá, sí existe la propiedad
            INSERT  [dbo].[Pago]
                (
                    [idTipoMedioPago],
                    [numeroReferencia],
                    [fechaPago]
                )
            SELECT  @ID_PAGO_CON_TARJETA,
                    @NUMERO_DE_REFERENCIA,
                    @FECHA_ACTUAL;

            -- Se actualizan todas las facturas correspondientes
            UPDATE  F
            SET     [idEstadoFactura] = @ID_FACTURA_PAGADA,
                    [idPago] = P.[id]
            FROM    [dbo].[Factura] F,
                    [dbo].[Pago] P
            WHERE   P.[fechaPago] = @FECHA_ACTUAL
                AND P.[numeroReferencia] = @NUMERO_DE_REFERENCIA
                AND DATEDIFF(DAY, @inFechaInicial, F.[fechaGeneracion]) >= 0
                AND DATEDIFF(DAY, @inFechaFinal, F.[fechaGeneracion]) <= 0
                AND F.[idPropiedad] = @idPropiedad
                AND F.[idPago] IS NULL;

            EXEC [dbo].[GenerarReconexiones] @FECHA_ACTUAL;

        COMMIT TRANSACTION tPagarFacturas

        SELECT  @NUMERO_DE_REFERENCIA AS 'numeroReferencia';

        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Ocurrió un error desconocido

        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION tPagarFacturas;
        END;

        SET @outResultCode = 50000;     -- Error desconocido
        SELECT  NULL AS 'numeroReferencia';
        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;
END;