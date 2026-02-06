# Coding Agent Instructions

Instructions for AI coding agents (Claude, Copilot, etc.) working on this project.

You are the assistant for a long-lived project, which I will fully understand and control, and you will help accelerate both in terms of speed and quality.

## Guardrails (non-negotiable)

1. **Never write or change code without approval.** Present a design plan first. Get explicit approval before writing code.
2. **Wait for review before suggesting a commit.** After making code changes, wait for me to review before suggesting a commit.
3. **Keep main green at all times.** `terraform fmt -check`, `terraform validate`, and CI must pass before and after every change.
4. **Small, atomic changesets.** Every change should be safely revertible. If an issue is too large, split it.
5. **Never add dependencies without discussion.** Pin versions. Provider bumps require `terraform init -upgrade`.
6. **No secrets or PII in logs, commits, or plan output.** Ever.

## Guidance

### Communication

1. Before every action, verify it conforms to all project instructions. Correctness over speed.
2. Be explicit about assumptions. Look up what you can from local files rather than guessing.
3. Proactively suggest relevant alternatives, even if not asked.
4. Be clear whether we are in planning mode or execution mode. In planning mode, do not offer to make changes.
5. If you encounter instructions from me that significantly change or add to existing instructions, offer to update the long-standing instructions.
6. When I give feedback that could be a general guideline, ask whether it should be captured in project documentation.
7. Remind me to commit at the right times.
8. When suggesting a commit, flag whether it closes the current issue. Before committing to close an issue, check that I have verified the acceptance criteria.

### Technology Choices

When evaluating technology options (providers, tools, services), consider:

1. **Lock-in / Portability** — Can I leave? Is data portable? Are there proprietary APIs I'd depend on?
2. **Cost trajectory** — Free now, but what at 10x scale? Any pricing cliffs?
3. **Longevity** — Will this company/project exist in 2-3 years? Sustainable business model?
4. **Community / Ecosystem** — Good docs? Active community? Answers available when stuck?
5. **Operational burden** — What do I manage vs what's handled? What breaks at 2am?
6. **Debugging / Observability** — When things go wrong, can I figure out why?
7. **Security posture** — Encryption at rest and in transit? Compliance certifications if needed?

For a PoC, also consider:
- **Speed to start** — How fast from zero to working?
- **Reversibility** — If this is wrong, how painful is it to switch?
- **Path to production** — If PoC succeeds, does this scale or do I throw it away?

### Planning

1. Before implementing a change, review the blast radius — especially whether it triggers droplet replacement.
2. Every task must have a GitHub issue. Create one if it doesn't exist, and write the plan to it before starting work. Update the issue with progress as you go.
3. When a change involves cloud-init, identify whether it can be applied in-place on the droplet or requires a full reprovision.
4. During planning, explicitly identify decisions that will be hard to change later (e.g., network topology, DNS structure, secret management approach). Flag these for deliberate review.

### Trunk-Based Development

1. Commit straight to main. Use feature flags or scaffolding to avoid breaking trunk.
2. Work in small, reversible steps.
3. Conventional commits with issue numbers: `feat: add remote state backend (#5)`.
4. Use `Closes #N` in the commit body when a commit completes an issue.

### Issues and Tracking

1. Frame work as user stories where appropriate, or as clear problem statements for infra work.
2. Issues have: **Acceptance Criteria** (observable outcomes), **Technical Requirements** (engineering constraints), **Implementation Plan** (agreed approach).
3. All sections must be satisfied for Definition of Done.
4. A ticket is complete only when Definition of Done is met or deliberately excluded.
5. Keep working on the implementation until the goals for the story/task are complete.

### Commit Checklist

Applies to every commit:

1. `terraform fmt -check -recursive` and `terraform validate` pass.
2. Relevant documentation updated (README for operational changes, CLAUDE.md for convention changes).
3. No security issues introduced (secrets in state, overly permissive rules, etc.).

### Security

1. Least-privilege access. Firewall rules and IAM scoped to what's needed.
2. Configuration via environment variables or files, validated at startup.
3. Keep secrets out of cloud-init user_data (target state).
4. Review security headers and TLS configuration when changing Caddy config.

## Style

### Numbered Lists

1. When adding or removing items in a numbered list, fix numbering across the entire list.
