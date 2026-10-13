---
name: production-runs
description: Load before starting any run that is unattended, whose results feed a decision or a downstream job, that touches data you cannot regenerate, or that you would not cheerfully run again from scratch — a training or eval sweep, a batch over many items, a migration, a scheduled job. The trigger is what the run is, not how it was asked for — "just run it" does not exempt it, and a prototype that has grown to a hundred items is now this. A three-example prompt iteration, a one-off script you will throw away, a command you can rerun in a minute do not load it. Holds the pre-flight (smoke test, infrastructure check, the plan you state before starting), the per-item logging standard, checkpointing, and what a result file must carry to count.
---

# Production runs

A prototype is something you iterate on and throw away. Production is anything unattended, anything whose results feed a decision, anything touching data you cannot regenerate, anything you would not cheerfully rerun. The moment a run crosses that line, do the pre-flight below before starting, and hold the run to the three properties.

## Pre-flight, before the run starts

1. **Smoke-test one item end to end**, and name in your report which item and what it produced. Path, permission and format errors show up on item 1, not item 50.
2. **Verify the infrastructure the run depends on**, and say what you checked: the log file is being written where you expect, a checkpoint saves and reloads, the output directory exists.
3. **State the plan in the same turn you start.** What runs, how long it should take, where results land, and how to inspect partial progress while it runs — a path that can be watched.

The pre-flight takes minutes; the rerun it prevents takes hours. The run already being late never justifies skipping it.

## Resumable

Processes die. Checkpoint intermediate results so a crash loses one item, not the run. Checkpoints are independent files — never overwrite the previous one — and resuming from any of them has to work.

## Reproducible

- Dependencies locked (`uv.lock`); the run is a script in the project, with every parameter it needs inside it.
- **Every result file carries its complete input** — prompts, messages, retrieval context, parameters, the model or commit in play. If a single failed example cannot be rerun from the result file alone, the result is not reproducible.
- **Rerun into a new file** (`_v2`, `_patched`) or back the original up first; the original is the audit trail. The global file's rules on stale copies and on marking a deliberate oddity apply here as everywhere.

## Observable

Set up logging before the run starts; once it is running it is too late. The standard is auditability: **from the log alone, without rerunning anything, can you answer what happened to any single item?**

```
[2026-09-01T14:22:07Z] item=doc_0412 status=fail reason=timeout_30s attempt=2/3 elapsed=30.1s
```

answers it. `Processing... done` does not, and neither does a progress bar. That standard is what makes the rest mandatory:

- **Per-item lines, with a start line and an end line.** Without a start line a hang is indistinguishable from an item never reached, and those have opposite fixes.
- **Timestamps on every line.** Without them there is no ETA, no stall detection, no performance diagnosis after the fact.
- **A skip logged as loudly as a failure.** Silent skips are how a run reports 100/100 having done 40.
- **The inputs that decided the outcome**: parameters, input path, model or commit. A run whose log does not say which configuration produced it cannot be compared with the next one.
- **Written to a file under a project-local path, flushed rather than buffered.** Stdout scrolls away and is lost on crash; a buffer loses exactly the lines that explain the crash.

## While it runs

Long jobs run in the background with the log path reported; the user watches the log, not the terminal. The global file's sync rule bites hardest here: a disabled eval, a swapped script, a zeroed interval is reported the moment it is made, not after the run ends.
