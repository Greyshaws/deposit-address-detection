-- Per-sender labeling table. Ran 4 Oct 2026, ~22.3 GB.
-- Result: deposit 21,372 (209,861.6 ETH); candidate 3,558 (519,096.0 ETH); likely_not 0.
-- Totals sum to 728,957.6 ETH, matching Mission 1, so no sender was lost or double-counted.
-- Replace `your-project-id` with your own Google Cloud project ID before running.
CREATE SCHEMA IF NOT EXISTS `your-project-id.deposit_detector`;

CREATE OR REPLACE TABLE `your-project-id.deposit_detector.mission2_labels` AS
WITH senders AS (
  SELECT DISTINCT from_address AS addr
  FROM `bigquery-public-data.crypto_ethereum.transactions`
  WHERE to_address = '0x28c6c06298d514db089934071355e5743bf21d60'
    AND block_timestamp >= '2026-09-01' AND block_timestamp < '2026-09-08'
    AND value >= 1e15 AND receipt_status = 1
),
outbound AS (
  SELECT t.from_address AS addr,
         COUNT(*) AS out_tx,
         COUNT(DISTINCT t.to_address) AS n_destinations,
         SUM(IF(t.to_address = '0x28c6c06298d514db089934071355e5743bf21d60', t.value, 0)) / 1e18 AS eth_to_b14,
         SUM(IF(t.to_address != '0x28c6c06298d514db089934071355e5743bf21d60', t.value, 0)) / 1e18 AS eth_elsewhere
  FROM `bigquery-public-data.crypto_ethereum.transactions` t
  JOIN senders s ON t.from_address = s.addr
  WHERE t.block_timestamp >= '2026-09-01' AND t.block_timestamp < '2026-09-08'
    AND t.receipt_status = 1
  GROUP BY t.from_address
)
SELECT
  s.addr, o.out_tx, o.n_destinations, o.eth_to_b14, o.eth_elsewhere,
  b.eth_balance / 1e18 AS balance_now,
  (IFNULL(o.eth_elsewhere, 0) = 0) AS rule2_only_b14,
  (b.eth_balance BETWEEN 1.9e15 AND 2.0e15) AS rule4_residual,
  CASE
    WHEN IFNULL(o.eth_elsewhere, 0) > 0 THEN 'likely_not'
    WHEN b.eth_balance BETWEEN 1.9e15 AND 2.0e15 THEN 'deposit'
    ELSE 'candidate'
  END AS label
FROM senders s
LEFT JOIN outbound o ON o.addr = s.addr
LEFT JOIN `bigquery-public-data.crypto_ethereum.balances` b ON b.address = s.addr;

SELECT label, COUNT(*) AS n_addr, ROUND(SUM(eth_to_b14), 1) AS eth_to_b14
FROM `your-project-id.deposit_detector.mission2_labels`
GROUP BY label
ORDER BY n_addr DESC;
