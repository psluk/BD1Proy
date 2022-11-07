/* Procedimiento que genera las órdenes de corta para el día de operación actual */

ALTER PROCEDURE [dbo].[GenerarCortas]
    -- Se crean las variables de entrada
    @inFechaOperacion DATE
AS
BEGIN
    -- CONSTANTES
    DECLARE @ID_PAGO_CORTA_PENDIENTE INT = 1;
    DECLARE @ID_FACTURA_PENDIENTE INT = 1;

    -- Si una factura debía pagarse el día 0 y no se pagó,
    -- la orden de corta de esa propiedad se genera el día 1
    -- Por lo tanto, se le suma 1 a la fecha para poder generar
    -- las órdenes de corta correspondientes
    SET @inFechaOperacion = DATEADD(DAY, 1, @inFechaOperacion);

    SET NOCOUNT ON;

    INSERT  INTO [dbo].[OrdenCorta]
    SELECT  DISTINCT
        -- Se genera una fila por factura para cada propiedad
        -- El DISTINCT se encarga de meter una sola de esas filas
            (
            SELECT  MIN(F2.[id])        -- ID de la factura más vieja de esa propiedad
            FROM    [dbo].[Factura] F2
            WHERE   F2.[idPropiedad] = F.[idPropiedad]
            AND F.[idEstadoFactura] = @ID_FACTURA_PENDIENTE
            AND (SELECT COUNT(F2.[id])  -- Mismas condiciones que abajo
                FROM    [dbo].[Factura] F2
                WHERE   F.idEstadoFactura = @ID_FACTURA_PENDIENTE
                AND DATEDIFF(DAY, F2.[fechaVencimiento], @inFechaOperacion) > 0
                AND F2.[idPropiedad] = F.[idPropiedad]) >= 2
                ) AS 'idFactura',
            F.[idPropiedad] AS 'idPropiedad',
            @ID_PAGO_CORTA_PENDIENTE AS 'idEstadoCorta',
            NULL AS 'idPago',
            AdP.[numeroMedidor] AS 'numeroMedidor',
            @inFechaOperacion AS 'fechaOperacion'
    FROM    [dbo].[Factura] F
    INNER JOIN [dbo].[ConceptoCobroDePropiedad] CCdP
        ON  CCdP.[idPropiedad] = F.[idPropiedad]
    INNER JOIN [dbo].[AguaDePropiedad] AdP
        ON  CCdP.[id] = AdP.[id]
    WHERE   F.[idEstadoFactura] = @ID_FACTURA_PENDIENTE
    AND (SELECT COUNT(F2.[id])          -- Número de facturas pendientes de la propiedad
        FROM    [dbo].[Factura] F2
        WHERE   F.idEstadoFactura = @ID_FACTURA_PENDIENTE
        AND DATEDIFF(DAY, F2.[fechaVencimiento], @inFechaOperacion) > 0
        AND F2.[idPropiedad] = F.[idPropiedad]
        ) >= 2                          -- Debe ser mayor o igual que dos
    AND (SELECT COUNT(OC.[id])
        FROM    [dbo].[OrdenCorta] OC
        WHERE   OC.[idPropiedad] = F.[idPropiedad]
        AND     idPago IS NULL
        ) = 0;                          -- No inserta una orden de corta si ya hay una

    SET NOCOUNT OFF;
END;