-- Index on email (unique lookup)
CREATE INDEX idx_users_email ON users (email);

-- Index on user_id for orders
CREATE INDEX idx_orders_user_id ON orders (user_id);

-- Composite index for user_id + created_at (filter and order)
CREATE INDEX idx_orders_user_created_at ON orders (user_id, created_at DESC);

-- Partial index for pending orders
CREATE INDEX idx_orders_pending_recent
  ON orders (created_at)
  WHERE status = 'pending';

