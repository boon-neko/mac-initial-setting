---
name: plan
description: Create a detailed implementation plan for a feature or task. Use when user wants to plan before coding.
disable-model-invocation: true
---

# Create Implementation Plan

Create an implementation plan for $ARGUMENTS.

## Planning Process

### 1. Requirements Analysis

First clarify:

- **Purpose**: What to achieve
- **Scope**: What to include, what to exclude
- **Constraints**: Technical, time, dependencies

### 2. Current State Investigation

Investigate the codebase:

```
- Related existing code
- Files affected
- Libraries/patterns to use
- Existing tests
```

### 3. Break Down Implementation Steps

Break into small steps:

1. Each step is independently testable
2. Consider dependency order
3. High-risk steps first

### 4. Output Format

```markdown
## Implementation Plan: {Title}

### Purpose
{1-2 sentences}

### Acceptance Criteria
- **AC-1**: {単体で検証可能な完了条件（Given/When/Then 推奨）}
- **AC-2**: ...

### Non-Goals
- {やらないこと。最低1つ}

### Scope
- New files: {list}
- Modified files: {list}
- Dependencies: {list}

### Implementation Steps

#### Step 1: {Title}（対応AC: AC-1）
- [ ] {Specific task}
- [ ] {Specific task}
**Verification**: {Completion criteria for this step}

#### Step 2: {Title}（対応AC: AC-2）
...

### Verification Plan
| AC | 検証手段 |
|----|---------|
| AC-1 | unit test / E2E / 手動確認（手順） |

### Risks & Considerations
- {Potential issues and mitigations}

### Open Questions
- {Items to clarify before implementation}
```

## Notes

- Plans should be at actionable granularity
- Include verification method for each step
- ACが未定義なら、先に `requirements` スキル（plugin では `/orchestra:requirements`）で定義し、その成果物を転記する
- 全てのステップがいずれかのACに対応していること（対応しないステップはスコープ見直しのサイン）
- Ask questions at planning stage for unclear points
- Don't over-detail (adjust during implementation)
