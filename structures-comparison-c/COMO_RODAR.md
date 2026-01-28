# Guia de Execução - Comparação de Estruturas (C)

A implementação em C está pronta na pasta `structures-comparison-c`.

## Requisitos
Para compilar e rodar, você precisa de um compilador C (`gcc`).
Detectamos que o `gcc` não está disponível diretamente no Windows nem na sua instalação atual do WSL (Ubuntu). O Docker também não parece estar rodando.

## Opção 1: Usando WSL (Recomendado)
Como você tem o WSL instalado, a maneira mais fácil é instalar o compilador lá:

1. Abra seu terminal WSL (Ubuntu):
   ```bash
   wsl -d Ubuntu
   ```
2. Instale o GCC:
   ```bash
   sudo apt-get update
   sudo apt-get install -y build-essential
   ```
3. Navegue até a pasta do projeto e rode:
   ```bash
   cd '/mnt/c/Users/USER/OneDrive/Documentos/TCC-PÓS/Projeto/structures-comparison-c'
   make
   ./benchmark
   ```

## Opção 2: Usando Docker
Certifique-se que o Docker Desktop está rodando e tente:

```bash
docker build -t structures-benchmark-c .
docker run --rm -v "$(pwd):/app" structures-benchmark-c
```

## O que foi implementado
- **B-Tree**: Árvore B em memória (inserção, busca, deleção simples).
- **LSM-Tree**: Árvore LSM com MemTable (BST em memória) e SSTables (arquivos em disco), incluindo busca que varre disco.
