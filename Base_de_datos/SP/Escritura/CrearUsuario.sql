/*
    Procedimiento que crea un usuario con los parametros dados
*/

/* Resumen de los codigos de salida de este procedimiento
-- exito --
        0: Insercion realizada correctamente

-- Error --
    50000: Ocurrio un error desconocido
    50001: Ocurrio un error desconocido en una transaccion
    50002: Credenciales incorrectas
    50003: Numero de finca invalido
    50004: Valor de area invalido
	50008: Ya hay un Usuario con ese nombre
	50009: No existe el la persona asociada a ese numero de identidad
*/

ALTER PROCEDURE [dbo].[CrearUsuario]
	-- Se definen las variables de entrada
    @inValorDocumentoIdentidad VARCHAR(32),
    @inTipoUsuario VARCHAR(32),
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
							AND T.nombre = 'Administrador'
						  );
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
		
		IF ISNUMERIC(@inValorDocumentoIdentidad) = 0
        BEGIN
            -- string de documento invalido (negativo)
            SET @outResultCode = 50003;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

		--sabemos que si es un numero por lo tanto
		--revisamo que sea un numero positivo

        IF CAST(@inValorDocumentoIdentidad AS BIGINT) < 0
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
		WHERE EXISTS( SELECT 1 
					  FROM [dbo].[Persona] 
					  WHERE p.valorDocumentoId = CAST(@inValorDocumentoIdentidad AS BIGINT));

		IF @Numero = 0
        BEGIN
            -- N�mero de DocumentoIdentidad invalido (negativo)
            SET @outResultCode = 50009;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;


        -- 3. Tipo de usuario valido?

        IF NOT EXISTS( SELECT 1 
					   FROM TipoUsuario tu 
					   WHERE tu.nombre = @inTipoUsuario)
        BEGIN
            -- Tipo de usuario invalido
            SET @outResultCode = 50004;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

		SET @idTipoUsuario = (SELECT id 
							  FROM [dbo].[TipoUsuario] tu 
							  WHERE tu.nombre = @inTipoUsuario
							 )

        -- 4. �Ya existe el nombre de usuario?
        IF EXISTS( SELECT 1 
				   FROM Usuario u
				   WHERE u.nombreDeUsuario = @inDbUsername
				 )
        BEGIN
            -- Usuario ya existe
            SET @outResultCode = 50008;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;;
        END
		
        -- Si llega ac�, ya pasaron las validaciones
        -- Se crea el mensaje para la bit�cora
        
        SET @LogDescription = 'Se inserta en la tabla [dbo].[Usuario]: '
            + '{Username = "' + @inDbUsername + '", '
            + 'Password = "' + @inPassword + '"'
            + '}';

        BEGIN TRANSACTION tCrearUsuario
            -- Empieza la transacci�n

            -- Se inserta la propiedad
            INSERT INTO [dbo].[Usuario] (
						[idPersona], 
						[idTipoUsuario], 
						[nombreDeUsuario], 
						[clave]
            )
            VALUES (
                @Numero,
                @idTipoUsuario,
                @inDbUsername,
                @inPassword
            );
			
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

        COMMIT TRANSACTION tCrearUsuario;

    END TRY
    BEGIN CATCH
        -- Si llega ac�, hubo alg�n error

        SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- �Fue dentro de una transacci�n?
        BEGIN
            ROLLBACK TRANSACTION tCrearUsuario;
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