# Análise Comparativa de Desempenho entre B-Trees e LSM-Trees em Hardware Moderno

**[Nome Completo Aluno]**¹*; **[Nome Completo Orientador]**²

¹[Nome da Empresa ou Instituição] (opcional). Titulação ou função ou departamento. Endereço completo (pessoal ou profissional) – Bairro; 00000-000 Cidade, Estado, País
²[Nome da Empresa ou Instituição] (opcional). Titulação ou função ou departamento. Endereço completo (pessoal ou profissional) – Bairro; 00000-000 Cidade, Estado, País
*autor correspondente: nome@email.com

## Resumo (ou Sumário Executivo)

Este trabalho apresenta os resultados preliminares da análise comparativa de desempenho entre as estruturas de dados B-Trees e LSM-Trees (Log-Structured Merge Trees) em dispositivos de armazenamento modernos (NVMe SSDs). O estudo utiliza uma abordagem híbrida, combinando *micro-benchmarks* desenvolvidos em C com I/O Direto (`O_DIRECT`) para isolar o comportamento das estruturas, e *macro-benchmarks* utilizando YCSB (Yahoo! Cloud Serving Benchmark) contra sistemas de banco de dados reais (PostgreSQL e RocksDB). Os resultados preliminares indicam um throughput de aproximadamente 5.000 ops/sec para o RocksDB no Workload A (50% leitura/50% escrita), estabelecendo uma linha de base para a avaliação das implementações customizadas.

**Palavras-chave:** B-Tree; LSM-Tree; NVMe; Banco de Dados; Desempenho.

## Introdução

O advento dos dispositivos de armazenamento de estado sólido com interface NVMe (Non-Volatile Memory Express) alterou fundamentalmente as premissas de design para sistemas de gerenciamento de dados. Enquanto as estruturas baseadas em B-Trees têm sido o padrão da indústria por décadas em sistemas relacionais como o PostgreSQL, elas sofrem de um fenômeno conhecido como Amplificação de Escrita (*Write Amplification*), que é exacerbado em SSDs devido à granularidade de página (4KB ou maior).

Em contrapartida, as LSM-Trees (Log-Structured Merge Trees), popularizadas por sistemas como RocksDB e LevelDB, prometem melhor desempenho de escrita ao transformar atualizações aleatórias em gravações sequenciais em lote. No entanto, essa vantagem pode vir ao custo de maior latência de leitura e picos de uso de CPU durante processos de compactação.

Este trabalho justifica-se pela necessidade de reavaliar essas estruturas clássicas sob a ótica do hardware moderno, onde a latência de I/O é drasticamente reduzida, tornando o *overhead* de software e a eficiência da CPU fatores críticos. O objetivo deste trabalho é quantificar as diferenças de desempenho e amplificação de escrita entre B-Trees e LSM-Trees em cargas de trabalho mistas, típicas de aplicações transacionais modernas.

## Metodologia ou Material e Métodos

A metodologia adotada divide-se em duas abordagens complementares: *Macro-benchmark* e *Micro-benchmark*.

### Macro-benchmark
Para a avaliação de sistemas de produção, utiliza-se o framework padronizado YCSB (Yahoo! Cloud Serving Benchmark) versão 0.18.0. Os sistemas alvo são:
1.  **RocksDB (LSM-Tree):** Representando o estado da arte em *key-value stores* otimizados para escrita.
2.  **PostgreSQL (B-Tree):** Representando bancos de dados relacionais tradicionais.

Os testes são executados em contêineres Docker isolados, simulando um ambiente de produção controlado. O *Workload A* do YCSB (50% Leitura, 50% Atualização) é utilizado como carga principal para avaliar o compromisso entre leitura e escrita.

### Micro-benchmark
Foi desenvolvido um *framework* de teste customizado em linguagem C, projetado especificamente para este estudo. Este *micro-benchmark* implementa:
*   Uma B-Tree em memória com simulação de persistência de páginas sujas.
*   Uma LSM-Tree com MemTable em memória e descarga sequencial de SSTables.
*   Utilização de **I/O Direto (`O_DIRECT`)** para contornar o *Page Cache* do sistema operacional, garantindo que as métricas de latência reflitam o desempenho real do dispositivo NVMe.
*   Instrumentação para medição precisa do Fator de Amplificação de Escrita (WAF), comparando bytes lógicos escritos pela aplicação versus bytes físicos escritos no dispositivo.

O ambiente de execução consiste em uma estação de trabalho equipada com processadores modernos e armazenamento NVMe, utilizando o sistema operacional Windows com subsistema Linux (WSL2) e Docker para orquestração.

## Resultados Preliminares

Até o presente momento, foram coletados dados de linha de base para o sistema RocksDB utilizando o *Workload A* do YCSB.

### Linha de Base: RocksDB (Workload A)
Os testes executados com o RocksDB demonstraram um comportamento consistente para cargas mistas de leitura e escrita. A execução de referência (`rocksdb_workload_a_run_20260127_014746.log`) apresentou os seguintes resultados:

*   **Throughput Global:** 5.069 operações/segundo.
*   **Latência Média de Leitura:** 181,7 µs (microssegundos).
*   **Latência Média de Atualização:** 205,4 µs.
*   **Latência P99 (Leitura/Atualização):** ~1.5 ms.

Oberva-se que o RocksDB mantém uma latência de cauda (*tail latency*) controlada (P99 abaixo de 2ms), característica desejável para sistemas de baixa latência.

### Resultados do Micro-benchmark e PostgreSQL
Os testes comparativos com o PostgreSQL e a implementação customizada em C encontram-se em fase de refinamento de configuração. Execuções iniciais com o PostgreSQL indicaram a necessidade de ajustes nos parâmetros de *buffer pool* e persistência para evitar erros de *timeout* e contenção de *lock* observados nos logs preliminares (`UPDATE-FAILED`). A implementação em C está sendo portada para garantir compatibilidade total com as chamadas de sistema de I/O assíncrono em ambiente containerizado.

Os próximos passos incluem a estabilização do ambiente de teste para o PostgreSQL e a coleta das métricas de WAF (Amplificação de Escrita) comparativas entre as implementações B-Tree e LSM-Tree customizadas.

## Conclusão(ões) ou Considerações Finais

Os resultados preliminares estabelecem que o RocksDB, representando a arquitetura LSM-Tree, oferece um desempenho robusto para cargas de trabalho mistas em hardware moderno, com latências na ordem de microssegundos. A etapa seguinte, crucial para a conclusão deste estudo, focará na obtenção de dados comparáveis para a arquitetura B-Tree, permitindo uma análise quantitativa direta das compensações (trade-offs) entre as duas estruturas, especialmente no que tange ao desgaste do dispositivo (WAF) e latência sob alta concorrência.

## Agradecimentos

Agradeço à orientação e suporte oferecidos durante o desenvolvimento deste projeto, bem como à disponibilidade de recursos computacionais para a realização dos benchmarks.

## Referências

COOPER, B. F. et al. **Benchmarking Cloud Serving Systems with YCSB**. In: Proceedings of the 1st ACM symposium on Cloud computing. 2010.
O'NEIL, P. et al. **The Log-Structured Merge-Tree (LSM-Tree)**. Acta Informatica, v. 33, n. 4, p. 351-385, 1996.
POSTGRESQL GLOBAL DEVELOPMENT GROUP. **PostgreSQL 14 Documentation**. 2023.
FACEBOOK. **RocksDB: A Persistent Key-Value Store for Flash and RAM Storage**. 2013.
