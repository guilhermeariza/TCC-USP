# Análise Comparativa: B-Trees vs LSM-Trees em SSDs NVMe

Este repositório contém o Trabalho de Conclusão de Curso (TCC) focado na análise comparativa de desempenho entre estruturas de dados B-Trees (representadas pelo **PostgreSQL**) e LSM-Trees (representadas pelo **RocksDB**) em ambientes de armazenamento moderno (SSDs NVMe).

O projeto utiliza o **YCSB (Yahoo! Cloud Serving Benchmark)** para simular workloads realistas e mensurar o desempenho em operações de leitura, escrita e mistas.

## 🚀 Como Executar (Rápido)

O projeto foi containerizado para garantir reprodutibilidade. Você só precisa do **Docker** e **Docker Compose**.

### Passos:

1.  Certifique-se de ter o Docker instalado e rodando.
2.  Abra um terminal na pasta `benchmarks`:
    ```bash
    cd benchmarks
    ```
3.  Inicie o benchmark e a análise automática:
    ```bash
    docker-compose up --build
    ```

> **Nota:** O processo pode levar várias horas (4h+) dependendo do hardware, pois executa cargas pesadas (10 milhões de registros).

### O que acontece durante a execução?
1.  **Setup:** Inicia um container PostgreSQL e prepara o ambiente.
2.  **Benchmarks:**
    *   Executa workloads A, B, C, D, E, F para **PostgreSQL**.
    *   Executa workloads A, B, C, D, E, F para **RocksDB**.
3.  **Análise:** Ao final, um script Python processa os logs e gera gráficos comparativos.

## 📊 Resultados e Análise

Após a conclusão, você encontrará os artefatos nas seguintes pastas (dentro de `benchmarks/`):

*   **`results/`**: Contém os logs brutos de execução.
    *   `postgresql/`: Logs individuais para cada workload do Postgres.
    *   `rocksdb/`: Logs individuais para cada workload do RocksDB.
*   **`analysis/charts/`**: Contém os gráficos gerados.
    *   `throughput_comparison.png`: Comparativo de vazão (Operações/segundo).
    *   `read_latency_comparison.png`: Comparativo de latência de leitura.

## 📂 Estrutura do Projeto

```
Projeto/
├── benchmarks/                 # Núcleo da execução
│   ├── analysis/               # Scripts de geração de gráficos
│   ├── configs/                # Definições dos workloads YCSB (A-F)
│   ├── results/                # (Gerado) Logs de saída
│   ├── scripts/                # Scripts de automação (Python/Bash)
│   ├── docker-compose.yml      # Orquestração dos containers
│   └── Dockerfile              # Definição da imagem de benchmark
├── ProjetoDePesquisa.pdf       # Documento original do projeto
└── README.md                   # Este arquivo
```

## 🛠️ Tecnologias Utilizadas

*   **Benchmark:** YCSB (Yahoo! Cloud Serving Benchmark) 0.17.0
*   **Bancos de Dados:**
    *   PostgreSQL 14 (B-Tree)
    *   RocksDB (LSM-Tree - via binding Java do YCSB)
*   **Automação:** Docker, Python 3, Bash
*   **Análise:** Pandas, Matplotlib

## 📝 Workloads Testados

*   **Workload A:** Update heavy (50% Read, 50% Update)
*   **Workload B:** Read mostly (95% Read, 5% Update)
*   **Workload C:** Read only (100% Read)
*   **Workload D:** Read latest (95% Read, 5% Insert)
*   **Workload E:** Short ranges (95% Scan, 5% Insert)
*   **Workload F:** Read-modify-write (50% Read, 50% RMW)
