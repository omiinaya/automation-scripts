# Contributing

## Getting Started

Clone the repo and review existing scripts for patterns:

```bash
git clone https://github.com/omiinaya/automation-scripts.git
cd automation-scripts
```

## Script Style

- PowerShell scripts use `PascalCase` for functions
- Include `#Requires -RunAsAdministrator` where applicable
- Add comment-based help blocks
- Handle errors with `try/catch`

## Testing

Tests are in the `tests/` directory. Run with Pester on Windows.

## Commit Messages

```
type: concise subject
```

Types: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`
