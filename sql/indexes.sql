CREATE INDEX IF NOT EXISTS idx_users_email ON users (email);

CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders (user_id);

CREATE INDEX IF NOT EXISTS idx_orders_user_created_at ON orders (user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_orders_pending_recent
  ON orders (created_at)
  WHERE status = 'pending';
