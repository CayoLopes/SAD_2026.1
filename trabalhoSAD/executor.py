from minizinc import Instance, Model, Solver

# 1. Definição do Modelo MiniZinc
model = Model()
model.add_string("""
int: n_professores = 7;
int: n_materias = 14;
int: n_dias = 5;
int: n_blocos = 6;

array[1..n_dias, 1..n_blocos] of var 0..n_materias: grade;

% Carga horária: cada matéria aparece 2 vezes
constraint forall(m in 1..n_materias) (
    sum(d in 1..n_dias, b in 1..n_blocos)(bool2int(grade[d,b] == m)) == 2
);

% Unicidade diária: evita 4 aulas seguidas
constraint forall(m in 1..n_materias, d in 1..n_dias)(
    sum(b in 1..n_blocos)(bool2int(grade[d,b] == m)) <= 1
);

% Regra do pulo: máximo 1 dia de intervalo útil
constraint forall(m in 1..n_materias)(
    exists(d1, d2 in 1..n_dias where d1 < d2)(
        (exists(b in 1..n_blocos)(grade[d1,b] == m)) /\\
        (exists(b in 1..n_blocos)(grade[d2,b] == m)) /\\
        (d2 - d1 <= 2)
    )
);

% Exatamente 2 slots vazios (30 slots - 28 aulas)
constraint sum(d in 1..n_dias, b in 1..n_blocos)(bool2int(grade[d,b] == 0)) == 2;

solve :: int_search(
    [grade[d,b] | d in 1..n_dias, b in 1..n_blocos],
    first_fail,
    indomain_min,
    complete
) satisfy;
""")

# 2. Configurações de Dados para o SAD (Nomes Reais)
professores = ["Prof. Carlos", "Prof. Ana", "Prof. Bruno", "Prof. Daniela", "Prof. Gustavo", "Prof. Fernanda", "Prof. Gabriel"]
materias_nomes = [
    "Programação", "ALgorítimos", "Infomática", "Arquitetura", 
    "Cálculo I", "Lógica", "S.O.", "Redes",
    "POO", "P. WEB", "SAD", "OSM",
    "IA", "Banco Dados"
]

dias = ["Segunda", "Terça", "Quarta", "Quinta", "Sexta"]
horarios = ["07:00", "08:40", "10:40", "13:00", "14:40", "16:20"]

# 3. Resolução
solver = Solver.lookup("gecode")
instance = Instance(solver, model)
result = instance.solve()

# 4. Exibição Formatada para o Artigo
if result:
    grade = result["grade"]
    
    print("\n" + "="*125)
    print(f"{'SAD - GRADE HORÁRIA UNIVERSITÁRIA':^125}")
    print("="*125)
    
    # Cabeçalho dos dias
    header = f"{'Horário':<12} | " + " | ".join([f"{d:<20}" for d in dias])
    print(header)
    print("-" * 125)

    # Varredura por bloco (linha) e dia (coluna)
    for b in range(6):
        linha = f"{horarios[b]:<12} | "
        for d in range(5):
            m_id = grade[d][b]
            
            if m_id > 0:
                nome_m = materias_nomes[m_id - 1]
                # Cada 2 matérias pertencem a um professor (0,1 -> Prof 0; 2,3 -> Prof 1...)
                nome_p = professores[(m_id - 1) // 2]
                celula = f"{nome_m} ({nome_p.split()[-1]})" # Pega apenas o último nome para caber
            else:
                celula = "--- VAGO ---"
            
            linha += f"{celula:<20} | "
        print(linha)
    
    print("-" * 125)
    print(f"Status: {result.status} | Tempo: {result.statistics['solveTime'].total_seconds()}s")
    print("="*125)
else:
    print("Inviável: O SAD não encontrou uma solução.")