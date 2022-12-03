/*
    Procedimiento que retorna las propiedades a las que está
    asociadada una persona (con la identificación de la persona)
*/

/* Resumen de los códigos de salida de este procedimiento
-- Éxito --
        0: Correcto

-- Error --
    50000: Ocurrió un error desconocido
    50001: Credenciales inválidas
    50002: La persona no existe
*/

ALTER PROCEDURE [dbo].[VerPropiedadesDePersona]
    -- Se definen las variables de entrada
    @inValorDocumentoId VARCHAR(32),

    -- Para determinar quién está haciendo la consulta
    @inUsername VARCHAR(32)
AS
BEGIN
    -- Se define la variable donde se guarda el código de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (éxito)
	DECLARE @idPersona AS INT;

    SET NOCOUNT ON;         -- Para evitar interferencias

    BEGIN TRY

        -- Verificamos que el usuario sea administrador
        IF NOT EXISTS( SELECT 1 
					   FROM [dbo].[Usuario] U
					   INNER JOIN [dbo].[TipoUsuario] T ON U.idTipoUsuario = T.id
					   WHERE U.nombreDeUsuario = @inUsername
					   AND T.nombre = 'Administrador'
					 )
        BEGIN
            -- Si llega acá, el usuario no es administrador
            -- Entonces no retornamos nada
            SET @outResultCode = 50001;     -- Credenciales inválidas
            SELECT NULL AS 'Finca',
				   NULL AS 'Uso',
				   NULL AS 'Zona',
				   NULL AS 'Area',
				   NULL AS 'Fiscal',
				   NULL AS 'Registro',
				   NULL AS 'Inicio_relacion'

            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Verificamos que exista la persona y obtenemos el ID
        IF EXISTS ( SELECT 1 
					FROM [dbo].[Persona] P
					WHERE P.valorDocumentoId = @inValorDocumentoId
				  )
        BEGIN
            -- Sí existe
            SET @idPersona = ( SELECT P.id 
							   FROM [dbo].[Persona] P
							   WHERE P.valorDocumentoId = @inValorDocumentoId
							 );
        END
        ELSE
        BEGIN 
            -- No existe
            -- Entonces no retornamos nada
            SET @outResultCode = 50002;     -- Persona inexistente
            SELECT NULL AS 'Finca',
				   NULL AS 'Uso',
				   NULL AS 'Zona',
				   NULL AS 'Area',
				   NULL AS 'Fiscal',
				   NULL AS 'Registro',
				   NULL AS 'Inicio_relacion'

            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega acá, se buscan las propiedades
        SELECT P.numeroFinca AS 'Finca',
			   TU.nombre AS 'Uso',
			   TZ.nombre AS 'Zona',
			   P.area AS 'Area',
			   P.valorFiscal AS 'Fiscal',
			   P.fechaRegistro AS 'Registro',
			   PdP.fechaInicio AS 'Inicio_relacion'
        FROM [dbo].[Propiedad] P
        INNER JOIN [dbo].[PropietarioDePropiedad] PdP ON PdP.idPropiedad = P.id
        INNER JOIN [dbo].[TipoUsoPropiedad] TU ON TU.id = P.idTipoUsoPropiedad
        INNER JOIN [dbo].[TipoZona] TZ ON TZ.id = P.idTipoZona
        WHERE PdP.idPersona = @idPersona
        AND PdP.fechaFin IS NULL; -- NULL = sigue activa la relación

        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Ocurrió un error desconocido
        SET @outResultCode = 50000;     -- Error
        SELECT NULL AS 'Finca',
               NULL AS 'Uso',
               NULL AS 'Zona',
               NULL AS 'Area',
               NULL AS 'Fiscal',
               NULL AS 'Registro',
               NULL AS 'Inicio_relacion'

        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;

END;