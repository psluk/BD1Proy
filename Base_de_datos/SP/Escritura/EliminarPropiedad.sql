/*
    Procedimiento que borra una propiedad seg�n su n�mero de finca
*/

/* Resumen de los c�digos de salida de este procedimiento
-- �xito --
        0: Eliminaci�n realizada correctamente

-- Error --
    50000: Ocurri� un error desconocido
    50001: Ocurri� un error desconocido en una transacci�n
    50002: Credenciales incorrectas
    50003: No existe el n�mero de finca
*/

ALTER PROCEDURE [dbo].[EliminarPropiedad]
    -- Se definen las variables de entrada
    @inNumeroFinca INT,

    -- Para determinar qui�n est� haciendo la transacci�n
    @inUsername VARCHAR(32),
    @inUserIp VARCHAR(64)
AS
BEGIN
    -- Se define la variable donde se guarda el c�digo de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (�xito)
	DECLARE @idUser INT;            -- Para guardar el ID del usuario
	DECLARE @idPropiedad INT;       -- Donde se guardar� el ID de la propiedad
    DECLARE @countInicial INT = @@TRANCOUNT;

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

        -- 2. �N�mero de finca v�lido?

        IF EXISTS ( SELECT 1 
					FROM [dbo].[Propiedad] P
					WHERE P.numeroFinca = @inNumeroFinca
				  )
        BEGIN
            -- S� existe
            SET @idPropiedad = ( SELECT P.id 
								 FROM [dbo].[Propiedad] P
								 WHERE P.numeroFinca = @inNumeroFinca
							   )
        END
        ELSE
        BEGIN
            -- N�mero de finca inexistente
            SET @outResultCode = 50003;
            SELECT @outResultCode AS 'resultCode';
            SET NOCOUNT OFF;
            RETURN;
        END;

        -- Si llega ac�, ya pasaron las validaciones

        BEGIN TRANSACTION tBorrarPropiedad
            -- Empieza la transacci�n


            -- Se eliminan las filas de otras tablas que dependen de esta
            DELETE UdP
            FROM [dbo].[UsuarioDePropiedad] UdP
            WHERE UdP.[idPropiedad] = @idPropiedad;

            DELETE PdP 
            FROM [dbo].[PropietarioDePropiedad] PdP
            WHERE PdP.[idPropiedad] = @idPropiedad;
            
            DELETE Reco
            FROM [dbo].[OrdenReconexion] Reco
            INNER JOIN [dbo].[OrdenCorta] Corta ON Reco.[idOrdenCorta] = Corta.[id]
            WHERE Corta.[idPropiedad] = @idPropiedad;

            DELETE Corta
            FROM [dbo].[OrdenCorta] Corta
            WHERE [idPropiedad] = @idPropiedad;

            DELETE P
            FROM [dbo].[Pago] P
            INNER JOIN [dbo].[Factura] F ON P.[id] = F.[id]
            WHERE F.[idPropiedad] = @idPropiedad;

            DELETE DCCA
            FROM [dbo].[DetalleConceptoCobroAgua] DCCA
            INNER JOIN [dbo].[DetalleConceptoCobro] DCC ON DCCA.[idDetalleConceptoCobro] = DCC.[id]
            INNER JOIN [dbo].[Factura] F ON DCC.[idFactura] = F.[id]
            WHERE F.[idPropiedad] = @idPropiedad;

            DELETE DCC
            FROM [dbo].[DetalleConceptoCobro] DCC
            INNER JOIN [dbo].[Factura] F ON DCC.[idFactura] = F.[id]
            WHERE F.[idPropiedad] = @idPropiedad;

            DELETE Mov
            FROM [dbo].[MovimientoConsumo] Mov
            INNER JOIN [dbo].[ConceptoCobroDePropiedad] CCdP ON Mov.[idAguaDePropiedad] = CCdP.[id]
            WHERE CCdP.[idPropiedad] = @idPropiedad;

            DELETE AdP
            FROM [dbo].[AguaDePropiedad] AdP
            INNER JOIN [dbo].[ConceptoCobroDePropiedad] CCdP ON AdP.[id] = CCdP.[id]
            WHERE CCdP.[idPropiedad] = @idPropiedad;

            DELETE CCdP
            FROM [dbo].[ConceptoCobroDePropiedad] CCdP
            WHERE CCdP.[idPropiedad] = @idPropiedad;

            -- Se elimina la propiedad
            DELETE FROM [dbo].[Propiedad]
            WHERE [id] = @idPropiedad;

            -- Les da los datos faltantes al evento
            UPDATE  EL
            SET     [insertedByUser] = @idUser,
                    [insertedInIp] = @inUserIp
            FROM    [dbo].[EventLog] EL
            WHERE   [insertedByUser] IS NULL;

        COMMIT TRANSACTION tBorrarPropiedad;

    END TRY
    BEGIN CATCH
        -- Si llega ac�, hubo alg�n error

        SET @outResultCode = 50000;     -- Error desconocido

        IF @@TRANCOUNT > @countInicial  -- �Fue dentro de una transacci�n?
        BEGIN
            ROLLBACK TRANSACTION tBorrarPropiedad;
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