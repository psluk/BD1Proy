/*
    Procedimiento para eliminar a una Persona
*/

/* Resumen de los c�digos de salida de este procedimiento
-- �xito --
        0: Inserci�n realizada correctamente

-- Error --
    50000: Ocurri� un error desconocido
    50001: Ocurri� un error desconocido en una transacci�n
    50002: Credenciales incorrectas
	50009: No existe el la persona asociada a ese numero de identidad
*/

AlTER PROCEDURE [dbo].[EliminarPersona]
	-- Se definen las variables de entrada

	@inValorDocumentoId VARCHAR(32),


    -- Para determinar qui�n est� haciendo la transacci�n
    @inUsername VARCHAR(32),
    @inUserIp VARCHAR(64)
AS
BEGIN
    -- Se define la variable donde se guarda el c�digo de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (�xito)
	DECLARE @idUser INT;            -- Para guardar el ID del usuario
	DECLARE @Numero AS BIGINT = 0; -- por defecto, 0 (fallo)
	DECLARE @strTexto AS VARCHAR(32) = ''; -- por defecto (vacio)
	DECLARE @idTipoDocumentoId AS INT = -1; -- por defecto (negativo)
	DECLARE @Nombre VARCHAR(64);
	DECLARE @Telefono1 BIGINT;
	DECLARE @Telefono2 BIGINT;
	DECLARE @Email VARCHAR(128);
	DECLARE @LogDescription VARCHAR(512);
	

    SET NOCOUNT ON;         -- Para evitar interferencias
    
    BEGIN TRY
        -- Empiezan las validaciones
        -- 1. �Existe el usuario como administrador?
        
        IF EXISTS( SELECT 1 
				   FROM [dbo].[Usuario] U
				   INNER JOIN [dbo].[TipoUsuario] T ON U.idTipoUsuario = T.id
				   WHERE U.nombreDeUsuario = @inUsername
                   AND T.nombre = 'Administrador'
				 )
        BEGIN
            SET @idUser = ( SELECT U.id 
						    FROM [dbo].[Usuario] U
							INNER JOIN [dbo].[TipoUsuario] T ON U.idTipoUsuario = T.id
							WHERE U.nombreDeUsuario = @inUsername
							AND T.nombre = 'Administrador');
        END
        ELSE
        BEGIN
            SET @outResultCode = 50002; -- Credenciales incorrectas
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

		--2. existe la persona a borrar?

        
		--obtenemos el id del docummento identidad asociado
		--de no existir @Numero = 0
		SELECT @Numero = p.id
		FROM [dbo].[Persona] p
		WHERE EXISTS(SELECT 1 
					 FROM [dbo].[Persona] 
					 WHERE p.valorDocumentoId = @inValorDocumentoId);

		IF @Numero = 0
        BEGIN
            -- N�mero de DocumentoIdentidad no existe
            SET @outResultCode = 50009;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

	-- recopilamos la informacion de la persona por ser eliminada

	SELECT @idTipoDocumentoId =[idTipoDocumentoId], 
		   @Nombre =[nombre], 
		   @Telefono1 =[telefono1], 
		   @Telefono2 =[telefono2],
		   @Email =[email]
	FROM Persona p
	WHERE p.valorDocumentoId = @inValorDocumentoId
	
		
        -- Si llega ac�, ya pasaron las validaciones
        -- Se crea el mensaje para la bit�cora
        
        SET @LogDescription = 'Se Elimina en la tabla [dbo].[Persona]: '
            + '{ValorDocumentoId = "' + @inValorDocumentoId + '", '
			+ 'TipoDocumentoId = "' + CAST(@idTipoDocumentoId AS VARCHAR(32)) + '"'
			+ 'Nombre  = "' + @Nombre + '"'
            + 'Telefono1 = "' + CAST(@Telefono1 AS VARCHAR(32)) + '"'
			+ 'Telefono2 = "' + CAST(@Telefono2 AS VARCHAR(32)) + '"'
            + 'Email = "' + @Email + '"'
            + '}';

        BEGIN TRANSACTION tEliminarPersona
            -- Empieza la transacci�n

			--se elimina la relacion propiedaPropietario
			DELETE pdp FROM PropietarioDePropiedad pdp
			INNER JOIN Persona p ON pdp.idPersona = p.id 
			WHERE p.valorDocumentoId = @inValorDocumentoId

			-- Se Elimina la Persona
			DELETE FROM Persona 
			WHERE Persona.valorDocumentoId = @inValorDocumentoId

			
            -- Se inserta el evento
            INSERT INTO [dbo].[EventLog] (
                 [LogDescription],
                 [PostTime],
                 [PostByUserId],
                 [PostInIp]
            )
            VALUES (
                @LogDescription,
                GETDATE(),
                @idUser,
                @inUserIp
            );

        COMMIT TRANSACTION tEliminarPersona;

    END TRY
    BEGIN CATCH
        -- Si llega ac�, hubo alg�n error

        SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- �Fue dentro de una transacci�n?
        BEGIN
            ROLLBACK TRANSACTION tEliminarPersona;
            SET @outResultCode = 50001; -- Error desconocido dentro de la transacci�n
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

    SELECT @outResultCode AS 'resultCode';
    SET NOCOUNT OFF;
END;