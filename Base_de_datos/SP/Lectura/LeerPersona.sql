/*
    segun el valor del documento identidad intentara buscar un a la persona correspondite


-- Error --
	50000: Ocurrió un error desconocido
    50009: No existe el la persona asociada a ese numero de identidad
*/

ALTER PROCEDURE [dbo].[LeerPersona]
    -- Se definen las variables de entrada
    @inValorDocumentoIdentidad VARCHAR(32)
AS
BEGIN
	-- Se define la variable donde se guarda el código de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (éxito)
	
	SET NOCOUNT ON;         -- Para evitar interferencias

	BEGIN TRY

		IF NOT EXISTS(SELECT 1 
					  FROM [dbo].[Persona] p 
					  WHERE p.valorDocumentoId = @inValorDocumentoIdentidad
					 )
		BEGIN
			--no se encontro a la persona
			SELECT [idTipoDocumentoId] = NULL, 
				   [nombre]= NULL, 
				   [valorDocumentoId]= NULL, 
				   [telefono1]= NULL, 
				   [telefono2]= NULL, 
				   [email]= NULL
			SET @outResultCode = 50009;
		END

		ELSE
		BEGIN
			--si se encontro a la persona
			SELECT [idTipoDocumentoId], 
				   [nombre], 
				   [valorDocumentoId], 
				   [telefono1], 
				   [telefono2], 
				   [email]
			FROM Persona p
			WHERE p.valorDocumentoId = @inValorDocumentoIdentidad

		END

		SELECT @outResultCode AS 'resultCode';
		
	END TRY

	BEGIN CATCH
        -- Si llega acá, es porque ocurrió un error

        SELECT [idTipoDocumentoId] = NULL, 
				   [nombre]= NULL, 
				   [valorDocumentoId]= NULL, 
				   [telefono1]= NULL, 
				   [telefono2]= NULL, 
				   [email]= NULL
		SET @outResultCode = 50000;

    END CATCH;

	SET NOCOUNT OFF;
END;