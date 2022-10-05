-- Este script es utilizado para crear las tablas
-- Tambi�n crea las relaciones necesarias (llaves primarias y externas)

-- CATEGOR�A: PERSONAS

CREATE TABLE dbo.TipoDocumentoId
(
    -- Llaves
    id int NOT NULL,

    -- Columnas
    nombre varchar(32) NOT NULL,
    
    -- Se establece la llave primaria
    CONSTRAINT PK_id PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.Persona
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idTipoDocumentoId int NOT NULL,

    -- Otras columnas
    nombre varchar(64) NOT NULL,
    valorDocumentoId varchar(32) NOT NULL,
    telefono1 bigint NOT NULL,
    telefono2 bigint NOT NULL,
    email varchar(128) NOT NULL

    -- Se establece la llave primaria
    CONSTRAINT PK_Persona PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_Persona_TipoDocumentoId FOREIGN KEY (idTipoDocumentoId)
        REFERENCES dbo.TipoDocumentoId (id)
);

-- CATEGOR�A: USUARIOS

CREATE TABLE dbo.TipoUsuario
(
    -- Llaves
    id int NOT NULL,

    -- Otras columnas
    nombre varchar(32) NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_TipoUsuario PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.Usuario
(
    -- Llaves
    id int NOT NULL,
    idTipoUsuario int NOT NULL,

    -- Otras columnas
    nombreDeUsuario varchar(32) NOT NULL,
    clave varchar(32) NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_Usuario PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_Usuario_Persona FOREIGN KEY (id)
        REFERENCES dbo.Persona (id),
    CONSTRAINT FK_Usuario_TipoUsuario FOREIGN KEY (idTipoUsuario)
        REFERENCES dbo.TipoUsuario (id)
);

-- CATEGOR�A: PROPIEDADES

CREATE TABLE dbo.TipoUsoPropiedad
(
    -- Llaves
    id int NOT NULL,

    -- Otras columnas
    nombre varchar(32) NOT NULL

    -- Se establece la llave primaria
    CONSTRAINT PK_TipoUsoPropiedad PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.TipoZona
(
    -- Llaves
    id int NOT NULL,

    -- Otras columnas
    nombre varchar(32) NOT NULL

    -- Se establece la llave primaria
    CONSTRAINT PK_TipoZona PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.Propiedad
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idTipoUsoPropiedad int NOT NULL,
    idTipoZona int NOT NULL,

    -- Otras columnas
    numeroFinca int NOT NULL,
    area int NOT NULL,
    valorFiscal bigint NOT NULL,
    fechaRegistro date NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_Propiedad PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_Propiedad_TipoUsoPropiedad FOREIGN KEY (idTipoUsoPropiedad)
        REFERENCES dbo.TipoUsoPropiedad (id),
    CONSTRAINT FK_Propiedad_TipoZona FOREIGN KEY (idTipoZona)
        REFERENCES dbo.TipoZona (id)
);

-- CATEGOR�A: Propiedad + (Persona o Usuario)

CREATE TABLE dbo.TipoAsociacion
(
	-- Llaves
	id int NOT NULL,

	-- Otras columnas
	descripcion varchar(32),

	-- Se establece la llave primaria
    CONSTRAINT PK_TipoAsociacion PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.PropietarioDePropiedad
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idPersona int NOT NULL,
    idPropiedad int NOT NULL,

    -- Otras columnas
    fechaInicio date NOT NULL,
    fechaFin date NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_PropietarioDePropiedad PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_PropietarioDePropiedad_Persona FOREIGN KEY (idPersona)
        REFERENCES dbo.Persona (id),
    CONSTRAINT FK_PropietarioDePropiedad_Propiedad FOREIGN KEY (idPropiedad)
        REFERENCES dbo.Propiedad (id)
);

CREATE TABLE dbo.UsuarioDePropiedad
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idUsuario int NOT NULL,
    idPropiedad int NOT NULL,

    -- Otras columnas
    fechaInicio date NOT NULL,
    fechaFin date NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_UsuarioDePropiedad PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_UsuarioDePropiedad_Persona FOREIGN KEY (idUsuario)
        REFERENCES dbo.Usuario (id),
    CONSTRAINT FK_UsuarioDePropiedad_Propiedad FOREIGN KEY (idPropiedad)
        REFERENCES dbo.Propiedad (id)
);

-- CATEGOR�A: Facturas

CREATE TABLE dbo.EstadoFactura
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),

    -- Otras columnas
    descripcion varchar(32) NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_EstadoFactura PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.Factura
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idPropiedad int NOT NULL,
    idEstadoFactura int NOT NULL,

    -- Otras columnas
    fechaGeneracion date NOT NULL,
    fechaVencimiento date NOT NULL,
    totalOriginal money NOT NULL,
    totalActual money NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_Factura PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_Factura_Propiedad FOREIGN KEY (idPropiedad)
        REFERENCES dbo.Propiedad (id),
    CONSTRAINT FK_Factura_EstadoFactura FOREIGN KEY (idEstadoFactura)
        REFERENCES dbo.EstadoFactura (id)
);

-- CATEGOR�A: Pagos

CREATE TABLE dbo.TipoMedioPago
(
	-- Llaves
	id int NOT NULL,

	-- Otras columnas
	descripcion varchar(64) NOT NULL,

	-- Se establece la llave primaria
	CONSTRAINT PK_TipoMedioPago PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.Pago
(
	-- Llaves
    id int NOT NULL,
	idTipoMedioPago int NOT NULL,

    -- Otras columnas
    fechaPago date NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_Pago PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
	CONSTRAINT FK_Pago_Factura FOREIGN KEY (id)
		REFERENCES dbo.Factura (id),
	CONSTRAINT FK_Pago_TipoMedioPago FOREIGN KEY
		(idTipoMedioPago) REFERENCES dbo.TipoMedioPago (id)
);

-- CATEGOR�A: Conceptos de cobro

CREATE TABLE dbo.TipoPeriodoConceptoCobro
(
	-- Llaves
	id int NOT NULL,

	-- Otras columnas
	descripcion varchar(32) NOT NULL,
	cantidadMeses int NOT NULL,

	-- Se establece la llave primaria
	CONSTRAINT PK_TipoPeriodoConceptoCobro PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.TipoMontoConceptoCobro
(
	-- Llaves
	id int NOT NULL,

	-- Otras columnas
	descripcion varchar(32) NOT NULL,

	-- Se establece la llave primaria
	CONSTRAINT PK_TipoMontoConceptoCobro PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.ConceptoCobro
(
    -- Llaves
    id int NOT NULL,
	idTipoPeriodoConceptoCobro int NOT NULL,
	idTipoMontoConceptoCobro int NOT NULL,

    -- Otras columnas
    nombre varchar(32) NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobro PRIMARY KEY CLUSTERED (id),

	 -- Se asocian las llaves externas
	 CONSTRAINT FK_ConceptoCobro_TipoPeriodoConceptoCobro FOREIGN KEY
		(idTipoPeriodoConceptoCobro) REFERENCES dbo.TipoPeriodoConceptoCobro (id),
	 CONSTRAINT FK_ConceptoCobro_TipoMontoConceptoCobro FOREIGN KEY
		(idTipoMontoConceptoCobro) REFERENCES dbo.TipoMontoConceptoCobro (id)
);

CREATE TABLE dbo.ConceptoCobroDePropiedad
(
    -- Llaves
    id int NOT NULL,
    idPropiedad int NOT NULL,
    idConceptoCobro int NOT NULL,

    -- Otras columnas
    fechaInicio date NOT NULL,
    fechaFin date NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroDePropiedad PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroDePropiedad_Propiedad FOREIGN KEY (idPropiedad)
        REFERENCES dbo.Propiedad (id),
    CONSTRAINT FK_ConceptoCobroDePropiedad_ConceptoCobro FOREIGN KEY (idConceptoCobro)
        REFERENCES dbo.ConceptoCobro (id)
);

CREATE TABLE dbo.DetalleConceptoCobro
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idFactura int NOT NULL,
    idConceptoCobro int NOT NULL,

    -- Otras columnas
    monto money NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_DetalleConceptoCobro PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_DetalleConceptoCobro_Factura FOREIGN KEY (idFactura)
        REFERENCES dbo.Factura (id),
    CONSTRAINT FK_DetalleConceptoCobro_ConceptoCobro FOREIGN KEY (idConceptoCobro)
        REFERENCES dbo.ConceptoCobro (id)
);

-- CATEGOR�A: Clases de concepto de cobro

CREATE TABLE dbo.ConceptoCobroAgua
(
	-- Llaves
	id int NOT NULL,

	-- Otras columnas
	montoMinimo money NOT NULL,
	consumoMinimo int NOT NULL,
	volumenTracto int NOT NULL,
	montoTracto money NOT NULL,

	-- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroAgua PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroAgua_ConceptoCobro FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobro (id)
);

CREATE TABLE dbo.ConceptoCobroPatente
(
	-- Llaves
	id int NOT NULL,

	-- Otras columnas
	valorPatente money NOT NULL,

	-- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroPatente PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroPatente_ConceptoCobro FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobro (id)
);

CREATE TABLE dbo.ConceptoCobroImpuestoPropiedad
(
	-- Llaves
	id int NOT NULL,

	-- Otras columnas
	valorPorcentual money NOT NULL,
		-- money fuerza la precisi�n a un decimal en base 10

	-- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroImpuestoPropiedad PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroImpuestoPropiedad_ConceptoCobro FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobro (id)
);

CREATE TABLE dbo.ConceptoCobroBasura
(
	-- Llaves
	id int NOT NULL,

	-- Otras columnas
	montoMinimo money NOT NULL,
	areaMinima int NOT NULL,
	areaTracto int NOT NULL,
	montoTracto money NOT NULL,

	-- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroBasura PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroBasura_ConceptoCobro FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobro (id)
);

CREATE TABLE dbo.ConceptoCobroParques
(
	-- Llaves
	id int NOT NULL,

	-- Otras columnas
	valorFijo money NOT NULL,

	-- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroParques PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroParques_ConceptoCobro FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobro (id)
);

CREATE TABLE dbo.ConceptoCobroInteresesMoratorios
(
	-- Llaves
	id int NOT NULL,

	-- Otras columnas
	valorPorcentual money NOT NULL,
		-- money fuerza la precisi�n a un decimal en base 10

	-- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroInteresesMoratorios PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroInteresesMoratorios_ConceptoCobro FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobro (id)
);

CREATE TABLE dbo.ConceptoCobroReconexionAgua
(
	-- Llaves
	id int NOT NULL,

	-- Otras columnas
	monto money NOT NULL,

	-- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroReconexionAgua PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroReconexionAgua_ConceptoCobro FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobro (id)
);

-- CATEGOR�A: Agua

CREATE TABLE dbo.AguaDePropiedad
(
    -- Llaves
    id int NOT NULL,

    -- Otras columnas
    numeroMedidor int NOT NULL,
    consumoAcumulado float NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_AguaDePropiedad PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_AguaDePropiedad_ConceptoCobroDePropiedad FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobroDePropiedad (id)
);

CREATE TABLE dbo.TipoMovimientoConsumo
(
    -- Llaves
    id int NOT NULL,

    -- Otras columnas
    nombre varchar(32) NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_TipoMovimientoConsumo PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.MovimientoConsumo
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idTipoMovimiento int NOT NULL,
    idAguaDePropidad int NOT NULL,

    -- Otras columnas
    fecha date NOT NULL,
    consumoMovimiento money NOT NULL,
    consumoAcumulado money NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_MovimientoConsumo PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_MovimientoConsumo_TipoMovimientoConsumo
        FOREIGN KEY (idTipoMovimiento)
        REFERENCES dbo.TipoMovimientoConsumo (id),
    CONSTRAINT FK_MovimientoConsumo_AguaDePropiedad
        FOREIGN KEY (idAguaDePropidad)
        REFERENCES dbo.AguaDePropiedad (id),
);

CREATE TABLE dbo.DetalleConceptoCobroAgua
(
    -- Llaves
    idDetalleConceptoCobro int NOT NULL,
    idMovimiento int NOT NULL UNIQUE,

    -- Se establece la llave primaria
    CONSTRAINT PK_DetalleConceptoCobroAgua PRIMARY KEY CLUSTERED
        (idDetalleConceptoCobro),

    -- Se asocian las llaves externas
    CONSTRAINT FK_DetalleConceptoCobroAgua_DetalleConceptoCobro
        FOREIGN KEY (idDetalleConceptoCobro)
        REFERENCES dbo.DetalleConceptoCobro (id),
    CONSTRAINT FK_DetalleConceptoCobroAgua_MovimientoConsumo
        FOREIGN KEY (idMovimiento)
        REFERENCES dbo.MovimientoConsumo (id)
);

CREATE TABLE dbo.OrdenCorta
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idFactura int NOT NULL UNIQUE,
    idPropiedad int NOT NULL,
    
    -- Otras columnas
    numeroMedidor int NOT NULL,
    fechaOperacion date NOT NULL,
    estadoPago int NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_OrdenCorta PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_OrdenCorta_Factura FOREIGN KEY (idFactura)
        REFERENCES dbo.Factura (id),
    CONSTRAINT FK_OrdenCorta_Propiedad FOREIGN KEY (idPropiedad)
        REFERENCES dbo.Propiedad (id)
);

CREATE TABLE dbo.OrdenReconexion
(
    -- Llaves
    id int NOT NULL IDENTITY(1,1),
    idFactura int NOT NULL,
    idOrdenCorta int NOT NULL UNIQUE,
    
    -- Otras columnas
    numeroMedidor int NOT NULL,
    fechaReconexion date NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_OrdenReconexion PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_OrdenReconexion_Factura FOREIGN KEY (idFactura)
        REFERENCES dbo.Factura (id),
    CONSTRAINT FK_OrdenReconexion_OrdenCorta FOREIGN KEY (idOrdenCorta)
        REFERENCES dbo.OrdenCorta (id)
);

-- CATEGOR�A: Par�metros del sistema

CREATE TABLE dbo.TipoParametroSistema
(
	-- Llaves
    id int NOT NULL,
    
    -- Otras columnas
    descripcion varchar(16),

    -- Se establece la llave primaria
    CONSTRAINT PK_TipoParametroSistema PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.ParametroSistema
(
	-- Llaves
    id int NOT NULL,
	idTipoParametroSistema int NOT NULL,
    
    -- Otras columnas
	descripcion varchar(128) NOT NULL,
    valor int NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_ParametroSistema PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ParametroSistema_TipoParametroSistema
		FOREIGN KEY (idTipoParametroSistema)
        REFERENCES dbo.TipoParametroSistema (id)
);

-- VALORES FIJOS NO INCLUIDOS EN LOS XML
INSERT INTO dbo.EstadoFactura (descripcion)
    VALUES ('Pendiente'), ('Pagado normalmente'),
        ('Pagado con arreglo de pago'), ('Anulado')