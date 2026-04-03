# deliberate

**Agreement is a bug.**

A multi-agent deliberation and brainstorming skill for AI coding assistants. Forces multiple agents to disagree before they agree, surfacing blind spots that single-perspective answers hide.

## The Problem

AI chatbots are sycophantic. They validate your claims, confirm your hypotheses, and produce polished answers that sound balanced but come from a single reasoning tradition. Research shows this leads to "delusional spiraling" where even rational users develop dangerously confident beliefs after prolonged conversations ([Chandra et al., 2025](https://arxiv.org/abs/2602.19141)).

A single LLM produces one coherent viewpoint per generation. It simulates balance. It does not achieve genuine adversarial deliberation.

## The Solution

`deliberate` externalizes the disagreement layer. Instead of asking one agent for a balanced answer, it spawns multiple agents with distinct analytical methods, explicit blind spots, and structural counterweights. They analyze independently, cross-examine each other, and produce a verdict that shows you where they agree, where they disagree, and why.

The disagreements are the point. A single model averages opposing views into one confident recommendation. `deliberate` keeps them separate so you can decide.

## Quick Start

```bash
npx deliberate
```

This auto-detects your platform (Claude Code, Windsurf, Cursor) and installs the skill to the current workspace. Then open your AI assistant and try:

**Claude Code:**
```
/deliberate "should we migrate from REST to GraphQL?"
```

**Windsurf / Cursor:**
```
@deliberate should we migrate from REST to GraphQL?
```

Windsurf also auto-invokes the skill when your question matches the skill description.

### Manual Installation

**Claude Code (workspace):**
```bash
git clone https://github.com/FavioVazquez/deliberate.git
cd deliberate
./install.sh --platform claude-code
```

**Claude Code (global -- all projects):**
```bash
./install.sh --platform claude-code --global
```

**Windsurf (workspace -- into .windsurf/skills/):**
```bash
git clone https://github.com/FavioVazquez/deliberate.git
cd deliberate
./install.sh --platform windsurf
```

**Windsurf (global -- into ~/.codeium/windsurf/skills/):**
```bash
./install.sh --platform windsurf --global
```

## Modes

### Full Deliberation (3 rounds)
```
/deliberate --full "is this acquisition worth pursuing at 8x revenue?"
```
All 14 agents. Round 1: independent analysis. Round 2: cross-examination (must disagree). Round 3: crystallization. Produces a structured verdict with minority report.

### Quick Deliberation (2 rounds)
```
/deliberate --quick "monorepo or polyrepo?"
```
Auto-selected triad. Rounds 1 + 3 only (skip cross-examination). Faster, cheaper.

### Triad (domain-optimized)
```
/deliberate --triad architecture "should we split the monolith?"
/deliberate --triad decision "build vs buy for notifications"
/deliberate --triad risk "should we launch before the audit?"
```
3 agents selected for the domain. 18 pre-defined triads available.

### Duo / Dialectic
```
/deliberate --duo assumption-breaker,pragmatic-builder "rewrite the auth layer?"
```
Two agents, two rounds of exchange, then synthesis. Best for binary decisions.

### Brainstorm
```
/deliberate --brainstorm "how should we redesign onboarding?"
/deliberate --brainstorm --visual "landing page redesign"
```
Creative exploration with multiple agents. Divergent ideas, cross-pollination, convergence into actionable designs. Optional visual companion with interactive idea maps.

### Auto-Detect (no flag)
```
/deliberate "should we migrate from REST to GraphQL?"
```
Parses your question, selects the best-matching triad, runs 3-round protocol.

## The 14 Core Agents

| Agent | Function |
|-------|----------|
| `assumption-breaker` | Destroys hidden premises, tests by contradiction |
| `first-principles` | Bottom-up derivation, refuses unexplained complexity |
| `classifier` | Taxonomic structure, category errors, four-cause analysis |
| `formal-verifier` | Computational skeleton, mechanization boundaries |
| `bias-detector` | Cognitive bias detection, pre-mortem, de-biasing |
| `systems-thinker` | Feedback loops, leverage points, unintended consequences |
| `resilience-anchor` | Control vs acceptance, moral clarity, anti-panic |
| `adversarial-strategist` | Terrain reading, competitive dynamics, strategic timing |
| `emergence-reader` | Non-action, subtraction, minimum intervention |
| `incentive-mapper` | Power dynamics, actor incentives, how people actually behave |
| `pragmatic-builder` | Ship it, maintenance cost, over-engineering detection |
| `reframer` | Dissolves false problems, frame audit, perspective shift |
| `risk-analyst` | Antifragility, tail risk, fragility profile |
| `inverter` | Multi-model reasoning, inversion ("what guarantees failure?") |

Plus 3 **optional specialists** activated for domain-specific triads: `ml-intuition` (AI/ML), `safety-frontier` (AI safety), `design-lens` (UX/design).

Agents are named by their function, not by historical figures. Each agent declares its analytical method, what it sees that others miss, and what it tends to miss. These declared blind spots are why the polarity pairs matter.

## 18 Pre-defined Triads

| Domain | Agents |
|--------|--------|
| architecture | classifier + formal-verifier + first-principles |
| strategy | adversarial-strategist + incentive-mapper + resilience-anchor |
| ethics | resilience-anchor + assumption-breaker + emergence-reader |
| debugging | first-principles + assumption-breaker + formal-verifier |
| innovation | formal-verifier + emergence-reader + classifier |
| conflict | assumption-breaker + incentive-mapper + resilience-anchor |
| complexity | emergence-reader + classifier + formal-verifier |
| risk | adversarial-strategist + resilience-anchor + first-principles |
| shipping | pragmatic-builder + adversarial-strategist + first-principles |
| product | pragmatic-builder + incentive-mapper + reframer |
| decision | inverter + bias-detector + risk-analyst |
| systems | systems-thinker + emergence-reader + classifier |
| economics | adversarial-strategist + inverter + incentive-mapper |
| uncertainty | risk-analyst + adversarial-strategist + assumption-breaker |
| bias | bias-detector + reframer + assumption-breaker |
| ai | formal-verifier + ml-intuition + safety-frontier |
| ai-product | pragmatic-builder + ml-intuition + design-lens |
| design | design-lens + reframer + pragmatic-builder |

## Visual Companion

The visual companion is a browser-based interface that shows deliberation progress in real time. Launch it with `--visual`:

```
/deliberate --visual --full "major architecture decision"
/deliberate --brainstorm --visual "redesign the dashboard"
```

It provides:
- **Agent Position Map**: Force-directed graph showing agents as colored nodes positioned by agreement/disagreement
- **Agreement Matrix**: Heatmap of which agents agree/disagree on which points
- **Idea Evolution Timeline** (brainstorm): How ideas appeared, forked, merged across phases
- **Verdict Formation** (deliberation): Step-by-step visualization of how the verdict emerged
- **Minority Report Panel**: Highlighted dissenting positions

Built with plain HTML + JS + Canvas 2D. No framework, no build step. Served locally via a lightweight Node.js file-watcher server.

## Platforms

| Platform | Execution Model | Default Profile | Invocation | Install Paths |
|----------|----------------|-----------------|------------|---------------|
| Claude Code | Parallel subagents (`context: fork`) | full (14 agents) | `/deliberate` | `~/.claude/skills/` (global), `.claude/skills/` (workspace) |
| Windsurf | Sequential role-prompting | lean (5 agents) | `@deliberate` or auto | `~/.codeium/windsurf/skills/` (global), `.windsurf/skills/` (workspace) |
| Cursor | Sequential role-prompting | lean (5 agents) | `@deliberate` or auto | `.cursor/skills/` (workspace) |

### How it works on each platform

**Claude Code**: Each agent runs as a parallel subagent with its own isolated context window. The coordinator dispatches all agents simultaneously in Round 1 and Round 3, and sequentially in Round 2 (cross-examination). Agents are installed as separate `.md` files in `~/.claude/agents/` and referenced by the skill.

**Windsurf / Cursor**: No subagent support. The coordinator adopts each agent's persona sequentially within a single context window. Agent definitions are bundled inside the skill directory and read on demand. The default "lean" profile (5 agents) keeps context usage manageable while still providing genuine multi-perspective deliberation.

**Cross-platform compatibility**: Windsurf discovers skills in `.claude/skills/` if Claude Code config reading is enabled. The agent `.md` files use a superset YAML frontmatter that both platforms handle gracefully (unknown fields are ignored).

## Configuration

### Model tiers
All agents use sonnet-equivalent models by default. To enable higher-tier models:

```yaml
# In your project's config.yaml:
model_tier: high
# WARNING: high-tier models consume significantly more tokens/credits
```

### Custom model routing
Copy `configs/provider-model-slots.example.yaml` to `configs/provider-model-slots.yaml` and customize per-agent model assignments.

### Output
All deliberation and brainstorm records are saved to `deliberations/` in your project root.

## When to Use

**Use `/deliberate` for** complex decisions where trade-offs are real: architecture choices, strategic pivots, build-vs-buy, pricing models, any situation where you suspect a single confident answer hides real trade-offs.

**Don't use `/deliberate` for** questions with clear correct answers. Don't convene 14 agents to debate tabs vs spaces.

**The sweet spot:** Decisions where you already have an opinion but suspect you're missing something.

## Enforcement

The protocol includes safeguards against common failure modes:
- **Hemlock rule**: Prevents infinite questioning spirals
- **3-level depth limit**: Forces position commitment after 3 rounds of questioning
- **2-message cutoff**: Prevents any pair from dominating the discussion
- **Dissent quota**: At least 30% of agents must disagree in Round 2
- **Novelty gate**: Round 2 must introduce new ideas
- **Groupthink flag**: Unanimous agreement triggers explicit warning

## References

- **Chandra, Y., Mishra, C., & Flynn, B.** (2025). *Can AIeli-bots turn us all delusional? How AI sycophancy, AI psychosis, and human self-correction interact.* arXiv:2602.19141. [Paper](https://arxiv.org/abs/2602.19141) — The formal model of sycophancy-induced delusional spiraling that motivated this project. Shows how even rational users develop dangerously confident beliefs after prolonged conversations with agreeable AI.
- **Council of High Intelligence** — [github.com/0xNyk/council-of-high-intelligence](https://github.com/0xNyk/council-of-high-intelligence) — The original multi-agent deliberation system for Claude Code. 18 agents modeled on historical thinkers with polarity pairs, triads, and a 3-round protocol. `deliberate` redesigns the agent roster around analytical functions rather than personas, adds enforcement rules, and extends to multiple platforms.
- **Superpowers Brainstorming Skill** — [github.com/obra/superpowers](https://github.com/obra/superpowers) — The brainstorming skill and browser-based visual companion architecture. `deliberate` adapts the file-watcher server pattern and CSS frame template approach for deliberation-specific visualizations (agent position maps, agreement matrices, idea evolution).

## License

MIT
