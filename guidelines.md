# Guidelines

Behavioral guidelines to reduce common LLM coding mistakes in RhodoniteMBT. Merge with project-specific instructions as needed.

Adapted for this repository from [`multica-ai/andrej-karpathy-skills`](https://github.com/multica-ai/andrej-karpathy-skills), which is MIT-licensed and derived from Andrej Karpathy's observations on LLM coding pitfalls.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State assumptions that affect behavior, public APIs, file layout, build outputs, or test scope.
- If uncertainty materially changes behavior or risk, ask. Otherwise make a reasonable local assumption and name it.
- If multiple plausible interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear enough that implementation would likely be wrong, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No defensive code for states ruled out by local invariants.
- Do handle real external failure modes: filesystem, network, browser/WebGPU availability, native runtime, subprocesses, and user-provided data.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

Choose verification that matches the changed surface:
- MoonBit library/API changes → `moon check --target all`, `moon fmt`, and targeted `moon test` or `pnpm run test:core:mbt`.
- TypeScript wrappers or sample host changes → `pnpm exec tsc --noEmit` and the relevant `pnpm run test:*` script.
- Browser sample entry/layout/path changes → `pnpm exec vite build`.
- Rendering behavior changes → relevant visual regression tests (`pnpm run test:examples:visual`, or native/browser subset).
- npm-facing wrapper/package changes → inspect `scripts/build-npm-package.mjs`, then run `pnpm run build:npm` and preferably `pnpm run pack:npm`.

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
