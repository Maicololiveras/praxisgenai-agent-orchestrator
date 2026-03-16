# Gemini Skills Table Patch

Add this row to the Skills table in your `GEMINI.md` file, inside the `### Framework/Library Detection` section:

```markdown
| Multi-agent coordination, phased work, SDD routing | agent-team-orchestrator |
```

This triggers the orchestrator skill whenever Gemini detects multi-agent coordination patterns, phased work requests, or SDD routing commands in the user's input.

## Full table example after patching

```markdown
### Framework/Library Detection

| Context                         | Skill to load |
| ------------------------------- | ------------- |
| Go tests, Bubbletea TUI testing | go-testing    |
| Creating new AI skills          | skill-creator |
| Multi-agent coordination, phased work, SDD routing | agent-team-orchestrator |
```
