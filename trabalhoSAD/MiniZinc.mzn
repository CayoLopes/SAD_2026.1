% Parâmetros
int: n_professores = 7;
int: n_materias = 14;
int: n_dias = 5;
int: n_blocos = 6; 

% Matriz de Decisão
array[1..n_dias, 1..n_blocos] of var 0..n_materias: grade;

% --- RESTRIÇÕES ---

% 1. Carga Horária: Cada matéria aparece exatamente 2 vezes na semana
constraint forall(m in 1..n_materias) (
    sum(d in 1..n_dias, b in 1..n_blocos) (
        bool2int(grade[d,b] == m)
    ) == 2
);

% 2. Unicidade Diária: No máximo um bloco da mesma matéria por dia
constraint forall(m in 1..n_materias, d in 1..n_dias) (
    sum(b in 1..n_blocos) (
        bool2int(grade[d,b] == m)
    ) <= 1
);

% 3. Regra do Pulo (máx. 1 dia de intervalo)
constraint forall(m in 1..n_materias) (
    exists(d1, d2 in 1..n_dias where d1 < d2) (
        (exists(b in 1..n_blocos) (grade[d1, b] == m)) /\
        (exists(b in 1..n_blocos) (grade[d2, b] == m)) /\
        (d2 - d1 <= 2)
    )
);

% 4. Exatamente 2 slots vazios
constraint sum(d in 1..n_dias, b in 1..n_blocos) (
    bool2int(grade[d,b] == 0)
) == 2;

% --- RESOLUÇÃO COM ESTRATÉGIA DE BUSCA ---
solve :: int_search(
    [grade[d,b] | d in 1..n_dias, b in 1..n_blocos],
    first_fail,
    indomain_min,
    complete
) satisfy;

% --- SAÍDA ---
output [
  if b == 1 then "\nDia " ++ show(d) ++ ": " else " | " endif ++
  if fix(grade[d,b]) < 10 then "0" ++ show(grade[d,b]) else show(grade[d,b]) endif
  | d in 1..n_dias, b in 1..n_blocos
];