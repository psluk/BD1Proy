-- Script que se encarga de cargar los datos de los catálogos

DECLARE @inputData xml; -- Donde se cargará el XML

SELECT @inputData = D
FROM OPENROWSET (
	BULK
	'C:\Users\p7285\GitHub\BD1Proy\Base_de_datos\Archivos XML\Catalogo.xml',
	SINGLE_BLOB)
AS inputData(D);

DECLARE @hdoc INT; -- Identificador (handle)

-- Arma la estructura del XML en memoria y retorna el handle
EXEC sp_xml_preparedocument @hdoc OUTPUT, @inputData;

-- CATEGORÍA: Personas y usuarios

-- AQUÍ SE CARGA: Tipos de documento de identidad

INSERT INTO [dbo].[TipoDocumentoId] (id, nombre, mascara)
SELECT id, Nombre, Mascara
FROM OPENXML(@hdoc, '/Catalogo/TipoDocumentoIdentidades/TipoDocumentoIdentidad', 1)
WITH (
	id INT,
	Nombre VARCHAR(32),
	Mascara VARCHAR(32)
	);

-- AQUÍ SE CARGA: Tipos de asociaciones

INSERT INTO [dbo].[TipoAsociacion] (id, descripcion)
SELECT id, Nombre
FROM OPENXML(@hdoc, '/Catalogo/TipoAsociaciones/TipoAsociacion', 1)
WITH (
	id INT,
	Nombre VARCHAR(32)
	);

-- CATEGORÍA: Propiedades

-- AQUÍ SE CARGA: Tipos de uso de propiedad

INSERT INTO [dbo].[TipoUsoPropiedad] (id, nombre)
SELECT id, Nombre
FROM OPENXML(@hdoc, '/Catalogo/TipoUsoPropiedades/TipoUsoPropiedad', 1)
WITH (
	id INT,
	Nombre VARCHAR(32)
	);

-- AQUÍ SE CARGA: Tipos de zona

INSERT INTO [dbo].[TipoZona] (id, nombre)
SELECT id, Nombre
FROM OPENXML(@hdoc, '/Catalogo/TipoZonaPropiedades/TipoZonaPropiedad', 1)
WITH (
	id INT,
	Nombre VARCHAR(32)
	);

-- CATEGORÍA: Conceptos de cobro

-- AQUÍ SE CARGA: Tipos de monto de concepto de cobro

INSERT INTO [dbo].[TipoMontoConceptoCobro] (id, descripcion)
SELECT id, Nombre
FROM OPENXML(@hdoc, '/Catalogo/TipoMontoCCs/TipoMontoCC', 1)
WITH (
	id INT,
	Nombre VARCHAR(32)
	);

-- AQUÍ SE CARGA: Tipos de periodos de concepto de cobro

INSERT INTO [dbo].[TipoPeriodoConceptoCobro] (id, descripcion, cantidadMeses)
SELECT id, Nombre, QMeses
FROM OPENXML(@hdoc, '/Catalogo/PeriodoMontoCCs/PeriodoMontoCC', 1)
WITH (
	id INT,
	Nombre VARCHAR(32),
	QMeses INT
	);

-- AQUÍ SE CARGA: Conceptos de cobro (CC)

-- Se hace una tabla temporal para más facilidad
DECLARE @ConceptoCobroTemp TABLE (
	id INT,
	nombre VARCHAR(32),
	idTipoMonto INT,
	idPeriodoMonto INT,
	
	montoMinimo MONEY,
	volumenMinimo INT,
	volumenTracto INT,
	montoTracto MONEY,
	
	valorPorcentual MONEY, -- MONEY da precisión de decimal de base 10
	valorFijo MONEY,
	
	areaMinima INT,
	areaTracto INT
);

-- Carga la información de los nodos XML en la tabla temporal
INSERT INTO @ConceptoCobroTemp (
	id,
	nombre,
	idTipoMonto,
	idPeriodoMonto,
	montoMinimo,
	volumenMinimo,
	volumenTracto,
	valorPorcentual,
	valorFijo,
	areaMinima,
	areaTracto,
	montoTracto)
SELECT id, Nombre, TipoMontoCC, PeriodoMontoCC, ValorMinimo,
	ValorMinimoM3, Valorm3, ValorPorcentual, ValorFijo,
	ValorM2Minimo, ValorTractosM2, ValorFijoM3Adicional
FROM OPENXML(
	@hdoc,
	'/Catalogo/CCs/CC',
	1)
WITH (
	id INT,
	Nombre VARCHAR(32),
	TipoMontoCC INT,
	PeriodoMontoCC INT,
	ValorMinimo MONEY,
	ValorMinimoM3 INT,
	Valorm3 INT,
	ValorPorcentual MONEY,
	ValorFijo MONEY,
	ValorM2Minimo INT,
	ValorTractosM2 INT,
	ValorFijoM3Adicional MONEY
	);

-- Se carga la información en la tabla [dbo].[ConceptoCobro]

INSERT INTO [dbo].[ConceptoCobro] (
	id,
	idTipoMontoConceptoCobro,
	idTipoPeriodoConceptoCobro,
	nombre)
SELECT CCT.id, CCT.idTipoMonto, CCT.idPeriodoMonto, CCT.nombre
FROM @ConceptoCobroTemp CCT;

-- El volumen del tracto del agua no puede ser 0. Si hay un 0, lo cambia a 1
UPDATE @ConceptoCobroTemp
	SET volumenTracto = 1
	WHERE nombre = 'ConsumoAgua' AND volumenTracto = 0;

-- Se carga la información en la tabla [dbo].[ConceptoCobroAgua]
INSERT INTO [dbo].[ConceptoCobroAgua] (
	id, montoMinimo, consumoMinimo, volumenTracto, montoTracto)
SELECT CCT.id, CCT.montoMinimo, CCT.volumenMinimo, CCT.volumenTracto, CCT.montoTracto
FROM @ConceptoCobroTemp CCT
WHERE CCT.nombre = 'ConsumoAgua';

-- Se carga la información en la tabla [dbo].[ConceptoCobroPatente]
INSERT INTO [dbo].[ConceptoCobroPatente] (id, valorPatente)
SELECT CCT.id, CCT.valorFijo
FROM @ConceptoCobroTemp CCT
WHERE CCT.nombre = 'Patente Comercial';

-- Se carga la información en la tabla [dbo].[ConceptoCobroImpuestoPropiedad]
INSERT INTO [dbo].[ConceptoCobroImpuestoPropiedad] (id, valorPorcentual)
SELECT CCT.id, CCT.valorPorcentual
FROM @ConceptoCobroTemp CCT
WHERE CCT.nombre = 'Impuesto a propiedad';

-- Se carga la información en la tabla [dbo].[ConceptoCobroBasura]
INSERT INTO [dbo].[ConceptoCobroBasura] (
	id, montoMinimo, areaMinima, areaTracto, montoTracto)
SELECT CCT.id, CCT.montoMinimo, CCT.areaMinima, CCT.areaTracto, CCT.valorFijo
FROM @ConceptoCobroTemp CCT
WHERE CCT.nombre = 'Recoleccion Basura';

-- Se carga la información en la tabla [dbo].[ConceptoCobroParques]
INSERT INTO [dbo].[ConceptoCobroParques] (
	id, valorFijo)
SELECT CCT.id, CCT.valorFijo
FROM @ConceptoCobroTemp CCT
WHERE CCT.nombre = 'MantenimientoParques';

-- Se carga la información en la tabla [dbo].[ConceptoCobroInteresesMoratorios]
INSERT INTO [dbo].[ConceptoCobroInteresesMoratorios] (
	id, valorPorcentual)
SELECT CCT.id, CCT.valorPorcentual
FROM @ConceptoCobroTemp CCT
WHERE CCT.nombre = 'Intereses Moratorios';

-- Se carga la información en la tabla [dbo].[ConceptoCobroReconexionAgua]
INSERT INTO [dbo].[ConceptoCobroReconexionAgua] (
	id, monto)
SELECT CCT.id, CCT.valorFijo
FROM @ConceptoCobroTemp CCT
WHERE CCT.nombre = 'Reconexion';

-- CATEGORÍA: Lecturas de medidor

-- AQUÍ SE CARGA: Tipos de movimientos de lectura de medidor

INSERT INTO [dbo].[TipoMovimientoConsumo] (id, nombre)
SELECT id, Nombre
FROM OPENXML(
	@hdoc,
	'/Catalogo/TipodeMovimientoLecturadeMedidores/TipodeMovimientoLecturadeMedidor',
	1)
WITH (
	id INT,
	Nombre VARCHAR(32)
	);

-- CATEGORÍA: Pagos

-- AQUÍ SE CARGA: Tipos de medio de pago

INSERT INTO [dbo].[TipoMedioPago] (id, descripcion)
SELECT id, Nombre
FROM OPENXML(@hdoc, '/Catalogo/TipoMedioPagos/TipoMedioPago', 1)
WITH (
	id INT,
	Nombre VARCHAR(64)
	);

-- CATEGORÍA: Parámetros del sistema

-- AQUÍ SE CARGA: Tipos de parámetros del sistema

INSERT INTO [dbo].[TipoParametroSistema] (id, descripcion)
SELECT id, Nombre
FROM OPENXML(@hdoc, '/Catalogo/TipoParametroSistema/TipoParametro', 1)
WITH (
	id INT,
	Nombre VARCHAR(16)
	);

-- AQUÍ SE CARGA: Parámetros del sistema

-- Se hace una tabla temporal para relacionar los parámetros con su tipo
DECLARE @ParametrosSistemaTemp TABLE (
	id INT,
	descripcion VARCHAR(128),
	valor INT,
	nombreTipo VARCHAR(16)
);

-- Carga la información de los nodos XML en la tabla temporal
INSERT INTO @ParametrosSistemaTemp (
	id,
	descripcion,
	valor,
	nombreTipo)
SELECT id, Nombre, Valor, NombreTipoPar
FROM OPENXML(@hdoc, '/Catalogo/ParametrosSistema/ParametroSistema', 1)
WITH (
	id INT,
	Nombre VARCHAR(128),
	NombreTipoPar VARCHAR(16),
	Valor INT
	);

-- Se carga la información en la tabla [dbo].[ParametroSistema]
INSERT INTO [dbo].[ParametroSistema] (
	id,
	idTipoParametroSistema,
	descripcion,
	valor)
SELECT P.id, Tipo.id, P.descripcion, P.valor
FROM [dbo].[TipoParametroSistema] Tipo, @ParametrosSistemaTemp P
WHERE Tipo.descripcion = P.nombreTipo;

EXEC sp_xml_removedocument @hdoc; -- Libera la memoria utilizada para la estructura del XML