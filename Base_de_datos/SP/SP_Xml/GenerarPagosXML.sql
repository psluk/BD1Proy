
USE proyecto
GO
-- SP que inserta crea la factura de la propiedad
-- no incluye en el cobro  

ALTER PROCEDURE [dbo].[GenerarPagosXML]
                        @hdoc INT,
                        @inFechaOperacion DATE
AS
BEGIN

    SET NOCOUNT ON;	

    -- CONSTANTES
    DECLARE @ID_ESTADO_FACTURA_ARREGLO INT = 3;
    DECLARE @ID_ESTADO_FACTURA_PAGADA INT = 1;

    BEGIN TRY

        DECLARE @temp_Lecturas TABLE
        (
            -- Llaves
            id INT PRIMARY KEY IDENTITY(1,1),
            NumFinca INT,
            TipoPago varchar(32),
            NumeroReferenciaComprobantePago BIGINT,
            FechaOperacion DATE
        
        );

        DECLARE @temp_Factura TABLE
        (
            -- Llaves
            id INT PRIMARY KEY IDENTITY(1,1),
            idPropiedad INT NOT NULL,
            MenorFechaCobro DATE
        );
        
        -- obtenemos los pagos realizados del dia
        INSERT INTO @temp_Lecturas (NumFinca,
                                    TipoPago,
                                    NumeroReferenciaComprobantePago,
                                    FechaOperacion)
        SELECT NumFinca,
            TipoPago,
            NumeroReferenciaComprobantePago,
            @inFechaOperacion
        FROM OPENXML(@hdoc, 'Operacion/Pago/Pago', 1)
        WITH 
        (
            NumFinca INT,
            TipoPago varchar(32),
            NumeroReferenciaComprobantePago varchar(32)
        );

        -- encontramos la factura mas vieja de la propiedad
        INSERT INTO @temp_Factura
        (
            idPropiedad,
            MenorFechaCobro
        )
        SELECT  f.idPropiedad,
                MIN(f.fechaGeneracion) AS 'minFecha'
        FROM Factura f 
        WHERE f.idEstadoFactura = 1 -- limitamos las facturas a solo las pendientes
        GROUP BY f.idPropiedad
        ORDER BY f.idPropiedad;

        BEGIN TRANSACTION PagoFactura

            INSERT INTO Pago
            (   [idTipoMedioPago], 
                [numeroReferencia], 
                [fechaPago]
            )
            SELECT  tmp.id,
                    tl.NumeroReferenciaComprobantePago,
                    @inFechaOperacion
            FROM @temp_Lecturas tl
            INNER JOIN TipoMedioPago tmp
                ON tmp.descripcion =  tl.TipoPago -- obtenemos el id del tipo pago
            INNER JOIN Propiedad p
                ON p.numeroFinca = tl.NumFinca -- obtenemos el id de propiedad
            INNER JOIN Factura f
                ON f.idPropiedad = p.id -- obtenemos el id de las facturas de la propiedad
            INNER JOIN @temp_Factura tf
                ON tf.MenorFechaCobro = f.fechaGeneracion
                AND  tf.idPropiedad = f.idPropiedad;

            -- le informamos a las facturas el id de pagos
            UPDATE f
            SET f.idPago = pa.id,
                f.idEstadoFactura = 2 -- Pago normal
            FROM @temp_Lecturas tl -- los datos leidos
            INNER JOIN Propiedad p
                ON p.numeroFinca = tl.NumFinca -- obtenemos el id de propiedad
            INNER JOIN Factura f
                ON f.idPropiedad = p.id -- obtenemos el id de las facturas de la propiedad
            INNER JOIN @temp_Factura tf
                ON tf.MenorFechaCobro = f.fechaGeneracion --unicamente las mas viejas
                AND  tf.idPropiedad = f.idPropiedad
            INNER JOIN Pago pa
                ON pa.numeroReferencia = tl.NumeroReferenciaComprobantePago -- obtenemos el id de pago y 
                AND pa.fechaPago = @inFechaOperacion;
        
        COMMIT TRANSACTION
    
    END TRY
    BEGIN CATCH
        -- Si llega aca, hubo algun error

        --SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- Fue dentro de una transaccion?
        BEGIN
            ROLLBACK TRANSACTION PagoFactura;
            --SET @outResultCode = 50001; -- Error desconocido dentro de la transaccion
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

    SET NOCOUNT OFF;
END