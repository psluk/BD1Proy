/* Trigger para que el estado de pago de una orden de corta
   se actualice al pagar una factura

   Solo lo hace cuando se pagan todas las facturas de la propiedad

   (También crea la orden de reconexión)
*/

ALTER TRIGGER [dbo].[OrdenCortaPagada]
ON  [dbo].[Factura]
AFTER UPDATE
AS
BEGIN

    IF (UPDATE(idEstadoFactura))
    BEGIN

        SET NOCOUNT ON;             -- Para evitar interferencias
        
        -- CONSTANTES
        DECLARE @ID_PAGO_CORTA_PENDIENTE INT = 1;
        DECLARE @ID_PAGO_CORTA_HECHO INT = 2;
        DECLARE @ID_FACTURA_PENDIENTE INT = 1;
        
        -- Otras variables
        DECLARE @propiedadesAfectadas TABLE
        (
            idPropiedad INT,
            idOrdenCorta INT,
            pendientes INT
        );

        BEGIN TRY

            -- Se insertan en la tabla temporal las propiedades
            -- con órden de corta que pagaron todas sus facturas
            INSERT INTO @propiedadesAfectadas
            (
                [idPropiedad],
                [idOrdenCorta],
                [pendientes]
            )
            SELECT  I.[idPropiedad],
                    MIN(OC.[id]),
                   (SELECT  COUNT(F2.[id])
                    FROM    [dbo].[Factura] F2
                    WHERE   F2.[idPropiedad] = I.[idPropiedad]
                        AND F2.[idEstadoFactura] = @ID_FACTURA_PENDIENTE)
            FROM    inserted I
            INNER JOIN  deleted D
                ON  D.[id] = I.[id]
            INNER JOIN [dbo].[OrdenCorta] OC
                ON  OC.[idPropiedad] = I.[idPropiedad]
            WHERE   D.idEstadoFactura = @ID_FACTURA_PENDIENTE
                AND I.idEstadoFactura != @ID_FACTURA_PENDIENTE
                --  Estas dos condiciones incluyen solo facturas recién pagadas
                AND OC.[idEstadoPago] = @ID_PAGO_CORTA_PENDIENTE
                --  Esta condición hace que solo se incluyan propiedades con cortas pendientes
            GROUP BY I.[idPropiedad];

            -- Se borran todas las propiedades con al menos una factura pendiente
            DELETE  P
            FROM    @propiedadesAfectadas P
            WHERE   P.[pendientes] != 0;
        
            BEGIN TRANSACTION tAplicarReconexiones
            
                --  Se actualiza el estado de las órdenes de corta
                UPDATE  OC
                SET     OC.idEstadoPago = @ID_PAGO_CORTA_HECHO
                FROM    [dbo].[OrdenCorta] OC
                INNER JOIN @propiedadesAfectadas P
                    ON  P.[idOrdenCorta] = OC.[id];

                --  Se crean las órdenes de reconexión
                INSERT INTO [dbo].[OrdenReconexion]
                (
                    [idFactura],
                    [idOrdenCorta],
                    [numeroMedidor],
                    [fechaReconexion]
                )
                SELECT  OC.[idFactura],
                        OC.[id],
                        OC.[numeroMedidor],
                        GETDATE()
                FROM    [dbo].[OrdenCorta] OC
                INNER JOIN @propiedadesAfectadas P
                    ON  P.[idOrdenCorta] = OC.[id];

            COMMIT TRANSACTION tAplicarReconexiones
        
        END TRY
        BEGIN CATCH
            -- Ocurrió un error
            IF @@TRANCOUNT > 0
            BEGIN
                -- Entra aquí si el error fue en la transacción
                ROLLBACK TRANSACTION tAplicarReconexiones;
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