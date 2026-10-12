-- Dataset freshness check. Ran 4 Oct 2026, ~2 MB.
-- (A first attempt used block_timestamp and failed: the blocks table calls it `timestamp`.)
SELECT MAX(timestamp)
FROM `bigquery-public-data.crypto_ethereum.blocks`
WHERE timestamp > '2026-09-01'
