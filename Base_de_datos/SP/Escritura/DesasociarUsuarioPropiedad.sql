﻿/*
    Procedimiento que desasocia un Usuario y una propiedad
*/

/* Resumen de los códigos de salida de este procedimiento
-- Éxito --
        0: Inserción realizada correctamente

-- Error --
    50000: Ocurrio un error desconocido
    50001: Ocurrio un error desconocido en una transaccion
    50002: Credenciales incorrectas
    50011: No existe la relación
*/

ALTER PROCEDURE [dbo].[DesasociarUsuarioPropiedad]
    -- Se definen las variables de entrada
    @inDbUsername VARCHAR(32),
	@inNumeroFinca INT,

    -- Para determinar quién está haciendo la transacción
    @inUsername VARCHAR(32),
    @inUserIp VARCHAR(64)
AS
BEGIN
    -- Se define la variable donde se guarda el código de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (éxito)
	DECLARE @idUsuarioPropiedad INT = 0;    -- Para guardar el ID de la asociación
	DECLARE @fechaActual DATETIME;
    DECLARE @jsonAntes VARCHAR(512);

    SET NOCOUNT ON;         -- Para evitar interferencias

    BEGIN TRY
        -- Empiezan las validaciones

        -- 1. ¿Existe el usuario como administrador?
        DECLARE @idUser INT;            -- Para guardar el ID del usuario
        IF EXISTS( SELECT 1 
				   FROM [dbo].[Usuario] U
				   INNER JOIN [dbo].[TipoUsuario] T
				   ON U.idTipoUsuario = T.id
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

		-- 2. ¿Existe la asociación?
		SELECT @idUsuarioPropiedad = udp.id
		FROM [dbo].[UsuarioDePropiedad] udp
		WHERE EXISTS(SELECT 1 
					 FROM [dbo].[UsuarioDePropiedad] udp
					 INNER JOIN [dbo].[Usuario] u ON udp.idUsuario = u.id
					 INNER JOIN [dbo].[Propiedad] p ON udp.idPropiedad = p.id
					 WHERE u.nombreDeUsuario = @inDbUsername
					 AND p.numeroFinca = @inNumeroFinca );

		IF @idUsuarioPropiedad = 0
        BEGIN
            -- Relacion no encontrada, no existe
            SET @outResultCode = 50011;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega acá, ya pasaron las validaciones
        
        SET @fechaActual = GETDATE();

        SET @jsonAntes = (SELECT   UdP.[idUsuario] AS 'idUsuario', 
						           UdP.[idPropiedad] AS 'idPropiedad', 
						           UdP.[fechaInicio] AS 'fechaInicio', 
						           '' AS 'fechaFin'
						           FROM [dbo].[UsuarioDePropiedad] UdP
						           WHERE UdP.[id] = @idUsuarioPropiedad
						           FOR JSON AUTO);

        BEGIN TRANSACTION tAsociarPropietarioPropiedad
            -- Empieza la transacción

            -- Se actualiza
            UPDATE [dbo].[UsuarioDePropiedad]
            SET [fechaFin] = @fechaActual
            WHERE [id] = @idUsuarioPropiedad;

            INSERT INTO EventLog([idEntityType], 
								 [entityId], 
								 [jsonAntes], 
								 [jsonDespues], 
								 [insertedAt], 
								 [insertedByUser], 
								 [insertedInIp])
			SELECT 5, 
				   UdP.id, 
				   @jsonAntes,
				  (SELECT   UdP2.[idUsuario] AS 'idUsuario', 
						    UdP2.[idPropiedad] AS 'idPropiedad', 
						    UdP2.[fechaInicio] AS 'fechaInicio', 
						    UdP2.[fechaFin] AS 'fechaFin'
						    FROM [dbo].[UsuarioDePropiedad] UdP2
						    WHERE UdP2.[id] = UdP.[id]
						    FOR JSON AUTO),
				  GETDATE(),
				  @idUser,
				  @inUserIp
			FROM    [dbo].[UsuarioDePropiedad] UdP
			WHERE   UdP.[id] = @idUsuarioPropiedad;

        COMMIT TRANSACTION tAsociarPropietarioPropiedad;

    END TRY
    BEGIN CATCH
        -- Si llega acá, hubo algún error

        SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > 0              -- ¿Fue dentro de una transacción?
        BEGIN
            ROLLBACK TRANSACTION tAsociarPropietarioPropiedad;
            SET @outResultCode = 50001; -- Error desconocido dentro de la transacción
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