# CAA Bridges To External Tools And Embedded Python

Use this reference when a CATIA V5R21 CAA command exports model data to a CLI, launches an external calculation, or ships an embedded Python runtime with the plugin.

## Separate Reference Data From Instance State

- A repeated CATPart reference may share one parsed reference-tree result, but each Product instance has its own placement.
- Cache immutable reference-level data only. Call `CATIMovable::GetAbsPosition()` for every instance.
- Apply the complete transform to points and positions. Apply only the rotation component to forces, directions, normals, and other free vectors.

## Prompt For A Single Output Path

- A simple export command can use `CATDlgFile` with `CATDlgFileSave`, `SetFilterStrings()`, `SetFileName()`, and `GetSelection()`.
- Do not add a separate parameter dialog when the only required input is an output filename.

## Structured Process Boundary

- Serialize bridge DTOs as UTF-8 JSON with a real writer or DOM API. Do not build JSON by concatenating quotes, commas, and braces.
- Transfer required engineering semantics as explicit typed fields with fixed units and stable input ordering. Do not make a downstream tool reconstruct scalar values from optional presentation geometry when the authoritative CAA workflow can persist and export those values directly.
- Keep reusable computation engines on the external-tool side when they already have a stable ABI there. For example, a Rust/PyO3 algorithm should usually stay as a Python extension behind the CLI JSON contract; let CAA scan CATIA candidates, validate identities, and transactionally write geometry instead of loading a Rust DLL directly into the CATIA process.
- When a downstream generation step lacks a real catalog or selection database, model that gap as an explicit replaceable strategy layer in the external tool. Return placeholder status and typed placeholder fields rather than pushing catalog semantics into the topology solver or CAA geometry writer.
- On VS2008-era modules, vendor and pin a small header-only implementation that is proven to compile in the RADE build. `RapidJSON 1.1.0` is one observed option, but verify it with the module's real PCH and include order.
- Launch the child process with `CreateProcessW()`, a hidden window, explicit argument quoting, and redirected output. Capture both process exit status and diagnostic output.
- Treat the temporary JSON and process log as a reproducibility boundary: delete them after success, but retain and report their paths after failure.
- Separate cross-process diagnostics by purpose: use the plugin's shared log for scan and invocation summaries, redirected stdout/stderr for one-run diagnostics, and a rotating child-tool log for internal validation, adaptation, rendering, and save stages.
- Retain and rotate the child-tool log across runs. All logging must remain best effort: setup or write failures must not replace the tool's business exit status.
- Log stable operation names, executable paths, result status, and failure reason. Do not duplicate full JSON payloads, model coordinates, vectors, generated entities, or other sensitive business data.

## External Interactive Editors

- When an external GUI provides richer 2D interaction but CAA must modify the CATPart, export stable model identities plus read-only geometry DTOs. Let the GUI return topology and user intent, then rescan the model and perform authoritative calculations and writes in CAA.
- Treat external preview coordinates and calculated values as visualization aids, not committed model results. Revalidate identities, availability, units, and dependencies immediately before applying the requested operation.

## Embedded Python Runtime

- A formal release must not depend on a source-tree `.venv`. Package a runtime and required dependencies, or provide a separately verified installation procedure.
- When several Python bridge tools ship together, reuse one verified embedded Python runtime and stage each tool's wrapper plus `site-packages` in separate directories.
- Give every packaged tool its own import smoke test and CLI `--help` gate. After all gates pass, clean `__pycache__` and `*.pyc` again before creating the final archive.
- Prefer a small wrapper script as the embedded-runtime entry point instead of relying on `python -m package`. The wrapper can add the bundled tool root and `site-packages` to `sys.path` before delegating to the package CLI.
- Keep runtime and tool locations centralized in environment variables so development and installed layouts can override them without rebuilding the DLL.
- If environment variables are absent, derive the installed tool directory relative to the calling DLL with `GetModuleFileNameW()`. Do not compile developer-workspace absolute paths into release binaries.
- For Tkinter-based tools, package the matching standard-library `tkinter` package and Tcl/Tk runtime directories, not only `python.exe` and third-party `site-packages`. Run the packaged interpreter through a real `import tkinter` smoke gate while constructing the release.

## V5R21 Compiler And PCH Constraints

- CATIA and MFC compatibility macros can pollute VS2008 standard-library headers. In translation units that use STL-heavy or vendored header-only code, include required standard-library headers before CATIA headers when the module's established PCH contract permits it.
- Treat the RADE-generated PCH and the real `mkmk` build as authoritative. Standalone checks must reproduce that contract; arbitrary forced includes such as `/FIafxwin.h` can create false `WINDOWS.H already included` or standard-library syntax failures.
- When a new dependency fails inside `<new>`, `<limits>`, `<locale>`, `<functional>`, or similar headers, inspect macro and include order before rewriting otherwise valid library code.
