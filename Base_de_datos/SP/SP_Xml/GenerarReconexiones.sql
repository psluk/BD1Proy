/* Procedimiento que genera las �rdenes de reconexi�n para las propiedades
   cuyas facturas fueron pagadas */

CREATE PROCEDURE [dbo].[GenerarReconexiones]
    -- Se definen las variables de entrada
    @inFechaOperacion DATE
AS
BEGIN    
    SET NOCOUNT ON;

    -- CONSTANTES
    DECLARE @ID_PAGO_CORTA_PENDIENTE INT = 1;
    DECLARE @ID_FACTURA_PENDIENTE INT = 1;

    BEGIN TRY
        
        BEGIN TRANSACTION tGenerarReconexiones;
            
            -- Se insertan las reconexiones correspondientes
            INSERT  INTO [dbo].[OrdenReconexion]
                    (
                        [idFactura],
                        [idOrdenCorta],
                        [numeroMedidor],
                        [fechaReconexion]
                    )
            SELECT  OC.[idFactura],
                    OC.[id],
                    OC.[numeroMedidor],
                    @inFechaOperacion
            FROM    [dbo].[OrdenCorta] OC
            WHERE   OC.[idEstadoPago] != @ID_PAGO_CORTA_PENDIENTE
                AND (
                        SELECT  COUNT(F.[id])
                        FROM    [dbo].[Factura] F
                        WHERE   F.[idPropiedad] = OC.[idPropiedad]
                        AND     F.[idEstadoFactura] = @ID_FACTURA_PENDIENTE
                    ) = 0       -- Ninguna factura pendiente para la propiedad
                AND (
                        SELECT  COUNT(R.[id])
                        FROM    [dbo].[OrdenReconexion] R
                        WHERE   R.[idFactura] = OC.[idFactura]
                    ) = 0;      -- No debe haber ninguna orden de reconexi�n
                                -- para la misma factura

        COMMIT TRANSACTION tGenerarReconexiones;

    END TRY
    BEGIN CATCH
        
        IF @@TRANCOUNT > 0
        BEGIN
            -- Entra aqu� si el error fue en la transacci�n
            ROLLBACK TRANSACTION tGenerarReconexiones;
        END;

    END CATCH;

    SET NOCOUNT OFF;
END;