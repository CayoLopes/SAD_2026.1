% =========================================================
% SISTEMA DE APOIO À DECISÃO - AVALIAÇÃO II
% Otimização Multiobjetivo: Grade Horária Universitária (4 Turmas)
% =========================================================

% --- 1. PARÂMETROS GERAIS ---
int: n_turmas = 4;
int: n_dias = 5;
int: n_blocos = 3; 
int: n_materias = 21;
int: n_professores = 8;

% --- 2. MAPEAMENTO DE DADOS ---

% 2.1. Carga horária por matéria  (60h = 2 blocos, 90h = 3 blocos)
array[1..n_materias] of int: carga_horaria = [
    3, 2, 2, 2, 2, % 1º Ano (M1 Algoritmos tem 3)
    3, 2, 2, 2, 2, % 2º Ano (M6 Programação tem 3)
    2, 2, 2, 2, 3, % 3º Ano (M15 Estrut. de Dados tem 3)
    2, 2, 2, 2, 2, 2  % 4º Ano (Todas tem 2)
];
% 2.2. Matéria -> turma 
array[0..n_materias] of int: turma_materia = array1d(0..n_materias, [
    0,
    1, 1, 1, 1, 1,
    2, 2, 2, 2, 2,
    3, 3, 3, 3, 3,
    4, 4, 4, 4, 4, 4
]);

% 2.3. Matéria -> professor 
array[0..n_materias] of int: prof_materia = array1d(0..n_materias, [
    0,
    1, 2, 5, 3, 4,  % 1º Ano
    1, 4, 3, 6, 6,  % 2º Ano
    7, 4, 3, 8, 7,  % 3º Ano
    2, 7, 5, 8, 8, 6  % 4º Ano
]);

% 2.4. Tipo de espaçamento pedagógico corrigido
array[1..n_materias] of int: tipo_espacamento = [
    0, 1, 2, 2, 1, % 1º Ano (M1 é 90h = 0)
    0, 2, 1, 2, 1, % 2º Ano (M6 é 90h = 0)
    2, 1, 1, 2, 0, % 3º Ano (M15 é 90h = 0)
    1, 2, 2, 2, 2, 1  % 4º Ano (Nenhuma é 90h)
];

% 2.5. Disponibilidade dos professores
array[1..n_professores, 1..n_dias] of 0..1: disponibilidade = [|
    0, 1, 1, 1, 0 |  % Prof 1 (A)
    1, 1, 1, 0, 0 |  % Prof 2 (B)
    0, 0, 1, 1, 1 |  % Prof 3 (C)
    1, 1, 0, 1, 0 |  % Prof 4 (D)
    0, 1, 1, 1, 0 |  % Prof 5 (E)
    0, 1, 1, 0, 1 |  % Prof 6 (F)
    0, 1, 1, 1, 0 |  % Prof 7 (G)
    1, 0, 1, 1, 0 |]; % Prof 8 (H)

% --- 3. VARIÁVEL DE DECISÃO ---
array[1..n_turmas, 1..n_dias, 1..n_blocos] of var 0..n_materias: grade;

% --- 4. RESTRIÇÕES RÍGIDAS ---

% 4.1 Pertencimento: matéria só na turma correta
constraint forall(t in 1..n_turmas, d in 1..n_dias, b in 1..n_blocos) (
    if grade[t,d,b] > 0 then turma_materia[grade[t,d,b]] == t else true endif
);

% 4.2 Carga horária
constraint forall(m in 1..n_materias) (
    sum(d in 1..n_dias, b in 1..n_blocos) (
        bool2int(grade[turma_materia[m], d, b] == m)
    ) == carga_horaria[m]
);

% 4.3 Unicidade diária: máximo 1 bloco
constraint forall(m in 1..n_materias, d in 1..n_dias) (
    sum(b in 1..n_blocos) (
        bool2int(grade[turma_materia[m], d, b] == m)
    ) <= 1
);

% 4.4 Disponibilidade
constraint forall(p in 1..n_professores, d in 1..n_dias) (
    if disponibilidade[p, d] == 0 then
        sum(t in 1..n_turmas, b in 1..n_blocos) (
            bool2int( grade[t,d,b] > 0 /\ prof_materia[grade[t,d,b]] == p )
        ) == 0
    endif
);

% 4.5 Conflito cruzado (Professor em máx 1 sala POR BLOCO)
constraint forall(p in 1..n_professores, d in 1..n_dias, b in 1..n_blocos) (
    sum(t in 1..n_turmas) (
        bool2int(grade[t,d,b] > 0 /\ prof_materia[grade[t,d,b]] == p)
    ) <= 1
);

% --- 5. OTIMIZAÇÃO ---

% 5.1 Penalidade pedagógica (Peso 100)
var int: penalidade_pedagogica = sum(m in 1..n_materias where tipo_espacamento[m] > 0) (
  sum(d1, d2 in 1..n_dias where d1 < d2) (
     if (sum(b in 1..n_blocos)(bool2int(grade[turma_materia[m], d1, b] == m)) > 0) /\ 
        (sum(b in 1..n_blocos)(bool2int(grade[turma_materia[m], d2, b] == m)) > 0)
     then
        abs((d2 - d1) - tipo_espacamento[m])
     else
        0
     endif
  )
);

% 5.2 Janelas de professores (Peso 1)
var int: total_janelas = sum(p in 1..n_professores, d in 1..n_dias) (
  bool2int(
     sum(t in 1..n_turmas)(bool2int(grade[t, d, 1] > 0 /\ prof_materia[grade[t, d, 1]] == p)) == 1 /\ 
     sum(t in 1..n_turmas)(bool2int(grade[t, d, 2] > 0 /\ prof_materia[grade[t, d, 2]] == p)) == 0 /\ 
     sum(t in 1..n_turmas)(bool2int(grade[t, d, 3] > 0 /\ prof_materia[grade[t, d, 3]] == p)) == 1
  )
);

% 5.3 Função de custo
var int: custo_total = (penalidade_pedagogica * 100) + total_janelas;

solve :: int_search(
    [grade[t,d,b] | t in 1..n_turmas, d in 1..n_dias, b in 1..n_blocos],
    first_fail,
    indomain_min,
    complete
) minimize custo_total;

% --- 6. SAÍDA  ---
output ["\n================ MÉTRICAS DE OTIMIZAÇÃO ================"] ++
       ["\n  Penalidade Pedagógica (Peso 100): ", show(penalidade_pedagogica)] ++
       ["\n  Total de Janelas (Peso 1)      : ", show(total_janelas)] ++
       ["\n  CUSTO TOTAL (O mais perto de 0): ", show(custo_total), "\n"] ++
       ["========================================================\n"] ++
[
    if d == 1 /\ b == 1 then "\n--- TURMA " ++ show(t) ++ " ---\n" else "" endif ++
    if b == 1 then "Dia " ++ show(d) ++ ": " else "" endif ++
    if fix(grade[t,d,b]) < 10 then "0" ++ show(grade[t,d,b]) ++ " " else show(grade[t,d,b]) ++ " " endif ++
    if b == n_blocos then "\n" else "| " endif
    | t in 1..n_turmas, d in 1..n_dias, b in 1..n_blocos
];
