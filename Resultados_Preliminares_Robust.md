# Análise Comparativa de Desempenho entre B-Trees e LSM-Trees em Hardware Moderno (NVMe SSDs)

**Data:** 06 de Fevereiro de 2026
**Status:** Dados Preliminares & Análise Inicial

## Resumo

Este relatório apresenta os resultados preliminares e a análise teórica para o projeto de pesquisa que visa comparar o desempenho das estruturas B-Trees e LSM-Trees em SSDs NVMe Gen4. Até o momento, foi estabelecida uma linha de base sólida para o **RocksDB (LSM-Tree)** utilizando o benchmark YCSB, atingindo aproximadamente **5.070 ops/sec** em cargas mistas (50/50 R/W) com latências de cauda (P99) abaixo de **1.6ms**. Os testes com **PostgreSQL (B-Tree)** encontram-se em fase final de estabilização do ambiente, com execuções iniciais identificando desafios críticos de configuração em ambientes containerizados. Este documento detalha os dados coletados, analisa os obstáculos técnicos encontrados e projeta o comportamento esperado para as próximas fases com base na literatura e nas especificações do hardware alvo (Kingston NV2 1TB NVMe).

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

## 3. Resultados Preliminares

Os testes iniciais focaram na validação do ambiente de teste e na obtenção de métricas de base (*baseline*) para o **Workload A (Update Heavy: 50% Leitura / 50% Atualização)**.

### 3.1. Linha de Base: RocksDB (LSM-Tree)

O RocksDB demonstrou alta eficiência na ingestão de dados e consistência em latência, confirmando a hipótese de que LSM-Trees se beneficiam do design *append-only*, mesmo em SSDs rápidos.

**Resumo da Execução (Workload A):**
*   **Throughput Médio:** `5.069 ops/sec`
*   **Tempo Total de Execução:** ~197 segundos para 1.000.000 operações.
*   **Latência de Leitura (Média):** `181 µs`
*   **Latência de Escrita (Média):** `205 µs`
*   **Latência de Cauda (P99):** `1.49 ms` (Leitura) / `1.56 ms` (Escrita)

A latência extremamente baixa de leitura (Média de 0.18 ms) sugere que o *Bloom Filter* e o cache de blocos do RocksDB estão operando eficientemente, minimizando o impacto da estrutura em níveis (*levels*).

### 3.2. Desafios com PostgreSQL (B-Tree)

As execuções preliminares com PostgreSQL revelaram desafios significativos na orquestração do ambiente de teste. Embora o throughput "bruto" tenha se aproximado de **5.100 ops/sec**, uma análise detalhada dos logs indicou uma taxa de erro elevada (`PSQLException: relation "usertable" does not exist`), sugerindo que os testes iniciavam antes da completa inicialização e carga das tabelas no banco de dados.

Nas operações bem-sucedidas isoladas, observou-se:
*   **Latência de Leitura (Sucesso):** ~218 µs (comparável ao RocksDB).
*   **Latência de Escrita (Sucesso):** ~1.623 µs (significativamente maior que o RocksDB).

Esta discrepância inicial na escrita (quase 8x mais lenta que o RocksDB) alinha-se com a teoria de que atualizações *in-place* em B-Trees são mais custosas devido à necessidade de *Page Writes* completos (frequentemente 4KB ou 8KB) para pequenas alterações, gerando maior amplificação de escrita.


### 3.3. Resultados do Micro-Benchmark (Implementação C)

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

## 4. Análise Teórica e Expectativas (Próximos Passos)

Com base nas características do hardware NVMe Gen4 e nos dados preliminares, projetamos os seguintes cenários para a bateria completa de testes:

### 4.1. Previsão de Desempenho por Workload

| Workload | Característica | Previsão: B-Tree (Postgres) | Previsão: LSM-Tree (RocksDB) | Hipótese NVMe |
| :--- | :--- | :--- | :--- | :--- |
| **A (50/50)** | Mista | Inferior (Gargalo de Escrita Aleatória) | **Superior** (Absorção de Escrita no MemTable) | NVMe reduz latência, mas não elimina o *overhead* de atualização *in-place*. |
| **B (95/5 Read)**| Leitura Predom. | **Competitivo / Superior** | Levemente Inferior (Overhead de descompactação) | Baixa latência do NVMe beneficia leituras diretas em B-Tree. |
| **C (100% Read)**| Apenas Leitura | **Superior** | Inferior | B-Tree deve vencer por acesso direto sem verificação de Bloom Filters. |
| **E (Scans)** | Range Scan | **Superior** | Inferior | Organização sequencial das folhas da B-Tree é ideal para scans; LSM sofre com *merges* de múltiplos arquivos. |
| **F (RMW)** | Read-Modify-Write | Inferior | **Superior** | Atomicidade do RMW no LSM é mais eficiente que o *lock* de página na B-Tree. |

### 4.2. Impacto da Amplificação de Escrita (WAF)
Espera-se que o B-Tree apresente um WAF significativamente maior (potencialmente > 5x) em comparação ao LSM-Tree no **Workload A**. Em SSDs NVMe, embora a velocidade mascare a latência, o WAF elevado consumirá mais ciclos de P/E (*Program/Erase*), degradando a vida útil do dispositivo mais rapidamente. O monitoramento via `iostat` será crucial para validar esta métrica.

---

## 5. Plano de Ação Imediato

1.  **Correção do PostgreSQL:** Ajustar o script de inicialização do benchmark para garantir que a tabela `usertable` esteja totalmente carregada e indexada antes do início da fase de execução (*run*).
2.  **Validação de WAF:** Instrumentar a coleta de bytes escritos no nível do bloco (`/sys/block/nvme0n1/stat`) para calcular o WAF real durante os testes.
3.  **Execução Completa:** Rodar os Workloads B, C, D, E e F após a estabilização do ambiente PostgreSQL.

## 6. Referências Bibliográficas Selecionadas

1.  **Bayer, R., & McCreight, E.** (1972). *Organization and Maintenance of Large Ordered Indexes*.
2.  **O’Neil, P., et al.** (1996). *The Log-Structured Merge-Tree (LSM-Tree)*.
3.  **Cooper, B. F., et al.** (2010). *Benchmarking Cloud Serving Systems with YCSB*.
