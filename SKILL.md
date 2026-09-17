---
name: catia-caa-plugin
description: Create, inspect, compile, install, run, and debug CATIA V5 CAA RADE plugins on this local Windows CATIA V5R21 setup. Use for CAA add-ins, commands, toolbars, Part or Product Structure workbench extensions, CATPart geometry and instance operations, assembly constraints, CNext resources and dico registration, mkmk builds, CATSTART environments, external CLI or embedded Python bridges, release packaging, and diagnosis of build, license, dictionary, NLS, toolbar, startup, or UI failures.
---

# CATIA CAA Plugin

## Execution Contract

- Match the requested scope. For inspection, explanation, review, or diagnosis, inspect and report evidence without compiling, installing, or launching CATIA unless the user requests those actions or they are required to verify an authorized fix.
- Treat source changes, `mkmk` compilation, runtime installation, and CATIA launch as separate execution levels. Do not infer later levels from an earlier one.
- Do not run CATIA CAA `mkmk` in sandboxed or offline execution. Request real Windows user or escalated execution from the start.
- Never judge a build only by the `mkmk` process exit code. Scan its redirected log and verify the expected runtime artifacts.
- Launch CATIA only through `CATSTART -env -direnv` with a project-local environment. Never launch bare `CNEXT.exe` with only plugin paths.
- Stop CATIA UI automation after launch and non-interactive process/window checks. Ask the user to perform workbench, document, toolbar, dialog, and model interactions manually.
- Do not modify Dassault public headers unless the user explicitly permits it. Preserve a backup and diagnostic evidence if repair is authorized.

## Core Workflow

1. Determine the requested execution level and acceptance evidence before changing state.
2. Inspect the workspace for `*.dico`, `Imakefile.mk`, `IdentityCard.h`, `*.CATNls`, `*.CATRsc`, `Start_*.bat`, `Install_config_*`, project-local `CATEnv` files, and a working neighboring module.
3. Search the installed V5R21 CAA documentation and `.edu` examples before designing or changing code. Prefer same-version APIs, project layouts, link modules, dictionary registrations, and resource conventions over memory.
4. Read only the task-relevant reference listed below, then compare the target module with the closest official or known-good local example.
5. Implement the smallest compatible change. Keep class names, module names, command/header ids, dictionary entries, TIE bindings, NLS keys, and runtime resource names exact.
6. Run `scripts/check_caa_project.ps1` when project shape or runtime copies matter. Treat exit `2` as missing required structure and exit `1` as warnings that require review.
7. Compile only when the requested scope or verification requires it. Use the real RADE/Visual Studio environment and redirect the complete `mkmk` output to a log.
8. Run `scripts/scan_mkmk_log.ps1`, fix the first failing layer, and verify DLL, import library, dictionary, message catalogs, and graphic resources as applicable.
9. Install or launch only when authorized. After launch, hand off a concrete manual UI checklist to the user and use their observations plus CATIA logs for follow-up diagnosis.

## Reference Routing

- Read `references/caa-doc-navigation.md` when the task category or official document/example location is unclear.
- Read `references/v5r21-workflow.md` for local project shape, compact CAA code patterns, build commands, CATEnv setup, launch procedure, UI handoff, and release guardrails.
- Read `references/part-workbench-geometry.md` for Part add-ins, NLS and icons, dialogs and selection agents, GSM geometry, sketches, pads, persistent Part metadata, temporary annotations, and batch geometry safety.
- Read `references/product-structure-assembly.md` for CATPart insertion, instance transforms, Product metadata, assembly constraints, tree refresh, transactional creation, and cross-module service boundaries.
- Read `references/external-tool-bridges.md` for CAA-to-CLI processes, structured JSON exchange, external GUI editors, embedded Python runtimes, and release-time tool discovery.
- Read `references/troubleshooting.md` after the normal workflow stalls or when symptoms involve startup, missing UI, stale resources, build/license context, link warnings, editor lifecycle, or shell-environment differences.

## Bundled Helpers

### Project preflight

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\check_caa_project.ps1 -ProjectRoot <Project>
```

Interpret the result as:

- Exit `0`: no missing items or warnings were found.
- Exit `1`: required structure is present, but optional or runtime items need review.
- Exit `2`: required project structure is missing.

Keep the full per-item output and summary as evidence.

### Build-log scan

Run:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\scan_mkmk_log.ps1 -LogPath <BuildLog>
```

Interpret the result as:

- Exit `0`: no known error or warning patterns were found.
- Exit `1`: reviewable warnings were found.
- Exit `2`: build-system, compile, link, or build-gate failure was found.
- Exit `3`: RADE/CATIA MAB license or execution-context failure was found.

Treat `LNK4006` and `LNK4088` as failed build gates. Do not classify every `warning LNKxxxx` as fatal.

## Local Environment Profile

Confirm every path before using it:

- CATIA install: `C:\DassaultSystemes\CatiaV5R21`
- RADE install: `C:\DassaultSystemes\RADEv5r21`
- Demo working tree: `C:\CatiaTest\LYD_GG_DESIGN`
- Observed build environment: `C:\DassaultSystemes\caa_work\mytest\test1\ToolsData\VisualStudio2008\vcenv.bat`
- Base CATIA environment: `C:\ProgramData\DassaultSystemes\CATEnv\CATIA_P3.V5R21.B21.txt`
- Official CAA docs/examples: `C:\DassaultSystemes\CatiaV5R21\CAADoc`

Prefer project-local CATIA environment files under `<Project>\CATEnv` so development tests do not modify the global CATIA environment.

## Implementation Guardrails

- Use Chinese for custom UI labels and messages unless the user requests another language or CATIA requires an exact contract string.
- Keep command ids, header ids, class ids, schema keys, and machine-matching aliases stable ASCII.
- Use the closest installed V5R21 sample as the starting architecture. Derive `LINK_WITH` and `IdentityCard.h` prerequisites from the owning official framework rather than guessing from class names.
- Do not remove a CAA prerequisite merely because the list is large or a current build links. Require an evidence chain through the consuming module, `LINK_WITH`, direct APIs, and same-version headers or CAADoc; retain protected runtime/interface companions unless a validated replacement proves removal safe.
- Keep `.dico` registrations one-to-one with implemented TIE bindings and target-workbench interfaces.
- Put localized user-facing strings in `.CATNls` when possible. Prove source and catalog encoding compatibility with VS2008 and Chinese CATIA before using non-ASCII C++ literals.
- Preserve actionable errors and add proportionate logging around add-in initialization, dynamic loading, external processes, save/rollback, and batch item failures.
- For multi-item model changes, preflight first, track mutations, isolate per-item failures where appropriate, and roll back transactional operations in reverse order.
- Keep development `win_b64` outputs and machine-specific CATEnv files out of source control and formal release packages unless the project explicitly defines otherwise.

## Completion Evidence

- Inspection or diagnosis: report the first failing layer, supporting file/log evidence, and unresolved uncertainty; do not claim a fix.
- Source change: report changed modules/resources and relevant compatibility impact.
- Build verification: provide the build-log classification and verified artifact paths or timestamps.
- Runtime installation: verify copied DLL, dictionary, NLS/RSC, and icon resources as applicable.
- CATIA launch: report process/window health and provide the exact manual UI checks for the user.
- Release work: follow `references/v5r21-workflow.md` and the repository release rules; verify the staged minimal package rather than shipping the entire `win_b64` tree.
