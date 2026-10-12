-- Mission 1: all plain-ETH senders to Binance 14. Ran 4 Oct 2026, ~1.78 GB.
-- Result: 25,118 senders, 34,799 txs, ~729,000 ETH.
-- Note: BETWEEN ends at midnight on 8 Sep, so the window is effectively 1-7 Sep.
SELECT from_address, COUNT(*) AS n_tx, SUM(value)/1e18 AS eth_sent
FROM `bigquery-public-data.crypto_ethereum.transactions`
WHERE to_address = LOWER('0x28C6c06298d514Db089934071355E5743bf21d60')
  AND block_timestamp BETWEEN '2026-09-01' AND '2026-09-08'
GROUP BY from_address
ORDER BY n_tx DESC
