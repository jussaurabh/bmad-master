---
skill: ci-cd-patterns
category: infrastructure
type: patterns
description: "Configure reliable, fast, and maintainable CI/CD pipelines"
---

# Skill: CI/CD Pipeline Patterns

## PURPOSE
Configure CI/CD pipelines that are reliable, fast, and maintainable.

## PIPELINE STAGES

```
Install -> Lint -> Test -> Build -> Deploy
```

1. **Install**: Dependencies with lockfile (`npm ci`, `pip install -r requirements.txt`)
2. **Lint**: Linters and formatters (eslint, prettier, pylint, black)
3. **Test**: Unit and integration tests with coverage
4. **Build**: Compile, bundle, create artifacts
5. **Deploy**: Push to target environment

## GITHUB ACTIONS PATTERNS

### Node.js CI
```yaml
name: CI
on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run test -- --coverage
      - run: npm run build
```

### Python CI
```yaml
name: CI
on: [push, pull_request]

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'
      - run: pip install -r requirements.txt -r requirements-dev.txt
      - run: black --check . && pylint src/
      - run: pytest --cov=src tests/
```

## CACHING STRATEGIES

- Cache `node_modules` based on `package-lock.json` hash
- Cache `pip` based on `requirements.txt` hash
- Cache Docker layers for build steps

## BRANCH STRATEGIES

```
main     -> production deployment (auto-deploy on merge)
develop  -> staging deployment (auto-deploy on merge)
feature/ -> CI only (lint + test + build, no deploy)
hotfix/  -> fast-track to main with CI
```

## BEST PRACTICES

- **Fail fast**: Put the fastest checks first (lint before test before build)
- **Parallel when possible**: Run lint and test in parallel if independent
- **Pin versions**: Pin action versions, dependency versions, base images
- **Secrets via CI**: Use GitHub Secrets / CI platform secret management
- **Artifact storage**: Save build artifacts for deployment (don't rebuild in deploy stage)
- **Notifications**: Alert on failure, don't spam on success
