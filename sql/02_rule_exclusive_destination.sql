-- Rule 2: does each (dust-filtered) sender send ETH anywhere other than Binance 14?
-- Ran 4 Oct 2026, ~1.89 GB. Result: 24,930 senders; 0 sent ETH elsewhere.
WITH senders AS (
  -- Step 1: everyone who sent real ETH (not dust) to Binance 14 in the window
  SELECT DISTINCT from_address
  FROM `bigquery-public-data.crypto_ethereum.transactions`
  WHERE to_address = LOWER('0x28C6c06298d514Db089934071355E5743bf21d60')
    AND block_timestamp >= '2026-09-01' AND block_timestamp < '2026-09-08'
    AND value >= 1e15          -- 0.001 ETH minimum: drops the 1-gwei poisoners
    AND receipt_status = 1     -- successful transactions only
)

-- Step 2: everything those senders sent, anywhere, in the same window
SELECT
  t.from_address,
  COUNT(*)                                     AS out_tx,
  COUNTIF(t.to_address = LOWER('0x28C6c06298d514Db089934071355E5743bf21d60'))  AS to_binance14,
  COUNT(DISTINCT t.to_address)                 AS n_destinations,
  SUM(IF(t.to_address = LOWER('0x28C6c06298d514Db089934071355E5743bf21d60'), t.value, 0)) / 1e18 AS eth_to_binance14,
  SUM(IF(t.to_address != LOWER('0x28C6c06298d514Db089934071355E5743bf21d60'), t.value, 0)) / 1e18 AS eth_elsewhere
FROM `bigquery-public-data.crypto_ethereum.transactions` t
JOIN senders s ON t.from_address = s.from_address
WHERE t.block_timestamp >= '2026-09-01' AND t.block_timestamp < '2026-09-08'
  AND t.receipt_status = 1
GROUP BY t.from_address
ORDER BY n_destinations DESC, eth_elsewhere DESC
