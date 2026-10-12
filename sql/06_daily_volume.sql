-- Daily transfers to Binance 14. Ran 4 Oct 2026, ~1.41 GB.
-- Result: ~2,500-4,000/day, with spikes on Sun 30 Aug (16,673) and Sun 6 Sep (16,192).
SELECT DATE(block_timestamp) AS day, COUNT(*) AS n_tx
FROM `bigquery-public-data.crypto_ethereum.transactions`
WHERE to_address = LOWER('0x28C6c06298d514Db089934071355E5743bf21d60')
  AND block_timestamp >= '2026-08-25' AND block_timestamp < '2026-09-08'
GROUP BY day
ORDER BY day
