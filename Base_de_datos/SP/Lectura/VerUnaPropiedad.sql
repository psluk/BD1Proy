/*
    Procedimiento que retorna la informaci�n de una propiedad
*/

/* Resumen de los c�digos de salida de este procedimiento
-- �xito --
        0: Correcto

-- Error --
    50000: Ocurri� un error desconocido
    50001: Credenciales inv�lidas
    50002: N�mero de finca inv�lido
*/

ALTER PROCEDURE [dbo].[VerUnaPropiedad]
    -- Variables de entrada
    @inNumeroFinca INT,

    -- Para determinar qui�n est� haciendo la consulta
    @inUsername VARCHAR(32)
AS
BEGIN
    -- Se define la variable donde se guarda el c�digo de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (�xito)
	DECLARE @idPropiedad AS INT;

    SET NOCOUNT ON;         -- Para evitar interferencias

    BEGIN TRY

        -- Verificamos que el usuario sea administrador
        IF NOT EXISTS(
					   SELECT 1 FROM [dbo].[Usuario] U
					   INNER JOIN [dbo].[TipoUsuario] T ON U.idTipoUsuario = T.id
					   WHERE U.nombreDeUsuario = @inUsername
					   AND T.nombre = 'Administrador'
					 )
        BEGIN
            -- Si llega ac�, el usuario no es administrador
            -- Entonces no retornamos nada
            SET @outResultCode = 50001;     -- Credenciales inv�lidas
            SELECT NULL AS 'Finca',
				   NULL AS 'Uso',
				   NULL AS 'Zona',
				   NULL AS 'Area',
				   NULL AS 'Fiscal',
				   NULL AS 'Registro',
				   NULL AS 'Medidor'
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Verificamos que exista la propiedad y obtenemos el ID en variable local
        
        IF EXISTS (
					SELECT 1 FROM [dbo].[Propiedad] P
					WHERE P.numeroFinca = @inNumeroFinca
				  )
        BEGIN
            -- S� existe
            SET @idPropiedad = (
								 SELECT P.id FROM [dbo].[Propiedad] P
								 WHERE P.numeroFinca = @inNumeroFinca
							   );
        END
        ELSE
        BEGIN 
            -- No existe
            -- Entonces no retornamos nada
            SET @outResultCode = 50002;     -- Propiedad inexistente
            SELECT NULL AS 'Finca',
				   NULL AS 'Uso',
				   NULL AS 'Zona',
				   NULL AS 'Area',
				   NULL AS 'Fiscal',
				   NULL AS 'Registro',
				   NULL AS 'Medidor'
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega ac�, se retorna la informaci�n
        SELECT P.numeroFinca AS 'Finca',
			   TU.nombre AS 'Uso',
			   TZ.nombre AS 'Zona',
			   P.area AS 'Area',
			   P.valorFiscal AS 'Fiscal',
			   P.fechaRegistro AS 'Registro',
			   AdP.numeroMedidor AS 'Medidor'
        FROM [dbo].[Propiedad] P
        INNER JOIN [dbo].[TipoUsoPropiedad] TU ON TU.id = P.idTipoUsoPropiedad
        INNER JOIN [dbo].[TipoZona] TZ ON TZ.id = P.idTipoZona
        INNER JOIN [dbo].[ConceptoCobroDePropiedad] CCdP ON CCdP.idPropiedad = P.id
        INNER JOIN [dbo].[AguaDePropiedad] AdP ON CCdP.id = AdP.id
        WHERE P.id = @idPropiedad;

        SELECT @outResultCode AS 'resultCode';

    END TRY
    BEGIN CATCH
        -- Ocurri� un error desconocido
        SET @outResultCode = 50000;     -- Error
        SELECT NULL AS 'Finca',
               NULL AS 'Uso',
               NULL AS 'Zona',
               NULL AS 'Area',
               NULL AS 'Fiscal',
               NULL AS 'Registro',
               NULL AS 'Medidor'
        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;

END;