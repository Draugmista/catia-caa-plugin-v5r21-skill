# CATIA V5R21 CAA Local Workflow

## Contents

- [Start With Installed Documentation](#start-with-installed-documentation)
- [Minimal Product Structure Button](#minimal-product-structure-button)
- [Required Files](#required-files)
- [Imakefile Pattern](#imakefile-pattern)
- [Build Commands](#build-commands)
- [Build Preflight](#build-preflight)
- [Build Failure Triage](#build-failure-triage)
- [CATSTART Test Environment](#catstart-test-environment)
- [UI Test Handoff Checklist](#ui-test-handoff-checklist)
- [Release Packaging Guardrails](#release-packaging-guardrails)

## Start With Installed Documentation

This machine includes official CAA V5R21 documentation and examples under:

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc
```

Use these examples as the primary reference before writing code. They are same-version sources for CAA idioms, link modules, command headers, dictionary registration, `CNext` resources, and RADE project layout.

Search examples with `rg`:

```powershell
rg -n "CATIPRDWorkshopAddin" C:\DassaultSystemes\CatiaV5R21\CAADoc
rg -n "CATStateCommand" C:\DassaultSystemes\CatiaV5R21\CAADoc
rg -n "CATDlgNotify" C:\DassaultSystemes\CatiaV5R21\CAADoc
rg -n "CATHybridShapeFactory|CATIGSMFactory" C:\DassaultSystemes\CatiaV5R21\CAADoc
```

Representative places to look:

- `C:\DassaultSystemes\CatiaV5R21\CAADoc\CAAApplicationFrame.edu` for add-ins, command headers, workbenches, workshops, menus, and toolbar patterns.
- `C:\DassaultSystemes\CatiaV5R21\CAADoc\CAADialog.edu` and `CAADialogEngine.edu` for dialog and state-command examples.
- `C:\DassaultSystemes\CatiaV5R21\CAADoc\CAAAssemblyUI.edu` and Product Structure related docs for product/assembly UI integration.
- Geometry/modeler docs such as `CAAGSMInterfaces.edu`, `CAAMechanicalModeler.edu`, and `CAAObjectSpecsModeler.edu` for point/line/feature creation patterns.

When a matching official sample has an `Imakefile.mk`, use it to infer required link modules. CAA link dependencies are version-sensitive; avoid guessing them from class names alone.

## Minimal Product Structure Button

Use this pattern for a demo button in Product Structure / Assembly.

Dictionary:

```text
# Dictionary <Framework>.dico

    <AddinClass>    CATIPRDWorkshopAddin    lib<ModuleName>
```

Add-in source essentials:

```cpp
#include "<AddinClass>.h"

#include "CATCommandHeader.h"
#include "CATCreateWorkshop.h"
#include "CATIPRDWorkshopAddin.h"

MacDeclareHeader(<CommandHeaderClass>);

CATImplementClass(<AddinClass>, Implementation, CATBaseUnknown, CATnull);

void <AddinClass>::CreateCommands()
{
  new <CommandHeaderClass>("<CommandHeaderId>",
                           "<CommandModuleOrCatalog>",
                           "<CommandClass>",
                           (void*)NULL);
}

CATCmdContainer* <AddinClass>::CreateToolbars()
{
  NewAccess(CATCmdContainer, pToolbarContainer, <ToolbarId>);
  NewAccess(CATCmdStarter, pCommandStarter, <StarterId>);

  SetAccessCommand(pCommandStarter, "<CommandHeaderId>");
  SetAccessChild(pToolbarContainer, pCommandStarter);

  AddToolbarView(pToolbarContainer, 1, Top);
  return pToolbarContainer;
}

#include "TIE_CATIPRDWorkshopAddin.h"
TIE_CATIPRDWorkshopAddin(<AddinClass>);
```

One-shot command essentials:

```cpp
#include "<CommandClass>.h"

#include "CATApplicationFrame.h"
#include "CATDlgNotify.h"
#include "CATCreateExternalObject.h"

CATCreateClass(<CommandClass>);

<CommandClass>::<CommandClass>()
  : CATStateCommand("<CommandClass>", CATDlgEngOneShot, CATCommandModeExclusive)
{
  CATDlgNotify* notify = new CATDlgNotify(
      (CATApplicationFrame::GetApplicationFrame())->GetMainWindow(),
      "<DialogId>",
      CATDlgNfyInformation | CATDlgNfyOK | CATDlgWndModal);
  notify->SetText("HelloWorld");
  notify->SetVisibility(CATDlgShow);

  RequestDelayedDestruction();
}

void <CommandClass>::BuildGraph()
{
}
```

## Required Files

Recommended project shape:

```text
<Project>\
  CATIAV5Level.lvl
  Install_config_win_b64
  Start_<Project>_CATIA.bat
  CATEnv\<EnvName>.txt
  <Framework>\
    PublicInterfaces\<Framework>.h
    IdentityCard\IdentityCard.h
    <Module>.m\
      Imakefile.mk
      LocalInterfaces\<AddinClass>.h
      LocalInterfaces\<CommandClass>.h
      src\<AddinClass>.cpp
      src\<CommandClass>.cpp
    CNext\
      code\dictionary\<Framework>.dico
      resources\msgcatalog\<AddinClass>.CATNls
      resources\msgcatalog\<CommandHeaderId>.CATNls
      resources\msgcatalog\<CommandClass>.CATNls
```

Keep generated `Objects`, `ImportedInterfaces`, and `win_b64` outputs out of hand-written explanations unless debugging build output.

## Imakefile Pattern

For a simple Product Structure toolbar button with a notification dialog:

```make
BUILT_OBJECT_TYPE=SHARED LIBRARY

WIZARD_LINK_MODULES = JS0GROUP \
JS0FM JS0GROUP ApplicationFrame CATAfrUUID \
DI0PANV2 CATDialogEngine CATPrsWksPRDWorkshop ProductStructureUIUUID

LINK_WITH = $(WIZARD_LINK_MODULES)

OS = AIX
OS = HP-UX
OS = IRIX
OS = SunOS
OS = Windows_NT
```

## Build Commands

Route each complete `mkmk` output to a stable, project-specific directory under `%TEMP%`, outside both the source tree and the release tree. Create the directory if necessary, overwrite the standard log for each build, and scan it immediately; archive a scanned copy only when audit evidence is actually needed.

```bat
set "CAA_BUILD_LOG_DIR=%TEMP%\<ProjectName>\build-logs"
if not exist "%CAA_BUILD_LOG_DIR%" mkdir "%CAA_BUILD_LOG_DIR%"
if not exist "%CAA_BUILD_LOG_DIR%" exit /b 1
call C:\DassaultSystemes\caa_work\mytest\test1\ToolsData\VisualStudio2008\vcenv.bat
cd /d C:\CatiaTest\LYD_GG_DESIGN\<ProjectName>
C:\DassaultSystemes\RADEv5r21\intel_a\code\command\mkmk.bat -a -u > "%CAA_BUILD_LOG_DIR%\mkmk_build.log" 2>&1
```

Equivalent one-shot form:

```bat
cmd /c "call C:\DassaultSystemes\caa_work\mytest\test1\ToolsData\VisualStudio2008\vcenv.bat && cd /d C:\CatiaTest\LYD_GG_DESIGN\<ProjectName> && C:\DassaultSystemes\RADEv5r21\intel_a\code\command\mkmk.bat -a -u"
```

Read this as three separate stages:

1. `vcenv.bat` sets the VS2008/RADE build environment (`INCLUDE`, `LIB`, `PATH`, `Mkmk*`, `mkcs*`, and related variables).
2. `cd /d <Project>` selects the RADE project root. This directory must contain `CATIAV5Level.lvl`, `Install_config_win_b64`, and the framework folders.
3. `mkmk.bat -a -u` builds all modules and asks RADE to update the runtime view. Do not assume `-u` copied everything; verify `win_b64` artifacts afterward.

## Build Preflight

Check these files before compiling a copied or newly generated project:

```powershell
Get-Item <Project>\CATIAV5Level.lvl
Get-Content <Project>\Install_config_win_b64
Get-Content <Project>\<Framework>\IdentityCard\IdentityCard.h
Get-Content <Project>\<Framework>\<Module>.m\Imakefile.mk
```

Known-good `Install_config_win_b64` shape:

```text
<Install> compatible
C:\DassaultSystemes\CatiaV5R21
```

If `mkmk` reports:

```text
unable to initialize macro level
Bad file descriptor
The script of the identity card cannot be load
```

then inspect `CATIAV5Level.lvl` and `Install_config_win_b64` first. For a local demo, copying these from a known-good CAA project targeting the same CATIA install is often the quickest repair.

Every framework named in `LINK_WITH` must be backed by an `AddPrereqComponent(...)` entry for its owning framework in `IdentityCard.h`. Example: linking `CATObjectSpecsModeler` requires:

```cpp
AddPrereqComponent("ObjectSpecsModeler", Public);
```

## Build Failure Triage

`mkmk` can print errors while returning process exit code 0. Treat the build as failed if output contains:

```text
mkmk-ERROR
make-ERROR
syst-ERROR
fatal error
error C
```

If output contains a license message such as:

```text
RequestLicensesFromSettings: error: the requested licenses do not authorize the given product, MAB.
```

then the build likely stopped during RADE/CATIA license setup before source compilation. Check license settings and requested products first; do not treat this as a C++ compile or link failure.

Common V5R21 fixes seen on this machine:

- `CATGRID_VCENTER` is not defined in `Dialog\PublicInterfaces\CATDlgGridConstraints.h`; use `CATGRID_LEFT`, `CATGRID_RIGHT`, `CATGRID_CENTER`, or `CATGRID_4SIDES`.
- `CATListValCATBaseUnknown.h` does not exist; use `CATListOfCATBaseUnknown.h` for `CATListValCATBaseUnknown_var`.
- `warning C4819` plus `error C2001: 常量中有换行符` around UI text usually means VS2008 is reading source text with the wrong encoding. Prefer moving Chinese UI text to `.CATNls`; otherwise use ASCII C++ literals for a clean compile.
- If link steps run but object files are missing, fix earlier compile errors first; the link errors are secondary.

After build, verify:

```powershell
Test-Path C:\CatiaTest\LYD_GG_DESIGN\<ProjectName>\win_b64\code\bin\<Module>.dll
Test-Path C:\CatiaTest\LYD_GG_DESIGN\<ProjectName>\win_b64\code\dictionary\<Framework>.dico
```

If the dictionary test fails but the source dictionary exists, copy it:

```powershell
New-Item -ItemType Directory -Force -Path <Project>\win_b64\code\dictionary
Copy-Item <Project>\<Framework>\CNext\code\dictionary\<Framework>.dico <Project>\win_b64\code\dictionary\<Framework>.dico -Force
```

## CATSTART Test Environment

Do not launch a plugin test by only doing:

```bat
set CATDLLPath=<PluginBin>;%CATDLLPath%
start "" "C:\DassaultSystemes\CatiaV5R21\win_b64\code\bin\CNEXT.exe"
```

That can open a blank gray CATIA shell because CATIA's base command, dictionary, and message catalog paths were not initialized.

Instead, copy:

```text
C:\ProgramData\DassaultSystemes\CATEnv\CATIA_P3.V5R21.B21.txt
```

to:

```text
<Project>\CATEnv\<EnvName>.txt
```

Then prepend plugin paths to `CATDLLPath`, `CATDictionaryPath`, `CATMsgCatalogPath`, `CATGraphicPath`, and `PATH`. Launch with:

```bat
C:\DassaultSystemes\CatiaV5R21\win_b64\code\bin\CATSTART.exe -run "CNEXT.exe" -env <EnvName> -direnv "<Project>\CATEnv"
```

## UI Test Handoff Checklist

Agent actions:

1. Start CATIA through the project launcher.
2. Confirm `CNEXT` is responding and the main window is present.
3. Stop interactive automation. Do not click buttons, open documents, switch workbenches, fill dialogs, or operate the CATIA UI.
4. Notify the user that CATIA is ready for manual testing and provide the relevant manual checks.

User manual checks for a Product Structure toolbar example:

1. Create or open a `CATProduct`.
2. Enter Product Structure or Assembly workbench.
3. Locate the toolbar/button by the command NLS label.
4. Click the button.
5. Confirm visible behavior, such as a `CATDlgNotify`, and optional test log output.

After the user reports the result, inspect `%LOCALAPPDATA%\DassaultSystemes\CATTemp\error.log` if CATIA closes, freezes, or the command is missing.

## Release Packaging Guardrails

- Treat project-local `CATEnv` files and launcher scripts as development artifacts. They often contain machine-specific absolute paths and should not be shipped unchanged.
- Generate release environment files and launchers for the install location, or document the path fields that users must replace.
- Do not package the entire `win_b64` directory as the only deliverable. Select the required DLLs, dictionary files, message catalogs, graphic resources such as `resources\graphic\icons\normal\*.bmp`, samples, and instructions explicitly.
- Build a staged release directory first, inspect it for required runtime files, launchers, install notes, and validation evidence, then create the final zip from that staged directory.
- Prefer launchers that derive plugin paths from the release bundle location. For CATIA install paths or other values that cannot be reliably autodetected, use a small plain-text configuration file such as `install\CATIA_ROOT.txt` before falling back to default path probes.
- Do not treat “no toolbar and no plugin log” as evidence that the common logger failed: if it lives in a business DLL, discovery, native-dependency, or security-policy failures occur before it can run. Have the release launcher independently record resolved paths, critical-file preflight results, pre-existing `CNEXT` processes, and `CATSTART` output before launch.
- When a target-machine load failure is not reproducible locally, include a minimal returnable diagnostic collector and integrity baseline. Collect CATIA `error.log`, SideBySide/Application Error events, CATEnv, SHA-256 values for critical DLL/DICO files, and Windows alternate data streams; exclude models, CSV/JSON contents, and unrelated system data.
- For V5R21-era Windows command shells, keep fixed `.bat` text ASCII. Do not assume UTF-8 Chinese renders correctly or force `chcp 65001` merely for display; provide Chinese operating guidance in a separate text file and add a packaging check that rejects non-ASCII batch content.
- Include a minimal manual acceptance record for the release package.
