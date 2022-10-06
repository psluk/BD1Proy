-- Este script es utilizado para crear las tablas
-- Tambi�n crea las relaciones necesarias (llaves primarias y externas)

-- CATEGOR�A: PERSONAS

CREATE TABLE dbo.TipoDocumentoId
(
    -- Llaves
    id INT NOT NULL,

    -- Columnas
    nombre VARCHAR(32) NOT NULL,
	mascara VARCHAR(32) NOT NULL,
    
    -- Se establece la llave primaria
    CONSTRAINT PK_id PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.Persona
(
    -- Llaves
    id INT NOT NULL IDENTITY(1,1),
    idTipoDocumentoId INT NOT NULL,

    -- Otras columnas
    nombre VARCHAR(64) NOT NULL,
    valorDocumentoId VARCHAR(32) NOT NULL,
    telefono1 BIGINT NOT NULL,
    telefono2 BIGINT NOT NULL,
    email VARCHAR(128) NOT NULL

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
    id INT NOT NULL IDENTITY(1,1),

    -- Otras columnas
    nombre VARCHAR(32) NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_TipoUsuario PRIMARY KEY CLUSTERED (id),
);

CREATE TABLE dbo.Usuario
(
    -- Llaves
    id INT NOT NULL IDENTITY(1,1),
	idPersona INT NOT NULL,
    idTipoUsuario INT NOT NULL,

    -- Otras columnas
    nombreDeUsuario VARCHAR(32) NOT NULL,
    clave VARCHAR(32) NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_Usuario PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_Usuario_Persona FOREIGN KEY (idPersona)
        REFERENCES dbo.Persona (id),
    CONSTRAINT FK_Usuario_TipoUsuario FOREIGN KEY (idTipoUsuario)
        REFERENCES dbo.TipoUsuario (id)
);

-- CATEGOR�A: PROPIEDADES

CREATE TABLE dbo.TipoUsoPropiedad
(
    -- Llaves
    id INT NOT NULL,

    -- Otras columnas
    nombre VARCHAR(32) NOT NULL

    -- Se establece la llave primaria
    CONSTRAINT PK_TipoUsoPropiedad PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.TipoZona
(
    -- Llaves
    id INT NOT NULL,

    -- Otras columnas
    nombre VARCHAR(32) NOT NULL

    -- Se establece la llave primaria
    CONSTRAINT PK_TipoZona PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.Propiedad
(
    -- Llaves
    id INT NOT NULL IDENTITY(1,1),
    idTipoUsoPropiedad INT NOT NULL,
    idTipoZona INT NOT NULL,

    -- Otras columnas
    numeroFinca INT NOT NULL,
    area INT NOT NULL,
    valorFiscal BIGINT NOT NULL,
    fechaRegistro DATE NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_Propiedad PRIMARY KEY CLUSTERED (id),

    -- Se asocian las llaves externas
    CONSTRAINT FK_Propiedad_TipoUsoPropiedad FOREIGN KEY (idTipoUsoPropiedad)
        REFERENCES dbo.TipoUsoPropiedad (id),
    CONSTRAINT FK_Propiedad_TipoZona FOREIGN KEY (idTipoZona)
        REFERENCES dbo.TipoZona (id)
);

-- CATEGOR�A: Propiedad + (Persona o Usuario)

CREATE TABLE dbo.PropietarioDePropiedad
(
    -- Llaves
    id INT NOT NULL IDENTITY(1,1),
    idPersona INT NOT NULL,
    idPropiedad INT NOT NULL,

    -- Otras columnas
    fechaInicio DATE NOT NULL,
    fechaFin DATE NULL,

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
    id INT NOT NULL IDENTITY(1,1),
    idUsuario INT NOT NULL,
    idPropiedad INT NOT NULL,

    -- Otras columnas
    fechaInicio DATE NOT NULL,
    fechaFin DATE NULL,

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
    id INT NOT NULL IDENTITY(1,1),

    -- Otras columnas
    descripcion VARCHAR(32) NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_EstadoFactura PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.Factura
(
    -- Llaves
    id INT NOT NULL IDENTITY(1,1),
    idPropiedad INT NOT NULL,
    idEstadoFactura INT NOT NULL,

    -- Otras columnas
    fechaGeneracion DATE NOT NULL,
    fechaVencimiento DATE NOT NULL,
    totalOriginal MONEY NOT NULL,
    totalActual MONEY NOT NULL,

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
	id INT NOT NULL,

	-- Otras columnas
	descripcion VARCHAR(64) NOT NULL,

	-- Se establece la llave primaria
	CONSTRAINT PK_TipoMedioPago PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.Pago
(
	-- Llaves
    id INT NOT NULL,
	idTipoMedioPago INT NOT NULL,

    -- Otras columnas
    fechaPago DATE NOT NULL,

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
	id INT NOT NULL,

	-- Otras columnas
	descripcion VARCHAR(32) NOT NULL,
	cantidadMeses INT NOT NULL,

	-- Se establece la llave primaria
	CONSTRAINT PK_TipoPeriodoConceptoCobro PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.TipoMontoConceptoCobro
(
	-- Llaves
	id INT NOT NULL,

	-- Otras columnas
	descripcion VARCHAR(32) NOT NULL,

	-- Se establece la llave primaria
	CONSTRAINT PK_TipoMontoConceptoCobro PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.ConceptoCobro
(
    -- Llaves
    id INT NOT NULL,
	idTipoPeriodoConceptoCobro INT NOT NULL,
	idTipoMontoConceptoCobro INT NOT NULL,

    -- Otras columnas
    nombre VARCHAR(32) NOT NULL,

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
    id INT NOT NULL,
    idPropiedad INT NOT NULL,
    idConceptoCobro INT NOT NULL,

    -- Otras columnas
    fechaInicio DATE NOT NULL,
    fechaFin DATE NULL,

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
    id INT NOT NULL IDENTITY(1,1),
    idFactura INT NOT NULL,
    idConceptoCobro INT NOT NULL,

    -- Otras columnas
    monto MONEY NOT NULL,

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
	id INT NOT NULL,

	-- Otras columnas
	montoMinimo MONEY NOT NULL,
	consumoMinimo INT NOT NULL,
	volumenTracto INT NOT NULL,
	montoTracto MONEY NOT NULL,

	-- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroAgua PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroAgua_ConceptoCobro FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobro (id)
);

CREATE TABLE dbo.ConceptoCobroPatente
(
	-- Llaves
	id INT NOT NULL,

	-- Otras columnas
	valorPatente MONEY NOT NULL,

	-- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroPatente PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroPatente_ConceptoCobro FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobro (id)
);

CREATE TABLE dbo.ConceptoCobroImpuestoPropiedad
(
	-- Llaves
	id INT NOT NULL,

	-- Otras columnas
	valorPorcentual MONEY NOT NULL,
		-- MONEY fuerza la precisi�n a un decimal en base 10

	-- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroImpuestoPropiedad PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroImpuestoPropiedad_ConceptoCobro FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobro (id)
);

CREATE TABLE dbo.ConceptoCobroBasura
(
	-- Llaves
	id INT NOT NULL,

	-- Otras columnas
	montoMinimo MONEY NOT NULL,
	areaMinima INT NOT NULL,
	areaTracto INT NOT NULL,
	montoTracto MONEY NOT NULL,

	-- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroBasura PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroBasura_ConceptoCobro FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobro (id)
);

CREATE TABLE dbo.ConceptoCobroParques
(
	-- Llaves
	id INT NOT NULL,

	-- Otras columnas
	valorFijo MONEY NOT NULL,

	-- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroParques PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroParques_ConceptoCobro FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobro (id)
);

CREATE TABLE dbo.ConceptoCobroInteresesMoratorios
(
	-- Llaves
	id INT NOT NULL,

	-- Otras columnas
	valorPorcentual MONEY NOT NULL,
		-- MONEY fuerza la precisi�n a un decimal en base 10

	-- Se establece la llave primaria
    CONSTRAINT PK_ConceptoCobroInteresesMoratorios PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ConceptoCobroInteresesMoratorios_ConceptoCobro FOREIGN KEY (id)
        REFERENCES dbo.ConceptoCobro (id)
);

CREATE TABLE dbo.ConceptoCobroReconexionAgua
(
	-- Llaves
	id INT NOT NULL,

	-- Otras columnas
	monto MONEY NOT NULL,

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
    id INT NOT NULL,

    -- Otras columnas
    numeroMedidor INT NOT NULL,
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
    id INT NOT NULL,

    -- Otras columnas
    nombre VARCHAR(32) NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_TipoMovimientoConsumo PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.MovimientoConsumo
(
    -- Llaves
    id INT NOT NULL IDENTITY(1,1),
    idTipoMovimiento INT NOT NULL,
    idAguaDePropidad INT NOT NULL,

    -- Otras columnas
    fecha DATE NOT NULL,
    consumoMovimiento MONEY NOT NULL,
    consumoAcumulado MONEY NOT NULL,

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
    idDetalleConceptoCobro INT NOT NULL,
    idMovimiento INT NOT NULL UNIQUE,

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
    id INT NOT NULL IDENTITY(1,1),
    idFactura INT NOT NULL UNIQUE,
    idPropiedad INT NOT NULL,
    
    -- Otras columnas
    numeroMedidor INT NOT NULL,
    fechaOperacion DATE NOT NULL,
    estadoPago INT NOT NULL,

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
    id INT NOT NULL IDENTITY(1,1),
    idFactura INT NOT NULL,
    idOrdenCorta INT NOT NULL UNIQUE,
    
    -- Otras columnas
    numeroMedidor INT NOT NULL,
    fechaReconexion DATE NOT NULL,

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
    id INT NOT NULL,
    
    -- Otras columnas
    descripcion VARCHAR(16),

    -- Se establece la llave primaria
    CONSTRAINT PK_TipoParametroSistema PRIMARY KEY CLUSTERED (id)
);

CREATE TABLE dbo.ParametroSistema
(
	-- Llaves
    id INT NOT NULL,
	idTipoParametroSistema INT NOT NULL,
    
    -- Otras columnas
	descripcion VARCHAR(128) NOT NULL,
    valor INT NOT NULL,

    -- Se establece la llave primaria
    CONSTRAINT PK_ParametroSistema PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
    CONSTRAINT FK_ParametroSistema_TipoParametroSistema
		FOREIGN KEY (idTipoParametroSistema)
        REFERENCES dbo.TipoParametroSistema (id)
);

-- CATEGOR�A: Registro de actividades y errores

CREATE TABLE [dbo].[EventLog]
(
	-- Llaves
	id INT NOT NULL IDENTITY(1,1),

	-- Otras columnas
	LogDescription VARCHAR(512) NOT NULL,
	PostTime DATETIME NOT NULL,
	PostByUserId INT NOT NULL,
	PostInIp VARCHAR(64) NOT NULL,

	-- Se establece la llave primaria
    CONSTRAINT PK_EventLog PRIMARY KEY CLUSTERED (id),

	-- Se asocian las llaves externas
	CONSTRAINT [FK_EventLog_Usuario] FOREIGN KEY ([PostByUserId])
		REFERENCES dbo.Usuario (id)
);

CREATE TABLE [dbo].[Errors]
(
	-- Llaves
	[ErrorID] INT NOT NULL IDENTITY(1,1),

	-- Otras columnas
	[UserName] VARCHAR(100) NULL,
	[ErrorNumber] INT NULL,
	[ErrorState] INT NULL,
	[ErrorSeverity] INT NULL,
	[ErrorLine] INT NULL,
	[ErrorProcedure] VARCHAR(max) NULL,
	[ErrorMessage] VARCHAR(max) NULL,
	[ErrorDateTime] DATETIME NULL,

	-- Se establece la llave primaria
    CONSTRAINT PK_DBErrors PRIMARY KEY CLUSTERED ([ErrorID])
);

-- VALORES FIJOS NO INCLUIDOS EN LOS XML
INSERT INTO [dbo].[TipoUsuario] (nombre)
	VALUES ('Administrador'), ('Propietario');

INSERT INTO [dbo].[EstadoFactura] (descripcion)
    VALUES ('Pendiente'), ('Pagado normalmente'),
        ('Pagado con arreglo de pago'), ('Anulado')