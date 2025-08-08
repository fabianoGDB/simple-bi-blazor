-- Tabela de estudantes
CREATE TABLE Estudantes (
    IdEstudante INT PRIMARY KEY,
    Nome VARCHAR(100),
    DataNascimento DATE
);

INSERT INTO Estudantes VALUES
(1, 'Ana Souza', '2007-05-12'),
(2, 'Carlos Silva', '2006-09-20'),
(3, 'Mariana Lima', '2007-02-01'),
(4, 'João Pereira', '2006-12-10');

-- Tabela de professores
CREATE TABLE Professores (
    IdProfessor INT PRIMARY KEY,
    Nome VARCHAR(100),
    Especialidade VARCHAR(100)
);

INSERT INTO Professores VALUES
(1, 'Paulo Santos', 'Matemática'),
(2, 'Fernanda Oliveira', 'Português'),
(3, 'Ricardo Mendes', 'História');

-- Tabela de turmas
CREATE TABLE Turmas (
    IdTurma INT PRIMARY KEY,
    NomeTurma VARCHAR(50),
    AnoLetivo INT,
    IdProfessor INT,
    FOREIGN KEY (IdProfessor) REFERENCES Professores(IdProfessor)
);

INSERT INTO Turmas VALUES
(1, 'Turma A', 2025, 1),
(2, 'Turma B', 2025, 2);

-- Tabela de matérias
CREATE TABLE Materias (
    IdMateria INT PRIMARY KEY,
    NomeMateria VARCHAR(100)
);

INSERT INTO Materias VALUES
(1, 'Matemática'),
(2, 'Português'),
(3, 'História');

-- Tabela de notas
CREATE TABLE Notas (
    IdNota INT PRIMARY KEY,
    IdEstudante INT,
    IdMateria INT,
    IdTurma INT,
    Nota DECIMAL(4,2),
    FOREIGN KEY (IdEstudante) REFERENCES Estudantes(IdEstudante),
    FOREIGN KEY (IdMateria) REFERENCES Materias(IdMateria),
    FOREIGN KEY (IdTurma) REFERENCES Turmas(IdTurma)
);

INSERT INTO Notas VALUES
(1, 1, 1, 1, 8.5),
(2, 1, 2, 1, 7.2),
(3, 2, 1, 1, 6.8),
(4, 2, 3, 1, 9.0),
(5, 3, 2, 2, 8.0),
(6, 3, 3, 2, 7.5),
(7, 4, 1, 2, 5.9),
(8, 4, 2, 2, 6.3);
