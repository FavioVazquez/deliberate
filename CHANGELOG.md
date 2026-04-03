# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.5] - 2025-04-03

### Fixed
- Added `protocols/` and `assets/` to npm `files` array — both were missing from published packages, causing `protocols/research-grounding.md` and all README images to be absent after install

## [0.2.4] - 2025-04-03

### Added
- `assets/research_grounding.png`: diagram explaining the `--research` grounding flow — pipeline stages R1–R5, codebase scan vs web search breakdown, without/with contrast panel
- Embedded `research_grounding.png` in README at the `--research` section

## [0.2.3] - 2025-04-03

### Added
- `--research` flag: opt-in grounding phase before Round 1 — scans codebase and/or searches the web before agents analyze
- `--research=web`: web search only variant
- `--research=code`: codebase scan only variant
- `protocols/research-grounding.md`: full grounding protocol (search strategy, codebase scan levels, scope limits, evidence quality rules)
- Research grounding integrated into SKILL.md coordinator sequence (Step 0), Quick mode, Duo mode
- Research grounding integrated into BRAINSTORM.md Phase 1
- Natural language Windsurf triggers: "with research", "search the web", "look at the codebase first", "do research first"
- README: Research Grounding section with dual-platform examples, grounding phase description, evidence rules

## [0.2.1] - 2025-04-03

### Added
- 7 Gemini-generated images for the README (banner, sycophancy diagram, modes overview, agents wheel, triad map, enforcement rules, verdict output)
- Expanded "The Problem" section with deep sycophancy analysis: confirmation bias amplification, delusional spiraling, simulated balance, hidden trade-offs, context collapse
- "What deliberate brings to the table" section explaining structural disagreement, forced dissent, minority report, cross-examination, transparent verdicts
- Images embedded throughout README at relevant sections

## [0.2.0] - 2025-04-03

### Changed
- Rewrote installer as pure Node.js (no bash dependency required)
- Blue ASCII "DELIBERATE" banner with professional CLI styling
- Interactive prompts: platform selection with auto-detection, global/local scope choice
- Clean ✓ checkmark output with colored status lines
- Platform flags: --claude, --windsurf, --cursor, --all
- Scope flags: --global/-g, --local/-l
- Added --dry-run preview, --uninstall support
- Moved release.sh to repo root (dev-only, excluded from npm package)

## [0.1.0] - 2025-04-03

### Added
- 14 core agents with functional names: assumption-breaker, first-principles, classifier, formal-verifier, bias-detector, systems-thinker, resilience-anchor, adversarial-strategist, emergence-reader, incentive-mapper, pragmatic-builder, reframer, risk-analyst, inverter
- 3 optional specialist agents: ml-intuition, safety-frontier, design-lens
- SKILL.md coordinator protocol with 4 modes: Full (3 rounds), Quick (2 rounds), Duo (dialectic), Brainstorm
- BRAINSTORM.md sub-skill with 11-phase creative exploration flow
- 18 pre-defined triads for domain-optimized deliberation
- 4 profiles: full, lean, exploration, execution
- Polarity pairs for structural disagreement
- Enforcement rules: hemlock rule, 3-level depth limit, 2-message cutoff, dissent quota, novelty gate, groupthink flag
- Visual companion: HTML+JS+Canvas 2D browser interface with force-directed graphs, agent position maps, agreement matrices
- File-watcher server (Node.js) with auto-refresh, JSONL event capture, 30-min auto-shutdown
- Frame template with dark theme CSS: options, cards, split views, mockups, pros/cons, agent badges, verdict styling
- Platform support: Claude Code (parallel subagents), Windsurf (sequential), Cursor (sequential)
- Platform-aware installer with auto-detection, global/workspace scope
- `npx @faviovazquez/deliberate` universal installer
- Model tier configs for Anthropic (claude-sonnet-4.6), OpenAI (gpt-5.4), Google (gemini-2.5-pro/flash), Ollama (qwen3-coder)
- Output templates for deliberation and brainstorm records saved to deliberations/
