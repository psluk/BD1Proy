/*
    Procedimiento para eliminar a un Usuario con unos par�metros dados
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
	50009: No existe la persona/Usuario indicado
	50010: Ya hay una Persona con ese documento identidad
*/

ALTER PROCEDURE [dbo].[EliminarUsuario]
	-- Se definen las variables de entrada
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

		--2. nombre de Usuario a borrar existe?
        
		--obtenemos el id del Usuario
		--de no existir @Numero = 0
		SELECT @Numero = u.id
		FROM [dbo].[Usuario] u
		WHERE EXISTS(SELECT 1 
					 FROM [dbo].[Usuario] u
					 WHERE CAST(u.nombreDeUsuario AS BINARY) = CAST(@inDbUsername AS BINARY)) 
			  AND CAST(u.nombreDeUsuario AS BINARY) = CAST(@inDbUsername AS BINARY);

		IF @Numero = 0
        BEGIN
            -- Nombre de Usuario a borrar no existe
            SET @outResultCode = 50009;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;


        --3. esta correcta la clave?
        
		SET @Numero = 0;

		--verificamos que la clave sea correcta
		--de no existir @Numero = 0
		SELECT @Numero = u.id
		FROM [dbo].[Usuario] u
		WHERE EXISTS(SELECT 1 
					 FROM [dbo].[Usuario] u
					 WHERE CAST(u.clave AS BINARY) = CAST(@inPassword AS BINARY)) 
			  AND CAST(u.clave AS BINARY) = CAST(@inPassword AS BINARY);

		IF @Numero = 0
        BEGIN
            -- Clave no coincide
            SET @outResultCode = 50002;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

		
        -- Si llega ac�, ya pasaron las validaciones
        -- Se crea el mensaje para la bit�cora
        DECLARE @LogDescription VARCHAR(512);
        SET @LogDescription = 'Se Elimina en la tabla [dbo].[Usuario]: '
            + '{Username = "' + @inDbUsername + '", '
            + 'Password = "' + @inPassword + '"'
            + '}';

        BEGIN TRANSACTION tEliminarUsuario
            -- Empieza la transacci�n

			--se elimina la relacion propiedaUsuario
			DELETE udp FROM UsuarioDePropiedad udp
			INNER JOIN Usuario u ON udp.idUsuario = u.id 
			WHERE CAST(u.clave AS BINARY) = CAST(@inPassword AS BINARY)

			-- Se Elimina al Usuario
			DELETE u FROM Usuario u
			WHERE CAST(u.nombreDeUsuario AS BINARY) = CAST(@inDbUsername AS BINARY)
            
			
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

        COMMIT TRANSACTION tEliminarUsuario;

    END TRY
    BEGIN CATCH
        -- Si llega ac�, hubo alg�n error

        SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- �Fue dentro de una transacci�n?
        BEGIN
            ROLLBACK TRANSACTION tEliminarUsuario;
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