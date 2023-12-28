-- ESQUEMA CRIADO NO SQLITE

CREATE TABLE EdicaoEvento (
    NomeEvento TEXT NOT NULL,
    DataEdicao DATETIME PRIMARY KEY NOT NULL,
    Localizacao TEXT NOT NULL,
  	FOREIGN KEY (NomeEvento) REFERENCES Eventos(NomeEvento)
);
CREATE TABLE Elenco (
    NomeArtistico TEXT NoT NULL,
    TituloOriginal TEXT NOT NULL,
    Funcao TEXT VARCHAR(15) CHECK (Funcao IN ('Atriz', 'Ator', 'Diretor', 'Roteirista', 'Produtor', 'Diretora', 'Produtora')) NOT NULL,
  	FOREIGN KEY (NomeArtistico) REFERENCES Pessoa(NomeArtistico),
  	FOREIGN KEY (TituloOriginal) REFERENCES Filmes(TituloOriginal)
);
CREATE TABLE Estreia (
    TituloOriginal TEXT NOT NULL,
    AnoProducao INTEGER CHECK (AnoProducao >= 1000 AND AnoProducao <= 9999) NOT NULL,
    DataEstreia DATETIME NOT NULL,
    PaisEstreia TEXT NOT NULL,
  	EnderecoEstreia TEXT NOT NULL,
  	FOREIGN KEY (TituloOriginal) REFERENCES Filmes(TituloOriginal)
  	FOREIGN KEY (AnoProducao) REFERENCES Filmes(AnoProducao)
);
CREATE TABLE Eventos (
    NomeEvento TEXT PRIMARY KEY UNIQUE NOT NULL,
    TipoEvento TEXT VARCHAR(10) CHECK (TipoEvento IN ('Academia', 'Festival', 'Concurso')) NOT NULL,
    Nacionalidade TEXT NOT NULL,
    AnoInicio INTEGER CHECK (AnoInicio >= 1000 AND AnoInicio <= 9999) NOT NULL
);
CREATE TABLE Artista_Indicado (
    NomeArtistico TEXT NOT NULL,
    NomeEvento TEXT NOT NULL,
    DataEdicao DATETIME NOT NULL,
  	TipoPremio TEXT NOT NULL,
  	NomePremio TEXT,
  	TituloOriginal TEXT NOT NULL,
  	Ganhou VARCHAR(3) CHECK (Ganhou IN ('S', 'N')) NOT NULL,
  	FOREIGN KEY (NomeArtistico) REFERENCES Pessoa(NomeArtistico),
  	FOREIGN KEY (NomeEvento) REFERENCES Eventos(NomeEvento),
  	FOREIGN KEY (DataEdicao) REFERENCES Eventos(DataEdicao),
  	FOREIGN KEY (TipoPremio) REFERENCES Premio(TipoPremio),
  	FOREIGN KEY (NomePremio) REFERENCES Premio(NomePremio),
  	FOREIGN KEY (TituloOriginal) REFERENCES Filmes(TituloOriginal)
);
CREATE TABLE E_Juri (
    NomeEvento TEXT NOT NULL,
    DataEdicao DATETIME NOT NULL,
    NomeArtistico TEXT NOT NULL,
    PRIMARY KEY (NomeEvento, DataEdicao, NomeArtistico),
    FOREIGN KEY (NomeEvento) REFERENCES Eventos(NomeEvento),
    FOREIGN KEY (DataEdicao) REFERENCES Eventos(DataEdicao),
    FOREIGN KEY (NomeArtistico) REFERENCES Pessoa(NomeArtistico)
);
CREATE TABLE Filmes (
	TituloOriginal TEXT NOT NULL,
    AnoProducao INTEGER CHECK (AnoProducao >= 1000 AND AnoProducao <= 9999) NOT NULL,
    TituloNoBrasil TEXT, -- Opcional pois se o filme for brasileiro ou não mudar o título não tem necessidade
  	Classe TEXT NOT NULL, -- Gênero do filme
  	IdiomaOriginal VARCHAR (15) NOT NULL,
  	Arrecadacao1Ano FLOAT NOT NULL,
  	PRIMARY KEY (TituloOriginal, AnoProducao)
  );
CREATE TABLE Filme_Indicado (
    TituloOriginal TEXT NOT NULL,
    AnoProducao INTEGER CHECK (AnoProducao >= 1000 AND AnoProducao <= 9999) NOT NULL,
    Premiado VARCHAR(2) CHECK (Premiado IN ('S', 'N')) NOT NULL,
    NomeEvento TEXT NOT NULL,
    DataEdicao DATETIME NOT NULL,
  	TipoPremio TEXT NOT NULL,
  	NomePremio TEXT,
  	FOREIGN KEY (NomeEvento) REFERENCES Eventos(NomeEvento),
  	FOREIGN KEY (DataEdicao) REFERENCES Eventos(DataEdicao),
  	FOREIGN KEY (TipoPremio) REFERENCES Premio(TipoPremio),
  	FOREIGN KEY (NomePremio) REFERENCES Premio(NomePremio),
  	FOREIGN KEY (AnoProducao) REFERENCES Filmes(AnoProducao)
);
CREATE TABLE Pessoa (
    NomeArtistico TEXT PRIMARY KEY NOT NULL,
    NomeVerdadeiro TEXT NOT NULL,
    Sexo CHAR(1) CHECK (Sexo IN ('F', 'M')) NOT NULL,
  	AnoNascimento DATETIME NOT NULL,
  	Site TEXT,
  	AnoInicioCarreira INTEGER CHECK (AnoInicioCarreira >= 1000 AND AnoInicioCarreira <= 9999) NOT NULL, 
  	NmroTotalAnos INTEGER NOT NULL
);
CREATE TABLE Premio (
    NomeEvento TEXT NOT NULL,
    DataEdicao DATETIME NOT NULL,
    NomePremio TEXT NOT NULL,
  	TipoPremio TEXT  PRIMARY KEY NOT NULL,
  	FOREIGN KEY (NomeEvento) REFERENCES Eventos(NomeEvento)
  	FOREIGN KEY (dataedicao) REFERENCES Eventos(dataedicao)
);
 
-- TRIGGER PARA RESTRINGIR APENAS UM DIRETOR NOS FILMES TIPO DOCUMENTÁRIO
CREATE TRIGGER RestricaoDiretorDocumentario 
BEFORE INSERT ON Elenco 
FOR EACH ROW 
WHEN (NEW.Funcao = 'Diretor' OR NEW.Funcao = 'Diretora') 
    AND EXISTS (
        SELECT 1
        FROM Elenco
        WHERE TituloOriginal = NEW.TituloOriginal
          AND (Funcao = 'Diretor' OR Funcao = 'Diretora')
          AND EXISTS (
              SELECT 1
              FROM Filmes
              WHERE TituloOriginal = NEW.TituloOriginal
                AND (Classe = 'Documentario' OR Classe = 'Documentário')  
          ) 

         AND (
              (SELECT COUNT(*) FROM Elenco WHERE TituloOriginal = NEW.TituloOriginal AND Funcao IN ('Diretor', 'Diretora')) > 1
             -- Ou se há exatamente um diretor ou diretora já registrado para o mesmo filme
           OR (SELECT COUNT(*) FROM Elenco WHERE TituloOriginal = NEW.TituloOriginal AND Funcao IN ('Diretor', 'Diretora')) = 1
          )
    )
BEGIN  
    SELECT RAISE(ABORT, 'Apenas um(a) diretor(a) é permitido(a) para filmes da classe "Documentário".');
END;

-- TRIGGER PARA RESTRINGIR APENAS UM ARTISTA VENCEDOR DE CADA PRÊMIO POR EDIÇÃO
CREATE TRIGGER RestricaoVencedorUnicoArtista_Indicado
BEFORE INSERT ON Artista_Indicado
FOR EACH ROW
WHEN NEW.Ganhou = 'S'
AND EXISTS (
    SELECT 1
    FROM Artista_Indicado
    WHERE NomeEvento = NEW.NomeEvento
      AND DataEdicao = NEW.DataEdicao
      AND TipoPremio = NEW.TipoPremio
      AND Ganhou = 'S'
)
BEGIN
    SELECT RAISE(ABORT, 'Já existe um vencedor para o mesmo prêmio nesta edição do evento.');
END;

-- TRIGGER PARA RESTRINGIR APENAS UM FILME VENCEDOR DE CADA PRÊMIO POR EDIÇÃO
CREATE TRIGGER RestricaoVencedorUnicoFilme_Indicado
BEFORE INSERT ON Filme_Indicado
FOR EACH ROW
WHEN NEW.Premiado = 'S'
AND EXISTS (
    SELECT 1
    FROM Filme_Indicado
    WHERE NomeEvento = NEW.NomeEvento
      AND DataEdicao = NEW.DataEdicao
      AND TipoPremio = NEW.TipoPremio
      AND Premiado = 'S'
)
BEGIN
    SELECT RAISE(ABORT, 'Já existe um vencedor para o mesmo prêmio nesta edição do evento.');
END;

-- TRIGGER PARA VERIFICAR SE O INDICADO QUE ESTA SENDO INSERIDO NÃO ESTÁ SENDO JÚRI NA MESMA EDIÇÃO
CREATE TRIGGER VerificaRestricaoIndicado
BEFORE INSERT ON Artista_Indicado
FOR EACH ROW
WHEN (
    SELECT COUNT(*)
    FROM E_Juri
    WHERE NomeArtistico = NEW.NomeArtistico
      AND DataEdicao = NEW.DataEdicao
) > 0
BEGIN
    SELECT RAISE(ABORT, 'Artista não pode ser indicado se já é juiz na mesma edição.');
END;

-- TRIGGER PARA VERIFICAR SE O ARTISTA QUE IRÁ COMPOR O JÚRI ESTÁ SENDO INDICADO PARA ALGUM PREMIO NA MESMA EDIÇÃO 
-- TAMBÉM LIMITAMOS O NÚMERO DE JUIZES EM CADA EDIÇÃO PARA ATÉ 1000
CREATE TRIGGER VerificaRestricaoJuri 
BEFORE INSERT ON E_Juri 
FOR EACH ROW 
WHEN ( 
    SELECT COUNT(*)
    FROM Artista_Indicado
    WHERE NomeArtistico = NEW.NomeArtistico
      AND DataEdicao = NEW.DataEdicao 
) > 0 
OR 
(
    SELECT COUNT(*)
    FROM Filme_Indicado
    WHERE TituloOriginal IN (
        SELECT TituloOriginal
        FROM Elenco
        WHERE NomeArtistico = NEW.NomeArtistico
    ) 
    AND EXISTS (
        SELECT 1
        FROM E_Juri
        WHERE NomeArtistico = NEW.NomeArtistico
          AND DataEdicao = NEW.DataEdicao
    ) 
) > 0 
OR 
(
    SELECT COUNT(*)
    FROM E_Juri
    WHERE NomeEvento = NEW.NomeEvento
      AND DataEdicao = NEW.DataEdicao
) >= 1000
BEGIN 
    SELECT RAISE(ABORT, 'Artista não pode ser juiz de um evento pois foi indicado ao prêmio ou participou de um filme indicado ao prêmio na mesma edição ou número máximo de jurados atingido (1000).'); -- Impede a inserção na tabela E_Juri e gera uma mensagem explicativa.
END;

