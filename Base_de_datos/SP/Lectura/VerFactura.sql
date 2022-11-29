/* Procedimiento que retorna los detalles de cobro de una factura */

ALTER PROCEDURE [dbo].[VerFactura]
    -- Se definen las variables de entrada
    @inNumeroFinca INT,
    @inFechaGeneracion DATE,

    -- Para determinar quién está haciendo la consulta
    @inUsername VARCHAR(32)
AS
BEGIN
    -- Se define la variable donde se guarda el código de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (éxito)
	DECLARE @idPropiedad AS INT;

    -- CONSTANTES
    DECLARE @ID_FACTURA_ESTADO_PENDIENTE INT = 1;

    SET NOCOUNT ON;         -- Para evitar interferencias

    BEGIN TRY

        -- Verificamos que el usuario sea administrador
        -- o esté tratando de procesar la factura de una propiedad suya
        IF NOT EXISTS(  -- ¿Es administrador?
					  SELECT 1 FROM [dbo].[Usuario] U
					  INNER JOIN [dbo].[TipoUsuario] T ON U.idTipoUsuario = T.id
					  WHERE U.nombreDeUsuario = @inUsername
					  AND T.nombre = 'Administrador'
		   ) AND NOT EXISTS( -- ¿Es un no administrador que consulta algo propio?
					  SELECT 1 FROM [dbo].[Usuario] U
					  INNER JOIN [dbo].[UsuarioDePropiedad] UdP ON U.id = UdP.idUsuario
					  INNER JOIN [dbo].[Propiedad] P ON UdP.idPropiedad = P.id
					  WHERE U.nombreDeUsuario = @inUsername
					  AND UdP.fechaFin IS NULL    -- NULL = relación activa
					  AND P.numeroFinca = @inNumeroFinca
            )
        BEGIN
            -- Si llega acá, el usuario no puede ver la factura
            -- Entonces no retornamos nada
            SET @outResultCode = 50001;     -- Credenciales inválidas
            SELECT NULL AS 'Concepto',
                   NULL AS 'Monto';
            SELECT NULL AS 'fechaGeneracion',
                   NULL AS 'fechaVencimiento',
                   NULL AS 'totalOriginal',
                   NULL AS 'totalAcumulado',
                   NULL AS 'estado',
                   NULL AS 'referenciaPago',
                   NULL AS 'pagada';
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
            -- No existe
            -- Entonces no retornamos nada
            SET @outResultCode = 50002;     -- Propiedad inexistente
            SELECT NULL AS 'Concepto',
                   NULL AS 'Monto';
            SELECT NULL AS 'fechaGeneracion',
                   NULL AS 'fechaVencimiento',
                   NULL AS 'totalOriginal',
                   NULL AS 'totalAcumulado',
                   NULL AS 'estado',
                   NULL AS 'referenciaPago',
                   NULL AS 'pagada';
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega acá, se buscan los detalles de la factura
        SELECT  CC.[nombre] AS 'Concepto',
                DCC.[monto] AS 'Monto'
        FROM    [dbo].[DetalleConceptoCobro] DCC
        INNER JOIN [dbo].[ConceptoCobro] CC
            ON  DCC.[idConceptoCobro] = CC.[id]
        INNER JOIN [dbo].[Factura] F
            ON  DCC.[idFactura] = F.[id]
        WHERE   F.[idPropiedad] = @idPropiedad
            AND F.[fechaGeneracion] = @inFechaGeneracion
            AND DCC.[monto] != 0;

        -- Se busca la información general de la factura
        SELECT  -- Facturas sin idPago
                F.[fechaGeneracion] AS 'fechaGeneracion',
                F.[fechaVencimiento] AS 'fechaVencimiento',
                F.[totalOriginal] AS 'totalOriginal',
                F.[totalActual] AS 'totalAcumulado',
                EF.[descripcion] AS 'estado',
                NULL AS 'referenciaPago',
                CASE
                    WHEN    F.[idEstadoFactura] = @ID_FACTURA_ESTADO_PENDIENTE
                        THEN    CAST(0 AS BIT)
                    ELSE    CAST(1 AS BIT)
                END AS 'pagado'
        FROM    [dbo].[Factura] F
        INNER JOIN [dbo].[EstadoFactura] EF
            ON  F.[idEstadoFactura] = EF.[id]
        WHERE   F.[idPropiedad] = @idPropiedad
            AND F.[idPago] IS NULL
            AND F.[fechaGeneracion] = @inFechaGeneracion
        UNION
        SELECT  -- Facturas con idPago
                F.[fechaGeneracion] AS 'fechaGeneracion',
                F.[fechaVencimiento] AS 'fechaVencimiento',
                F.[totalOriginal] AS 'totalOriginal',
                F.[totalActual] AS 'totalAcumulado',
                EF.[descripcion] AS 'estado',
                P.[numeroReferencia] AS 'referenciaPago',
                CAST(1 AS BIT) AS 'pagado'
        FROM    [dbo].[Factura] F
        INNER JOIN [dbo].[EstadoFactura] EF
            ON  F.[idEstadoFactura] = EF.[id]
        INNER JOIN [dbo].[Pago] P
            ON  F.[idPago] = P.[id]
        WHERE   F.[idPropiedad] = @idPropiedad
            AND F.[fechaGeneracion] = @inFechaGeneracion
        ORDER BY F.[fechaGeneracion] DESC;

        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Ocurrió un error desconocido
        SET @outResultCode = 50000;     -- Error desconocido
        SELECT NULL AS 'Concepto',
               NULL AS 'Monto';
        SELECT NULL AS 'fechaGeneracion',
               NULL AS 'fechaVencimiento',
               NULL AS 'totalOriginal',
               NULL AS 'totalAcumulado',
               NULL AS 'estado',
               NULL AS 'referenciaPago',
               NULL AS 'pagada';
        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;

END;