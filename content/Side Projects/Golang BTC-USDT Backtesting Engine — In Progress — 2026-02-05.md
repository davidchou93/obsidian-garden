---

---
**Task ID: **TASK-20260205-001

**Started: **2026-02-05T22:45:00+08:00

**Status: **In Progress

---

## Original Request

Create a Golang Project to allow backtesting BTC/USDT trading strategies. The trading logic should be pluggable (user writes their own). Use Binance API for data. For testing, use BTC/USDT 1d history within 3 years. The project should output performance metrics.

---

## Sequence Log

### SEQ-001 — Task Initiated

`Timestamp: 2026-02-05T22:45:00+08:00`

Action: Received task from David, beginning workflow

### SEQ-002 — Questions Generated

`Timestamp: 2026-02-05T22:46:00+08:00`

Agent: Questioner | 8 clarifying questions generated

### SEQ-003 — Answers Provided

`Timestamp: 2026-02-05T22:49:00+08:00`

David confirmed:

- 6. Output: CLI tables
- 7. Template: SMA crossover
- 8. Data caching: CSV

Questions 1-5 deferred to Thinker for research

### SEQ-004 — Thinker Research (In Progress)

`Timestamp: 2026-02-05T22:52:00+08:00`

Agent: Thinker researching answers for Q1-5

### SEQ-005 — Thinker Proposed Answers

`Timestamp: 2026-02-05T22:55:00+08:00`

Agent: Thinker | Research complete on Q1-5

Status: Awaiting David confirmation

### Q1: Performance Metrics

- Tier 1 (default): Total Return, CAGR, Sharpe Ratio, Max Drawdown, Win Rate, Profit Factor
- Tier 2 (extended flag): Sortino Ratio, Calmar Ratio, Beta vs BTC, Average Trade Return

### Q2: Strategy Interface

```go
type Strategy interface {
    Init(symbol string, broker Broker) error
    Next(data Data) error
    Name() string
}
```

### Q3: Order Types

- Market orders: Execute at next bar Open
- Limit/Stop: Check against bar High/Low range
- No partial fills for v1 (simpler, BTC/USDT daily is liquid)

### Q4: Fees & Slippage

- Fee: 0.1% per trade (Binance VIP 0 spot fee)
- Slippage: 0.05% (realistic for BTC daily)
- Both configurable via CLI flags

### Q5: Initial Capital & Sizing

- Default capital: $10,000 USDT
- Sizing: Strategy-controlled with optional helpers
- Helpers: FixedSize(), FixedPercentInvest(), FixedPercentRisk()

---

**Next: Await David confirmation → Spawn Planner → Create execution plan**