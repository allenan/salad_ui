SET lock_timeout = '5s';

CREATE INDEX CONCURRENTLY events_account_inserted_idx
  ON events (account_id, inserted_at DESC)
  WHERE deleted_at IS NULL;
