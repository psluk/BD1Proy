
USE proyecto
GO
-- SP que inserta crea la factura de la propiedad
-- no incluye en el cobro  

ALTER PROCEDURE [dbo].[GenerarFacturaXML]
						@inFechaOperacion DATE
AS
BEGIN

	SET NOCOUNT ON;	

	DECLARE @costoPatentes AS INT;
	DECLARE @costoParques AS INT;
	DECLARE @procesando AS INT = -1;
	DECLARE @error AS INT = 0;

	DECLARE @sumatoriaConceptos TABLE --donde almacenaremos la sumatoria de los conceptos
	(
	    -- Llaves
	    id INT  PRIMARY KEY IDENTITY(1,1),
	    idFactura INT NOT NULL,
		Monto INT NOT NULL
	)

	BEGIN TRY

			--obtenemos el costo de patentes
		SELECT @costoPatentes = ccp.valorPatente
		FROM ConceptoCobro cc
		INNER JOIN ConceptoCobroPatente ccp ON ccp.id = cc.id

		--obtenemos el costo de parques
		SELECT @costoParques = ccp.valorFijo
		FROM ConceptoCobro cc
		INNER JOIN ConceptoCobroParques ccp ON ccp.id = cc.id

		
	BEGIN TRANSACTION GenerarFactura	
		-- en @generamos una factura incompleta de todas las propiedades a las que les deberemos generar una factura

		INSERT INTO FACTURA(idPropiedad, 
							idEstadoFactura, 
							idPago, 
							fechaGeneracion, 
							fechaVencimiento, 
							totalOriginal, 
							totalActual
							)
		SELECT p.id, 
			   1, 
			   NULL, 
			   @inFechaOperacion, 
			   DATEADD(DAY,8,@inFechaOperacion), --8 dias antes de vencimiento
			   @procesando,
			   @procesando
		FROM Propiedad p
		WHERE p.fechaRegistro < @inFechaOperacion -- fecha actual es mayor que la de registros
		AND DAY(DATEADD(MONTH,
					   (MONTH(@inFechaOperacion)- MONTH(p.fechaRegistro)),
					   p.fechaRegistro)
			   ) = DAY(@inFechaOperacion) -- dia mas cernano del siguiente mes


		-- al ya tener un id para la factura, podemos generar el DetalleDeCobro
		-- para encontrar la factura, indicamos el idPropiedad y totalOriginal = -1



		INSERT INTO DetalleConceptoCobro(idFactura, 
										 idConceptoCobro, 
										 monto)
		SELECT f.id, 
			   ccdp.idConceptoCobro, 
			   CASE
				   WHEN ccdp.idConceptoCobro = 1 
				   THEN CASE --formula cobro del agua
							WHEN (p.consumoAcumulado-p.acumuladoUltimaFactura)*cca.montoTracto>cca.montoMinimo
							THEN (p.consumoAcumulado-p.acumuladoUltimaFactura)*cca.montoTracto/tpcc.cantidadMeses
							ELSE cca.montoMinimo/tpcc.cantidadMeses
						END
				   WHEN ccdp.idConceptoCobro = 2 
				   THEN CAST(p.valorFiscal AS MONEY)*ccip.valorPorcentual/tpcc.cantidadMeses--formula propiedad
				   
				   WHEN ccdp.idConceptoCobro = 3 
				   THEN CASE --formula de la basura
							WHEN p.area<=ccb.areaMinima 
							THEN ccb.montoMinimo/tpcc.cantidadMeses
							ELSE (ccb.montoMinimo+
								  ccb.montoTracto*(
												   (p.area%ccb.areaTracto)-
												   (ccb.areaMinima%ccb.areaTracto)
												  )
								 )/tpcc.cantidadMeses
						END
				   WHEN ccdp.idConceptoCobro = 4 THEN @costoPatentes/tpcc.cantidadMeses--patente
				   WHEN ccdp.idConceptoCobro = 7 THEN @costoParques/tpcc.cantidadMeses--parques
				   WHEN ccdp.idConceptoCobro = 8 THEN @procesando   --Arreglo de pago
				   ELSE @error
			   END
		FROM Factura f
		-- obtenemos los atributos de las propiedades
		INNER JOIN Propiedad p ON p.id = f.idPropiedad
		-- obtenemos los ConceptosDeCobro asociados a las propiedades
		INNER JOIN ConceptoCobroDePropiedad ccdp ON ccdp.idPropiedad = p.id 
		-- vinculo para obtener precios de los impuestos
		INNER JOIN ConceptoCobro cc ON cc.id = ccdp.idConceptoCobro 
		-- obtenemos cada cuanto debe ser calculado
		INNER JOIN TipoPeriodoConceptoCobro tpcc ON tpcc.id = cc.idTipoPeriodoConceptoCobro 
		-- precio de la basura
		LEFT JOIN ConceptoCobroBasura ccb ON ccb.id = cc.id 
		-- precio impuesto propiedad
		LEFT JOIN ConceptoCobroImpuestoPropiedad ccip ON ccip.id = cc.id 
		-- precio agua
		LEFT JOIN ConceptoCobroAgua cca ON cca.id = cc.id 
		WHERE f.totalOriginal = @procesando

		--procedimiento nuevo para agregar el cobro de AP

		--insertamos el movimiento del arreglo

			--1credito  2debito
			INSERT INTO MovimientoArreglo (idTipoMovimiento, 
									       idArregloPago, 
									       fecha, 
									       montoCuota, 
									       amortizado, 
									       intereses
								          )
			SELECT 1, adp.id, @inFechaOperacion, ma.montoCuota, (ma.montoCuota - (adp.Saldo* tia.tasaInteresAnual/12)) , (adp.Saldo* tia.tasaInteresAnual/12)
			FROM ArregloDePago adp
			INNER JOIN MovimientoArreglo ma ON ma.idArregloPago = adp.id -- obtenemos el monto de la cuota
			INNER JOIN TasaInteresArreglo tia ON tia.id = adp.idTasaInteres -- obtenemos la tasa anual
			INNER JOIN Factura f ON (f.idPropiedad = adp.idPropiedad AND f.totalOriginal = @procesando) --obtenemos el idfactura
			INNER JOIN DetalleConceptoCobro dcc ON dcc.idFactura = f.id -- obtenemos los id de DetalleConceptoCobro
			WHERE dcc.idConceptoCobro = 8 -- solo el arreglo de pago
			AND dcc.monto = @procesando --solo arreglos de pago siendo procesados
			AND adp.idEstado = 1 --activo

            IF DATEPART(DAY, @inFechaOperacion) = 29 AND DATEPART(MONTH, @inFechaOperacion) > 8
            BEGIN
              
              select *
              FROM MovimientoArreglo;


            SELECT dcc.id, ma.id
			FROM MovimientoArreglo ma
			INNER JOIN ArregloDePago adp ON adp.id = ma.idArregloPago --obtenemos el idpropiedad
			INNER JOIN DetalleConceptoCobro dcc ON dcc.idConceptoCobro = 8
			WHERE dcc.monto = -1--@procesando
			AND adp.idEstado = 1 --activo
            AND ma.id = (SELECT MAX(ma2.[id])
                         FROM   [dbo].[MovimientoArreglo] ma2
                         WHERE  ma.idArregloPago = ma2.idArregloPago);
            END;

			--insertamos la conexion con el id detalleconceptoCobro
			INSERT INTO DetalleConceptoCobroArreglo(id,idMovimiento)
			SELECT dcc.id, ma.id
			FROM MovimientoArreglo ma
			INNER JOIN ArregloDePago adp ON adp.id = ma.idArregloPago --obtenemos el idpropiedad
			INNER JOIN DetalleConceptoCobro dcc ON dcc.idConceptoCobro = 8
			WHERE dcc.monto = -1--@procesando
			AND adp.idEstado = 1 --activo
            AND ma.id = (SELECT MAX(ma2.[id])
                         FROM   [dbo].[MovimientoArreglo] ma2
                         WHERE  ma.idArregloPago = ma2.idArregloPago);
			
			--actualizamo el monto de DetalleConceptoCobro Arreglo Pago
			UPDATE dcc
			SET dcc.monto = ma.montoCuota
			FROM DetalleConceptoCobro dcc
			INNER JOIN DetalleConceptoCobroArreglo dcca ON dcca.id = dcc.id --obtenemos el idmovimiento
			INNER JOIN MovimientoArreglo ma ON ma.id = dcca.idMovimiento -- obtenemos el monto
			WHERE dcc.idConceptoCobro = 8

			--por ultimo, actualizamos el saldo en arreglo de pago
			--UPDATE adp
			--SET adp.saldo
			--

		-- llegados a este punto DetalleConceptoCobro tiene el id de la factura, el id del cobro y el monto a cobrar

		-- para poder realizar la sumatoria de los montos utilizamos la tabla temporal @sumatoriaConceptos

		INSERT INTO @sumatoriaConceptos(idFactura,Monto)
		SELECT dcc.idFactura, SUM(dcc.monto)
		FROM DetalleConceptoCobro dcc
		INNER JOIN Factura f ON dcc.idFactura = f.id
		WHERE totalOriginal = @procesando
		GROUP BY dcc.idFactura
		

		--antes de terminar las facturas actualizamos el valor del agua consumida en propiedad

		UPDATE p
		SET p.acumuladoUltimaFactura = p.consumoAcumulado
		FROM Propiedad p
		INNER JOIN Factura f ON f.idPropiedad = p.id
		WHERE f.totalOriginal = @procesando -- sobrando, pero lo dejamos por seguridad

		--recordemos que:
		-- para encontrar la factura, indicamos el idPropiedad y totalOriginal = @procesando
		-- pero como ya tenemos el id de la factura entonces con eso basta
		UPDATE f
		SET f.totalOriginal = sc.Monto,
			f.totalActual = sc.Monto
		FROM Factura f
		INNER JOIN @sumatoriaConceptos sc ON sc.idFactura = f.id
		WHERE totalOriginal = @procesando -- sobrando, pero lo dejamos por seguridad
	
	COMMIT TRANSACTION

	END TRY
		BEGIN CATCH
        -- Si llega aca, hubo algun error

        --SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- Fue dentro de una transaccion?
        BEGIN
            ROLLBACK TRANSACTION GenerarFactura;
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