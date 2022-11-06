	
	--Instrucciones
	
	--Para medir de forma adecuada la cantidad de desasociaciones realizadas se creo una tabla.
	
	--Adicionalmente se añande un pequeño segmento de codigo: en (Des)AsociarUsuarioPropiedadXml.sql
	


	--Instrucciones de uso

	--hacer pull de git
	--crear la tabla socorro (codigo de creacion viene abajo)
	--correr (Des)AsociarUsuarioPropiedadXml.sql para que aplique los cambios del git
	--correr limpiar tablas, leer catalogo(si no ha sido corrido) y LeerOperaciones.sql
	--correr el select de abajo

	--CREATE TABLE socorro(
	--
	--id INT PRIMARY KEY IDENTITY(1,1),
	--idUsuario INT NOT NULL,
	--idPersona INT NOT NULL,
	--ValorDocumentoIdentidad BIGINT NOT NULL,
	--idPropiedad INT NOT NULL,
	--NumeroFinca INT NOT NULL,
	--TipoAsociacion varchar(32) NOT NULL,
	--FechaOperacion DATE
	--)


SELECT * FROM socorro s JOIN socorro ss ON 1=1
WHERE s.TipoAsociacion = 'Agregar' AND ss.TipoAsociacion = 'Eliminar'
AND s.ValorDocumentoIdentidad = ss.ValorDocumentoIdentidad
AND s.FechaOperacion <= ss.FechaOperacion