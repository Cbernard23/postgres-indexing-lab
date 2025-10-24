#!/bin/bash
# =============================================
# 🚀 PostgreSQL Index Benchmark Runner
# =============================================

DB_USER="chris"
DB_NAME="indexing_lab"
CONTAINER="pg_indexing_lab"
SQL_DIR="/docker-entrypoint-initdb.d"

echo "============================================"
echo "🧠 PostgreSQL Index Performance Benchmark"
echo "============================================"
echo

# Ensure container is running
if ! docker ps | grep -q "$CONTAINER"; then
  echo "⚠️  Starting PostgreSQL container..."
  docker-compose up -d
  sleep 5
fi

# Step 1 — Reset tables and reload data
echo "🧹 Resetting database..."
docker exec -i $CONTAINER psql -U $DB_USER -d $DB_NAME <<SQL
TRUNCATE orders RESTART IDENTITY CASCADE;
TRUNCATE users RESTART IDENTITY CASCADE;
\i $SQL_DIR/insert_data.sql
SQL

echo "✅ Data reloaded."
echo

echo "🧹 Dropping all non-primary indexes..."
docker exec -i $CONTAINER psql -U $DB_USER -d $DB_NAME <<'SQL'
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT indexrelid::regclass AS idx_name
        FROM pg_stat_user_indexes
        WHERE indexrelname NOT LIKE '%pkey%'
          AND indexrelname NOT LIKE '%_key%'
    LOOP
        EXECUTE format('DROP INDEX IF EXISTS %I;', r.idx_name);
    END LOOP;
END $$;
SQL
echo "✅ Indexes dropped."
echo

# Step 2 — Run benchmarks BEFORE indexing
echo "📊 Running queries BEFORE indexes..."
docker exec -i $CONTAINER psql -U $DB_USER -d $DB_NAME -f $SQL_DIR/explain_analyze.sql \
  | grep "Execution Time" | awk 'NR % 2 == 0' > before_index.csv
echo "✅ Results saved to before_index.csv"
echo

# Step 3 — Apply indexes
echo "⚙️ Creating indexes..."
docker exec -i $CONTAINER psql -U $DB_USER -d $DB_NAME -f $SQL_DIR/indexes.sql
echo "✅ Indexes created."
echo

# Step 4 — Run benchmarks AFTER indexing
echo "📊 Running queries AFTER indexes..."
docker exec -i $CONTAINER psql -U $DB_USER -d $DB_NAME -f $SQL_DIR/explain_analyze.sql \
  | grep "Execution Time" | awk 'NR % 2 == 0' > after_index.csv
echo "✅ Results saved to after_index.csv"
echo

# Step 5 — Print summary
echo "============================================"
echo "📈 Comparing Execution Times"
echo "============================================"

awk '
/Execution Time/ {
  # Extract numeric part of "Execution Time: 12.345 ms"
  n = split($0, parts, " ")
  time = parts[3]
  gsub("ms", "", time)
  if (time != "" && time + 0 > 0) {
    if (FNR == NR) {
      before[++bcount] = time
    } else {
      after[++acount] = time
    }
  }
}
END {
  printf "%-8s %-15s %-15s %-10s\n", "Query#", "Before(ms)", "After(ms)", "Speedup"
  n = (bcount < acount ? bcount : acount)
  for (i = 1; i <= n; i++) {
    if (after[i] + 0 > 0 && before[i] + 0 > 0) {
      speedup = before[i] / after[i]
      printf "%-8d %-15.3f %-15.3f x%.0f\n", i, before[i], after[i], speedup
    } else {
      printf "%-8d %-15s %-15s %-10s\n", i, before[i], after[i], "N/A"
    }
  }
}' before_index.csv after_index.csv


echo
echo "✅ Benchmark complete!"
echo "Check before_index.csv and after_index.csv for raw EXPLAIN output."
echo

