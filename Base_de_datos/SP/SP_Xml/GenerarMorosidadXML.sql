
USE proyecto
GO
-- SP que inserta crea la morosida de una factura
-- no incluye en el cobro  

ALTER PROCEDURE [dbo].[GenerarMorosidadXML]
						@inFechaOperacion DATE
AS
BEGIN

	DECLARE @sumatoriaConceptos TABLE --donde almacenaremos la sumatoria de los conceptos
	(
	    -- Llaves
	    id INT  PRIMARY KEY IDENTITY(1,1),
	    idFactura INT NOT NULL,
		Monto MONEY NOT NULL
	)

	DECLARE @FacturaMororas TABLE(
		
		id INT  PRIMARY KEY IDENTITY(1,1),
		idFactura INT NOT NULL,
		idPropiedad INT NOT NULL,
		mesesMorosos INT NOT NULL,
		total MONEY NOT NULL
	)

	DECLARE @CalculoMorosidad TABLE --donde almacenaremos la sumatoria de los conceptos
	(
	    -- Llaves
	    id INT  PRIMARY KEY IDENTITY(1,1),
	    idFactura INT NOT NULL,
		MontoCalculado MONEY NOT NULL
	)

	SET NOCOUNT ON;	
	
	BEGIN TRY

	BEGIN TRANSACTION GenerarMorosidad 

		--encontramos a cuales facturas hay que aplicarles morosidad
		INSERT INTO @FacturaMororas(idFactura,
								 idPropiedad,
								 mesesMorosos,
								 total)
		SELECT f.id, 
			   f.idPropiedad, 
			   (1+ MONTH(@inFechaOperacion) - MONTH(f.fechaVencimiento)),
			   f.totalOriginal
		FROM Factura f
		WHERE f.fechaVencimiento <= @inFechaOperacion -- solo si fecha actual es mayor que la de vencimiento
		AND f.idEstadoFactura = 1 -- si el estado es 'pendiente pago' 
		-- dia mas cernano del siguiente mes
		AND DAY(DATEADD(MONTH,
					   (MONTH(@inFechaOperacion)- MONTH(f.fechaVencimiento)),
					   f.fechaVencimiento)
			   ) = DAY(@inFechaOperacion) 


	--ya tenemos una lista de a cuales facturas aplicarle morosidad

		INSERT INTO @CalculoMorosidad (idFactura,
									   MontoCalculado)
		SELECT fm.idFactura,
			   ((fm.total * fm.mesesMorosos) * ccim.valorPorcentual)
		FROM @FacturaMororas fm
		INNER JOIN DetalleConceptoCobro dcc ON fm.idFactura = dcc.idFactura
		 -- vinculo para obtener precios de los impuestos
		INNER JOIN ConceptoCobro cc ON cc.id = dcc.idConceptoCobro
		--precio de morosidad (limitante a solo morosidad)
		INNER JOIN ConceptoCobroInteresesMoratorios ccim ON ccim.id = cc.id 

		UPDATE dcc
		SET dcc.monto = cm.MontoCalculado
		FROM DetalleConceptoCobro dcc
		INNER JOIN @CalculoMorosidad cm ON cm.idFactura = dcc.idFactura
		INNER JOIN ConceptoCobro cc ON 1=1 -- vinculo para obtener precios de los impuestos
		INNER JOIN ConceptoCobroInteresesMoratorios ccim ON 1=1 --(limitante a solo morosidad)
		WHERE cm.idFactura = dcc.idFactura AND cc.id = dcc.idConceptoCobro AND ccim.id = cc.id

		--calculamos el monto totalActual para cada factura siendo afectada

		INSERT INTO @sumatoriaConceptos(idFactura,Monto)
		SELECT dcc.idFactura, SUM(dcc.monto)
		FROM DetalleConceptoCobro dcc
		INNER JOIN @FacturaMororas fm ON dcc.idFactura = fm.idFactura
		GROUP BY dcc.idFactura

		--recordemos que:
		-- como ya tenemos el id de la factura entonces con eso basta para localizar la factura a actualizar

		UPDATE f
		SET f.totalActual = sc.Monto
		FROM Factura f
		INNER JOIN @sumatoriaConceptos sc ON sc.idFactura = f.id

	COMMIT TRANSACTION GenerarMorosidad 
	
	END TRY
	BEGIN CATCH
        -- Si llega aca, hubo algun error

        --SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- Fue dentro de una transaccion?
        BEGIN
            ROLLBACK TRANSACTION GenerarMorosidad;
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