# Delta Lake

> **Delta Lake** é um *open-source storage framework* que adiciona transações ACID, time travel, schema evolution e DML (UPDATE/DELETE/MERGE) sobre arquivos Parquet em qualquer storage (S3, ADLS, HDFS, disco local). Criado pela **Databricks** em 2019, open-sourced em 2020.

---

## :material-information: Como funciona

Uma tabela Delta é **um diretório** com:

```
fact_pokemon/
├── _delta_log/                    ← transaction log
│   ├── 00000000000000000000.json  ← v0 — write inicial
│   ├── 00000000000000000001.json  ← v1 — INSERT
│   ├── 00000000000000000002.json  ← v2 — UPDATE
│   └── 00000000000000000010.checkpoint.parquet  ← snapshot a cada 10 versões
├── generation_id=1/
│   ├── part-00000-...snappy.parquet
│   └── part-00001-...snappy.parquet
├── generation_id=2/
│   └── part-...
└── ...
```

O `_delta_log/` é **a fonte da verdade**: cada arquivo JSON descreve as **mudanças** em relação à versão anterior (arquivos adicionados, removidos, mudanças de schema). Para ler uma versão N, o Delta:

1. Carrega o último checkpoint anterior a N.
2. Aplica todos os JSONs entre o checkpoint e N.
3. Resultado: lista exata de arquivos Parquet a ler.

Esta arquitetura dá:

- **ACID**: cada commit é um arquivo JSON único — `mv` atômico no filesystem.
- **Time travel**: reler qualquer versão anterior é só repetir os passos acima até N.
- **Concurrency**: múltiplos writers usam **optimistic locking** com retry em conflito.

---

## :material-database-arrow-up: Setup da SparkSession

```python
from pyspark.sql import SparkSession
from delta import configure_spark_with_delta_pip

builder = (
    SparkSession.builder.appName("DeltaApp")
    .config("spark.sql.extensions",
            "io.delta.sql.DeltaSparkSessionExtension")
    .config("spark.sql.catalog.spark_catalog",
            "org.apache.spark.sql.delta.catalog.DeltaCatalog")
)
spark = configure_spark_with_delta_pip(builder).getOrCreate()
```

`configure_spark_with_delta_pip` é um helper do `delta-spark` que injeta o JAR Delta correto no classpath.

---

## :material-table-edit: CRUD — exemplos do notebook

Os exemplos abaixo são **trechos exatos** de [`notebooks/01_delta_lake.ipynb`](https://github.com/lucascholzeh/spark-lakehouse-project/blob/main/notebooks/01_delta_lake.ipynb), aplicados ao modelo dimensional Pokémon.

### CREATE / Write inicial

```python
# fact_pokemon — particionada por generation_id
(fact_pokemon.write
    .format("delta")
    .mode("overwrite")
    .partitionBy("generation_id")
    .save("/workspace/data/delta/fact_pokemon"))
```

A primeira escrita cria `_delta_log/00000000000000000000.json` (versão 0).

### INSERT — append

```python
new_pokemons = spark.createDataFrame([
    (801, "Decidueye",  "Grass", "Ghost",  78,107,75,100,100,70, 530, False, 7),
    (802, "Incineroar", "Fire",  "Dark",   95,115,90,80,90,60,   530, False, 7),
    (803, "Primarina",  "Water", "Fairy",  80,74,74,126,116,60,  530, False, 7),
], schema="...")

new_pokemons.write.format("delta").mode("append").save(path)
```

!!! info "O que acontece no log"
    Uma nova entrada `add` é criada para cada arquivo Parquet adicionado. Nada é reescrito — append é puro.

### UPDATE — `DeltaTable.update()`

Cenário: rebalancear lendários, diminuindo `attack` em 10.

```python
from delta.tables import DeltaTable
from pyspark.sql import functions as F

fact_table = DeltaTable.forPath(spark, "/workspace/data/delta/fact_pokemon")

fact_table.update(
    condition = F.col("is_legendary") == True,
    set       = {"attack": F.col("attack") - F.lit(10)}
)
```

!!! info "Como o Delta executa UPDATE"
    UPDATE não é in-place. O Delta:

    1. Lê os arquivos que **podem** conter linhas com `is_legendary = true`.
    2. Reescreve esses arquivos com a transformação aplicada.
    3. Cria um commit que **adiciona** os novos arquivos e **remove** os antigos.
    4. Linhas que não casam com a condição são copiadas inalteradas.

    Por isso UPDATE é mais caro que INSERT — sempre que possível, prefira append e use UPDATE só quando realmente for corrigir dados.

### DELETE — `DeltaTable.delete()`

```python
fact_table.delete(F.col("total") < F.lit(250))
```

Mesmo padrão do UPDATE: arquivos afetados são reescritos sem as linhas que casam com a condição.

### MERGE — Upsert

A operação mais poderosa. Cenário: chegou uma fonte com **correções de stats existentes** + **novos Pokémons**. Um único MERGE resolve as duas operações:

```python
(fact_table.alias("t")
    .merge(updates.alias("s"), "t.pokemon_id = s.pokemon_id")
    .whenMatchedUpdateAll()
    .whenNotMatchedInsertAll()
    .execute())
```

Equivalente SQL (Spark SQL):

```sql
MERGE INTO delta.`/workspace/data/delta/fact_pokemon` t
USING updates_view s
ON t.pokemon_id = s.pokemon_id
WHEN MATCHED THEN UPDATE SET *
WHEN NOT MATCHED THEN INSERT *
```

---

## :material-format-list-bulleted-square: Schema Evolution

Adicionar uma coluna `mega_evolution: boolean` sem precisar declarar `ALTER TABLE`:

```python
mega = spark.createDataFrame([...], schema="... mega_evolution BOOLEAN")

(mega.write.format("delta")
    .mode("append")
    .option("mergeSchema", "true")  # <-- mágica acontece aqui
    .save(path))
```

Linhas antigas ficam com `mega_evolution = NULL` automaticamente.

!!! warning "Operações suportadas"
    Schema evolution **suporta**: adicionar colunas, mudar nullable, reordenar.

    Schema evolution **NÃO suporta**: renomear colunas, mudar tipos incompatíveis, deletar colunas (precisa `ALTER TABLE` explícito ou recriar).

---

## :material-clock-time-eight: Time Travel

Ler qualquer versão anterior:

```python
# Por número de versão
v0 = (spark.read.format("delta")
      .option("versionAsOf", 0)
      .load(path))

# Por timestamp
v_yesterday = (spark.read.format("delta")
               .option("timestampAsOf", "2026-04-27 12:00:00")
               .load(path))
```

Útil para:

- **Auditoria**: o que essa tabela continha quando o relatório foi gerado?
- **Debug**: quando essa linha foi alterada?
- **Rollback**: `spark.sql("RESTORE TABLE ... TO VERSION AS OF N")`.

### `DESCRIBE HISTORY`

```python
spark.sql(f"DESCRIBE HISTORY delta.`{path}`").show(truncate=False)
```

Saída (recortada):

| version | timestamp | operation | operationMetrics |
|---|---|---|---|
| 0 | 2026-04-28 ... | WRITE | numFiles=6 |
| 1 | 2026-04-28 ... | WRITE (append) | numAddedRecords=3 |
| 2 | 2026-04-28 ... | UPDATE | numUpdatedRows=65 |
| 3 | 2026-04-28 ... | DELETE | numDeletedRows=12 |
| 4 | 2026-04-28 ... | MERGE | numTargetRowsUpdated=2, numTargetRowsInserted=1 |

---

## :material-broom: Manutenção

### `OPTIMIZE` — compaction

Ao longo do tempo, muitos `INSERT` pequenos geram muitos arquivos pequenos (problema clássico de "small files"). `OPTIMIZE` compacta:

```sql
OPTIMIZE delta.`/workspace/data/delta/fact_pokemon`
```

Combinado com `ZORDER BY <coluna>`, reorganiza fisicamente para *data skipping* eficiente em queries que filtram por essa coluna.

### `VACUUM` — GC físico

`UPDATE`, `DELETE` e `OPTIMIZE` deixam **arquivos antigos no disco** (necessários para time travel). `VACUUM` remove arquivos mais antigos que a janela de retenção:

```sql
VACUUM delta.`/workspace/data/delta/fact_pokemon` RETAIN 168 HOURS  -- 7 dias (default)
```

!!! danger "Não rebaixe a retenção sem entender as consequências"
    Se `VACUUM ... RETAIN 0 HOURS` for executado e existir uma query Delta de longa duração lendo a tabela, a query **vai quebrar**. Por isso o Delta exige uma flag (`spark.databricks.delta.retentionDurationCheck.enabled=false`) para rodar com retenção menor que 168h. No notebook deste projeto fazemos isso **apenas para fins de demo**.

---

## :material-thumb-up-outline: Quando escolher Delta Lake?

- :material-check: Stack 100% **Spark / Databricks**.
- :material-check: Quer a **integração mais polida** com PySpark (`DeltaTable` API).
- :material-check: Precisa de **liquid clustering** ou **deletion vectors** (recursos Databricks-first).
- :material-check: Time já familiar com `OPTIMIZE / ZORDER`.

---

## :material-book-open-variant: Referências

- [Documentação Delta Lake](https://docs.delta.io/latest/index.html)
- [Delta Lake — releases](https://github.com/delta-io/delta/releases)
- [Quick Start (Jupyter)](https://delta.io/blog/delta-lake-jupyter-notebook/)
- [API `DeltaTable`](https://docs.delta.io/latest/api/python/index.html)
- [Notebook deste projeto: `01_delta_lake.ipynb`](https://github.com/lucascholzeh/spark-lakehouse-project/blob/main/notebooks/01_delta_lake.ipynb)
