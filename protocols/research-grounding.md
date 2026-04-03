# Research Grounding Protocol

This protocol is injected into deliberations and brainstorms when the `--research` flag is active. It runs **before Round 1 / Divergent Phase** and grounds each agent's analysis in real, retrieved evidence rather than parametric knowledge alone.

---

## When This Protocol Activates

Only when the user explicitly passes `--research` (or natural language equivalent on Windsurf: "with research", "do research first", "search before answering").

This is **opt-in only**. It is never the default. The flag exists because:
- Agents have a training cutoff — recent events, new libraries, current prices, live APIs are not in parametric memory
- The user's codebase is not in parametric memory — agents must read it to understand the actual context
- Some decisions require current external data (benchmark results, competitor pricing, regulatory text, recent CVEs, API specs)

Without `--research`, agents reason from internalized knowledge. With `--research`, agents ground first, reason second.

---

## Coordinator Instructions: Pre-Round Grounding Phase

### Step R1: Classify the Research Needs

Before dispatching agents, the coordinator classifies what kind of grounding this deliberation needs. Announce this to the user:

```
Research mode active. Before agents analyze, I'll gather grounding context.
Classifying research needs for: "{problem restatement}"
```

Determine which of the following apply:

| Type | When to activate | Tools to use |
|------|-----------------|--------------|
| **Codebase scan** | Question involves existing code, architecture, tech debt, dependencies | Read files, grep, list dirs |
| **Web search** | Question involves current technology landscape, recent events, pricing, benchmarks, regulatory changes, competitor moves | Web search |
| **Documentation lookup** | Question involves a specific tool, library, API, or framework | Web search targeting official docs |
| **Both** | Complex technical decisions that involve current state of the codebase AND the external landscape | Both |

Announce what you're about to do:
```
I'll do a [codebase scan / web search / documentation lookup / full research pass] before agents speak.
This may take a moment. The grounding evidence will be shared with all agents.
```

---

### Step R2: Codebase Scan (if applicable)

If codebase research is needed, run the following in order, stopping when you have enough context:

**Level 1 — Orientation** (always run if codebase scan is active):
```
Read: AGENTS.md (if exists) — understand project soul and current state
Read: .planning/PROJECT.md or README.md — understand what's being built
List: top-level directory structure
```

**Level 2 — Focused scan** (run based on question domain):
- Architecture questions → read main entry points, config files, dependency manifests (`package.json`, `pyproject.toml`, `go.mod`, `pom.xml`, `Cargo.toml`)
- Debugging questions → read the failing file + its direct imports + relevant test files
- Tech debt questions → search for TODO/FIXME/HACK comments, read the most recently modified files
- Performance questions → read the hot path files + any profiling configs
- Security questions → read auth/middleware layers, dependency files for known vulnerable versions

**Level 3 — Deep dive** (only if Level 2 reveals something specific to pursue):
- Follow the specific file/module/function surfaced in Level 2

Cap the codebase scan at **10 files maximum**. If the codebase is larger, surface what you read and note what you skipped.

Produce a **Codebase Context Summary**:
```markdown
## Codebase Context
- Stack: {languages, frameworks, key libraries with versions}
- Relevant files read: {list}
- Current state relevant to the question: {3-5 bullet points of facts found}
- Gaps: {what exists in the codebase that wasn't read, if relevant}
```

---

### Step R3: Web Search (if applicable)

Perform targeted searches. Each search should be precise — bad searches waste context.

**Search strategy by question type:**

| Question type | Search queries to run |
|--------------|----------------------|
| Technology choice (A vs B) | "{tech A} vs {tech B} {year}" + "{tech A} production issues {year}" + "{tech B} benchmark {year}" |
| Library/framework | "{library name} changelog" + "{library name} known issues" + "{library name} alternatives {year}" |
| Architecture pattern | "{pattern name} at scale case study" + "{pattern name} failure modes" |
| Security/compliance | "{CVE or regulation} {year}" + "{tool name} security audit" |
| Pricing/vendor | "{vendor} pricing {year}" + "{vendor} enterprise SLA" |
| Competitor landscape | "{domain} tools comparison {year}" + "{competitor} recent updates" |

Run a **maximum of 5 searches**. Prioritize recency (last 12 months) and primary sources (official docs, engineering blogs, academic papers, CVE databases).

Produce a **Web Research Summary**:
```markdown
## Web Research
- Searches run: {list of queries}
- Key findings: {bullet points of facts found, each with source URL}
- Recency note: {newest source date found}
- Gaps: {what couldn't be found or verified}
```

---

### Step R4: Distribute Grounding Context to Agents

The coordinator packages the grounding evidence and includes it in every agent's Round 1 prompt, as an additional section:

```
## Grounding Evidence
{Codebase Context Summary if applicable}
{Web Research Summary if applicable}

Use this evidence in your analysis. You may cite specific findings.
If the evidence is insufficient for your analytical method, note what additional information would change your position.
```

**Critical rule**: Agents must treat grounding evidence as **facts to reason from**, not conclusions to agree with. The `assumption-breaker` in particular should scrutinize the sources and flag any evidence that looks cherry-picked, outdated, or from a biased source.

---

### Step R5: Evidence Quality Check

After agents complete Round 1, the coordinator scans for evidence misuse:

- Did any agent **over-cite** grounding evidence (treating search results as definitive when they're preliminary)?
- Did any agent **ignore** grounding evidence that was directly relevant to their analysis?
- Did `assumption-breaker` scrutinize the evidence quality, or just accept it?

If evidence was over-relied on, add to the coordinator's Round 2 dispatch:
```
Note to agents: The grounding evidence is current as of the search date but may be incomplete. 
{agent name} may be over-weighting {specific finding}. Challenge this if your analysis warrants.
```

---

## Agent Instructions: Using Grounding Evidence

When `--research` is active, each agent receives the grounding context. Agents should:

1. **Ground your analysis in the evidence** — reference specific findings from the codebase scan or web research. "The codebase currently uses X version, which has Y implication" is stronger than generic analysis.

2. **Flag evidence gaps** — if the grounding evidence doesn't cover what your analytical method needs, say so explicitly. "The web research didn't surface benchmark data for >10M records/day — my risk analysis is therefore based on first principles rather than empirical data."

3. **Challenge evidence quality** (especially `assumption-breaker`) — search results can be wrong, outdated, or from biased sources. If you find a reason to distrust a finding, say so.

4. **Don't be anchored** — grounding evidence informs but doesn't determine your position. If the evidence points one way but your analytical method points another, hold your position and explain the discrepancy.

---

## Scope Limits

The research grounding phase has strict limits to prevent it from becoming a context-consuming sinkhole:

| Limit | Value |
|-------|-------|
| Max files read (codebase) | 10 |
| Max searches (web) | 5 |
| Max tokens in Codebase Context Summary | ~500 |
| Max tokens in Web Research Summary | ~500 |
| Max total grounding context per agent | ~1000 tokens |

If the research scope would exceed these limits, the coordinator surfaces the most relevant subset and notes what was excluded. More research is not always better — precision matters more than volume.

---

## Platform Notes

**Claude Code**: Agents run as parallel subagents. Each receives the same grounding context package prepared by the coordinator. The coordinator itself does the research before dispatching agents.

**Windsurf**: The coordinator does the research inline (using Windsurf's web search and file tools) before role-prompting each agent. The grounding context is included in every agent's prompt.

**No tool access**: If the platform has no web search or file reading capability, the coordinator announces:
```
Research mode requested but this platform doesn't have [web search / file access] available.
Falling back to parametric knowledge. Consider providing relevant context manually in your question.
```
