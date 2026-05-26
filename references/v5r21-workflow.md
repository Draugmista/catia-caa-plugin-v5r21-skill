# CATIA V5R21 CAA Local Workflow

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

```bat
call C:\DassaultSystemes\caa_work\mytest\test1\ToolsData\VisualStudio2008\vcenv.bat
cd /d C:\CatiaTest\LYD_GG_DESIGN\<ProjectName>
C:\DassaultSystemes\RADEv5r21\intel_a\code\command\mkmk.bat -a -u
```

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

Then prepend plugin paths to `CATDLLPath`, `CATDictionaryPath`, `CATMsgCatalogPath`, and `PATH`. Launch with:

```bat
C:\DassaultSystemes\CatiaV5R21\win_b64\code\bin\CATSTART.exe -run "CNEXT.exe" -env <EnvName> -direnv "<Project>\CATEnv"
```

## Smoke Test Checklist

1. Start CATIA through the project launcher.
2. Confirm `CNEXT` is responding.
3. Create or open a `CATProduct`.
4. Enter Product Structure or Assembly workbench.
5. Locate the toolbar/button by the command NLS label.
6. Click the button.
7. Confirm visible behavior, such as a `CATDlgNotify`, and optional test log output.
8. Inspect `%LOCALAPPDATA%\DassaultSystemes\CATTemp\error.log` if CATIA closes, freezes, or the command is missing.
