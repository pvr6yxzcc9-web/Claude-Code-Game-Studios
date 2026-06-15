---
name: feedback-shows-work-pattern
description: For adversarial GDD reviews, lead with concrete boundary-value analysis on every numeric field before flagging structural or semantic issues
metadata:
  type: feedback
---

For adversarial GDD reviews on systems with numeric fields, lead with concrete boundary-value analysis (plug MIN/MAX into downstream formulas) before flagging structural or semantic problems.

Why: numeric range issues are the cheapest to find, easiest to fix, and most likely to be silently broken in production. Abstract structural critiques are valuable but secondary — designers can argue with them, boundary problems are unambiguous.

How to apply: when reviewing a Resource/Formula/System GDD, structure the FINDING-N output as: (1) boundary sweep on every `@export_range` and table column, showing what goes degenerate at min and max; (2) invariant coverage check (the asserts vs. the actual valid-state space); (3) typed-array / cross-language marshaling issues; (4) ambiguous semantics (linear vs tree, singleton vs save, etc.); (5) completeness (types referenced but not declared). Linked: [[project-railhunter]].
