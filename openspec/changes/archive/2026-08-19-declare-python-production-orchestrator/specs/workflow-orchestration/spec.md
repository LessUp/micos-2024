# Workflow Orchestration Change Specification

## ADDED Requirements

### Requirement: Single production orchestrator
The project SHALL designate `micos full-run` and its Python implementation as the sole production orchestration and parameter-semantics authority.

#### Scenario: User chooses a supported full run
- **WHEN** a user follows the primary full-analysis documentation
- **THEN** the documented entry point SHALL be `micos full-run`

### Requirement: Shell wrapper remains thin
The full-analysis shell script SHALL be documented as a wrapper around the Python CLI and SHALL NOT define a second workflow contract.

#### Scenario: Wrapper documentation
- **WHEN** a user inspects the shell entry point
- **THEN** its supported options and behavior SHALL point to the Python CLI contract

### Requirement: WDL status is experimental
Existing WDL files SHALL be labeled experimental single-step references until a top-level workflow, pinned runtime inputs and executable validation exist.

#### Scenario: User reads WDL documentation
- **WHEN** WDL is presented in README or `steps/` documentation
- **THEN** it SHALL NOT be described as equivalent to the production Python full run
- **AND** its missing production prerequisites SHALL be stated

### Requirement: Resume is not promised
The current project documentation SHALL state that full-run resume/skip semantics are unsupported.

#### Scenario: User searches for recovery behavior
- **WHEN** the user reads current full-run usage and limitations
- **THEN** the documentation SHALL NOT claim checkpoint resume or automatic recovery
- **AND** SHALL NOT suggest output-directory existence as a safe resume condition

### Requirement: Orchestration claims remain consistent
README, CLI help, project docs and contributor guidance SHALL use the same support classification for Python, shell, WDL and resume.

#### Scenario: Documentation audit
- **WHEN** current capability claims are searched across active documentation
- **THEN** no active page SHALL contradict the support matrix
