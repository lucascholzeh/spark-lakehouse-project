# Spark Lakehouse Project — Delta Lake & Apache Iceberg

[![Python](https://img.shields.io/badge/Python-3.11-3776AB?logo=python&logoColor=white)](https://www.python.org/)
[![Spark](https://img.shields.io/badge/Apache_Spark-3.5.3-E25A1C?logo=apachespark&logoColor=white)](https://spark.apache.org/)
[![Delta Lake](https://img.shields.io/badge/Delta_Lake-3.2.1-00ADD4)](https://delta.io/)
[![Iceberg](https://img.shields.io/badge/Apache_Iceberg-1.6.1-2196F3)](https://iceberg.apache.org/)
[![Docker](https://img.shields.io/badge/Docker-Ubuntu_24.04-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![uv](https://img.shields.io/badge/uv-0.5%2B-FFD43B)](https://docs.astral.sh/uv/)
[![MkDocs Material](https://img.shields.io/badge/MkDocs-Material-526CFE?logo=materialformkdocs&logoColor=white)](https://squidfunk.github.io/mkdocs-material/)
[![License](https://img.shields.io/badge/license-MIT-green)](https://opensource.org/licenses/MIT)

> Trabalho acadêmico de **Engenharia de Dados** — ambiente único PySpark + Jupyter Lab demonstrando **Delta Lake** e **Apache Iceberg** sobre o dataset Pokémon, com **MkDocs publicado via GitHub Pages**.

**📖 Documentação publicada**: <https://lucascholzeh.github.io/spark-lakehouse-project/>

---

## 📑 Sumário

- [O que está aqui](#-o-que-está-aqui)
- [Stack tecnológica](#-stack-tecnológica)
- [Por que `uv` e não Poetry?](#-por-que-uv-e-não-poetry)
- [Por que Docker Ubuntu e não WSL?](#-por-que-docker-ubuntu-e-não-wsl-direto)
- [Pré-requisitos no host Windows](#-pré-requisitos-no-host-windows)
- [Como reproduzir (passo a passo)](#-como-reproduzir-passo-a-passo)
- [Como executar os notebooks](#-como-executar-os-notebooks)
- [Como rodar/publicar o MkDocs](#-como-rodarpublicar-o-mkdocs)
- [Estrutura de pastas](#-estrutura-de-pastas)
- [Roteiro de apresentação (10 min)](#-roteiro-de-apresentação-10-min)
- [Troubleshooting](#-troubleshooting)
- [Referências](#-referências)
- [Uso de IA](#-uso-de-ia)

---

## 🎯 O que está aqui

Este repositório entrega:

1. Um **container Docker Ubuntu 24.04** com **Python 3.11 + OpenJDK 17 + PySpark 3.5.3 + JupyterLab** prontos para uso.
2. **3 notebooks** (`notebooks/`):
   - `00_modelagem_dados.ipynb` — descrição da fonte, **diagrama ER (Mermaid)**, **DDL (Delta + Iceberg)** e pipeline **bronze → silver → gold**.
   - `01_delta_lake.ipynb` — **CRUD completo** (INSERT, UPDATE, DELETE, MERGE) + schema evolution + time travel + OPTIMIZE/VACUUM em **Delta Lake**.
   - `02_apache_iceberg.ipynb` — mesmas operações + **partition evolution** (recurso exclusivo) + metadata tables + compaction em **Apache Iceberg**.
3. **MkDocs** (`docs/`) com 4 páginas (Início, PySpark, Delta, Iceberg) **publicado automaticamente** em GitHub Pages via Action no `push` para `main`.
4. **Reprodução à prova de balas**: `Pokemon.csv` está commitado em `data/raw/`, então não precisa de Kaggle login. Basta `docker compose up`.

---

## 🛠️ Stack tecnológica

| Componente | Versão | Por quê |
|---|---|---|
| [Ubuntu](https://ubuntu.com/) | 24.04 LTS (Noble) | Imagem oficial estável |
| [Python](https://www.python.org/) | 3.11 | PySpark 3.5 não suporta 3.12 |
| [OpenJDK](https://openjdk.org/) | 17 | Java moderno suportado pelo Spark 3.5 |
| [Apache Spark](https://spark.apache.org/) | 3.5.3 | LTS estável |
| [PySpark](https://spark.apache.org/docs/latest/api/python/) | 3.5.3 | API Python casada com Spark |
| [Delta Lake](https://delta.io/) | `delta-spark==3.2.1` | Compatível com Spark 3.5 |
| [Apache Iceberg](https://iceberg.apache.org/) | `iceberg-spark-runtime-3.5_2.12:1.6.1` | Última estável Spark 3.5 |
| [JupyterLab](https://jupyter.org/) | 4.x | IDE web dos notebooks |
| [uv](https://docs.astral.sh/uv/) | 0.5+ | Gerenciador de pacotes |
| [MkDocs Material](https://squidfunk.github.io/mkdocs-material/) | 9.5+ | Site de documentação |
| [Docker](https://www.docker.com/) | 24+ | Containerização |

---

## 📦 Por que `uv` e não Poetry?

| Critério | uv | Poetry |
|---|---|---|
| Velocidade | **10–100× mais rápido** (escrito em Rust) | Mais lento (Python puro) |
| Gerencia versão Python | ✅ Auto-instala Python | ❌ Depende de pyenv |
| Lockfile | `uv.lock` (PEP 751) | `poetry.lock` (formato próprio) |
| PEP compliance | ✅ Estrita | Às vezes desvia |
| Maturidade | Recente, mas backed pela Astral (Ruff) | Mais antigo, comunidade maior |
| Publicar lib em PyPI | OK | **Mais polido** |
| Build Docker | ✅ Cache agressivo, build rápido | Lento |

**Escolhemos `uv`** porque este é um *projeto de aplicação rodando em Docker*, não uma biblioteca para PyPI. Velocidade de build no CI e simplicidade ganham.

> Quer migrar de Poetry para uv? `uv add <pacote>` substitui `poetry add`, e `uv lock` substitui `poetry lock`. O `pyproject.toml` segue PEP 621 e funciona nos dois (com ajustes mínimos).

---

## 🐳 Por que Docker Ubuntu e não WSL direto?

O trabalho **precisa rodar em Linux** mas o host é Windows. As opções eram:

| Opção | Reprodutível? | Setup do avaliador | Veredito |
|---|---|---|---|
| **Docker container Ubuntu** | ✅ Idêntico em qualquer host | Só Docker Desktop | **Escolhida** |
| WSL2 Ubuntu direto | ❌ Depende do estado da distro | Instalar WSL + dependências | Frágil |
| VM VirtualBox/Hyper-V | ⚠️ Pesada | Instalar VM + ISO | Overhead alto |

Numa apresentação acadêmica de **10 minutos onde "não funcionou = nota 0"**, reprodutibilidade é prioridade absoluta. O `docker-compose.yml` é a **única dependência** do avaliador.

---

## 🧰 Pré-requisitos no host Windows

| Software | Link | Versão mínima |
|---|---|---|
| **Docker Desktop** | <https://www.docker.com/products/docker-desktop/> | 24+ |
| **Git** | <https://git-scm.com/download/win> | 2.40+ |
| **VS Code** *(opcional, recomendado)* | <https://code.visualstudio.com/> | latest |
| **Extensão "Dev Containers"** *(VS Code)* | <https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers> | latest |
| **Extensão "Jupyter"** *(VS Code)* | <https://marketplace.visualstudio.com/items?itemName=ms-toolsai.jupyter> | latest |

> **Não precisa instalar Python, Java ou Spark no Windows**. Tudo roda dentro do container.

---

## 🚀 Como reproduzir (passo a passo)

### 1. Clonar o repositório

```bash
git clone https://github.com/lucascholzeh/spark-lakehouse-project.git
cd spark-lakehouse-project
```

### 2. (Opcional) Baixar o `Pokemon.csv`

O arquivo já está commitado em `data/raw/Pokemon.csv` para a apresentação não depender de internet. Se quiser refazer o download:

```bash
bash scripts/setup_data.sh
```

### 3. Subir o ambiente

```bash
docker compose up --build -d
```

A primeira execução baixa a imagem Ubuntu, instala Java 17, copia o `uv` e cria o ambiente Python (~3-5 min). Execuções subsequentes usam o cache e levam ~5 segundos.

### 4. Verificar que o JupyterLab está rodando

```bash
docker compose ps
docker compose logs -f jupyter
```

Você deve ver `Jupyter Server ... is running at http://0.0.0.0:8888/lab`.

### 5. Abrir o JupyterLab no browser

Acesse: **<http://localhost:8888>** (sem token — vinculado a `127.0.0.1` apenas).

### 6. (Alternativa) Abrir no VS Code

```text
F1 → "Dev Containers: Attach to Running Container..." → escolha "spark-lakehouse-jupyter"
```

A extensão Jupyter detecta o kernel automaticamente e os notebooks rodam direto no editor.

### 7. Derrubar o ambiente quando terminar

```bash
docker compose down            # mantém volumes (cache de JARs Iceberg, dados)
docker compose down -v         # apaga TUDO inclusive o cache
```

---

## 📓 Como executar os notebooks

Execute **na ordem**:

| # | Notebook | O que faz | Tempo |
|---|---|---|---|
| 1 | `00_modelagem_dados.ipynb` | Lê `Pokemon.csv`, normaliza em modelo estrela e escreve `data/gold/` em Parquet | ~30 s |
| 2 | `01_delta_lake.ipynb` | Cria 3 tabelas Delta + CRUD + schema evolution + time travel + OPTIMIZE/VACUUM | ~1 min |
| 3 | `02_apache_iceberg.ipynb` | Cria 3 tabelas Iceberg + CRUD + schema/partition evolution + time travel + compaction | ~2 min (primeira vez baixa o JAR Iceberg) |

> **Importante**: o notebook 00 **precisa ser executado primeiro**, pois os notebooks 01 e 02 leem do `data/gold/`.

---

## 📚 Como rodar/publicar o MkDocs

### Localmente (dentro do container)

```bash
docker compose exec jupyter uv run mkdocs serve -a 0.0.0.0:8000
```

E acesse <http://localhost:8000>. *Para isso funcionar, exponha também a porta 8000 no `docker-compose.yml` (já está pronto para 8888 — basta adicionar).*

### Localmente (no host, se quiser)

```bash
uv sync --group docs

# Copiar notebooks para docs/ (só para o site renderizá-los)
mkdir -p docs/notebooks && cp notebooks/*.ipynb docs/notebooks/

uv run mkdocs serve
```

### Publicar no GitHub Pages

**Automático** via GitHub Action (`.github/workflows/deploy-docs.yml`):

- A cada push em `main` que toque em `docs/**`, `mkdocs.yml`, `notebooks/**` ou `pyproject.toml`, a Action roda `mkdocs gh-deploy --force` e publica em `https://lucascholzeh.github.io/spark-lakehouse-project/`.

**Manual** (se preferir):

```bash
uv run mkdocs gh-deploy --force
```

> :rotating_light: **Configure GitHub Pages no repositório**:
> Settings → Pages → Source: "Deploy from a branch" → Branch: `gh-pages` → Folder: `/ (root)` → Save.

---

## 📁 Estrutura de pastas

```text
spark-lakehouse-project/
├── README.md                          ← este arquivo (instruções de reprodução)
├── Dockerfile                         ← Ubuntu 24.04 + Java 17 + uv
├── docker-compose.yml                 ← serviço jupyter
├── pyproject.toml                     ← dependências Python (gerido pelo uv)
├── uv.lock                            ← lockfile (gerado no 1º build)
├── .python-version                    ← 3.11
├── .dockerignore
├── .gitignore
│
├── mkdocs.yml                         ← config do site
├── docs/                              ← conteúdo MkDocs (publicado em gh-pages)
│   ├── index.md                       ← contextualização do trabalho
│   ├── pyspark.md                     ← Apache Spark / PySpark
│   ├── delta-lake.md                  ← Delta Lake
│   ├── iceberg.md                     ← Apache Iceberg
│   └── assets/                        ← imagens (se houver)
│
├── notebooks/
│   ├── 00_modelagem_dados.ipynb       ← ER + DDL + bronze→silver→gold
│   ├── 01_delta_lake.ipynb            ← CRUD + time travel Delta
│   └── 02_apache_iceberg.ipynb        ← CRUD + time travel Iceberg
│
├── scripts/
│   └── setup_data.sh                  ← (re)baixa Pokemon.csv
│
├── data/
│   ├── raw/Pokemon.csv                ← fonte (commitada, ~45 KB)
│   ├── gold/                          ← Parquet (gitignored)
│   ├── delta/                         ← warehouse Delta (gitignored)
│   └── iceberg/warehouse/             ← warehouse Iceberg (gitignored)
│
└── .github/
    └── workflows/
        └── deploy-docs.yml            ← GitHub Action: gh-deploy
```

---

## 🎬 Roteiro de apresentação (10 min)

> Use este roteiro durante a apresentação para o professor. Tempo total: **9 min de demo + 1 min de Q&A**.

| Tempo | Ação | O que mostrar |
|---|---|---|
| **0:00 – 1:00** | Abrir o repositório no GitHub | README com badges, estrutura de pastas, link para o MkDocs publicado |
| **1:00 – 2:00** | Abrir o MkDocs publicado | Página inicial, navegação pelas 4 páginas, diagramas Mermaid renderizando, código com syntax highlight |
| **2:00 – 2:30** | Subir o ambiente | `docker compose up -d` + `docker compose logs jupyter` + abrir <http://localhost:8888> |
| **2:30 – 4:30** | Notebook 00 — modelagem | Mostrar diagrama ER (Mermaid), DDLs lado a lado, rodar pipeline bronze→silver→gold, conferir schemas |
| **4:30 – 7:00** | Notebook 01 — Delta Lake | Rodar células: write inicial → INSERT → UPDATE (avg attack lendários antes/depois) → DELETE → MERGE → schema evolution → **time travel** (versão 0 vs atual) → DESCRIBE HISTORY |
| **7:00 – 9:00** | Notebook 02 — Iceberg | Mesmo CRUD via SQL puro → schema evolution → **partition evolution (destacar: só Iceberg tem)** → time travel → metadata tables (`.snapshots`, `.history`, `.files`) → compaction |
| **9:00 – 10:00** | Conclusão | Tabela comparativa Delta × Iceberg, próximos passos, Q&A |

> 💡 **Dica para a apresentação**: deixe o ambiente **já buildado** antes (`docker compose up -d` 5 min antes do horário) para o slot 2:00–2:30 ser instantâneo. O cache de JARs do Iceberg também já estará quente.

---

## 🩺 Troubleshooting

### Porta 8888 já em uso

```bash
# Veja quem está usando
docker ps | grep 8888
# ou no Windows
netstat -ano | findstr :8888
```

Solução: derrube quem está usando, ou edite `docker-compose.yml` para `127.0.0.1:8889:8888`.

### Java OutOfMemory durante OPTIMIZE/MERGE

Adicione no `docker-compose.yml` em `environment:`:

```yaml
SPARK_DRIVER_MEMORY: "4g"
```

Ou direto na SparkSession dos notebooks:

```python
.config("spark.driver.memory", "4g")
```

### Download lento dos JARs Iceberg na primeira execução

O Spark baixa `iceberg-spark-runtime-3.5_2.12:1.6.1` (~30 MB) do Maven Central na primeira vez. O `docker-compose.yml` deste projeto monta um volume `ivy-cache` para que execuções subsequentes sejam instantâneas. Se for muito lento, pode pré-baixar:

```bash
docker compose exec jupyter bash -c "uv run python -c 'from pyspark.sql import SparkSession; SparkSession.builder.config(\"spark.jars.packages\", \"org.apache.iceberg:iceberg-spark-runtime-3.5_2.12:1.6.1\").getOrCreate().stop()'"
```

### `Pokemon.csv` ausente

```bash
bash scripts/setup_data.sh
```

### Permissões em `data/` no Linux/WSL

```bash
sudo chown -R "$USER":"$USER" data/
```

### GitHub Pages 404

1. Settings → Pages → Source: **Deploy from a branch**, Branch: `gh-pages`, Folder: `/ (root)` → Save.
2. Aguarde 1-2 min após o `gh-deploy` para o GitHub propagar.
3. Verifique a Action em Actions → "Deploy MkDocs to GitHub Pages" — deve estar verde.

### `docker compose up` falha por falta de memória

Docker Desktop por padrão limita memória a 2 GB no Windows. Suba para 6+ GB:
**Settings → Resources → Memory → 6 GB**.

### Notebook não acha o Pokemon.csv

Confira se você abriu o JupyterLab a partir do container (porta 8888), não diretamente no host. Os caminhos são `/workspace/data/...` (caminho **dentro do container**).

---

## 📚 Referências

### Apache Spark
- [Spark 3.5 Docs](https://spark.apache.org/docs/3.5.3/)
- [PySpark API](https://spark.apache.org/docs/3.5.3/api/python/)

### Delta Lake
- [delta.io](https://delta.io/)
- [delta-spark on PyPI](https://pypi.org/project/delta-spark/)
- [Quick Start (Jupyter)](https://delta.io/blog/delta-lake-jupyter-notebook/)

### Apache Iceberg
- [iceberg.apache.org](https://iceberg.apache.org/)
- [Spark Quickstart](https://iceberg.apache.org/spark-quickstart/)
- [Multi-Engine Support](https://iceberg.apache.org/multi-engine-support/)

### Ferramentas
- [uv documentation](https://docs.astral.sh/uv/)
- [MkDocs Material](https://squidfunk.github.io/mkdocs-material/)
- [MkDocs gh-deploy](https://www.mkdocs.org/user-guide/deploying-your-docs/#deploying-to-github-pages)
- [Docker Compose v2](https://docs.docker.com/compose/)

### Dataset
- [Pokemon (Kaggle abcsds/pokemon)](https://www.kaggle.com/datasets/abcsds/pokemon)
- [Mirror público do CSV (Gist)](https://gist.githubusercontent.com/armgilles/194bcff35001e7eb53a2a8b441e8b2c6)

---

## 🤖 Uso de IA

Este projeto foi desenvolvido com auxílio de **IA generativa (Claude — Anthropic)** em conformidade com o requisito do enunciado. A IA foi usada para:

- Pesquisar a **matriz de compatibilidade** entre Spark 3.5, Delta Lake 3.2.1 e Iceberg 1.6.1 (versões e dependências verificadas em fontes oficiais durante o desenvolvimento).
- Comparar **uv vs Poetry** com base em benchmarks e artigos de 2026.
- Estruturar o **Dockerfile multi-stage** (importando `uv` da imagem oficial), o `docker-compose.yml` e a GitHub Action de deploy.
- Esboçar os **notebooks didáticos** (CRUD + time travel) com cenários narrativos sobre o dataset Pokémon (rebalanceamento de lendários, Gen 7, mega-evoluções).
- Gerar os **diagramas Mermaid** (ER, arquitetura) e o esqueleto das páginas MkDocs.
- Propor o **roteiro de apresentação de 10 minutos**.

Todo o código foi revisado, testado e adaptado pelo autor. Decisões arquiteturais (uv, Docker, Pokemon, modelo estrela) foram tomadas pelo autor com base no comparativo apresentado pela IA.

---

## 👤 Autor

**Lucas Hoffmann**

- Email: lucasschoff@gmail.com
- GitHub: [@lucascholzeh](https://github.com/lucascholzeh)
- Documentação publicada: <https://lucascholzeh.github.io/spark-lakehouse-project/>

---

📄 **Licença**: MIT
