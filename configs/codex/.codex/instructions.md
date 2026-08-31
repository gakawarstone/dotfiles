Use Conventional Commits for commit messages unless the user explicitly asks for a different format.

## Orchestration (sol)
- Delegate parallelizable, independent, or long-running implementation work to the `luna` subagent.
- Give each spawn a self-contained brief: goal, relevant files/context, constraints, and expected deliverable.
- Do small or tightly coupled edits yourself; only delegate when the task is well-scoped.
- Never nest spawns: luna must not spawn further agents.
- Always wait for and review subagent results before presenting them as done.
