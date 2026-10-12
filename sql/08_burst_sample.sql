-- Targeted sample from the 6 Sep 16:00 burst. Ran 4 Oct 2026, ~49 MB.
-- Result: all 10 in the same block; 7 of 10 had nonce 0. Etherscan checks showed dormant Binance deposit addresses.
SELECT from_address, nonce, value / 1e18 AS eth, block_timestamp
FROM `bigquery-public-data.crypto_ethereum.transactions`
WHERE to_address = LOWER('0x28C6c06298d514Db089934071355E5743bf21d60')
  AND receipt_status = 1
  AND block_timestamp >= '2026-09-06 16:00:00'
  AND block_timestamp <  '2026-09-06 17:00:00'
  AND value BETWEEN 1.38e17 AND 1.43e17
ORDER BY block_timestamp
LIMIT 10
