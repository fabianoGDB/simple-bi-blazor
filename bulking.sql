-- ############################################################
-- BULK DE DADOS (MySQL 8+)
-- Gera dados sintéticos para Estudantes, Professores, Materias,
-- Turmas e Notas, prontos para análises no Power BI.
-- ############################################################

-- ===== Parâmetros (ajuste à vontade) =====
SET @qtd_estudantes  = 2000;   -- número de estudantes
SET @qtd_professores = 40;     -- número de professores
SET @qtd_turmas      = 60;     -- número de turmas
-- Materias será preenchida por lista fixa abaixo
SET @ano_letivo      = 2025;

-- ===== Preparação =====
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS Notas;
DROP TABLE IF EXISTS Materias;
DROP TABLE IF EXISTS Turmas;
DROP TABLE IF EXISTS Professores;
DROP TABLE IF EXISTS Estudantes;

CREATE TABLE Estudantes (
  IdEstudante INT PRIMARY KEY,
  Nome VARCHAR(100) NOT NULL,
  DataNascimento DATE NOT NULL
);

CREATE TABLE Professores (
  IdProfessor INT PRIMARY KEY,
  Nome VARCHAR(100) NOT NULL,
  Especialidade VARCHAR(100) NOT NULL
);

CREATE TABLE Materias (
  IdMateria INT PRIMARY KEY,
  NomeMateria VARCHAR(100) NOT NULL
);

CREATE TABLE Turmas (
  IdTurma INT PRIMARY KEY,
  NomeTurma VARCHAR(50) NOT NULL,
  AnoLetivo INT NOT NULL,
  IdProfessor INT NOT NULL,
  CONSTRAINT fk_turma_prof FOREIGN KEY (IdProfessor) REFERENCES Professores(IdProfessor)
);

CREATE TABLE Notas (
  IdNota BIGINT PRIMARY KEY,
  IdEstudante INT NOT NULL,
  IdMateria INT NOT NULL,
  IdTurma INT NOT NULL,
  Nota DECIMAL(4,2) NOT NULL,
  CONSTRAINT fk_notas_aluno  FOREIGN KEY (IdEstudante) REFERENCES Estudantes(IdEstudante),
  CONSTRAINT fk_notas_materia FOREIGN KEY (IdMateria)   REFERENCES Materias(IdMateria),
  CONSTRAINT fk_notas_turma   FOREIGN KEY (IdTurma)     REFERENCES Turmas(IdTurma)
);

-- ===== Índices para performance =====
CREATE INDEX ix_notas_estudante ON Notas(IdEstudante);
CREATE INDEX ix_notas_materia   ON Notas(IdMateria);
CREATE INDEX ix_notas_turma     ON Notas(IdTurma);

-- ===== Helpers: sequência 1..N via CTE =====
WITH RECURSIVE seq(n) AS (
  SELECT 1
  UNION ALL
  SELECT n+1 FROM seq WHERE n+1 <= GREATEST(@qtd_estudantes, @qtd_professores, @qtd_turmas)
)
SELECT n INTO @dummy FROM seq ORDER BY n DESC LIMIT 1;
-- @dummy só força execução da CTE sem deixar resíduos

-- ===== Materias (lista fixa) =====
INSERT INTO Materias (IdMateria, NomeMateria)
VALUES
 (1,'Matemática'),
 (2,'Português'),
 (3,'História'),
 (4,'Geografia'),
 (5,'Ciências'),
 (6,'Inglês'),
 (7,'Física'),
 (8,'Química'),
 (9,'Biologia'),
 (10,'Artes'),
 (11,'Educação Física'),
 (12,'Filosofia');

-- ===== Professores =====
-- Gera @qtd_professores com nomes sintéticos e especialidades distribuídas
WITH RECURSIVE p(n) AS (
  SELECT 1
  UNION ALL
  SELECT n+1 FROM p WHERE n+1 <= @qtd_professores
)
INSERT INTO Professores (IdProfessor, Nome, Especialidade)
SELECT
  n AS IdProfessor,
  CONCAT('Prof. ', ELT((n % 10)+1,
    'Ana','Bruno','Carla','Diego','Elisa','Fabio','Giovana','Heitor','Isabela','João'),
    ' ', ELT((n % 10)+1,
    'Silva','Souza','Lima','Pereira','Oliveira','Mendes','Santos','Costa','Rocha','Barbosa')
  ) AS Nome,
  ELT((n % 12)+1,
    'Matemática','Português','História','Geografia','Ciências','Inglês',
    'Física','Química','Biologia','Artes','Educação Física','Filosofia') AS Especialidade
FROM p;

-- ===== Estudantes =====
-- Datas de nascimento distribuídas entre 2005–2009
WITH RECURSIVE e(n) AS (
  SELECT 1
  UNION ALL
  SELECT n+1 FROM e WHERE n+1 <= @qtd_estudantes
)
INSERT INTO Estudantes (IdEstudante, Nome, DataNascimento)
SELECT
  n,
  CONCAT('Aluno ', LPAD(n, 4, '0')) AS Nome,
  DATE_ADD('2005-01-01', INTERVAL FLOOR(RAND(n)* (5*365)) DAY) AS DataNascimento
FROM e;

-- ===== Turmas =====
-- Distribui professores nas turmas em round-robin
WITH RECURSIVE t(n) AS (
  SELECT 1
  UNION ALL
  SELECT n+1 FROM t WHERE n+1 <= @qtd_turmas
)
INSERT INTO Turmas (IdTurma, NomeTurma, AnoLetivo, IdProfessor)
SELECT
  n AS IdTurma,
  CONCAT('Turma ', ELT((n % 26)+1,
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z'),
    '-', LPAD(CEIL(n/26), 2, '0')) AS NomeTurma,
  @ano_letivo AS AnoLetivo,
  ((n-1) % @qtd_professores) + 1 AS IdProfessor
FROM t;

-- ===== Notas =====
-- Estratégia: para cada Estudante x cada Matéria, atribui uma Turma aleatória
-- e gera uma nota entre 4.0 e 10.0. Isso dá (@qtd_estudantes × #materias) linhas.
-- Para ficar mais “real”, sorteamos ~70% das combinações.
SET @materias_total = (SELECT COUNT(*) FROM Materias);
SET @total_notas    = @qtd_estudantes * @materias_total;

-- Gerar tabela temporária de pares (estudante, matéria)
DROP TEMPORARY TABLE IF EXISTS tmp_pairs;
CREATE TEMPORARY TABLE tmp_pairs (
  rn BIGINT PRIMARY KEY AUTO_INCREMENT,
  IdEstudante INT NOT NULL,
  IdMateria INT NOT NULL
) ENGINE=Memory;

-- Preenche os pares via produto cartesiano controlado
INSERT INTO tmp_pairs (IdEstudante, IdMateria)
SELECT s.IdEstudante, m.IdMateria
FROM Estudantes s
CROSS JOIN Materias m;

-- Insere Notas com amostragem de ~70% e turmas aleatórias
-- Nota ~ Normal-like (média ~7.2) usando combinação de RAND
INSERT INTO Notas (IdNota, IdEstudante, IdMateria, IdTurma, Nota)
SELECT
  tp.rn AS IdNota,
  tp.IdEstudante,
  tp.IdMateria,
  -- turma aleatória existente
  (SELECT IdTurma FROM Turmas ORDER BY RAND(tp.IdEstudante*1000 + tp.IdMateria) LIMIT 1) AS IdTurma,
  -- nota entre 4.00 e 10.00 com leve viés ao redor de 7.2
  ROUND(
    LEAST(10.0, GREATEST(4.0,
      7.2
      + (RAND(tp.IdEstudante*17 + tp.IdMateria*31)-0.5)*2.4
      + (RAND(tp.IdEstudante*23 + tp.IdMateria*11)-0.5)*1.6
    )), 2
  ) AS Nota
FROM tmp_pairs tp
-- ~70% das combinações viram avaliação
WHERE RAND(tp.IdEstudante*13 + tp.IdMateria*7) < 0.70;

SET FOREIGN_KEY_CHECKS = 1;

-- ===== Contagens rápidas =====
SELECT 'Estudantes' AS Tabela, COUNT(*) AS Registros FROM Estudantes
UNION ALL
SELECT 'Professores', COUNT(*) FROM Professores
UNION ALL
SELECT 'Materias', COUNT(*) FROM Materias
UNION ALL
SELECT 'Turmas', COUNT(*) FROM Turmas
UNION ALL
SELECT 'Notas', COUNT(*) FROM Notas;
