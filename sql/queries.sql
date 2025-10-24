-- Find one user by email
SELECT * FROM users WHERE email = 'user9999@example.com';

-- Find all orders for a specific user
SELECT * FROM orders WHERE user_id = 9999;

-- Find pending orders in the last 7 days
SELECT * FROM orders WHERE status = 'pending' AND created_at > NOW() - interval '7 days';

