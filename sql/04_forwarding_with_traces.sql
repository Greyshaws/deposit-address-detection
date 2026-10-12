-- Rule 3 again, with inbound ETH from traces (includes internal transactions).
-- Ran 4 Oct 2026, ~37.95 GB (about 10x the transactions version).
-- Result: resolved ~500 blank addresses; internal transfers were ~30% of inbound ETH by value.
WITH senders AS (
  SELECT DISTINCT from_address AS addr
  FROM `bigquery-public-data.crypto_ethereum.transactions`
  WHERE to_address = LOWER('0x28C6c06298d514Db089934071355E5743bf21d60')
    AND block_timestamp >= '2026-09-01' AND block_timestamp < '2026-09-08'
    AND value >= 1e15
    AND receipt_status = 1
),

inbound AS (
  -- ALL ETH arriving, from traces. Traces include both normal transfers
  -- (top-level calls) and internal ones, so nothing is counted twice.
  SELECT
    t.to_address AS addr,
    COUNT(*)                         AS in_transfers,
    COUNT(DISTINCT t.from_address)   AS in_senders,
    SUM(t.value) / 1e18              AS eth_in_total,
    SUM(IF(IFNULL(t.trace_address, '') != '', t.value, 0)) / 1e18 AS eth_in_internal,
    COUNTIF(t.from_address = LOWER('0x28C6c06298d514Db089934071355E5743bf21d60')) AS from_binance14
  FROM `bigquery-public-data.crypto_ethereum.traces` t
  JOIN senders s ON t.to_address = s.addr
  WHERE t.block_timestamp >= '2026-08-25' AND t.block_timestamp < '2026-09-08'
    AND t.status = 1
    AND t.value > 0
    AND t.trace_type = 'call'
    AND IFNULL(t.call_type, 'call') = 'call'   -- delegatecall/staticcall move no ETH
  GROUP BY t.to_address
),

outbound AS (
  SELECT
    t.from_address AS addr,
    SUM(t.value) / 1e18 AS eth_to_b14
  FROM `bigquery-public-data.crypto_ethereum.transactions` t
  JOIN senders s ON t.from_address = s.addr
  WHERE t.to_address = LOWER('0x28C6c06298d514Db089934071355E5743bf21d60')
    AND t.block_timestamp >= '2026-08-25' AND t.block_timestamp < '2026-09-08'
    AND t.receipt_status = 1
  GROUP BY t.from_address
)

SELECT
  s.addr,
  IFNULL(i.in_transfers, 0)     AS in_transfers,
  IFNULL(i.in_senders, 0)       AS in_senders,
  IFNULL(i.eth_in_total, 0)     AS eth_in_total,
  IFNULL(i.eth_in_internal, 0)  AS eth_in_internal,
  o.eth_to_b14,
  SAFE_DIVIDE(o.eth_to_b14, i.eth_in_total) AS forward_ratio,
  IFNULL(i.from_binance14, 0)   AS from_binance14
FROM senders s
LEFT JOIN inbound  i ON s.addr = i.addr
LEFT JOIN outbound o ON s.addr = o.addr
ORDER BY forward_ratio
