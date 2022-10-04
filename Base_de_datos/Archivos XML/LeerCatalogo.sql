-- Script que se encarga de cargar los datos de los catálogos

DECLARE @inputData xml; -- Donde se cargará el XML

SELECT @inputData = D
FROM OPENROWSET (
	BULK
	'C:\Users\p7285\Desktop\Proyecto - Bases de Datos\Catalogo.xml',
	SINGLE_BLOB)
AS inputData(D);

DECLARE @hdoc int; -- Identificador (handle)

-- Arma la estructura del XML en memoria y retorna el handle
EXEC sp_xml_preparedocument @hdoc OUTPUT, @inputData;

-- CATEGORÍA: Personas y usuarios

-- AQUÍ SE CARGA: Tipos de documento de identidad

INSERT INTO [dbo].[TipoDocumentoId] (nombre)
SELECT Nombre
FROM OPENXML(@hdoc, '/Catalogo/TipoDocumentoIdentidades/TipoDocumentoIdentidad', 1)
WITH (
	Nombre varchar(32)
	);

-- AQUÍ SE CARGA: Tipos de usuarios

INSERT INTO [dbo].[TipoDocumentoId] (nombre)
SELECT Nombre
FROM OPENXML(@hdoc, '/Catalogo/TipoUsuarios/TipoUsuario', 1)
WITH (
	Nombre varchar(32)
	);

-- AQUÍ SE CARGA: Tipos de asociaciones

INSERT INTO [dbo].[TipoAsociacion] (descripcion)
SELECT Nombre
FROM OPENXML(@hdoc, '/Catalogo/TipoAsociaciones/TipoAsociacion', 1)
WITH (
	Nombre varchar(32)
	);

-- CATEGORÍA: Propiedades

-- AQUÍ SE CARGA: Tipos de uso de propiedad

INSERT INTO [dbo].[TipoUsoPropiedad] (nombre)
SELECT Nombre
FROM OPENXML(@hdoc, '/Catalogo/TipoUsoPropiedades/TipoUsoPropiedad', 1)
WITH (
	Nombre varchar(32)
	);

-- AQUÍ SE CARGA: Tipos de zona

INSERT INTO [dbo].[TipoZona] (nombre)
SELECT Nombre
FROM OPENXML(@hdoc, '/Catalogo/TipoZonaPropiedades/TipoZonaPropiedad', 1)
WITH (
	Nombre varchar(32)
	);

-- CATEGORÍA: Conceptos de cobro

-- AQUÍ SE CARGA: Tipos de monto de concepto de cobro

-- Se hace una tabla temporal para relacionar los CC con estos tipos
DECLARE @TipoMontoCC TABLE (
	id int,
	nombre varchar(32)
);

-- Carga la información de los nodos XML en la tabla temporal
INSERT INTO @TipoMontoCC (id, nombre)
SELECT id, Nombre
FROM OPENXML(@hdoc, '/Catalogo/TipoMontoCCs/TipoMontoCC', 1)
WITH (
	id int,
	Nombre varchar(32)
	);

-- Carga la información a la tabla [dbo].[TipoMontoConceptoCobro]
INSERT INTO [dbo].[TipoMontoConceptoCobro] (descripcion)
SELECT M.nombre
FROM @TipoMontoCC M;

-- AQUÍ SE CARGA: Tipos de periodos de concepto de cobro

-- Se hace una tabla temporal para relacionar los CC con estos tipos
DECLARE @TipoPeriodoCC TABLE (
	id int,
	nombre varchar(32),
	cantidadMeses int
);

-- Carga la información de los nodos XML en la tabla temporal
INSERT INTO @TipoPeriodoCC (id, nombre, cantidadMeses)
SELECT id, Nombre, QMeses
FROM OPENXML(@hdoc, '/Catalogo/PeriodoMontoCCs/PeriodoMontoCC', 1)
WITH (
	id int,
	Nombre varchar(32),
	QMeses int
	);

-- Carga la información a la tabla [dbo].[TipoPeriodoConceptoCobro]
INSERT INTO [dbo].[TipoPeriodoConceptoCobro] (descripcion, cantidadMeses)
SELECT P.nombre, P.cantidadMeses
FROM @TipoPeriodoCC P;

-- AQUÍ SE CARGA: Conceptos de cobro (CC)

-- Se hace una tabla temporal para relacionar los CC con sus tipos
DECLARE @ConceptoCobroTemp TABLE (
	nombre varchar(32),
	idTipoMonto int,
	idPeriodoMonto int,
	
	montoMinimo money,
	volumenMinimo int,
	volumenTracto int,
	montoTracto money,
	
	valorPorcentual money, -- money da precisión de decimal de base 10
	valorFijo money,
	
	areaMinima int,
	areaTracto int
);

-- Carga la información de los nodos XML en la tabla temporal
INSERT INTO @ConceptoCobroTemp (
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
SELECT Nombre, TipoMontoCC, PeriodoMontoCC, ValorMinimo,
	ValorMinimoM3, Valorm3, ValorPorcentual, ValorFijo,
	ValorM2Minimo, ValorTractosM2, ValorFijoM3Adicional
FROM OPENXML(
	@hdoc,
	'/Catalogo/CCs/CC',
	1)
WITH (
	Nombre varchar(32),
	TipoMontoCC int,
	PeriodoMontoCC int,
	ValorMinimo money,
	ValorMinimoM3 int,
	Valorm3 int,
	ValorPorcentual money,
	ValorFijo money,
	ValorM2Minimo int,
	ValorTractosM2 int,
	ValorFijoM3Adicional money
	);

-- Se carga la información en la tabla [dbo].[ConceptoCobro]

INSERT INTO [dbo].[ConceptoCobro] (
	idTipoMontoConceptoCobro,
	idTipoPeriodoConceptoCobro,
	nombre)
SELECT Monto.id, Periodo.id, CC.nombre
FROM [dbo].[TipoMontoConceptoCobro] Monto,
	[dbo].[TipoPeriodoConceptoCobro] Periodo,
	@ConceptoCobroTemp CC,
	@TipoMontoCC MontoTemp,
	@TipoPeriodoCC PeriodoTemp
WHERE Monto.descripcion = MontoTemp.nombre AND CC.idTipoMonto = MontoTemp.id
	AND Periodo.descripcion = PeriodoTemp.nombre AND CC.idPeriodoMonto = PeriodoTemp.id;

-- El volumen del tracto del agua no puede ser 0. Si hay un 0, lo cambia a 1
UPDATE @ConceptoCobroTemp
	SET volumenTracto = 1
	WHERE nombre = 'ConsumoAgua' AND volumenTracto = 0;

-- Se carga la información en la tabla [dbo].[ConceptoCobroAgua]
INSERT INTO [dbo].[ConceptoCobroAgua] (
	id, montoMinimo, consumoMinimo, volumenTracto, montoTracto)
SELECT CC.id, CCT.montoMinimo, CCT.volumenMinimo, CCT.volumenTracto, CCT.montoTracto
FROM [dbo].[ConceptoCobro] CC, @ConceptoCobroTemp CCT
WHERE CCT.nombre = 'ConsumoAgua' AND CCT.nombre = CC.nombre

-- Se carga la información en la tabla [dbo].[ConceptoCobroPatente]
INSERT INTO [dbo].[ConceptoCobroPatente] (id, valorPatente)
SELECT CC.id, CCT.valorFijo
FROM [dbo].[ConceptoCobro] CC, @ConceptoCobroTemp CCT
WHERE CCT.nombre = 'Patente Comercial' AND CCT.nombre = CC.nombre

-- Se carga la información en la tabla [dbo].[ConceptoCobroImpuestoPropiedad]
INSERT INTO [dbo].[ConceptoCobroImpuestoPropiedad] (id, valorPorcentual)
SELECT CC.id, CCT.valorPorcentual
FROM [dbo].[ConceptoCobro] CC, @ConceptoCobroTemp CCT
WHERE CCT.nombre = 'Impuesto a propiedad' AND CCT.nombre = CC.nombre

-- Se carga la información en la tabla [dbo].[ConceptoCobroBasura]
INSERT INTO [dbo].[ConceptoCobroBasura] (
	id, montoMinimo, areaMinima, areaTracto, montoTracto)
SELECT CC.id, CCT.montoMinimo, CCT.areaMinima, CCT.areaTracto, CCT.valorFijo
FROM [dbo].[ConceptoCobro] CC, @ConceptoCobroTemp CCT
WHERE CCT.nombre = 'Recoleccion Basura' AND CCT.nombre = CC.nombre

-- Se carga la información en la tabla [dbo].[ConceptoCobroParques]
INSERT INTO [dbo].[ConceptoCobroParques] (
	id, valorFijo)
SELECT CC.id, CCT.valorFijo
FROM [dbo].[ConceptoCobro] CC, @ConceptoCobroTemp CCT
WHERE CCT.nombre = 'MantenimientoParques' AND CCT.nombre = CC.nombre

-- Se carga la información en la tabla [dbo].[ConceptoCobroInteresesMoratorios]
INSERT INTO [dbo].[ConceptoCobroInteresesMoratorios] (
	id, valorPorcentual)
SELECT CC.id, CCT.valorPorcentual
FROM [dbo].[ConceptoCobro] CC, @ConceptoCobroTemp CCT
WHERE CCT.nombre = 'Intereses Moratorios' AND CCT.nombre = CC.nombre

-- Se carga la información en la tabla [dbo].[ConceptoCobroReconexionAgua]
INSERT INTO [dbo].[ConceptoCobroReconexionAgua] (
	id, monto)
SELECT CC.id, CCT.valorFijo
FROM [dbo].[ConceptoCobro] CC, @ConceptoCobroTemp CCT
WHERE CCT.nombre = 'Reconexion' AND CCT.nombre = CC.nombre

-- CATEGORÍA: Lecturas de medidor

-- AQUÍ SE CARGA: Tipos de movimientos de lectura de medidor

INSERT INTO [dbo].[TipoMovimientoConsumo] (nombre)
SELECT Nombre
FROM OPENXML(
	@hdoc,
	'/Catalogo/TipodeMovimientoLecturadeMedidores/TipodeMovimientoLecturadeMedidor',
	1)
WITH (
	Nombre varchar(32)
	);

-- CATEGORÍA: Pagos

-- AQUÍ SE CARGA: Tipos de medio de pago

INSERT INTO [dbo].[TipoMedioPago] (descripcion)
SELECT Nombre
FROM OPENXML(@hdoc, '/Catalogo/TipoMedioPagos/TipoMedioPago', 1)
WITH (
	Nombre varchar(64)
	);

-- CATEGORÍA: Parámetros del sistema

-- AQUÍ SE CARGA: Tipos de parámetros del sistema

INSERT INTO [dbo].[TipoParametroSistema] (descripcion)
SELECT Nombre
FROM OPENXML(@hdoc, '/Catalogo/TipoParametroSistema/TipoParametro', 1)
WITH (
	Nombre varchar(16)
	);

-- AQUÍ SE CARGA: Parámetros del sistema

-- Se hace una tabla temporal para relacionar los parámetros con su tipo
DECLARE @ParametrosSistemaTemp TABLE (
	descripcion varchar(128),
	valor int,
	nombreTipo varchar(16)
);

-- Carga la información de los nodos XML en la tabla temporal
INSERT INTO @ParametrosSistemaTemp (
	descripcion,
	valor,
	nombreTipo)
SELECT Nombre, Valor, NombreTipoPar
FROM OPENXML(@hdoc, '/Catalogo/ParametrosSistema/ParametroSistema', 1)
WITH (
	Nombre varchar(128),
	NombreTipoPar varchar(16),
	Valor int
	);

-- Se carga la información en la tabla [dbo].[ParametroSistema]
INSERT INTO [dbo].[ParametroSistema] (
	idTipoParametroSistema,
	descripcion,
	valor)
SELECT T.id, P.descripcion, P.valor
FROM [dbo].[TipoParametroSistema] T, @ParametrosSistemaTemp P
WHERE T.descripcion = P.nombreTipo;

EXEC sp_xml_removedocument @hdoc; -- Libera la memoria utilizada para la estructura del XML