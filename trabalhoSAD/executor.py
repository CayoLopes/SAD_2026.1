from minizinc import Instance, Model, Solver
import time

# 1. Configuração do Modelo
model = Model("avaliacao2.mzn")
solver = Solver.lookup("chuffed")
instance = Instance(solver, model)

# 2. Dados reais para tradução (Mapeamento)
professores_nomes = ["Carlos", "Ana", "Bruno", "Daniela", "Gustavo", "Fernanda", "Gabriel", "Heitor"] # Ajuste os nomes conforme seu mapeamento 1-8
materias_nomes = [
    "Algoritmos", "Int. Informática", "Fund. Matemática", "Lógica", "Adm. Geral", # 1º Ano
    "Programação", "T. Geral Sistemas", "Cálculo I", "Metodologia", "Leitura/Prod.", # 2º Ano
    "POO I", "Fund. SI", "Álgebra Linear", "OSM", "Estrutura Dados",             # 3º Ano
    "Arquitetura", "Prog. Web", "Prob./Estat.", "Banco Dados", "Eng. Soft I", "Inglês Téc." # 4º Ano
]
mapa_professores = [
    1, 2, 5, 3, 4, # 1º Ano
    1, 4, 3, 6, 6, # 2º Ano
    7, 4, 3, 8, 7, # 3º Ano
    2, 7, 5, 8, 8, 6 # 4º Ano
]

turmas_nomes = ["1º ANO", "2º ANO", "3º ANO", "4º ANO"]
dias = ["Segunda", "Terça", "Quarta", "Quinta", "Sexta"]
horarios = ["13:00", "14:50", "16:40"]

# 3. Execução
print("Executando otimização com Chuffed...")
start = time.time()
result = instance.solve()
end = time.time()

# 4. Saída Didática
if result:
    grade = result["grade"]
    
    for t in range(1, 5): 
        print(f"\n{'='*130}")
        print(f"{f'GRADE HORÁRIA - {turmas_nomes[t-1]}':^130}")
        print(f"{'='*130}")
        
        # Cabeçalho com largura fixa
        header = f"{'Horário':<10} | " + " | ".join([f"{d:^22}" for d in dias])
        print(header)
        print("-" * 130)
        
        for b in range(3):
            linha = f"{horarios[b]:<10} | "
            for d in range(5):
                m_id = grade[t-1][d][b]
                if m_id > 0:
                    # Truncamos o nome da matéria para 12 letras para caber no slot
                    nome_m = materias_nomes[m_id-1][:12] 
                    prof_id = mapa_professores[m_id-1]
                    nome_p = professores_nomes[prof_id-1]
                    # Formata: "Matéria (Prof)" dentro de um espaço de 22
                    celula = f"{nome_m} ({nome_p[:5]})" 
                else:
                    celula = "--- VAGO ---"
                
                # O segredo da simetria: largura fixa de 22 para todas as células
                linha += f"{celula:^22} | "
            print(linha)
        print("-" * 130)

    print(f"\nTempo total de execução: {end - start:.2f} segundos.")
else:
    print("Inviável: O modelo não encontrou solução.")
