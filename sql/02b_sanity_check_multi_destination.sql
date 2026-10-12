-- Sanity check on the busiest multi-destination sender (161 destinations).
-- Ran 4 Oct 2026, ~1.78 GB. Result: every destination except Binance 14 was an ERC-20 token contract with 0 ETH.
SELECT to_address, COUNT(*) AS n, SUM(value)/1e18 AS eth
FROM `bigquery-public-data.crypto_ethereum.transactions`
WHERE from_address = '0x06fd4ba7973a0d39a91734bbc35bc2bcaa99e3b0'
  AND block_timestamp >= '2026-09-01' AND block_timestamp < '2026-09-08'
GROUP BY to_address
ORDER BY n DESC
LIMIT 20
