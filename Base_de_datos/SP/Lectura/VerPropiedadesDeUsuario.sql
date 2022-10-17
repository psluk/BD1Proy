/*
    Procedimiento que retorna las propiedades a las que est�
    asociadado un usuario (con el nombre de usuario)
*/

/* Resumen de los c�digos de salida de este procedimiento
-- �xito --
        0: Correcto

-- Error --
    50000: Ocurri� un error desconocido
    50001: Credenciales inv�lidas
    50002: El usuario no existe
*/

ALTER PROCEDURE [dbo].[VerPropiedadesDeUsuario]
    -- Se definen las variables de entrada
    @inUsernameConsultado VARCHAR(32),

    -- Para determinar qui�n est� haciendo la consulta
    @inUsername VARCHAR(32)
AS
BEGIN
    -- Se define la variable donde se guarda el c�digo de salida
    DECLARE @outResultCode AS INT = 0;  -- Por defecto, 0 (�xito)

    SET NOCOUNT ON;         -- Para evitar interferencias

    BEGIN TRY

        -- Verificamos que el usuario sea administrador
        -- o, si no, que est� buscando sus propias propiedades
        IF NOT EXISTS(
                SELECT 1 FROM [dbo].[Usuario] U
                INNER JOIN [dbo].[TipoUsuario] T
                ON U.idTipoUsuario = T.id
                WHERE U.nombreDeUsuario = @inUsername
                    AND (T.nombre = 'Administrador'
                    OR U.nombreDeUsuario = @inUsernameConsultado)
                )
        BEGIN
            -- Si llega ac�, el usuario no tiene permiso para ver
            -- las propiedades
            -- Entonces no retornamos nada
            SET @outResultCode = 50001;     -- Credenciales inv�lidas
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

        -- Verificamos que exista el usuario y obtenemos el ID
        DECLARE @idUsuario AS INT;
        IF EXISTS (
            SELECT 1 FROM [dbo].[Usuario] U
            WHERE U.nombreDeUsuario = @inUsernameConsultado
            )
        BEGIN
            -- S� existe
            SET @idUsuario = (
                SELECT id FROM [dbo].[Usuario] U
                WHERE U.nombreDeUsuario = @inUsernameConsultado
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

        -- Si llega ac�, se buscan las propiedades
        SELECT P.numeroFinca AS 'Finca',
            TU.nombre AS 'Uso',
            TZ.nombre AS 'Zona',
            P.area AS 'Area',
            P.valorFiscal AS 'Fiscal',
            P.fechaRegistro AS 'Registro',
            UdP.fechaInicio AS 'Inicio_relacion'
        FROM [dbo].[Propiedad] P
        INNER JOIN [dbo].[UsuarioDePropiedad] UdP
        ON UdP.idPropiedad = P.id
        INNER JOIN [dbo].[TipoUsoPropiedad] TU
        ON TU.id = P.idTipoUsoPropiedad
        INNER JOIN [dbo].[TipoZona] TZ
        ON TZ.id = P.idTipoZona
        WHERE UdP.idUsuario = @idUsuario
            AND UdP.fechaFin IS NULL; -- NULL = sigue activa la relaci�n

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
                NULL AS 'Inicio_relacion'
        SELECT @outResultCode AS 'resultCode';

    END CATCH;

    SET NOCOUNT OFF;

END;