/*
    Procedimiento para ver las cuotas posibles según el plazo y la tasa impositiva
*/

/* Resumen de los códigos de salida de este procedimiento
-- Éxito --
        0: Correcto

-- Error --
    50000: Ocurrió un error desconocido
    50001: Credenciales inválidas
    50002: La propiedad no existe
    50003: No hay facturas pendientes
*/

ALTER PROCEDURE [dbo].[SolicitarAP]
    -- Se definen las variables de entrada
    @inNumeroFinca VARCHAR(32),

    -- Para determinar quién está haciendo la consulta
    @inUsername VARCHAR(32)
AS
BEGIN
    -- CONSTANTES
    DECLARE @ID_FACTURA_ESTADO_PENDIENTE INT = 1;
    DECLARE @MIN_FACTURAS_PENDIENTES INT = 2;

    -- Se define la variable donde se guarda el código de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (éxito)
    DECLARE @idPropiedad AS INT;
    DECLARE @facturasPendientes TABLE (
        numeroFacturas INT,             -- Número de facturas pendientes
        montoPendiente MONEY            -- Total
    );

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
            SELECT NULL AS 'Usuario', 
				    NULL AS 'Tipo', 
				    NULL AS 'Nombre', 
				    NULL AS 'Identificacion';
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
            -- Sí existe
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
            SELECT NULL AS 'Nombre', 
				   NULL AS 'ID', 
				   NULL AS 'Inicio';

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
            -- Si llega acá, entonces no hay facturas pendientes suficientes
            SET @outResultCode = 50003;     -- Sin facturas pendientes
            SELECT NULL AS 'Usuario', 
				    NULL AS 'Tipo', 
				    NULL AS 'Nombre', 
				    NULL AS 'Identificacion';
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Se calculan las cuotas
        SELECT  TI.[plazoMeses] AS 'Plazo',
                TI.[tasaInteresAnual] AS 'Tasa anual',
                (
                    ((TI.[tasaInteresAnual] / 12)
                     + ((TI.[tasaInteresAnual] / 12)
                        / (POWER((1 + (TI.[tasaInteresAnual] / 12)), TI.[plazoMeses]) - 1)
                       )
                    ) * (SELECT [montoPendiente] FROM @facturasPendientes)
                ) AS 'Cuota'
        FROM    [dbo].[TasaInteresArreglo] TI;
        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Ocurrió un error desconocido
        SET @outResultCode = 50000;     -- Error
        SELECT NULL AS 'Nombre', 
			   NULL AS 'ID', 
			   NULL AS 'Inicio';

        SELECT @outResultCode AS 'resultCode';
    END CATCH;

    SET NOCOUNT OFF;

END;