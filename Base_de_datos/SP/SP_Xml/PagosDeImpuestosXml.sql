USE proyecto
GO
-- SP_XML que realiza los pagos de facturas2

ALTER PROCEDURE [dbo].[PagoDeImpuestosXML]
						@hdoc INT,
						@inFechaOperacion DATE
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @temp_Lecturas TABLE
	(
	    -- Llaves
	    id INT  PRIMARY KEY IDENTITY(1,1),
	    NumFinca int NOT NULL,
		TipoPago varchar(32) NOT NULL,
		ReferenciaComprobantePago int NOT NULL,
		FechaOperacion DATE
	
	);
	
	INSERT INTO @temp_Lecturas (
				NumFinca, 
				TipoPago, 
				ReferenciaComprobantePago, 
				FechaOperacion)
	SELECT NumFinca, 
		   TipoPago, 
		   NumeroReferenciaComprobantePago, 
		   @inFechaOperacion
	FROM OPENXML(@hdoc, 'Operacion/Pago/Pago', 1)
	WITH 
	(
	    NumFinca int,
		TipoPago varchar(32),
		NumeroReferenciaComprobantePago int
		
	);

	--registramos que el pago se hizo






	SET NOCOUNT OFF;
END