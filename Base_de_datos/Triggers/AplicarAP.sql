/*
    Trigger para aplicar el pago del arreglo de pago
*/

ALTER TRIGGER [dbo].[AplicarAP]
ON [dbo].[Factura]
AFTER UPDATE
AS
BEGIN
    IF (UPDATE(idPago))         -- Solo trabaja con facturas a las que se les asocia un pago
    BEGIN
        SET NOCOUNT ON;         -- Para evitar interferencias

        -- CONSTANTES
        DECLARE @ID_CONCEPTO_COBRO_ARREGLO INT = 8;
        DECLARE @ID_ARREGLO_ACTIVO INT = 1;
        DECLARE @ID_PAGADA_CON_ARREGLO INT = 3;
        DECLARE @ID_PAGADA_NORMAL INT = 2;

        -- Otras variables
        DECLARE @arregloPago TABLE
        (
            id INT,
            montoDisponible MONEY,
            continuarPagando BIT            -- 1 = sí, 0 = no
        );
        DECLARE @facturasPorActualizar TABLE
        (
            id INT IDENTITY(1,1),
            idFactura INT,
            idArreglo INT,
            monto MONEY,
            pagable BIT                     -- 1 = sí, 0 = no
        );
        DECLARE @montoDisponible MONEY;     -- Disponible para amortizar

        -- Variables para iterar
        DECLARE @minIndex INT;
        DECLARE @maxIndex INT;
        DECLARE @currIndex INT;
        DECLARE @montoFacturaActual MONEY;

        BEGIN TRY

            -- Se obtiene el ID del arreglo, de haberlo
            IF  EXISTS( SELECT  1
                        FROM    [dbo].[DetalleConceptoCobro] DCC
                        INNER JOIN  inserted I
                            ON  DCC.[idFactura] = I.[id]
                        WHERE   DCC.[idConceptoCobro] = @ID_CONCEPTO_COBRO_ARREGLO )
            BEGIN
                INSERT INTO @arregloPago
                (
                    [id],
                    [montoDisponible],
                    [continuarPagando]
                )
                SELECT  DISTINCT
                        AdP.[id],
                        AdP.[acumuladoPagado] - AdP.[acumuladoAmortizado],
                        1
                FROM    [dbo].[DetalleConceptoCobro] DCC
                INNER JOIN inserted I
                    ON  DCC.[idFactura] = I.[id]
                INNER JOIN [dbo].[DetalleConceptoCobroArreglo] DCCAP
                    ON  DCC.[id] = DCCAP.[id]
                INNER JOIN [dbo].[MovimientoArreglo] M
                    ON  DCCAP.[idMovimiento] = M.[id]
                INNER JOIN [dbo].[ArregloDePago] AdP
                    ON  M.[idArregloPago] = AdP.[id];
            END
            ELSE
            BEGIN
                -- Si llega acá, no hay ningún arreglo, así que se sale
                RETURN;
            END;

            -- Se insertan en la tabla temporal todas las facturas del AP
            -- que tengan el estado de pago = 'pagada con arreglo de pago'
            INSERT INTO @facturasPorActualizar
            (
                [idFactura],
                [idArreglo],
                [monto],
                [pagable]
            )
            SELECT  F.[id],
                    AP.[id],
                    F.[totalActual],
                    0
            FROM    [dbo].[FacturaConArreglo] FA
            INNER JOIN [dbo].[Factura] F
                ON  F.[id] = FA.[id]
            INNER JOIN @arregloPago AP
                ON  FA.[idArregloPago] = AP.[id]
            WHERE   F.[idEstadoFactura] = @ID_PAGADA_CON_ARREGLO
            ORDER BY F.[fechaGeneracion] ASC;       -- De más vieja a más reciente

            IF (SELECT COUNT(F.[id]) FROM @facturasPorActualizar F) > 0
            BEGIN
                -- Si se insertó al menos una factura, entra acá
                SET @minIndex = (SELECT MIN(F.[id]) FROM @facturasPorActualizar F);
                SET @maxIndex = (SELECT MAX(F.[id]) FROM @facturasPorActualizar F);
                SET @currIndex = @minIndex;

                -- Hacemos la iteración
                WHILE @currIndex <= @maxIndex
                BEGIN
                    IF EXISTS(  SELECT  1
                                FROM    @facturasPorActualizar F
                                INNER JOIN @arregloPago AP
                                    ON  AP.[id] = F.[idArreglo]
                                WHERE   F.id = @currIndex
                                    AND AP.[continuarPagando] = 1)
                    BEGIN
                        -- ¿Alcanza para amortizar esta factura?
                        SET @montoFacturaActual =  (SELECT  F.[monto]
                                                    FROM @facturasPorActualizar F
                                                    WHERE F.[id] = @currIndex);
                        SET @montoDisponible = (SELECT  AP.[montoDisponible]
                                                FROM    @arregloPago AP
                                                INNER JOIN @facturasPorActualizar F
                                                    ON  F.[idArreglo] = AP.[id]
                                                WHERE F.[id] = @currIndex);
                        IF @montoDisponible >= @montoFacturaActual
                        BEGIN
                            -- Sí alcanza. Resta del monto disponible
                            SET @montoDisponible = @montoDisponible - @montoFacturaActual;
                            
                            UPDATE  F
                            SET     [pagable] = 1
                            FROM    @facturasPorActualizar F
                            WHERE   F.id = @currIndex;

                            UPDATE  AP
                            SET     [montoDisponible] = @montoDisponible
                            FROM    @arregloPago AP
                            INNER JOIN @facturasPorActualizar F
                                ON  F.[idArreglo] = AP.[id]
                            WHERE   F.[id] = @currIndex;
                        END
                        ELSE
                        BEGIN
                            UPDATE  AP
                            SET     [continuarPagando] = 0
                            FROM    @arregloPago AP
                            INNER JOIN @facturasPorActualizar F
                                ON  F.[idArreglo] = AP.[id]
                            WHERE   F.[id] = @currIndex;
                        END;
                    END;

                    SET @currIndex = @currIndex + 1;
                END;

                -- Se borran todas las facturas que no se pueden pagar
                DELETE  F
                FROM    @facturasPorActualizar F
                WHERE   F.[pagable] = 0;

                SELECT  *
                FROM    @facturasPorActualizar;

                SELECT  *
                FROM    @arregloPago;

                -- Se actualizan las facturas que sí se pudieron pagar
                UPDATE  F
                SET     F.[idEstadoFactura] = @ID_PAGADA_NORMAL
                FROM    [dbo].[Factura] F
                INNER JOIN @facturasPorActualizar FA
                    ON  F.[id] = FA.[idFactura];

                -- Se actualiza el acumuladoAmortizado del arreglo de pago
                UPDATE  AdP
                SET     AdP.[acumuladoAmortizado] = AdP.[acumuladoPagado] - AP.[montoDisponible]
                FROM    [dbo].[ArregloDePago] AdP
                INNER JOIN @arregloPago AP
                    ON  AP.[id] = AdP.[id];

            END;

        END TRY
        BEGIN CATCH

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
        END CATCH;
    END;
END;