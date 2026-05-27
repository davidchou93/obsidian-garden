---

---
## Part 1: Choosing Your AI Agent Stack

When generating code via AI agents, you have three main strategic paths:

### 1. Frameworks (Build Your Own)

Best for strict control and complex internal business logic.

- **LangGraph (LangChain):** Best for deterministic workflows (DAGs) and production apps.
- **CrewAI:** Best for role-based team simulations (e.g., "Manager" delegating to "dev").
- **Microsoft AutoGen:** Best for conversational multi-agent solving.

### 2. Autonomous Coding Agents (Open Source Tools)

Best for "AFK coding" where the agent acts as a junior engineer.

- **Cline (VS Code Extension):** Model-agnostic, runs in your IDE, edits files directly. **(Recommended)**
- **Aider:** Command-line tool, excellent git integration and context management.
- **OpenDevin:** A fully sandboxed environment (Docker based).

### 3. AI-Native IDEs

Best for immediate UI integration.

- **Cursor / Windsurf:** IDEs with built-in AI that understands your codebase.

---

## Part 2: The "Ralph Loop" Technique

The **Ralph Loop** is a technique to prevent AI "context rot" during long tasks.

- **Concept:** Instead of one long chat history, the agent restarts its context every cycle.
- **Memory:** It relies on the **file system** (reading code and logs) to know what to do next, rather than chat history.
- **Logic:**
    1. Agent reads the task.
    2. Agent writes code.
    3. External tool (Compiler/Backtester) verifies it.
    4. If it fails, the loop restarts with the error log as input.

---

## Part 3: The Bitcoin Trading Workflow

**Goal:** Create an autonomous researcher that tests strategies to find the best performer.

### The Stack

1. **The Brain:** **Cline** (running inside VS Code).
2. **The Simulator:** **Freqtrade** (Python-based crypto backtesting library).
3. **The Workflow:**
    - Cline writes a Python strategy.
    - Cline runs `freqtrade backtesting ...` in the terminal.
    - Cline reads the output (Profit/Drawdown).
    - Cline iterates/improves the code based on results.

### Setup Commands

```bash
# Install Freqtrade
pip install freqtrade

# Download Data (Required for the agent to test against)
freqtrade download-data --pairs BTC/USDT --timeframe 1h 4h --days 365

```

---

## Part 4: The System Prompt (For Cline)

Save this content into a file named `.clinerules` in your project root. This instructs the AI on how to behave autonomously.

```markdown
# Role
You are an expert Quantitative Algorithmic Trader specializing in Python and the Freqtrade framework. Your goal is to iteratively build, test, and refine a profitable Bitcoin trading strategy.

# The Mission
We are searching for a strategy for the BTC/USDT 1h timeframe that meets these criteria:
- Net Profit: > 15% (over the test period)
- Max Drawdown: < 10%
- Sharpe Ratio: > 1.0

# The Workflow (The Ralph Loop)
You will perform the following loop autonomously until the goal is met or I stop you:

1. **ANALYZE:** Read the previous backtest results (terminal output) to understand why it failed or performed poorly.
2. **MODIFY:** Edit the strategy file at `user_data/strategies/AI_Strategy.py`.
   - If indicators are missing, add them to `populate_indicators`.
   - Adjust `populate_entry_trend` and `populate_exit_trend` logic.
   - You act as a researcher: try Moving Averages, RSI, Bollinger Bands, or MACD.
3. **EXECUTE:** Run the backtest command in the terminal:
   `freqtrade backtesting --strategy AI_Strategy --timerange 20240101-20241231 -i 1h`
4. **VERIFY:** Check the output.
   - If CRASH: Fix the syntax error immediately.
   - If POOR PERFORMANCE: Tweak parameters (e.g., change RSI threshold from 30 to 25).
   - If SUCCESS: Save the file as `AI_Strategy_Winner.py` and stop.

# Technical Constraints (Freqtrade Standard)
- Inherit from `IStrategy`.
- Use `qtpylib` and `talib` for indicators.
- Indicators must be calculated in `populate_indicators` and assigned to `dataframe['indicator_name']`.
- Buy/Sell signals must be vectorised pandas operations (e.g., `(dataframe['rsi'] < 30)`).
- **Do NOT** use `.iloc` iteration for signals; use vectorised boolean logic.

# Communication
- Do NOT ask for permission to run the backtest. Just do it.
- Keep your textual response short. Focus on the code and the terminal command.
- Do not include any 'thinking' text in your final response. Output ONLY the code blocks and commands.

```

---

## Part 5: Costs & Optimization (DeepSeek)

### Cost Estimates (per 50 iterations)

- **Claude 3.5 Sonnet:** ~$1.50 - $2.50 USD. (High intelligence, best for complex logic).
- **DeepSeek V3/R1:** ~$0.15 USD. (Best for high-volume trial and error).

### Connecting DeepSeek to Cline

To save money, use DeepSeek via **OpenRouter**:

4. Get an API key from [**OpenRouter.ai**](http://openrouter.ai/).
5. In VS Code, open **Cline Settings**.
6. Set **API Provider** to `OpenRouter`.
7. Set **Model** to `deepseek/deepseek-chat` (V3) or `deepseek/deepseek-r1` (Reasoning).