/*
    segun el valor del documento identidad intentara buscar un a la persona correspondite
*/

ALTER PROCEDURE [dbo].[LeerPersona]
    -- Se definen las variables de entrada
    @inValorDocumentoIdentidad VARCHAR(32)
AS
BEGIN
	-- Se define la variable donde se guarda el código de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (éxito)
	
	SET NOCOUNT ON;         -- Para evitar interferencias

	IF NOT EXISTS(SELECT 1 FROM [dbo].[Persona] p WHERE p.valorDocumentoId = @inValorDocumentoIdentidad)
	BEGIN
		--no se encontro a la persona
		SELECT [idTipoDocumentoId] = NULL, [nombre]= NULL, [valorDocumentoId]= NULL, [telefono1]= NULL, [telefono2]= NULL, [email]= NULL
		SET @outResultCode = 50009;
	END

	ELSE
	BEGIN
		--si se encontro a la persona
		SELECT [idTipoDocumentoId], [nombre], [valorDocumentoId], [telefono1], [telefono2], [email]
		FROM Persona p
		WHERE p.valorDocumentoId = @inValorDocumentoIdentidad

	END
	SELECT @outResultCode AS 'resultCode';

    SET NOCOUNT OFF;
END;