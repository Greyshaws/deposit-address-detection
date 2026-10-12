-- Profile of the 0.138-0.143 ETH cluster by hour. Ran 4 Oct 2026, ~17.9 GB.
-- Result: 13,428 transfers from 13,428 addresses in one hour (6 Sep, 16:00 UTC); median nonce 1.
-- Cost lesson: selecting the `input` column made this query expensive. BigQuery bills per column scanned.
WITH cluster AS (
  SELECT from_address, value, block_timestamp, nonce, gas_price, input
  FROM `bigquery-public-data.crypto_ethereum.transactions`
  WHERE to_address = LOWER('0x28C6c06298d514Db089934071355E5743bf21d60')
    AND block_timestamp >= '2026-09-01' AND block_timestamp < '2026-09-08'
    AND receipt_status = 1
    AND value BETWEEN 1.38e17 AND 1.43e17
)
SELECT
  DATE(block_timestamp)              AS day,
  EXTRACT(HOUR FROM block_timestamp) AS hour,
  COUNT(*)                           AS n_tx,
  COUNT(DISTINCT from_address)       AS n_addr,
  MIN(nonce) AS min_nonce, MAX(nonce) AS max_nonce,
  APPROX_QUANTILES(nonce, 2)[OFFSET(1)] AS median_nonce,
  COUNT(DISTINCT gas_price)          AS distinct_gas_prices,
  COUNTIF(input != '0x')             AS with_data
FROM cluster
GROUP BY day, hour
ORDER BY day, hour
