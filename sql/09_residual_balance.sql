-- Rule 4: bucket senders by current ETH balance. Ran 4 Oct 2026, ~22.3 GB.
-- Result: 85.7% in the 0.0019-0.0020 ETH band; 459 at exactly 0.001993776772955 ETH.
-- Caveat: balances are current, not as of the window end.
WITH senders AS (
  SELECT DISTINCT from_address AS addr
  FROM `bigquery-public-data.crypto_ethereum.transactions`
  WHERE to_address = '0x28c6c06298d514db089934071355e5743bf21d60'
    AND block_timestamp >= '2026-09-01' AND block_timestamp < '2026-09-08'
    AND value >= 1e15 AND receipt_status = 1
)
SELECT
  CASE
    WHEN b.eth_balance IS NULL THEN 'a_no_balance_row'
    WHEN b.eth_balance = 1993776772955000 THEN 'b_exact_residual'
    WHEN b.eth_balance BETWEEN 1.9e15 AND 2.0e15 THEN 'c_near_residual_0.0019_0.0020'
    WHEN b.eth_balance < 1e15 THEN 'd_under_0.001'
    WHEN b.eth_balance < 1e16 THEN 'e_0.001_to_0.01_other'
    WHEN b.eth_balance < 1e17 THEN 'f_0.01_to_0.1'
    ELSE 'g_over_0.1'
  END AS bucket,
  COUNT(*) AS n_addr
FROM senders s
LEFT JOIN `bigquery-public-data.crypto_ethereum.balances` b ON b.address = s.addr
GROUP BY bucket
ORDER BY bucket
