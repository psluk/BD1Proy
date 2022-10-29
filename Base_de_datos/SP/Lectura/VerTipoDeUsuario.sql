
/* Sp encargado de informar que tipo de usuario es


	Devuelve: 
	
	0 si es no administrador
	1 si es administrador
*/


ALTER PROCEDURE [dbo].[VerTipoDeUsuario]
    @inNombreUsuario VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @output INT = 0;

    IF EXISTS( SELECT 1
			   FROM [dbo].[Usuario] U
			   INNER JOIN [dbo].[TipoUsuario] TU ON U.[idTipoUsuario] = TU.[id]
			   WHERE u.[nombreDeUsuario] = @inNombreUsuario
			   AND TU.nombre = 'Administrador')
    BEGIN
        SET @output = 1;
    END;

    SELECT @output AS "resultCode";
    SET NOCOUNT OFF;
END;