
--SP insercion de personas mediante xml
-- inserta todas las personas del nodo entregado

ALTER PROCEDURE [dbo].[InsertarPersonasXml]
						@hdoc INT

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @temp_Persona TABLE 
	(
    -- Llave
    id INT PRIMARY KEY IDENTITY(1,1),

	--columnas
    ValorDocumentoIdentidad INT NOT NULL,
    Nombre VARCHAR(64) NOT NULL,
    TipoDocumentoIdentidad VARCHAR(32) NOT NULL,
    Telefono1 BIGINT NOT NULL,
    Telefono2 BIGINT NOT NULL,
    Email VARCHAR(128) NOT NULL
	);
	
	
	INSERT INTO @temp_Persona (
				[nombre], 
				[TipoDocumentoIdentidad], 
				[ValorDocumentoIdentidad], 
				[telefono1], 
				[telefono2], 
				[email])
	
	SELECT Nombre, 
		   TipoDocumentoIdentidad, 
		   ValorDocumentoIdentidad, 
		   Telefono1, 
		   Telefono2, 
		   Email
	FROM OPENXML(@hdoc, 'Operacion/Personas/Persona', 1)
	WITH 
	(
		ValorDocumentoIdentidad INT,
		Nombre VARCHAR(64),
		TipoDocumentoIdentidad VARCHAR(32),
		Telefono1 BIGINT,
		Telefono2 BIGINT,
		Email VARCHAR(128)
	);
	
    -- realizamos la insercion de personas
	INSERT INTO [dbo].[Persona] (
				[idTipoDocumentoId], 
				[nombre], 
				[valorDocumentoId],
				[telefono1], 
				[telefono2], 
				[email])
	SELECT td.id AS idTipoDocumentoId, 
		   tp.[Nombre], 
		   [ValorDocumentoIdentidad], 
		   [telefono1], 
		   [telefono2], 
		   [email] 
	FROM @temp_Persona tp
	INNER JOIN [dbo].[TipoDocumentoId] td ON tp.TipoDocumentoIdentidad = td.nombre

	SET NOCOUNT OFF;
END