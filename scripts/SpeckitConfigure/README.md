# SpeckitConfigure

Multi-language SpecKit initializer for creating new projects with TDD support.

## Structure

```
scripts/SpeckitConfigure/
├── build.sh              # Build script
├── src/
│   ├── common.sh         # Shared functions and variables
│   ├── phase-constitution.sh  # Constitution generation
│   ├── phase-scaffold.sh      # Language-specific scaffolding
│   ├── phase-config.sh        # SpecKit config creation
│   └── phase-init.sh          # SpecKit init execution
```

## Usage

```bash
./bin/speckit-configure [OPTIONS] <project-dir>
```

See `./bin/speckit-configure --help` for options.