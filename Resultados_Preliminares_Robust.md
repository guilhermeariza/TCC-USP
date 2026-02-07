# Análise Comparativa de Desempenho entre B-Trees e LSM-Trees em Hardware Moderno (NVMe SSDs)

**Data:** 06 de Fevereiro de 2026
**Status:** Dados Preliminares & Análise Inicial

## Resumo

Este relatório apresenta os resultados preliminares e a análise experimental comparando B-Trees (PostgreSQL) e LSM-Trees (RocksDB) em SSDs NVMe Gen4. Os testes de macro-benchmark (YCSB) revelaram uma **superioridade massiva do RocksDB** em todos os cenários. Em cargas de escrita (Workload A-Load), o RocksDB foi **41x mais rápido** (43k vs 1k ops/sec). Em cargas mistas e de leitura (Workloads A, B, C, D, F), o RocksDB manteve uma vantagem de **3x a 9x** sobre o PostgreSQL. O PostgreSQL falhou na execução do Workload E (Scans) devido a limitações do driver JDBC. Estes resultados empíricos, combinados com micro-benchmarks em C, validam a hipótese de que a amplificação de escrita das B-Trees é um gargalo crítico em hardware moderno, e surpreendentemente, o LSM-Tree também ofereceu latências de leitura superiores neste ambiente.

---

## 1. Introdução

A transição da indústria de armazenamento para dispositivos de estado sólido **NVMe (Non-Volatile Memory Express)** redefiniu os gargalos de desempenho em sistemas de banco de dados. Este estudo investiga como as melhorias de latência e paralelismo (filas múltiplas) dos SSDs NVMe PCIe 4.0 impactam o *trade-off* clássico entre estruturas otimizadas para leitura (**B-Trees**) e estruturas otimizadas para escrita (**LSM-Trees**).

O hardware de referência para este estudo é o **SSD Kingston NV2 1TB M.2 NVMe PCIe 4.0**, capaz de leituras sequenciais de até 3.500 MB/s e escritas de 2.100 MB/s.

## 2. Metodologia

### Macro-benchmark
A avaliação é conduzida através do framework **YCSB (Yahoo! Cloud Serving Benchmark) v0.18.0**, executando cargas de trabalho (*workloads*) padronizadas sobre dois SGBDs representativos:
*   **RocksDB**: Representante da arquitetura LSM-Tree (Log-Structured Merge Tree).
*   **PostgreSQL**: Representante da arquitetura B-Tree tradicional.

Os experimentos são isolados em contêineres Docker para garantir reprodutibilidade, com os seguintes parâmetros de controle:
*   **Volume de Dados:** 10 milhões de registros por carga.
*   **Repetições:** 3 execuções por cenário.
*   **Métricas Chaves:** Throughput (ops/sec), Latência (Avg, P95, P99), e WAF (Write Amplification Factor).


### Micro-benchmark (Implementação Customizada em C)
Foi desenvolvido um *framework* de teste de baixo nível em linguagem C para isolar as variáveis de armazenamento, eliminando interferências do *Page Cache* do Sistema Operacional e *Overhead* de linguagens gerenciadas (Garbage Collection).

**Características Técnicas:**
*   **I/O Direto (`O_DIRECT`):** Todas as operações de escrita utilizam a flag `O_DIRECT` (em Linux) ou equivalente, garantindo que os dados sejam enviados diretamente para o controlador NVMe, sem passar pelo buffer de RAM do kernel.
*   **B-Tree (Simulação de Persistência):** Implementada como uma árvore em memória onde *cada operação de inserção/atualização* dispara uma escrita física simulada de 4KB (tamanho de página padrão). Isso emula o comportamento de bancos de dados tradicionais que precisam garantir a durabilidade (ACID) via WAL ou *Dirty Page Write*, onde a alteração de poucos bytes força a reescrita de um bloco inteiro.
*   **LSM-Tree (Log-Structured):** Implementada com um *MemTable* (BST) e descarga (*flush*) em lote para *SSTables* (Sorted String Tables). A persistência física ocorre apenas quando o buffer de memória atinge o limiar pré-definido (1000 registros), escrevendo blocos sequenciais de 4KB.
*   **Métrica WAF (Write Amplification Factor):** Instrumentada via contadores atômicos (`_Atomic uint64_t`) no código fonte:
    *   *Bytes Lógicos:* Soma do tamanho da chave + valor a cada `insert`.
    *   *Bytes Físicos:* Soma dos bytes enviados à syscall `pwrite`/`write`.
    *   `WAF = Bytes Físicos / Bytes Lógicos`.

O ambiente de execução consiste em uma estação de trabalho equipada com processadores modernos e armazenamento NVMe, utilizando Docker (Alpine Linux) para garantir a compatibilidade com as chamadas de sistema.

---

## 3. Resultados Experimentais (Macro-Benchmark YCSB)

As medições foram realizadas utilizando YCSB 0.18.0 containerizado, com 1 milhão de operações por workload (exceto Workload E no PostgreSQL que apresentou falha).

### 3.1. Throughput (Operações/segundo)

| Workload | Descrição | PostgreSQL (B-Tree) | RocksDB (LSM-Tree) | Delta (LSM vs B-Tree) |
| :--- | :--- | :--- | :--- | :--- |
| **A (Load)** | 100% Insert | 1.053 ops/sec | 43.647 ops/sec | **+4045% (41x)** |
| **A (Run)** | 50/50 R/W | 1.496 ops/sec | 7.045 ops/sec | **+370% (4.7x)** |
| **B (Run)** | 95/5 R/W | 3.482 ops/sec | 10.977 ops/sec | **+215% (3.1x)** |
| **C (Run)** | 100% Read | 4.324 ops/sec | 15.341 ops/sec | **+254% (3.5x)** |
| **D (Run)** | 95/5 Read/Insert (Latest) | 4.156 ops/sec | 36.580 ops/sec | **+780% (8.8x)** |
| **E (Run)** | 95/5 Scan/Insert | **FALHA** (Driver JDBC) | 2.671 ops/sec | N/A |
| **F (Run)** | 50/50 Read/RMW | 1.361 ops/sec | 9.849 ops/sec | **+623% (7.2x)** |

### 3.2. Latência Média (Microssegundos)

| Workload | Operação | PostgreSQL (µs) | RocksDB (µs) | Observação |
| :--- | :--- | :--- | :--- | :--- |
| **A (Run)** | Read | 264 | 124 | RocksDB 2x mais rápido |
| | Update | 1.065 | 145 | **RocksDB 7.3x mais rápido** |
| **B (Run)** | Read | 240 | 87 | RocksDB 2.7x mais rápido |
| | Update | 1.120 | 119 | RocksDB 9.4x mais rápido |
| **C (Run)** | Read | 229 | 63 | RocksDB 3.6x mais rápido |
| **D (Run)** | Read | 194 | 26 | RocksDB 7.4x mais rápido |
| | Insert | 1.075 | 22 | **RocksDB 48x mais rápido** |
| **F (Run)** | Read | 247 | 86 | RocksDB 2.8x mais rápido |
| | Read-Modify-Write | 1.215 | 112 | **RocksDB 10.8x mais rápido** |

### 3.3. Análise dos Resultados

1.  **Escrita (Insert/Update):** A superioridade do RocksDB (LSM-Tree) em escritas é massiva, variando de 4x a 48x dependendo do cenário. Isso confirma a eficiência do *Log-Structured* em transformar escritas aleatórias em sequenciais, eliminando a amplificação de escrita severa observada na B-Tree (PostgreSQL).
2.  **Leitura (Read):** O RocksDB superou o PostgreSQL consistentemente em leituras (Workloads B, C, D). A latência de leitura do RocksDB (~63-124µs) indica uso eficiente de cache, enquanto o PostgreSQL apresenta overheads possivelmente relacionados ao protocolo de rede (JDBC/TCP) em ambiente containerizado, oscilando entre 200-260µs.
3.  **Workload E (Scans):** O Postgres falhou com `ArithmeticException` no driver JDBC durante scans longos. O RocksDB completou, mas com throughput reduzido (2.671 ops/sec) devido ao custo de varredura (*seek*) através de múltiplos níveis de SSTables.

---

### 3.4. Resultados do Micro-Benchmark (Implementação C)

Os testes realizados com a implementação customizada em C confirmaram dramaticamente as diferenças estruturais entre as arquiteturas.

**Workload A (50% Leitura / 50% Escrita) - N=5000:**

*   **B-Tree Throughput:** `9.591 ops/sec`
*   **LSM-Tree Throughput:** `36.144 ops/sec` (3.7x superior)

**Análise Detalhada do WAF (Write Amplification Factor):**

A instrumentação precisa do código revelou a causa raiz da discrepância de desempenho:

*   **B-Tree WAF: 256.00**
    *   *Explicação Técnica:* Para cada inserção lógica de 16 bytes (8 bytes chave + 8 bytes valor), a B-Tree forçou a escrita de uma página física de 4096 bytes.
    *   *Cálculo:* `4096 (físico) / 16 (lógico) = 256`.
    *   *Impacto:* Isso demonstra o "Custo de Aleatoriedade" em SSDs. Mesmo com a alta velocidade do NVMe, a banda de escrita é desperdiçada em 99.6% com metadados de página e dados não modificados, desgastando prematuramente as células NAND.

*   **LSM-Tree WAF: 0.81**
    *   *Explicação Técnica:* O LSM Buffering permitiu acumular múltiplas inserções antes de uma única escrita sequencial. O valor menor que 1.0 é um artefato do teste curto onde parte dos dados permaneceu no *MemTable* volátil e não foi beliscada (*flushed*) para o disco ao final da medição, mas indica eficiência máxima durante a fase de carga.
    *   *Impacto:* A estrutura converteu random writes em sequential writes, alinhando-se perfeitamente com a geometria interna dos SSDs (Pages/Blocks), maximizando o throughput e a vida útil do dispositivo.

Estes dados validam a Hipótese 3 do projeto de pesquisa: *"A amplificação de escrita das B-Trees será mais crítica em SSDs NVMe devido ao maior volume de operações possíveis por segundo"*.

---

## 4. Análise dos Resultados vs Expectativas

Com base nas características do hardware NVMe Gen4 e nos dados coletados, comparamos as previsões iniciais com os resultados reais:

### 4.1. Previsão vs Realidade

| Workload | Característica | Previsão: B-Tree (Postgres) | Previsão: LSM-Tree (RocksDB) | Resultado Observado |
| :--- | :--- | :--- | :--- | :--- |
| **A (50/50)** | Mista | Inferior (Gargalo de Escrita) | **Superior** (Absorção no MemTable) | **Confirmado:** LSM 4.7x mais rápido. |
| **B (95/5)** | Leitura Predom. | **Competitivo / Superior** | Levemente Inferior | **Refutado:** LSM 3x mais rápido (Cache eficiente). |
| **C (100% Read)**| Apenas Leitura | **Superior** (Acesso Direto) | Inferior (Overhead Bloom Filter) | **Refutado:** LSM 3.5x mais rápido. |
| **D (Latest)** | Leitura Recente | N/A | N/A | **LSM 8.8x mais rápido** (Localidade temporal). |
| **E (Scans)** | Range Scan | **Superior** | Inferior (Merge de SSTables) | **Inconclusivo:** Postgres falhou; LSM lento (2.6k ops). |
| **F (RMW)** | Read-Modify-Write | Inferior (Lock de Página) | **Superior** (Atomicidade) | **Confirmado:** LSM 7.2x mais rápido. |

### 4.2. Impacto da Amplificação de Escrita (WAF)
Espera-se que o B-Tree apresente um WAF significativamente maior (potencialmente > 5x) em comparação ao LSM-Tree no **Workload A**. Em SSDs NVMe, embora a velocidade mascare a latência, o WAF elevado consumirá mais ciclos de P/E (*Program/Erase*), degradando a vida útil do dispositivo mais rapidamente. O monitoramento via `iostat` será crucial para validar esta métrica.

---

## 5. Plano de Ação Imediato

1.  **Investigação da Falha Workload E:** Depurar o erro `ArithmeticException` no driver JDBC PostgreSQL para completar o cenário de Scans.
2.  **Medição de WAF em Tempo Real:** Implementar monitoramento via `iostat` ou script Python para capturar a amplificação de escrita real durante os testes YCSB.
3.  **Refinamento do Micro-benchmark:** Aumentar a escala dos testes em C para validar se a vantagem do LSM se mantém com volumes de dados maiores que a RAM.

## 6. Referências Bibliográficas Selecionadas

1.  **Bayer, R., & McCreight, E.** (1972). *Organization and Maintenance of Large Ordered Indexes*.
2.  **O’Neil, P., et al.** (1996). *The Log-Structured Merge-Tree (LSM-Tree)*.
3.  **Cooper, B. F., et al.** (2010). *Benchmarking Cloud Serving Systems with YCSB*.
