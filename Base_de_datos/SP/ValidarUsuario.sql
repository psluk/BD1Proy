/*
    Procedimiento que verifica un nombre de usuario y una contraseña
    con los datos presentes en la base de datos.

    El nombre de usuario no distingue entre mayúsculas y minúsculas,
    pero la contraseña sí
*/

ALTER PROCEDURE [dbo].[ValidarUsuario]
    -- Se definen las variables de entrada
    @inUsername VARCHAR(32),
    @inClave VARCHAR(32)
AS
BEGIN
    SET NOCOUNT ON;         -- Para evitar interferencias

    -- Retorna 1 si lo encuentra. Si no, 0
    SELECT (CASE
            WHEN EXISTS (
                         SELECT 1 
                         FROM [dbo].[Usuario] U
                         WHERE CAST(U.nombreDeUsuario AS BINARY) = CAST(@inUsername AS BINARY)
                         AND CAST(U.clave AS BINARY) = CAST(@inClave AS BINARY)
                        ) 
            THEN 1
            ELSE 0
            END
           ) AS 'Resultado'

    SET NOCOUNT OFF;
END;