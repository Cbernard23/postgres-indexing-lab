-- Generate 100,000 users
INSERT INTO users (name, email)
SELECT
  'User ' || i,
  'user' || i || '@example.com'
FROM generate_series(1, 100000) AS s(i);

-- Generate 1,000,000 orders
INSERT INTO orders (user_id, amount, status, created_at)
SELECT
  (floor(random() * 100000 + 1)),
  (random() * 1000)::numeric(10,2),
  CASE
    WHEN random() < 0.8 THEN 'completed'
    WHEN random() < 0.9 THEN 'pending'
    ELSE 'canceled'
  END,
  NOW() - (random() * interval '365 days')
FROM generate_series(1, 1000000);

