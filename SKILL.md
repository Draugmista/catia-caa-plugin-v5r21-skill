---
name: catia-caa-plugin
description: Create, compile, install, run, and debug CATIA V5 CAA RADE plugins on this Windows CATIA V5R21 setup. Use when Codex is asked to write a CAA add-in, command, toolbar button, CATIA plugin, CNext/CNEXT extension, dico registration, mkmk build, CATSTART launch script, temporary install, or to diagnose CATIA blank gray startup, missing toolbar, frozen UI, or plugin load failures.
---

# CATIA CAA Plugin

## Core Workflow

Use this skill for small CATIA V5 CAA demo plugins and local smoke tests.

1. Inspect the existing workspace first: look for `*.dico`, `Imakefile.mk`, `IdentityCard.h`, `*.CATNls`, `Start_*.bat`, `Install_config_*`, and any working example.
2. Scaffold or modify a CAA framework/module using the local RADE layout: `<Project>\<Framework>\<Module>.m\LocalInterfaces`, `src`, `CNext\code\dictionary`, `CNext\resources\msgcatalog`, and `IdentityCard`.
3. Register add-ins in a `.dico` file and make sure command header ids, class names, module names, and NLS files match exactly.
4. Compile with the machine's RADE/Visual Studio environment, then verify that the DLL and dictionary were copied into the project's runtime `win_b64` tree.
5. Launch CATIA through `CATSTART -env -direnv`, never by bare `CNEXT.exe` with only plugin paths.
6. Verify in CATIA by opening the target workbench/document type and checking logs, process state, and CATIA `error.log`.

For compact code patterns and local commands, read `references/v5r21-workflow.md`.

## Local Assumptions

- CATIA install: `C:\DassaultSystemes\CatiaV5R21`
- RADE install: `C:\DassaultSystemes\RADEv5r21`
- Working tree for demos: `C:\CatiaTest\LYD_GG_DESIGN`
- Build env batch observed on this machine: `C:\DassaultSystemes\caa_work\mytest\test1\ToolsData\VisualStudio2008\vcenv.bat`
- Base CATIA environment file: `C:\ProgramData\DassaultSystemes\CATEnv\CATIA_P3.V5R21.B21.txt`

Confirm paths before using them. Prefer project-local CATIA env files under `<Project>\CATEnv` so tests do not pollute the user's global CATIA environment.

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

Expected runtime artifacts:

- `<Project>\win_b64\code\bin\<Module>.dll`
- `<Project>\win_b64\code\dictionary\<Framework>.dico`
- `<Project>\win_b64\resources\msgcatalog\...`

If compilation starts failing in `CATCommandHeader.h` after previous experiments, inspect the file state and any backups before changing it. This is a global CATIA header and should not be silently edited.

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
