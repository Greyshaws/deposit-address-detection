-- Top 20 senders by ETH volume, checked manually on Etherscan. Ran 4 Oct 2026, ~2.5 MB.
-- Replace `your-project-id` with your own Google Cloud project ID before running.
-- Result: 18 labeled Binance Deposit, 1 Binance internal wallet (true negative), 1 unlabeled.
SELECT addr, label, ROUND(eth_to_b14, 1) AS eth_to_b14, out_tx, n_destinations, ROUND(balance_now, 4) AS balance_now
FROM `your-project-id.deposit_detector.mission2_labels`
ORDER BY eth_to_b14 DESC
LIMIT 20
