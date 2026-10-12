-- Rule 3: forwarding ratio (ETH out to Binance 14 / ETH in), transactions table only.
-- Ran 4 Oct 2026, ~3.70 GB. Result: 54% of senders showed no inbound ETH; median ratio 0.99999 where measurable.
WITH senders AS (
  SELECT DISTINCT from_address AS addr
  FROM `bigquery-public-data.crypto_ethereum.transactions`
  WHERE to_address = LOWER('0x28C6c06298d514Db089934071355E5743bf21d60')
    AND block_timestamp >= '2026-09-01' AND block_timestamp < '2026-09-08'
    AND value >= 1e15
    AND receipt_status = 1
),

inbound AS (
  -- ETH arriving at each sender. Starts a week early so deposits made
  -- just before the window still count.
  SELECT
    t.to_address AS addr,
    COUNT(*)                         AS in_tx,
    COUNT(DISTINCT t.from_address)   AS in_senders,
    SUM(t.value) / 1e18              AS eth_in,
    COUNTIF(t.from_address = LOWER('0x28C6c06298d514Db089934071355E5743bf21d60')) AS from_binance14
  FROM `bigquery-public-data.crypto_ethereum.transactions` t
  JOIN senders s ON t.to_address = s.addr
  WHERE t.block_timestamp >= '2026-08-25' AND t.block_timestamp < '2026-09-08'
    AND t.receipt_status = 1
    AND t.value > 0
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
  IFNULL(i.in_tx, 0)          AS in_tx,
  IFNULL(i.in_senders, 0)     AS in_senders,
  IFNULL(i.eth_in, 0)         AS eth_in,
  o.eth_to_b14,
  SAFE_DIVIDE(o.eth_to_b14, i.eth_in) AS forward_ratio,
  IFNULL(i.from_binance14, 0) AS from_binance14
FROM senders s
LEFT JOIN inbound  i ON s.addr = i.addr
LEFT JOIN outbound o ON s.addr = o.addr
ORDER BY forward_ratio
