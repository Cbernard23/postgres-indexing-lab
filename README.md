# 🧠 PostgreSQL Indexing Lab

A hands-on lab project to learn and demonstrate how **database indexes** improve query performance in PostgreSQL.

---

## 🚀 Project Overview

This project simulates a real-world database (`users` + `orders`) with over **1 million records**, then compares performance of queries **before and after** indexing.

You’ll learn:

- What database indexes are and how they work
- How to create different types of indexes (B-tree, partial, composite)
- How to use `EXPLAIN ANALYZE` to measure query performance
- How to detect and remove unused indexes
- How to organize reproducible experiments using Docker + SQL scripts

---

## 🧰 Tech Stack

| Tool                              | Purpose                             |
| --------------------------------- | ----------------------------------- |
| **PostgreSQL 16**                 | Database engine                     |
| **Docker Compose**                | Easy local setup                    |
| **psql CLI**                      | Run SQL commands interactively      |
| **Optional:** TablePlus / pgAdmin | GUI to visualize tables and indexes |

---

## 📁 Project Structure

```

postgres-indexing-lab/
├─ sql/
│  ├─ schema.sql              # Table definitions
│  ├─ insert_data.sql         # Generate fake users and orders
│  ├─ queries.sql             # Example queries to test
│  ├─ indexes.sql             # Index creation statements
│  └─ explain_analyze.sql     # Benchmark queries with EXPLAIN ANALYZE
├─ docker-compose.yml         # PostgreSQL container setup
├─ README.md                  # Documentation (this file)
├─ run_benchmark.sh           # Automates the before/after benchmark run
├─ before_index.csv           # Runner output (Execution Time before indexes)
└─ after_index.csv            # Runner output (Execution Time after indexes)

```

---

## ⚙️ Setup Instructions

### 1️⃣ Clone the repo

```bash
git clone https://github.com/cbernard23/postgres-indexing-lab.git
cd postgres-indexing-lab
```

### 2️⃣ Start PostgreSQL via Docker

```bash
docker-compose up -d
```

This launches a PostgreSQL 16 database named `indexing_lab`:

- Host: `localhost`
- Port: `5432`
- User: `chris`
- Password: `password`

Verify it’s running:

```bash
docker ps
```

---

## 🧑‍💻 Connecting to the Database

Run the PostgreSQL shell inside the container:

```bash
docker exec -it pg_indexing_lab psql -U chris -d indexing_lab
```

You’ll see a prompt like:

```
indexing_lab=#
```

From here, you can:

```sql
\dt                -- list tables
\q                 -- quit psql
```

---

## 🧩 Running the SQL Files

### Option 1: Inside `psql` (interactive)

Once in the psql shell, run:

```sql
\i /docker-entrypoint-initdb.d/schema.sql
\i /docker-entrypoint-initdb.d/insert_data.sql
\i /docker-entrypoint-initdb.d/queries.sql
\i /docker-entrypoint-initdb.d/indexes.sql
```

### Option 2: From Mac terminal (non-interactive)

You can run all scripts directly:

```bash
docker exec -i pg_indexing_lab psql -U chris -d indexing_lab -f /docker-entrypoint-initdb.d/schema.sql
docker exec -i pg_indexing_lab psql -U chris -d indexing_lab -f /docker-entrypoint-initdb.d/insert_data.sql
```

---

## 🧮 Running Performance Tests

### Automated runner (recommended)

```bash
chmod +x run_benchmark.sh   # only needed once
./run_benchmark.sh
```

The runner:

- ensures the `pg_indexing_lab` container is up (starting it if needed)
- truncates and reloads the seed data
- drops any non-Postgres-managed indexes (`_pkey` / `_key` stay in place)
- captures `EXPLAIN ANALYZE` timing before and after applying the lab indexes
- writes the raw timings to `before_index.csv` and `after_index.csv`
- prints a side-by-side summary so you can spot the speedups quickly

Sample summary:

```text
Query#   Before(ms)      After(ms)       Speedup
1        0.188           0.160           x1
2        46.395          0.264           x176
3        38.516          28.814          x1
4        23.266          0.009           x2585
5        4.039           0.028           x144
```

| #   | Query                              | Before (ms) | After (ms) | Notes                                                                    |
| --- | ---------------------------------- | ----------- | ---------- | ------------------------------------------------------------------------ |
| 1   | Find user by email                 | 0.188       | 0.160      | Already covered by PostgreSQL’s automatic `users_email_key` unique index |
| 2   | Orders by user_id                  | 46.395      | 0.264      | Benefit from `idx_orders_user_id`                                        |
| 3   | Pending orders (last 7 days)       | 38.516      | 28.814     | Partial index `idx_orders_pending_recent` keeps scans tighter            |
| 4   | User’s recent orders (sorted DESC) | 23.266      | 0.009      | Composite index `idx_orders_user_created_at` avoids sort                 |
| 5   | Lookup by notes                    | 4.039       | 0.028      | `idx_users_notes` turns the seq scan into an index scan                  |

> PostgreSQL automatically creates indexes for every `PRIMARY KEY` and `UNIQUE` constraint. Because the runner leaves those intact, you’ll see two rows where the before/after numbers (and the `Speedup` column) are essentially the same—those queries are already using the auto-built indexes by design.

### Manual exploration

If you prefer to poke around manually, run `EXPLAIN ANALYZE` inside psql:

```sql
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'user50000@example.com';
```

Repeat the query before and after executing `sql/indexes.sql` to compare the plans.

---

## ⚡ Index Types Used

| Index                        | Purpose                                  |
| ---------------------------- | ---------------------------------------- |
| `idx_users_email`            | Fast user lookup by email                |
| `idx_orders_user_id`         | Optimize `WHERE user_id = ?`             |
| `idx_orders_user_created_at` | Optimize combined filter + order queries |
| `idx_orders_pending_recent`  | Partial index for recent pending orders  |

---

## 🧭 Inspecting Index Usage

Check how often each index is used:

```sql
SELECT indexrelname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

Check if any are never used:

```sql
SELECT * FROM pg_stat_user_indexes WHERE idx_scan = 0;
```

Rebuild bloated indexes:

```sql
REINDEX TABLE orders;
```

---

## 🧰 Maintenance & Cleanup

To rebuild everything from scratch:

```bash
docker-compose down -v
docker-compose up -d
```

This resets both the container and the data volume.

---

## 📘 Key Takeaways

1. **Indexes speed up reads** but **slow down writes** slightly.
2. Use indexes on columns frequently used in `WHERE`, `JOIN`, or `ORDER BY`.
3. Avoid indexing columns with low selectivity (like boolean flags).
4. Use `EXPLAIN ANALYZE` to _measure_, not guess.
5. Keep your indexes tidy — remove unused ones.

---

## 🧠 Optional Enhancements

- Add a Python or Node.js script to generate realistic data using Faker.
- Visualize query plans using `pgAdmin`’s Graphical EXPLAIN.
- Add benchmark scripts to auto-record timings.
- Include `pg_stat_statements` to track query frequency.

---

## 🏁 Example Workflow Summary

```bash
# Start DB
docker-compose up -d

# Open SQL shell
docker exec -it pg_indexing_lab psql -U chris -d indexing_lab

# Load schema and data
\i /docker-entrypoint-initdb.d/schema.sql
\i /docker-entrypoint-initdb.d/insert_data.sql

# Run queries before indexes
\i /docker-entrypoint-initdb.d/queries.sql

# Add indexes
\i /docker-entrypoint-initdb.d/indexes.sql

# Run EXPLAIN ANALYZE
\i /docker-entrypoint-initdb.d/explain_analyze.sql

# Compare results
./run_benchmark.sh              # Automated before/after benchmark + CSV output
```

My Results:

I added a notes field to test with:

```sql
ALTER TABLE users ADD COLUMN notes TEXT;
```

Then I ran to see the query speed:

```sql
EXPLAIN ANALYZE SELECT * FROM users WHERE notes = 'abc123';
```

Which produced the following:

Seq Scan on users (cost=0.00..3613.00 rows=1 width=76) (actual time=11.492..11.492 rows=0 loops=1)
Filter: (notes = 'abc123'::text)
Rows Removed by Filter: 100000
Planning Time: 0.314 ms
Execution Time: 11.515 ms
(5 rows)

Then I added the index on the notes field with

```sql
CREATE INDEX idx_users_notes ON users (notes);
```

Now the new speed results are:

Index Scan using idx_users_notes on users (cost=0.42..8.44 rows=1 width=76) (actual time=0.043..0.044 rows=0 loops=1)
Index Cond: (notes = 'abc123'::text)
Planning Time: 0.245 ms
Execution Time: 0.056 ms
(4 rows)

So this index took the query time from 11.515ms down to 0.056ms which means the query with the index is 205x faster

---

## 🧾 License

MIT — free for educational and portfolio use.

---

## ✨ Author

**Chris Bernard**
👩‍💻 Senior Software Engineer

```
github.com/cbernard23
```
