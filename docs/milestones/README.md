# Usapyon — Milestones

**This folder is the build authority.** A milestone file says what gets built,
what is deliberately left out, and when it is done. If something is not in the
current milestone, it is not being built — no matter how thoroughly
[`../design/`](../design/) describes it.

| Milestone | Status |
| --- | --- |
| [01 — A Usapyon You Can Touch](01-interactive-bunny.md) | ✅ Complete |
| [02 — A Usapyon That Needs You](02-persistent-pet.md) | ▶ Next |

Milestone 1 documents what the project does today. Milestone 2 adds stats,
saving and the passage of time.

[`../plans/`](../plans/) holds worked-out implementation plans for individual
features within a milestone.

Rules that hold across every milestone — debug vs release builds, save file
separation, how to test — live in [`../conventions.md`](../conventions.md).
Don't restate them in a milestone file.
