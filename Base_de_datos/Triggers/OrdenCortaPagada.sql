/* Trigger para que el estado de pago de una orden de corta
   se actualice al pagar una factura */

ALTER TRIGGER [dbo].[OrdenCortaPagada]
ON  [dbo].[Factura]
AFTER UPDATE
AS
BEGIN
    -- CONSTANTES
    DECLARE @ID_PAGO_CORTA_HECHO INT = 2;
    DECLARE @ID_FACTURA_PENDIENTE INT = 1;

    UPDATE  OC
    SET [idPago] = I.[idPago],
        [idEstadoPago] = @ID_PAGO_CORTA_HECHO
    FROM    [dbo].[OrdenCorta] OC
    INNER JOIN inserted I
        ON  I.[id] = OC.[idFactura]
    INNER JOIN deleted D
        ON  D.[id] = OC.[idFactura]
    WHERE   D.idEstadoFactura = @ID_FACTURA_PENDIENTE
        AND I.idEstadoFactura != @ID_FACTURA_PENDIENTE;
        -- El WHERE hace que la operación solo trabaje con facturas
        -- a las que se les acaba de hacer un pago
END;