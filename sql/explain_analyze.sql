-- ============================================
-- 📊 PostgreSQL Index Performance Benchmark
-- File: 05_explain_analyze.sql
-- Run inside psql:  \i /docker-entrypoint-initdb.d/05_explain_analyze.sql
-- ============================================

-- Clear the screen (psql-specific)
\! clear

\echo '============================================'
\echo '🧠  Indexing Performance Benchmark Started...'
\echo '============================================'

-- -------------------------------
-- 1️⃣ User Lookup by Email
-- -------------------------------
\echo '\n-- 🔍 Query 1: Find a user by email (users.email)'

EXPLAIN ANALYZE
SELECT * FROM users WHERE email = 'user50000@example.com';

-- -------------------------------
-- 2️⃣ Orders by User
-- -------------------------------
\echo '\n-- 📦 Query 2: Find all orders for a specific user_id'

EXPLAIN ANALYZE
SELECT * FROM orders WHERE user_id = 50000;

-- -------------------------------
-- 3️⃣ Recent Pending Orders
-- -------------------------------
\echo '\n-- ⏳ Query 3: Pending orders from the last 7 days'

EXPLAIN ANALYZE
SELECT * FROM orders
WHERE status = 'pending'
  AND created_at > NOW() - interval '7 days';

-- -------------------------------
-- 4️⃣ Sorted Orders for One User
-- -------------------------------
\echo '\n-- 🧾 Query 4: User’s recent orders (sorted by created_at DESC)'

EXPLAIN ANALYZE
SELECT * FROM orders
WHERE user_id = 50000
ORDER BY created_at DESC
LIMIT 10;

-- -------------------------------
-- 5️⃣ Optional Custom Test
-- -------------------------------
\echo '\n-- 🧩 Query 5: Test on non-indexed text column (users.notes)'

EXPLAIN ANALYZE
SELECT * FROM users WHERE notes = 'abc123';

\echo '\n✅  Benchmark Complete!'
\echo 'Compare Execution Time between index and no index.'
\echo 'Look for: Seq Scan → Index Scan and time reductions.'
