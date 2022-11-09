
USE proyecto
GO
-- SP que cambia el valor fiscal de prpiedad

ALTER PROCEDURE [dbo].[CambiarPropiedadXML]
						@hdoc INT,
						@inFechaOperacion DATE
AS
BEGIN

	SET NOCOUNT ON;	

	BEGIN TRY

	DECLARE @temp_Lecturas TABLE
	(
	    -- Llaves
	    id INT  PRIMARY KEY IDENTITY(1,1),
	    NumFinca INT,
		Valor INT,
		FechaOperacion DATE
	
	);
	
	-- obtenemos los pagos realizados del dia
	INSERT INTO @temp_Lecturas (NumFinca,
								Valor,
								FechaOperacion)
	SELECT NumFinca,
		   Valor,
		   @inFechaOperacion
	FROM OPENXML(@hdoc, 'Operacion/PropiedadCambio/PropiedadCambios', 1)
	WITH 
	(
		NumFinca INT,
		Valor INT
	);

	BEGIN TRANSACTION CambiarPropiedad
	
		UPDATE p
		SET p.valorFiscal = tl.Valor
		FROM Propiedad p
		INNER JOIN @temp_Lecturas tl ON tl.NumFinca = p.numeroFinca
	
	COMMIT TRANSACTION
	
	END TRY
	BEGIN CATCH
        -- Si llega aca, hubo algun error

        --SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- Fue dentro de una transaccion?
        BEGIN
            ROLLBACK TRANSACTION CambiarPropiedad;
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