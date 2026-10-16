#!/bin/bash
# UserPromptSubmit hook. Background subagents report back as a <task-notification>
# that starts a new turn; PostToolUse on the Agent tool fires only at launch, so
# this is the moment the report is read. Adds a reminder of what tends to go
# wrong at that handoff. Notifications for background shell commands are skipped.
input=$(cat)
prompt=$(printf '%s' "$input" | jq -r '.prompt // ""')
case "$prompt" in
  *"<task-notification>"*"<summary>Agent "*) ;;
  *) exit 0 ;;
esac
jq -n --arg ctx "A subagent report has just come back. What tends to go wrong at this handoff: a claim in it does not match what its tools actually returned, or it made no tool calls at all; it reports as done something it only planned or inferred; it misread the task because it saw only the brief; a remark beyond what it was asked to do got no scrutiny from anyone. Once a claim from it enters your reasoning, a recommendation, a file, or text the user approves, it reads as fact, and inside approved text as the user's own ruling." \
  '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'
