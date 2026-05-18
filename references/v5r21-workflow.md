# CATIA V5R21 CAA Local Workflow

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

After build, verify:

```powershell
Test-Path C:\CatiaTest\LYD_GG_DESIGN\<ProjectName>\win_b64\code\bin\<Module>.dll
Test-Path C:\CatiaTest\LYD_GG_DESIGN\<ProjectName>\win_b64\code\dictionary\<Framework>.dico
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
