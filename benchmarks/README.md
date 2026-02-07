# Análise Comparativa: B-Trees vs LSM-Trees em SSDs NVMe

Este projeto contém os scripts e configurações para realizar o benchmarking comparativo entre PostgreSQL (B-Tree) e RocksDB (LSM-Tree) usando YCSB.

## Benchmarks de Estruturas de Dados

## Executando os Benchmarks (Método Recomendado)

Para garantir resultados confiáveis e evitar erros de estado residual (ex: "table already exists"), utilize o script wrapper que limpa o ambiente antes de cada execução:

### Linux / WSL / Git Bash
```bash
./run_docker_benchmarks.sh
```

Este script irá:
1.  Remover containers e volumes antigos (`docker-compose down -v`).
2.  Reconstruir as imagens (`docker-compose build`).
3.  Iniciar os testes e exibir os logs.

---

## Estrutura do Projeto

*   `configs/`: Arquivos de configuração dos workloads do YCSB (A-F).
*   `scripts/`: Scripts Python/Bash para automação dos testes.
*   `results/`: Diretório onde os resultados dos testes serão salvos.
*   `analysis/`: Scripts para análise dos dados e geração de gráficos.

## Pré-requisitos

*   WSL2 ou Linux Nativo (Kernel 5.15+)
*   Java 8+
*   Maven
*   Python 3
*   PostgreSQL
*   Compilador C++ (g++)

## Como Executar (Docker - Recomendado)

A maneira mais fácil de rodar o projeto é usando Docker, pois ele configura todo o ambiente automaticamente.

1.  Instale o Docker Desktop.
2.  Navegue até a pasta `benchmarks`.
3.  Execute:
    ```bash
    docker-compose up --build
    ```
4.  Aguarde a finalização. Os resultados estarão em `results/` e os gráficos em `analysis/charts/`.

## Como Executar (Manual - Linux/WSL)

1.  Navegue até a pasta `scripts`.
2.  Execute o script de setup: `./setup.sh`
3.  Compile o YCSB: `./build_ycsb.sh`
4.  Execute o benchmark: `./run_all.sh`
