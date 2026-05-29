---
name: catia-caa-plugin
description: Create, compile, install, run, and debug CATIA V5 CAA RADE plugins on this Windows CATIA V5R21 setup. Use when Codex is asked to write a CAA add-in, command, toolbar button, CATIA plugin, CNext/CNEXT extension, dico registration, mkmk build, CATSTART launch script, temporary install, locate official same-version CAA docs/examples, or diagnose CATIA blank gray startup, missing toolbar, frozen UI, build artifact, license, dictionary, or NLS failures.
---

# CATIA CAA Plugin

## Core Workflow

Use this skill for small CATIA V5 CAA demo plugins and local smoke tests.

1. Inspect the existing workspace first: look for `*.dico`, `Imakefile.mk`, `IdentityCard.h`, `*.CATNls`, `Start_*.bat`, `Install_config_*`, and any working example.
2. Search the installed CAA documentation and examples under `C:\DassaultSystemes\CatiaV5R21\CAADoc` before writing or changing CAA code. If the task category is unclear, use `references/caa-doc-navigation.md` to map the request to the right official docs and `.edu` examples first. Prefer same-version examples over memory for APIs, link modules, `.dico`, `CNext`, and `Imakefile.mk` details.
3. Scaffold or modify a CAA framework/module using the local RADE layout: `<Project>\<Framework>\<Module>.m\LocalInterfaces`, `src`, `CNext\code\dictionary`, `CNext\resources\msgcatalog`, and `IdentityCard`.
4. Register add-ins in a `.dico` file and make sure command header ids, class names, module names, and NLS files match exactly.
5. Compile with the machine's RADE/Visual Studio environment, then verify that the DLL and dictionary were copied into the project's runtime `win_b64` tree.
6. Launch CATIA through `CATSTART -env -direnv`, never by bare `CNEXT.exe` with only plugin paths.
7. Verify in CATIA by opening the target workbench/document type and checking logs, process state, and CATIA `error.log`.

For compact code patterns and local commands, read `references/v5r21-workflow.md`. For task-to-document navigation across ApplicationFrame, Dialog, DialogEngine, Product Structure, GSM, Mechanical Modeler, and Object Specs Modeler topics, read `references/caa-doc-navigation.md`. For symptom-driven debugging, read `references/troubleshooting.md`.

## Bundled Helpers

- Use `scripts/check_caa_project.ps1` before or after a build when the project shape, copied runtime artifacts, dictionary files, or message catalogs are suspect.
- Use `scripts/scan_mkmk_log.ps1` after redirecting an `mkmk` build log; classify license/setup failures separately from C++ compile/link failures.
- Keep helper output as evidence. Do not treat `mkmk` exit code alone as proof of success.

## Local Assumptions

- CATIA install: `C:\DassaultSystemes\CatiaV5R21`
- RADE install: `C:\DassaultSystemes\RADEv5r21`
- Working tree for demos: `C:\CatiaTest\LYD_GG_DESIGN`
- Build env batch observed on this machine: `C:\DassaultSystemes\caa_work\mytest\test1\ToolsData\VisualStudio2008\vcenv.bat`
- Base CATIA environment file: `C:\ProgramData\DassaultSystemes\CATEnv\CATIA_P3.V5R21.B21.txt`
- Official CAA docs/examples: `C:\DassaultSystemes\CatiaV5R21\CAADoc`

Confirm paths before using them. Prefer project-local CATIA env files under `<Project>\CATEnv` so tests do not pollute the user's global CATIA environment.

## Use Installed CAA Docs First

Before implementing a feature, use `rg` against `CAADoc` to find official V5R21 examples that match the target API or workbench. Good first searches:

```powershell
rg -n "CATIPRDWorkshopAddin|CATIWorkbenchAddin|CATStateCommand|CATDlgNotify" C:\DassaultSystemes\CatiaV5R21\CAADoc
rg -n "CATCreateClass|CATImplementClass|MacDeclareHeader|TIE_CAT" C:\DassaultSystemes\CatiaV5R21\CAADoc
rg -n "CATHybridShapeFactory|CATIGSMFactory|CreateLine|CreatePoint" C:\DassaultSystemes\CatiaV5R21\CAADoc
```

Useful areas include:

- `CAAApplicationFrame.edu` for command headers, add-ins, workbenches, workshops, menus, and toolbars.
- `CAADialog.edu` and `CAADialogEngine.edu` for dialogs and state-command interactions.
- `CAAProductStructure.edu`, `CAAAssemblyUI.edu`, and Product Structure related examples for assembly/product workbench behavior.
- `CAAGSMInterfaces.edu`, `CAAMechanicalModeler.edu`, `CAAObjectSpecsModeler.edu`, and geometry/modeler docs for creating or editing CATPart geometry.

When a matching example exists, copy its architectural pattern rather than inventing one. Use the example's `Imakefile.mk` as the starting point for link modules, then trim only after the build is stable.

## Implementation Rules

- Use Chinese for custom UI labels/messages unless the user requests English or a CATIA contract requires exact English ids.
- Keep command/header ids ASCII and stable: e.g. `HelloWorldCmdHeader`, `HelloWorldAddin`, `HelloWorldCmd`.
- For a Product Structure / Assembly toolbar, implement `CATIPRDWorkshopAddin`, tie it with `TIE_CATIPRDWorkshopAddin`, and register in `.dico` as `AddinClass CATIPRDWorkshopAddin libModuleName`.
- Use `CATStateCommand` one-shot commands for simple button actions; call `RequestDelayedDestruction()` after showing a dialog or writing a test log.
- Add only the needed link modules in `Imakefile.mk`; for a simple dialog command include `ApplicationFrame`, `CATDialogEngine`, `CATPrsWksPRDWorkshop`, and `ProductStructureUIUUID` when targeting PRDWorkshop.
- Do not modify Dassault public headers unless the user explicitly permits it. If a vendor header is already known to be corrupted, back it up before repair and restore it when asked.

## Build

Run builds from the project root after loading the RADE/VS environment:

```bat
call C:\DassaultSystemes\caa_work\mytest\test1\ToolsData\VisualStudio2008\vcenv.bat
cd /d C:\CatiaTest\LYD_GG_DESIGN\<ProjectName>
C:\DassaultSystemes\RADEv5r21\intel_a\code\command\mkmk.bat -a -u
```

For one-shot automation, it is OK to chain the same steps through `cmd /c`:

```bat
cmd /c "call C:\DassaultSystemes\caa_work\mytest\test1\ToolsData\VisualStudio2008\vcenv.bat && cd /d C:\CatiaTest\LYD_GG_DESIGN\<ProjectName> && C:\DassaultSystemes\RADEv5r21\intel_a\code\command\mkmk.bat -a -u"
```

Interpret the command in stages:

- `vcenv.bat` prepares VS2008/RADE variables such as `INCLUDE`, `LIB`, `PATH`, `Mkmk*`, and `mkcs*`.
- `cd /d <Project>` must land in the RADE project root containing `CATIAV5Level.lvl`, `Install_config_win_b64`, and framework folders.
- `mkmk.bat -a -u` builds all modules and requests runtime-view update, but `-u` does not guarantee every runtime artifact was copied. Always verify DLL, library, dictionary, and message catalogs after the build.

Expected runtime artifacts:

- `<Project>\win_b64\code\bin\<Module>.dll`
- `<Project>\win_b64\code\dictionary\<Framework>.dico`
- `<Project>\win_b64\resources\msgcatalog\...`

If compilation starts failing in `CATCommandHeader.h` after previous experiments, inspect the file state and any backups before changing it. This is a global CATIA header and should not be silently edited.

## Build Preflight And Pitfalls

Before running `mkmk`, verify root control files and direct dependencies:

- `CATIAV5Level.lvl` must be the real CAA level header, not a tiny placeholder or missing file.
- `Install_config_win_b64` should point to the CATIA install, usually:
  `<Install> compatible`
  `C:\DassaultSystemes\CatiaV5R21`
- `IdentityCard.h` must declare each framework used by `LINK_WITH` as a direct prerequisite. If `mkmk` says a linked module is ignored because it is not a direct prerequisite, add the owning framework to `IdentityCard.h`.
- A `Start_*.bat` file may be empty in unfinished projects; do not treat its presence as proof that runtime launch is ready.

Do not trust `mkmk` exit code alone. It may return success while printing build failures. Always scan output for `mkmk-ERROR`, `make-ERROR`, `syst-ERROR`, `fatal error`, and `error C`.

Differentiate license/setup failures from C++ compile failures. If output contains `RequestLicensesFromSettings` and text like `the requested licenses do not authorize the given product, MAB`, the command may not have reached source compilation; inspect CATIA/RADE license settings instead of changing C++ code.

On this machine, `mkmk` can fail the MAB authorization check under a sandbox/offline execution user while succeeding as the real Windows user. Before treating `MAB` as a project or C++ problem, retry the same command with real-user/escalated execution and compare shell fingerprints. A successful environment observed here has:

- `whoami=desktop-c64rlob\carcharoth`
- `USERNAME=Carcharoth`
- `USERPROFILE=C:\Users\Carcharoth`
- `RADECATSettingPath=C:\Users\Carcharoth\AppData\Roaming\DassaultSystemes\CATSettings\RADE`
- `__COMPAT_LAYER=ElevateCreateProcess`
- `MkmkROOT_PATH=C:\DASSAU~1\RADEV5~1\intel_a`
- `MkmkINSTALL_PATH=C:\DASSAU~1\RADEV5~1`

When comparing two agents/shells, use delayed expansion so values after `vcenv.bat` are not hidden by early `%VAR%` expansion:

```bat
cmd /v:on /c "whoami && echo USERNAME=!USERNAME! && echo USERPROFILE=!USERPROFILE! && echo CD=!CD! && echo before_RADECATSettingPath=!RADECATSettingPath! && echo before_COMPAT=!__COMPAT_LAYER! && call C:\DassaultSystemes\caa_work\mytest\test1\ToolsData\VisualStudio2008\vcenv.bat >nul && echo after_RADECATSettingPath=!RADECATSettingPath! && echo after_COMPAT=!__COMPAT_LAYER! && echo TCK_TMP_FILE=!TCK_TMP_FILE! && echo MkmkROOT_PATH=!MkmkROOT_PATH! && echo MkmkINSTALL_PATH=!MkmkINSTALL_PATH! && dir /a "!RADECATSettingPath!""
```

For reproducible diagnosis, redirect build logs and scan them before drawing conclusions:

```bat
cmd /c "call C:\DassaultSystemes\caa_work\mytest\test1\ToolsData\VisualStudio2008\vcenv.bat >nul && cd /d <Project> && C:\DassaultSystemes\RADEv5r21\intel_a\code\command\mkmk.bat -a -u > mkmk_build.log 2>&1"
```

If `mkmk` succeeds but DLL timestamps do not change, it may have decided everything is up to date. Compare source, object, and runtime artifact timestamps such as `<Module>.cpp`, `Objects\win_b64\<Module>.obj`, and `win_b64\code\bin\<Module>.dll` before assuming a change was compiled.

For V5R21-specific C++ issues:

- Check installed headers before using UI constants. `CATGRID_VCENTER` is not available in this V5R21 install; use supported constants such as `CATGRID_LEFT`, `CATGRID_RIGHT`, `CATGRID_CENTER`, and `CATGRID_4SIDES`.
- Use `CATListOfCATBaseUnknown.h` for `CATListValCATBaseUnknown_var`; do not invent include names.
- Avoid non-ASCII C++ string literals with VS2008/mkmk unless the source encoding is proven compatible. Prefer localized UI text in `.CATNls`; use ASCII literals when the priority is getting a clean DLL build.

After a successful link, verify runtime artifacts, not just object files:

- `<Project>\win_b64\code\bin\<Module>.dll`
- `<Project>\win_b64\code\lib\<Module>.lib`
- `<Project>\win_b64\code\dictionary\<Framework>.dico`
- `<Project>\win_b64\resources\msgcatalog\...`

If `.dico` was not copied into `win_b64\code\dictionary`, copy it from `<Framework>\CNext\code\dictionary`; without it CATIA will not discover the add-in even when the DLL exists.

## Launch And Test

Create a project-local env file by copying the base CATIA env and prepending plugin paths:

- `CATDLLPath=<Project>\win_b64\code\bin;C:\DassaultSystemes\CatiaV5R21\win_b64\code\bin`
- `CATDictionaryPath=<Project>\win_b64\code\dictionary;C:\DassaultSystemes\CatiaV5R21\win_b64\code\dictionary`
- `CATMsgCatalogPath=<Project>\win_b64\resources\msgcatalog;C:\DassaultSystemes\CatiaV5R21\win_b64\resources\msgcatalog`
- `PATH=<Project>\win_b64\code\bin;C:\DassaultSystemes\CatiaV5R21\win_b64\code\bin;C:\DassaultSystemes\CatiaV5R21\win_b64\code\command;%JAVA_HOME%\bin;%PATH%`

Use a launcher like:

```bat
@echo off
setlocal
set "PROJECT_HOME=C:\CatiaTest\LYD_GG_DESIGN\<ProjectName>"
set "CATSTART=C:\DassaultSystemes\CatiaV5R21\win_b64\code\bin\CATSTART.exe"
start "CATIA <ProjectName>" "%CATSTART%" -run "CNEXT.exe" -env <EnvName> -direnv "%PROJECT_HOME%\CATEnv"
```

If CATIA opens as a gray blank frame with no menus/toolbars, suspect startup environment first. Check whether CATIA was launched as bare `CNEXT.exe`; this usually means core CATIA dictionary/msgcatalog/command paths were not loaded.

## Diagnostics

- Check process state: `Get-Process CNEXT -ErrorAction SilentlyContinue | Select Id, MainWindowTitle, Responding`
- Check command line when permissions allow: `Get-CimInstance Win32_Process -Filter "Name='CNEXT.exe'" | Select ProcessId, CommandLine`
- Check CATIA log: `%LOCALAPPDATA%\DassaultSystemes\CATTemp\error.log`
- If the plugin button is missing but CATIA UI is normal, inspect `.dico`, add-in interface, NLS/header ids, and whether the target workbench is active.
- If CATIA exits normally after launch, verify the user did not close it and inspect the latest `error.log` line for `normal_end` vs `abend`.


