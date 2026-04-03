# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
