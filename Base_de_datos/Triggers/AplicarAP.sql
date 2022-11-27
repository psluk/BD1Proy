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
        DECLARE @ID_PAGADA_NORMAL INT = 1;

        -- Otras variables
        DECLARE @idArregloPago INT;
        DECLARE @facturasPorActualizar TABLE
        (
            id INT IDENTITY(1,1),
            idFactura INT,
            monto MONEY
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
                        WHERE   DCC.[idConceptoCobro] = @ID_CONCEPTO_COBRO_ARREGLO )
            BEGIN
                SET @idArregloPago = ( 
                        SELECT  M.[idArregloPago]
                        FROM    [dbo].[DetalleConceptoCobro] DCC
                        INNER JOIN [dbo].[DetalleConceptoCobroArreglo] DCCAP
                            ON  DCC.[id] = DCCAP.[id]
                        INNER JOIN [dbo].[MovimientoArreglo] M
                            ON  DCCAP.[idMovimiento] = M.[id]
                        WHERE   DCC.[idConceptoCobro] = @ID_CONCEPTO_COBRO_ARREGLO
                        )
            END
            ELSE
            BEGIN
                -- Si llega acá, no hay ningún arreglo, así que se sale
                RETURN;
            END;

            -- Se obtiene el monto disponible para amortizar
            SET @montoDisponible = (SELECT  (AP.[acumuladoPagado] - AP.[acumuladoAmortizado])
                                    FROM    [dbo].[ArregloDePago] AP
                                    WHERE   AP.[id] = @idArregloPago);

            -- Se insertan en la tabla temporal todas las facturas del AP
            -- que tengan el estado de pago = 'pagada con arreglo de pago'
            INSERT INTO @facturasPorActualizar
            (
                [idFactura],
                [monto]
            )
            SELECT  F.[id],
                    F.[totalActual]
            FROM    [dbo].[FacturaConArreglo] FA
            INNER JOIN [dbo].[Factura] F
                ON  F.[id] = FA.[id]
            WHERE   [idArregloPago] = @idArregloPago
                AND F.[idEstadoFactura] = @ID_PAGADA_CON_ARREGLO
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
                    IF EXISTS(  SELECT 1
                                FROM @facturasPorActualizar F
                                WHERE F.id = @currIndex  )
                    BEGIN
                        -- ¿Alcanza para amortizar esta factura?
                        SET @montoFacturaActual =  (SELECT  F.[monto]
                                                    FROM @facturasPorActualizar F
                                                    WHERE F.id = @currIndex)
                        IF @montoDisponible >= @montoFacturaActual
                        BEGIN
                            -- Sí alcanza. Resta del monto disponible
                            SET @montoDisponible = @montoDisponible - @montoFacturaActual;
                        END
                        ELSE
                        BEGIN
                            -- No alcanza. Se sale
                            BREAK;
                        END;
                    END;

                    SET @currIndex = @currIndex + 1;
                END;

                -- ¿Se pudo pagar al menos una?
                IF @currIndex = @minIndex
                BEGIN
                    -- Si no pasó ni de la primera, no se puede pagar ninguna,
                    -- así que se sale
                    RETURN;
                END;

                -- Se borran todas las facturas que no se pueden pagar
                DELETE  F
                FROM    @facturasPorActualizar F
                WHERE   F.[id] >= @currIndex;

                BEGIN TRANSACTION tActualizarFacturas

                    -- Se actualizan las facturas que sí se pudieron pagar
                    UPDATE  F
                    SET     F.[idEstadoFactura] = @ID_PAGADA_NORMAL
                    FROM    [dbo].[Factura] F
                    INNER JOIN @facturasPorActualizar FA
                        ON  F.[id] = FA.[idFactura];

                    -- Se actualiza el acumuladoAmortizado del arreglo de pago
                    UPDATE  AP
                    SET     AP.[acumuladoAmortizado] = @montoDisponible
                    FROM    [dbo].[ArregloDePago] AP
                    WHERE   AP.[id] = @idArregloPago;

                COMMIT TRANSACTION tActualizarFacturas
            END;

        END TRY
        BEGIN CATCH
            -- Ocurrió un error
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
        END CATCH;
    END;
END;