# Configuration Change Specification

## ADDED Requirements

### Requirement: Production configuration rejects unknown fields
The production configuration model SHALL use `extra="forbid"` so that unknown fields
fail validation instead of being silently allowed.

#### Scenario: Unknown field in YAML
- **GIVEN** a configuration YAML containing a field not declared by the model
- **WHEN** `micos --config ... full-run` loads it
- **THEN** the command SHALL exit with a configuration error naming the unknown field
- **AND** SHALL NOT start any external tool

#### Scenario: Wrong field type
- **GIVEN** a configuration YAML whose value type does not match the model
- **WHEN** the configuration is loaded
- **THEN** validation SHALL fail with a configuration error

### Requirement: Templates contain only wired fields
`analysis.yaml.template` and other active config templates SHALL contain only fields
that are wired into the CLI; vision parameters SHALL move to roadmap documentation and
SHALL NOT remain in an executable template.

#### Scenario: User copies the template
- **WHEN** a user configures from the active template
- **THEN** every template field SHALL be observable in the `--dry-run` resolved plan
- **AND** no unimplemented vision parameter SHALL be required

### Requirement: Unimplemented resource fields are absent
Fields that drift from implemented behavior (e.g. `max_memory`/`memory_gb`) SHALL NOT
appear in active configuration until a corresponding resource limit is implemented.

#### Scenario: User reads the active template
- **WHEN** a user inspects `config/*.template`
- **THEN** no unimplemented `memory_gb`/`max_memory` field SHALL be present

### Requirement: Configuration failures fail closed
YAML syntax or Pydantic validation failures SHALL make `micos ... full-run` exit with a
configuration error; the CLI SHALL NOT warn and fall back to defaults.

#### Scenario: Corrupted YAML
- **GIVEN** a syntactically invalid YAML configuration file
- **WHEN** `micos --config ... full-run` runs
- **THEN** it SHALL exit non-zero with a configuration error
- **AND** SHALL NOT use default values and continue

### Requirement: Configuration precedence is explicit and traceable
Effective values SHALL follow the precedence: explicit CLI argument > `analysis.yaml` >
corresponding database value in `databases.yaml` > code default. On request, the
resolved value SHALL report its source.

#### Scenario: CLI overrides file
- **GIVEN** a value set both in `analysis.yaml` and as an explicit CLI argument
- **WHEN** the resolved plan is computed
- **THEN** the CLI value SHALL win and its source SHALL be reported

#### Scenario: Conflicting database sources
- **GIVEN** the same database key with different values in two database config sources
- **WHEN** the resolved plan is computed
- **THEN** the conflict SHALL be resolved by precedence or reported as an error

### Requirement: Relative paths resolve against the containing config file
Relative paths in a configuration SHALL resolve relative to the directory of the
configuration file that contains them, not the process working directory.

#### Scenario: Config in another directory
- **GIVEN** a config file in directory `/a` referencing a relative path
- **WHEN** the command runs from a different working directory
- **THEN** the path SHALL resolve against `/a`

### Requirement: validate-config fails on invalid configuration
`validate-config` SHALL return non-zero for syntax errors, unknown fields, and missing
required stage dependencies; placeholders and optional databases SHALL be warnings.

#### Scenario: Invalid configuration
- **GIVEN** a configuration with a syntax error, unknown field, or missing required stage
- **WHEN** `validate-config` runs
- **THEN** it SHALL exit non-zero and list the problems

### Requirement: Dry-run emits a resolved plan without executing tools
`micos ... --dry-run` SHALL print a resolved plan listing stage, input, output, threads,
databases and parameter sources, and SHALL NOT execute any external tool.

#### Scenario: Dry-run on valid config
- **GIVEN** a valid configuration and `--dry-run`
- **WHEN** the command runs
- **THEN** the resolved plan SHALL be printed with each field and its source
- **AND** no external analysis tool SHALL be invoked

### Requirement: Configuration errors surface at the CLI boundary
Configuration failures SHALL NOT be swallowed by broad `except Exception`; known
configuration exceptions SHALL be converted to a stable non-zero exit code at the CLI
boundary.

#### Scenario: Configuration exception
- **GIVEN** any known configuration failure
- **WHEN** the CLI processes it
- **THEN** the failure SHALL surface as a stable non-zero exit code with a clear message
