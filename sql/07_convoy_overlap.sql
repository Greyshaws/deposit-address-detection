-- Do the two Sunday batches share addresses? Ran 4 Oct 2026, ~564 MB.
-- Result: 15,843 senders on 30 Aug, 15,381 on 6 Sep, only 242 on both.
WITH burst AS (
  SELECT from_address, DATE(block_timestamp) AS day, value
  FROM `bigquery-public-data.crypto_ethereum.transactions`
  WHERE to_address = LOWER('0x28C6c06298d514Db089934071355E5743bf21d60')
    AND receipt_status = 1
    AND (
      block_timestamp BETWEEN '2026-08-30 00:00:00' AND '2026-08-30 23:59:59'
      OR block_timestamp BETWEEN '2026-09-06 00:00:00' AND '2026-09-06 23:59:59'
    )
)
SELECT
  COUNT(DISTINCT IF(day = '2026-08-30', from_address, NULL)) AS addr_aug30,
  COUNT(DISTINCT IF(day = '2026-09-06', from_address, NULL)) AS addr_sep6,
  (SELECT COUNT(*) FROM (
     SELECT from_address FROM burst GROUP BY from_address
     HAVING COUNT(DISTINCT day) = 2)) AS addr_both_days,
  APPROX_QUANTILES(IF(day = '2026-08-30', value, NULL), 4) AS aug30_value_quartiles,
  (SELECT STRING_AGG(from_address, ', ' LIMIT 5)
   FROM (SELECT DISTINCT from_address FROM burst WHERE day = '2026-09-06')) AS sample_sep6
FROM burst
