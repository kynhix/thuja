# Contributing to the capstone repository

This file is about how to work on `thuja` for the year without turning the repository into ten unrelated
experiments.

For the technical design, read [`ARCHITECTURE.md`](ARCHITECTURE.md). For Ada syntax used in the project, read
[`Ada_for_Thuja.md`](Ada_for_Thuja.md).

## The seed and your fork

This repository is the **seed** maintained by the GNAT Academic Program.

Each capstone team works in its own **fork**. Your fork is your working project for the year. You can create branches,
try ideas, revert them, and review each other's work there.

The seed should change rarely during the year. Typical seed changes are:

- a broken build;
- a genuinely wrong contract;
- a platform file that cannot compile or link;
- a small correction needed by every team.

If the seed changes, your team will be told so you can rebase or merge the small upstream change.

At the end of the year, useful student work can be folded back into the seed for future cohorts, with authorship kept
in the commit history and project credits.

## Your normal change should look like this

For most tasks:

1. Start from a green branch.
2. Read the package spec and existing tests.
3. Add or change one behaviour.
4. Add a test, proof, or both in the same branch.
5. Build locally.
6. Run the relevant tests.
7. Run GNATprove if you changed SPARK code.
8. Open/review the diff as a team before merging.

Avoid giant branches that contain a new feature, a redesign, formatting changes, renamed files, and unrelated cleanup
at the same time. They are difficult to review and difficult to recover from.

## Keep CI green

CI is not decoration. It tells you whether your branch still satisfies the shared project contract.

On Linux and Windows, CI:

- builds the library;
- builds and runs the tests;
- runs the showcase snapshot.

On Linux it also runs the SPARK proof.

A broken CI run should normally be fixed before starting more work on top of it.

## Tests and TODOs

`tests/src/tests.adb` uses two simple helpers:

```ada
Check ("behaviour that must work", Condition);
Todo  ("behaviour not implemented yet", Condition);
```

A `Todo` documents a seed milestone without failing CI.

When you implement that feature and the `Todo` starts printing `DONE`, change it into a `Check`. That turns your work
into a permanent regression test.

Do not simply delete tests that expose a bug.

## Contracts are not obstacles to remove

Ada/SPARK contracts appear as `Pre`, `Post`, ranges, subtypes, and invariants.

If new code fails a contract or proof, first determine which of these is true:

- the caller violated a valid precondition;
- the implementation no longer meets a valid postcondition;
- a range or bound is genuinely too small;
- the contract itself was incorrect.

Only the last case justifies changing the contract merely because proof became difficult. If you believe a shared
contract is wrong, make that a small, explicit change and bring the reasoning to the project review.

## Architectural rules

These rules protect the simplicity of the core:

- Only `Thuja.Terminal` performs terminal I/O.
- The application owns its event loop.
- Events are polled, not pushed through callbacks.
- Do not add Ada tasks, access types, or heap allocation to `src/` without an architectural discussion first.
- Widgets must tolerate empty and tiny areas.
- Widgets must not draw outside the `Area` they receive.
- Layout arithmetic should go through `Thuja.Layout` rather than being copied into each widget.
- Unknown or malformed terminal input must not crash the decoder.
- Input-decoder changes need both regression tests and successful SPARK proof.

If you think one of these rules prevents an important feature, raise the design issue. Do not work around it silently.

## Reviews

Reviews happen on your team's fork, normally around the regular project meeting.

Come with a branch or commit range that can be inspected as a diff. A useful review is much easier when the change
has a clear purpose and the tests demonstrating it are beside the implementation.

For a non-trivial change, be ready to answer:

- What user-visible or library behaviour changed?
- Where is the test for it?
- Did any public contract change?
- Does this add a new dependency or new mutable state?
- If performance was the goal, what measurement improved?

## Ada style

The project uses GNAT style checks and warnings as errors.

Practical conventions:

- Keep lines readable; the project target is about 100 columns.
- Use descriptive Ada names rather than abbreviations unless the protocol defines the abbreviation.
- Public subprogram comments should explain what the operation guarantees or means, not narrate its implementation.
- Prefer named associations when a call would otherwise be ambiguous:

```ada
Term.Poll (Timeout => 0.1, E => E);
```

- Keep package specs (`.ads`) small and intentional. Public API changes affect every caller.

## Commits

Use a short imperative first line:

```text
Decode modified CSI arrow keys
```

Use a commit body when the reason is not obvious from the diff, especially for protocol interpretation, contract
changes, platform differences, or performance tradeoffs.

Good history matters in a year-long student project because you will forget why a strange line exists six months
later.

## External specifications

For terminal protocol behaviour, use specifications rather than guessing from one emulator:

- ECMA-48 for control-sequence grammar;
- XTerm Control Sequences for common terminal behaviour;
- xterm on POSIX and Windows Terminal on Windows as project reference environments.

If two terminals disagree, record what you observed and keep the compatibility decision explicit in code/tests.
