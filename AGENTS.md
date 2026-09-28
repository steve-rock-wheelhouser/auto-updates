# Mandatory Version Bump and Changelog Policy

## Core Principle
Never make source code modifications without an explicit version increment and a clear, descriptive changelog entry.

## Rules for Every Code Modification
Whenever making ANY code changes, refactors, bug fixes, or new features in this repository:

1. **Increment Version**:
   - Update `VERSION` in the primary application entry point (`src/main.sh`).
   - Synchronize `VERSION` in `bin/auto-updates`, `build_rpm.sh`, and `auto-updates.spec` (`Version:` and `%changelog`).

2. **Add Header Changelog Entry**:
   - Add a numbered version entry to the top header / changelog comment section of `src/main.sh`:
     `# X.Y.Z - Clear explanation of the fix or feature.`
   - Append a corresponding `%changelog` entry in `auto-updates.spec`.
   - Ensure the summary accurately describes the changes made so all developers, packagers, and automated systems have an immediate source of truth.

3. **Zero Unversioned Code Changes**:
   - No silent or untracked changes. Every edit must be tied to a documented version increment.

4. **Quality Benchmark**:
   - All RPM packaging must maintain 0 errors and 0 warnings under `rpmlint`.

5. **Commit Changes**:
   - Commit changes with a clear and descriptive commit message.
