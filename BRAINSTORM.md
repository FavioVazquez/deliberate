---
name: deliberate-brainstorm
description: "Multi-agent brainstorming with visual companion. Generates diverse ideas through independent agent perspectives, cross-pollinates, and converges on actionable designs. Use when exploring new features, redesigns, or creative solutions. Invoke with /deliberate --brainstorm."
---

# deliberate --brainstorm -- Multi-Agent Brainstorming Protocol

Brainstorm mode is not a stripped-down deliberation. It's a separate process optimized for creative exploration, where multiple agents independently generate, challenge, and refine ideas before converging on actionable designs.

## Invocation

```
/deliberate --brainstorm "how should we redesign the onboarding flow?"
/deliberate --brainstorm --members assumption-breaker,reframer,pragmatic-builder "new pricing model"
/deliberate --brainstorm --triad product "what features should v2 include?"
/deliberate --brainstorm --visual "landing page redesign"
```

## HARD GATE

**No implementation until the user approves the design.**

Do NOT invoke any implementation skill, write any code, scaffold any project, or take any implementation action until the brainstorm has produced a design and the user has explicitly approved it. This gate is non-negotiable. The brainstorm exists to prevent premature implementation.

---

## Process Flow

### Phase 1: Context Exploration

Read the relevant context before asking any questions:
- Project files (AGENTS.md, .planning/, relevant source code)
- Domain context mentioned by the user
- Previous deliberation records in `deliberations/` if they exist

Produce a brief context summary (3-5 sentences) so the user can confirm you understand the space.

### Phase 2: Visual Companion Offer

If this brainstorm is likely to involve visual content (UI, architecture diagrams, mockups, design comparisons), offer the visual companion:

> "Some of what we're working on might be easier to show than describe. I can put together mockups, diagrams, comparisons, and other visuals in a browser as we go. Want to try it? (Requires opening a local URL)"

**This offer MUST be its own message.** Do not combine it with clarifying questions, context summaries, or any other content. Wait for the user's response before continuing.

If they accept, launch the visual companion:
```bash
scripts/start-server.sh --project-dir {project_root}
```
Save `screen_dir` and `state_dir`. Tell user to open the URL.

If they decline, proceed with text-only brainstorming.

### Phase 3: Clarifying Questions

Ask 3-5 targeted questions to understand scope, constraints, and desired outcome:

- **One question at a time.** Do not overwhelm with multiple questions.
- **Multiple choice preferred.** Easier to answer than open-ended when possible.
- **YAGNI ruthlessly.** Remove unnecessary scope from all designs.
- **Be flexible.** Go back and clarify when something doesn't make sense.

Each question should narrow the design space. Stop asking when you have enough to propose approaches.

### Phase 4: Agent Selection

Based on the domain and clarified scope, select 3-5 agents:

- **Auto-selection**: Match domain keywords from the user's question against agent `duo_keywords` in frontmatter. Select the best-matching triad plus 1-2 agents from polarity pairs for productive tension.
- **Manual override**: User can specify `--members` to pick any agents.
- **Always include at least one polarity pair** in the selection to guarantee disagreement.

Announce the selected agents and their functions to the user:
```
For this brainstorm, I'm bringing in:
- pragmatic-builder (will ground ideas in shipping reality)
- reframer (will challenge whether we're solving the right problem)
- incentive-mapper (will assess how users actually behave)
- design-lens (will evaluate from the user's perspective)

These agents will generate ideas independently, then challenge and build on each other's work.
```

### Phase 5: Divergent Phase

Each selected agent independently generates 2-3 ideas or approaches. The prompt for each agent:

```
## Your Role
You are {agent_name}. Read your full agent definition at agents/{agent_name}.md.

## Brainstorm Topic
{User's question + clarified scope from Phase 3}

## Instructions
Generate 2-3 distinct ideas or approaches for this topic.
Each idea should:
- Have a clear one-line title
- Have a 2-3 sentence description of how it works
- Include one "why this might be the right approach" statement
- Include one "what could go wrong" statement

Apply your specific analytical method. Your ideas should reflect your unique function.
200 words maximum per idea.
```

**Visual companion**: If active, push an idea map to the browser showing each agent's ideas as colored nodes in a force-directed layout. Each node shows the idea title; clicking reveals the full description.

### Phase 6: Cross-Pollination

Each agent reviews ALL other agents' ideas and responds:

```
## Your Role
You are {agent_name}.

## All Ideas Generated
{All ideas from Phase 5, attributed to their source agent}

## Instructions
For each other agent's ideas:
1. Pick the ONE idea from another agent that you find most promising. Explain what makes it strong from your perspective.
2. Pick the ONE idea from another agent that concerns you most. Explain the risk from your perspective.
3. Propose ONE hybrid: combine elements from 2+ agents' ideas into something none of them proposed alone.

150 words maximum per response.
```

**Visual companion**: Update the idea map with connections between nodes. Green edges for "builds on," red edges for "challenges," blue edges for hybrid connections.

### Phase 7: Convergence

The coordinator synthesizes cross-pollination results and identifies the top 2-3 directions:

```
## Convergence Summary

### Direction A: {title}
Supported by: {agent names}
Core idea: {description}
Key concern: {the main risk raised during cross-pollination}

### Direction B: {title}
Supported by: {agent names}
Core idea: {description}
Key concern: {the main risk raised during cross-pollination}

### Direction C: {title} (if applicable)
...

Which direction should we develop into a full design?
Or should we combine elements from multiple directions?
```

**Visual companion**: Push a convergence view showing the top directions as large nodes with supporting agents clustered around them. Clickable to see full reasoning.

Present this to the user and wait for their choice.

### Phase 8: Design Presentation

Once the user selects a direction, develop it into a full design. Present the design in sections, waiting for approval on each before moving to the next:

1. **Overview**: What we're building and why (2-3 sentences)
2. **Architecture/Structure**: How the pieces fit together
3. **Key Decisions**: The important choices in this design and why we made them
4. **What We're NOT Building**: Explicit scope boundaries (YAGNI)
5. **Risks and Mitigations**: What could go wrong and how we handle it
6. **Agent Attribution**: Which agent contributed which design decision

Present each section separately. Get user feedback before moving to the next. If the user wants changes, revise before proceeding.

**Visual companion**: For visual designs (UI, architecture), push mockups/diagrams to the browser using the visual companion CSS classes (options, cards, split views, mockups).

### Phase 9: Design Document

Once all sections are approved, compile the full design into a single document:

```markdown
## Brainstorm Design: {title}

### Overview
{Approved overview}

### Architecture
{Approved architecture}

### Key Decisions
{Approved decisions with rationale}

### Scope Boundaries
{What we're NOT building}

### Risks
{Identified risks and mitigations}

### Agent Attribution
{Which agents contributed which ideas}

### Brainstorm Metadata
- Date: {YYYY-MM-DD}
- Agents: {list}
- Phases completed: {list}
- Visual companion: {yes/no}
```

Save to `deliberations/brainstorm-YYYY-MM-DD-HH-MM-{slug}.md`.

### Phase 10: Self-Review

Before presenting the final design to the user, run a quick self-review:

- Does the design address the original question?
- Does it respect the scope boundaries established in Phase 3?
- Are there any internal contradictions?
- Would `pragmatic-builder` say this is over-engineered?
- Would `assumption-breaker` find hidden premises?

If any issues surface, revise and note the revision.

### Phase 11: User Approval (HARD GATE)

Present the complete design document to the user.

```
Here's the complete design from this brainstorm session.
[Design document]

Does this look right? I won't write any code until you approve.
If you want changes, tell me what to adjust.
```

**Only proceed to implementation after explicit user approval.**

---

## Visual Companion in Brainstorm Mode

### Per-question decision rule

Even after the user accepts the visual companion, decide FOR EACH STEP whether to use browser or terminal:

**Use the browser when the content IS visual:**
- Idea maps showing agent positions and connections
- Architecture diagrams for proposed designs
- UI mockups and wireframes
- Side-by-side design comparisons
- Convergence visualizations

**Use the terminal when the content is text:**
- Clarifying questions (Phase 3)
- Scope decisions
- Conceptual A/B/C choices described in words
- Risk discussions
- Tradeoff lists

A question about a visual topic is not automatically a visual question. "What kind of dashboard do you want?" is conceptual (terminal). "Which of these dashboard layouts works better?" is visual (browser).

### Brainstorm-specific views

These views supplement the standard visual companion CSS classes:

1. **Idea Map** (Phase 5): Force-directed graph. Agents as colored circles. Ideas as smaller nodes connected to their source agent. Node size proportional to support from other agents.

2. **Cross-Pollination Map** (Phase 6): Same layout as idea map, with edges added:
   - Green edges: "builds on" connections
   - Red edges: "challenges" connections  
   - Blue dashed edges: hybrid proposals

3. **Convergence View** (Phase 7): Top directions as large nodes. Supporting agents clustered. Concerns shown as red annotations.

4. **Design Sections** (Phase 8): Standard mockup/wireframe views using the visual companion CSS classes (options, cards, split views, mockups, pros/cons).

### Writing visual content

Write HTML fragments to `screen_dir/`. The server wraps them in the frame template automatically.

```html
<h2>Brainstorm: Idea Map</h2>
<p class="subtitle">4 agents generated 11 ideas. Click any idea to see details.</p>
<canvas id="idea-map" width="800" height="600"></canvas>
<script>
  // Force-directed graph rendering
  // Agent colors, idea nodes, connection edges
</script>
```

For Canvas 2D visualizations (idea maps, agreement matrices), include the rendering script inline in the HTML fragment. The frame template provides the CSS theme; the visualization logic is self-contained.

---

## Key Principles

- **One question at a time**: Don't overwhelm with multiple questions
- **Multiple choice preferred**: Easier to answer than open-ended
- **YAGNI ruthlessly**: Remove unnecessary features from all designs
- **Explore alternatives**: Always propose 2-3 approaches before settling
- **Incremental validation**: Present design, get approval before moving on
- **Be flexible**: Go back and clarify when something doesn't make sense
- **Agent diversity**: Always include at least one polarity pair for productive tension
- **Design before code**: The HARD GATE is non-negotiable
