---
name: to-tasks
description: Break a plan, specification, issue, or conversation into dependency-aware tracer-bullet tasks and save approved tasks as separate Markdown files under .tasks. Use only when explicitly invoked.
---

# To Tasks

Turn the available plan, specification, issue, or conversation into small, executable tasks. Each task must declare the tasks that block it.

## Gather context

Use the conversation context first. If the user provides a file, issue, or URL, read its full contents and comments before drafting tasks.

Explore the relevant code when that would clarify the current architecture, domain vocabulary, or constraints. Respect applicable ADRs and repository instructions. Look for small prefactors that make the requested change easier, and place them before the work they unblock.

## Draft tracer-bullet tasks

Prefer narrow vertical slices:

- Each task delivers a complete, independently verifiable path through every affected layer.
- Each task fits in one fresh context window.
- A task lists only genuine prerequisites under **Blocked by**. Tasks with no blockers form the initial frontier.
- Describe outcomes and acceptance criteria, not a layer-by-layer implementation recipe.

For a wide mechanical refactor that cannot land green as vertical slices, use expand-migrate-contract:

1. Add the new form alongside the old.
2. Migrate callers in independently green batches sized by blast radius.
3. Remove the old form only after every migration task is complete.

If migration batches cannot remain green independently, state that they share an integration branch and make them all block a final integration-and-verification task.

## Get approval

Before writing files, present the proposed breakdown as a numbered list. For each task include:

- **Title**
- **Blocked by**
- **What it delivers**

Ask whether the granularity and blocking edges are right and whether any tasks should be merged or split. Revise until the user approves. Do not treat the initial request to create tasks as approval of the first draft unless the user explicitly asks to skip review.

## Save approved tasks

Create one file per task under `.tasks/<feature-slug>/`, relative to the repository root. Choose a short kebab-case feature slug from the work unless the user provides one. Number files in dependency order, blockers first:

```text
.tasks/<feature-slug>/<NN>-<task-slug>.md
```

Never overwrite an existing task directory or task file without the user's approval. Do not create a combined task file. Do not publish to an external tracker.

Use this template:

```markdown
# <NN>: <Task title>

**What to build:** <The end-to-end behaviour this task makes work from the user's perspective.>

**Blocked by:** <Task numbers and titles, or "None (can start immediately)".>

**Status:** ready

- [ ] <Acceptance criterion 1>
- [ ] <Acceptance criterion 2>
```

Avoid file paths and code snippets because they go stale. A short decision-defining snippet from a prototype is acceptable when prose would be less precise; identify it as prototype-derived and keep only the essential shape.

After saving, report the directory and identify the current frontier: every task whose blockers are already complete, or every unblocked task when none have started.
