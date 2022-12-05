/*
    SP que actualiza los datos del Usuario
*/

/* Resumen de los c�digos de salida de este procedimiento
-- �xito --
        0: Inserci�n realizada correctamente

-- Error --
    50000: Ocurri� un error desconocido
    50001: Ocurri� un error desconocido en una transacci�n
    50002: Credenciales incorrectas
    50003: N�mero de finca inv�lido
    50004: Valor de �rea inv�lido
    50005: No existe el tipo de zona
    50006: No existe el tipo de uso de la propiedad
    50007: Ya hay una propiedad con ese n�mero de finca
	50008: Ya hay un Usuario con ese nombre
	50009: No existe el la persona asociada a ese numero de identidad
*/

ALTER PROCEDURE [dbo].[UpdateUsuario]
	-- Se definen las variables de entrada
    @inNuevoValorDocumentoIdentidad VARCHAR(32),
    @inNuevoTipoUsuario VARCHAR(32),
	@inNuevoPassword VARCHAR(32),
    @inNuevoDbUsername VARCHAR(32),
    @inPassword VARCHAR(32),
    @inDbUsername VARCHAR(32),
	

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
	DECLARE @idTipoUsuario AS INT = -1; -- por defecto (negativo)
    DECLARE @jsonAntes VARCHAR(512);

    SET NOCOUNT ON;         -- Para evitar interferencias
    
    BEGIN TRY
        -- Empiezan las validaciones
        -- 1. �Existe el usuario como administrador?
        
        IF EXISTS(
            SELECT 1 FROM [dbo].[Usuario] U
            INNER JOIN [dbo].[TipoUsuario] T
            ON U.idTipoUsuario = T.id
            WHERE U.nombreDeUsuario = @inUsername
                AND T.nombre = 'Administrador'
            )
        BEGIN
            SET @idUser = (SELECT U.id FROM [dbo].[Usuario] U
                INNER JOIN [dbo].[TipoUsuario] T
                ON U.idTipoUsuario = T.id
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

		--2. numero de documento valido?

		--revisamos que el string sea un numero
		
		IF ISNUMERIC(@inNuevoValorDocumentoIdentidad) = 0
        BEGIN
            -- string de documento invalido (negativo)
            SET @outResultCode = 50003;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

		--sabemos que si es un numero por lo tanto
		--revisamo que sea un numero positivo

        IF CAST(@inNuevoValorDocumentoIdentidad AS BIGINT) < 0
        BEGIN
            -- N�mero de DocumentoIdentidad invalido (negativo)
            SET @outResultCode = 50003;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;
        
		--obtenemos el id del docummento identidad asociado
		--de no existir @Numero = 0
		SELECT @Numero = p.id
		FROM [dbo].[Persona] p
		WHERE EXISTS(SELECT 1 
					 FROM [dbo].[Persona] 
					 WHERE p.valorDocumentoId = @inNuevoValorDocumentoIdentidad);

		IF @Numero = 0
        BEGIN
            -- N�mero de DocumentoIdentidad invalido (negativo)
            SET @outResultCode = 50009;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;


        -- 3. Tipo de usuario valido?

        IF NOT EXISTS(SELECT 1 
				  FROM TipoUsuario tu 
				  WHERE tu.nombre = @inNuevoTipoUsuario)
        BEGIN
            -- Tipo de usuario invalido
            SET @outResultCode = 50004;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

		SET @idTipoUsuario = (SELECT id FROM [dbo].[TipoUsuario] tu WHERE tu.nombre = @inNuevoTipoUsuario)

        -- 4. �Ya existe el nombre de usuario?
        IF EXISTS(
            SELECT 1 FROM Usuario u
            WHERE CAST(u.nombreDeUsuario AS BINARY) = CAST(@inNuevoDbUsername AS BINARY) AND CAST(@inNuevoDbUsername AS BINARY) != CAST(@inDbUsername AS BINARY)
            )
        BEGIN
            -- Usuario ya existe y diferente que el actual
            SET @outResultCode = 50008;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;;
        END

		--5. �existe el nombre de usuario a cambiar?
		IF NOT EXISTS(
            SELECT 1 FROM Usuario u
            WHERE CAST(u.nombreDeUsuario AS BINARY) = CAST(@inDbUsername AS BINARY)
            )
        BEGIN
            -- Usuario no existe
            SET @outResultCode = 50002;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;;
        END

		--6. �es la clave correcta del usuario a cambiar?
		IF NOT EXISTS(
            SELECT 1 FROM Usuario u
            WHERE CAST(u.clave AS BINARY) = CAST(@inPassword AS BINARY)
            )
        BEGIN
            -- clave no existe
            SET @outResultCode = 50002;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;;
        END
		
        -- Si llega ac�, ya pasaron las validaciones

        -- generamos el json de la informacion antes de la actualizacion
        SET @jsonAntes = (SELECT  U.[idPersona],
						   U.[idTipoUsuario],
						   U.[nombreDeUsuario],
                           U.[clave]
						   FROM Usuario U
			               WHERE U.[nombreDeUsuario] = @inDbUsername
						   FOR JSON AUTO);

        BEGIN TRANSACTION tupdateUsuario
            -- Empieza la transacci�n

            -- Se actualiza al Usuario
            UPDATE [dbo].[Usuario]
		    SET [idPersona] = @Numero, 
				[idTipoUsuario] = @idTipoUsuario, 
		        [nombreDeUsuario] = @inNuevoDbUsername, 
		        [clave] = @inNuevoPassword
			WHERE [dbo].[Usuario].nombreDeUsuario = @inDbUsername;

            -- Inserta el evento
            INSERT INTO EventLog([idEntityType], 
								 [entityId], 
								 [jsonAntes], 
								 [jsonDespues], 
								 [insertedAt], 
								 [insertedByUser], 
								 [insertedInIp])
			SELECT 3, 
				   U.id,
                   @jsonAntes,
				  (SELECT  U2.[idPersona],
						   U2.[idTipoUsuario],
						   U2.[nombreDeUsuario],
                           U2.[clave]
						   FROM Usuario U2
			                WHERE U.[id] = U2.[id]
						   FOR JSON AUTO),
				  GETDATE(),
				  @idUser,
				  @inUserIp
			FROM    [dbo].[Usuario] U
			WHERE   U.nombreDeUsuario = @inDbUsername;

        COMMIT TRANSACTION tupdateUsuario;

    END TRY
    BEGIN CATCH
        -- Si llega ac�, hubo alg�n error

        SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- �Fue dentro de una transacci�n?
        BEGIN
            ROLLBACK TRANSACTION tupdateUsuario;
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