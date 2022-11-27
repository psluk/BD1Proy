/*
    Procedimiento que permite formalizar el arreglo de pago
*/

/* Resumen de los c�digos de salida de este procedimiento
-- �xito --
        0: Correcto

-- Error --
    50000: Ocurri� un error desconocido
    50001: Credenciales inv�lidas
    50002: La propiedad no existe
    50003: No hay facturas pendientes
    50004: No existe ese plazo
*/

ALTER PROCEDURE [dbo].[FormalizarAP]
    -- Se definen las variables de entrada
    @inNumeroFinca VARCHAR(32),
    @inPlazoMeses INT,

    -- Para determinar qui�n est� haciendo la consulta
    @inUsername VARCHAR(32)
AS
BEGIN
    -- CONSTANTES
    DECLARE @ID_FACTURA_ESTADO_PENDIENTE INT = 1;
    DECLARE @MIN_FACTURAS_PENDIENTES INT = 2;
    DECLARE @ID_MOVIMIENTO_DEBITO INT = 2;

    -- Se define la variable donde se guarda el c�digo de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (�xito)
    DECLARE @idPropiedad AS INT;
    DECLARE @facturasPendientes TABLE (
        numeroFacturas INT,             -- N�mero de facturas pendientes
        montoPendiente MONEY            -- Total
    );
    DECLARE @idTasaInteres AS INT;
    DECLARE @montoCuota AS INT;

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
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Verificamos que la propiedad exista y obtenemos el ID
        IF EXISTS ( SELECT 1 
				    FROM [dbo].[Propiedad] P
				    WHERE P.numeroFinca = @inNumeroFinca
				  )
        BEGIN
            -- S� existe
            SET @idPropiedad = ( SELECT P.id 
								 FROM [dbo].[Propiedad] P
								 WHERE P.numeroFinca = @inNumeroFinca
							   );
        END
        ELSE
        BEGIN 
            -- No existe
            -- Entonces no retornamos nada
            SET @outResultCode = 50002;     -- Propiedad inexistente

            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Se insertan las facturas pendientes a la tabla
        INSERT INTO @facturasPendientes
        SELECT  COUNT(F.[id]),
                SUM(F.[totalActual])
        FROM    [dbo].[Factura] F
        WHERE   F.[idPropiedad] = @idPropiedad
            AND F.[idEstadoFactura] = @ID_FACTURA_ESTADO_PENDIENTE

        IF  (SELECT  F.[numeroFacturas]
            FROM    @facturasPendientes F) < @MIN_FACTURAS_PENDIENTES
        BEGIN
            -- Si llega ac�, entonces no hay facturas pendientes suficientes
            SET @outResultCode = 50003;     -- Sin facturas pendientes
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Se obtiene el ID de la tasa de inter�s
        IF  EXISTS (SELECT  1
                    FROM    [dbo].[TasaInteresArreglo]
                    WHERE   [plazoMeses] = @inPlazoMeses)
        BEGIN
            -- S� existe
            SET @idTasaInteres =   (SELECT  [id]
                                    FROM    [dbo].[TasaInteresArreglo]
                                    WHERE   [plazoMeses] = @inPlazoMeses);
        END
        ELSE
        BEGIN 
            -- No existe el plazo
            -- Entonces no retornamos nada
            SET @outResultCode = 50004;     -- Plazo inexistente
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Se calcula la cuota
        SET @montoCuota = (
            SELECT  (
                        ((TI.[tasaInteresAnual] / 12)
                         + ((TI.[tasaInteresAnual] / 12)
                            / (POWER((1 + (TI.[tasaInteresAnual] / 12)), TI.[plazoMeses]) - 1)
                           )
                        ) * (SELECT [montoPendiente] FROM @facturasPendientes)
                    )
            FROM    [dbo].[TasaInteresArreglo] TI
            WHERE   TI.[id] = @idTasaInteres);

        BEGIN  TRANSACTION  tArregloDePago
            
            -- Se crea el arreglo de pago
            INSERT INTO [dbo].[ArregloDePago]
                (
                    idTasaInteres,
                    idPropiedad,
                    montoOriginal,
                    saldo,
                    acumuladoAmortizado,
                    acumuladoPagado
                )
            SELECT  @idTasaInteres,
                    @idPropiedad,
                    F.[montoPendiente],
                    F.[montoPendiente],
                    0,
                    0
            FROM    @facturasPendientes F;

            -- Se crea el movimiento de tipo d�bito
            INSERT INTO [dbo].[MovimientoArreglo]
                (
                    idTipoMovimiento,
                    idArregloPago,
                    fecha,
                    montoCuota,
                    amortizado,
                    intereses
                )
            SELECT  @ID_MOVIMIENTO_DEBITO,                      -- Movimiento de d�bito
                   (SELECT  MAX(A.[id])                         -- ID del arreglo reci�n creado
                    FROM    [dbo].[ArregloDePago] A
                    WHERE   A.[idPropiedad] = @idPropiedad),
                    GETDATE(),                                  -- Fecha
                    @montoCuota,                                -- Cuota
                    F.[montoPendiente],                         -- Monto total por amortizar
                    (@montoCuota * @inPlazoMeses - F.montoPendiente) -- Interes totales
            FROM    @facturasPendientes F;

        COMMIT TRANSACTION  tArregloDePago

        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Ocurri� un error desconocido
        IF  @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION tArregloDePago;
        END;

        -- Registra el error
        INSERT INTO [dbo].[Errors]
        VALUES (
            SUSER_NAME(),
            ERROR_NUMBER(),
            ERROR_STATE(),
            ERROR_SEVERITY(),
            ERROR_LINE(),
            ERROR_PROCEDURE(),
            ERROR_MESSAGE(),
            GETDATE()
        );

        SET @outResultCode = 50000;     -- Error
        SELECT @outResultCode AS 'resultCode';
    END CATCH;

    SET NOCOUNT OFF;
END;