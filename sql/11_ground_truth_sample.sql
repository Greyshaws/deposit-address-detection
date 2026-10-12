-- Deterministic random sample: 50 addresses per label for manual Etherscan verification.
-- Replace `your-project-id` with your own Google Cloud project ID before running.
-- Ran 4 Oct 2026, ~2 MB.
SELECT label, addr, ROUND(eth_to_b14, 4) AS eth_to_b14, ROUND(balance_now, 6) AS balance_now
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY label ORDER BY FARM_FINGERPRINT(addr)) AS rn
  FROM `your-project-id.deposit_detector.mission2_labels`
)
WHERE rn <= 50
ORDER BY label, rn
