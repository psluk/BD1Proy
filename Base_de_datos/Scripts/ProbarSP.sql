


--_________________________________________________________________________________________________________________________________________________
--EXEC CrearUsuario '46228548','Administrador','PRUEBAprueba', 'NombrePrueba', 'guiltyChough3','199.999.999';
--@inValorDocumentoIdentidad VARCHAR(32), @inTipoUsuario VARCHAR(32), @inPassword VARCHAR(32), @inDbUsername VARCHAR(32), @inUsername VARCHAR(32), @inUserIp VARCHAR(64)	
--																							   nombre a registrar		  nombre de quien registra


--_________________________________________________________________________________________________________________________________________________
--nuevos valores:    *		    *               *                 *
--EXEC UpdateUsuario '84374642','Administrador','Comiendo fideos','actulizando',
--				   'PRUEBAprueba', 'NombrePrueba', 'guiltyChough3','199.999.999';
-- @inNuevoValorDocumentoIdentidad VARCHAR(32), @inNuevoTipoUsuario VARCHAR(32),@inNuevoPassword VARCHAR(32),@inNuevoDbUsername VARCHAR(32),
-- @inPassword VARCHAR(32),@inDbUsername VARCHAR(32), @inUsername VARCHAR(32), @inUserIp VARCHAR(64)

--_________________________________________________________________________________________________________________________________________________
--Datos originales 'Cedula CR','Robin Magee','84374642',32812449,53621879,'cc3daba8fe7a5f08@gmail.com'

--nuevos valores:                *           *             *          *        *         *                      
--EXEC UpdatePersona '123456789','Cedula CR','Robin Magee','84374642',32812449,53621879, 'cc3daba8fe7a5f08@gmail.com', 'guiltyChough3','199.999.999'
--@inValorDocumentoId VARCHAR(32), @inNuevoTipoDocumentoId VARCHAR(32),@inNuevoNombre VARCHAR(64),@inNuevoValorDocumentoId VARCHAR(32),
--@inNuevoTelefono1 BIGINT,@inNuevoTelefono2 BIGINT,@inNuevoEmail VARCHAR(128), @inUsername VARCHAR(32),@inUserIp VARCHAR(64)

--_________________________________________________________________________________________________________________________________________________


--EXEC CrearPersona 'Cedula CR', 'nombrecito', '123456789', 11111111, 22222222,'pruebita@hotmail.com', 'guiltyChough3','199.999.999'
-- @inNuevoTipoDocumentoId VARCHAR(32),@inNuevoNombre VARCHAR(64),@inNuevoValorDocumentoId VARCHAR(32),@inNuevoTelefono1 BIGINT,
-- @inNuevoTelefono2 BIGINT,@inNuevoEmail VARCHAR(128),@inUsername VARCHAR(32),@inUserIp VARCHAR(64)

	--SELECT * FROM Persona p WHERE p.Id >= 650 
	--DELETE FROM Persona WHERE Persona.id >=650

--_________________________________________________________________________________________________________________________________________________

EXEC LeerPersona '84374642';
-- @inValorDocumentoId