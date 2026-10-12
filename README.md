# Exchange Deposit-Address Detection on Ethereum

Detecting Binance deposit addresses from public Ethereum data in Google BigQuery, and measuring the heuristic's precision and coverage honestly.

**Data:** `bigquery-public-data.crypto_ethereum` (`transactions`, `traces`, `balances`)
**Target:** Binance 14 hot wallet, `0x28c6c06298d514db089934071355e5743bf21d60`
**Window:** 1–7 Sep 2026 (inbound lookback from 25 Aug)

## Background

Exchanges give each customer a unique deposit address. Funds sent there are swept into a hot wallet. Every address that sweeps into a hot wallet is therefore a candidate deposit address. The question is how reliably simple onchain rules separate real deposit addresses from everything else that sends to the same hot wallet.

## Results at a glance

| Metric | Value |
|---|---|
| ETH senders to Binance 14 in window | 25,118 senders, 34,799 txs, ~728,958 ETH |
| After dust filter (≥ 0.001 ETH) | 24,930 senders |
| Sent ETH anywhere other than Binance 14 | 0 |
| Precision of final rule (random sample, n = 100) | 88% lower bound (95% CI 80–93%), up to 100% if unlabeled addresses are deposits |
| Coverage of dust-filtered senders | 100% |
| Largest precision leak found | Binance internal wallet, ~8% of ETH volume |

## Method

| Step | File | What it does |
|---|---|---|
| 0 | `sql/00_freshness.sql` | Confirms the dataset is current |
| 1 | `sql/01_senders.sql` | All plain-ETH senders to the hot wallet |
| 2 | `sql/02_rule_exclusive_destination.sql` | Dust filter; checks whether senders send ETH anywhere else |
| 2b | `sql/02b_sanity_check_multi_destination.sql` | Inspects the sender with the most destinations |
| 3 | `sql/03_rule_forwarding_ratio.sql` | Outbound-to-inbound ETH ratio per sender (transactions only) |
| 4 | `sql/04_forwarding_with_traces.sql` | Same, with inbound ETH from internal transactions (`traces`) |
| 5 | `sql/05_cluster_profile.sql` | Hourly profile of the near-identical-amount cluster |
| 6 | `sql/06_daily_volume.sql` | Daily transfer counts, which revealed the Sunday batches |
| 7 | `sql/07_convoy_overlap.sql` | Address overlap between the two Sunday batches |
| 8 | `sql/08_burst_sample.sql` | Targeted sample from the burst hour |
| 9 | `sql/09_residual_balance.sql` | Buckets senders by current balance |
| 10 | `sql/10_labels_table.sql` | Builds the per-sender labeling table, with a consistency check |
| 11 | `sql/11_ground_truth_sample.sql` | Deterministic random sample for manual verification |
| 12 | `sql/12_top_senders.sql` | Top 20 senders by volume for manual verification |

These are the exact queries run on 4 October 2026. Each file notes its bytes processed and result. Re-running today may give slightly different numbers, because `balances` reflects current state.

Ground truth: 100 random addresses (50 per label stratum) plus the top 20 senders by volume, checked against Etherscan name tags and "Funded By". Precision is weighted back to the population with 95% Wilson intervals. Unlabeled addresses are scored both ways, because Etherscan labels are incomplete.

## Findings

**1. Address poisoning appears among the top senders.** Two of the five most frequent senders were poisoning addresses that sent 1 gwei every few minutes. Their vanity prefix and suffix (`0x93c9…4dd1`) imitate a heavily used, labeled Binance deposit address. A dust filter removes them. Without it, any frequency-based rule would rank them as heavy depositors.

**2. Destination counts mislead on Ethereum.** ERC-20 transfers are addressed to the token contract, not the recipient. One sender appeared to have 161 destinations, but every one was a token contract and all of its ETH went to Binance 14. Rules should be tested on ETH value.

**3. A suspected sybil cluster was Binance's own maintenance.** About 13,400 addresses sent near-identical amounts (0.138–0.143 ETH) to Binance 14 within one hour on Sunday 6 Sep, and a similar batch arrived the previous Sunday. The initial hypothesis was a bot farm. A targeted sample showed the addresses were labeled Binance deposit addresses that had been dormant for 1.5+ years, swept in weekly batches. That initial hypothesis was wrong, and these addresses are true positives.

- Nonce counts sends, not wallet age. A 20-month-old dormant address has nonce 0.
- A short inbound window misreads slow money. That's why no inbound ETH appeared for these addresses.

**4. Internal transactions matter, but less than expected.** Reading inbound ETH from `traces` added ~30% of inbound value and resolved ~500 addresses with no visible funding. It cost ~10× the bytes scanned.

**5. The residual-balance fingerprint is striking but not useful as a filter.** 85.7% of senders hold 0.0019–0.0020 ETH, and many share a residual identical to 15 decimal places. However, ground truth showed addresses outside the band are labeled deposits at the same 88% rate. They are deposits caught mid-cycle. The rule cut coverage by 14% for no measurable precision gain, so it was dropped.

**6. Precision leaks by volume, not by count.** No non-deposit addresses appeared in the random sample. In the top 20 by volume, one was a Binance internal wallet that moved 60,000 ETH, about 8% of window volume. Count-based precision hides this, so both views should be reported.

**7. Funding source.** Being funded by "Binance: Deposit Funder 1" indicated a deposit in every labeled case. Being funded by another exchange (Coinbase, OKX, Bybit and others) is not a negative signal, because users withdraw straight into their Binance deposit address.

## Limitations

- One hot wallet, one week, ETH only. ERC-20 sweeps (`token_transfers`) are not covered.
- Balances are current, not as of the window's end.
- Etherscan labels are a third party's attribution and incomplete. There are few confirmed negatives.
- A reliable negative rule for exchange-internal wallets is still needed. Candidates: large round transfers, or regular inflows from hot wallets.

## Cost notes

BigQuery bills by columns scanned, not rows returned. Selecting the `input` column pushed one query (`05`) to ~17.9 GB. Byte counts are noted at the top of each file.
