# CATIA CAA V5R21 Troubleshooting

Use this reference after the normal workflow stalls. Prefer diagnosing the first failing layer instead of patching code blindly.

## Fast Symptom Map

| Symptom | First suspects | First checks |
| --- | --- | --- |
| CATIA opens as a blank gray frame | Launched bare `CNEXT.exe`; base CATIA environment was not loaded | Use `CATSTART.exe -run "CNEXT.exe" -env <EnvName> -direnv <Project>\CATEnv`; confirm base `CATDLLPath`, `CATDictionaryPath`, `CATMsgCatalogPath`, and `PATH` remain present |
| CATIA UI is normal but plugin button is missing | `.dico` not copied, wrong add-in interface, wrong target workbench, NLS/header id mismatch | Check runtime `win_b64\code\dictionary`, source `.dico`, add-in class, `TIE_CAT...`, command header id, and active workbench/document type |
| Toolbar works in the first document but is empty in later editors | `DataExtension` implementation class and registered late type were conflated; command headers were not recreated in the new `CATFrmEditor` | Compare with the official pattern `CATImplementClass(ImplementationClass, DataExtension, CATBaseUnknown, AddinLateType)`; verify each editor logs `CreateCommands()`, command-header registration, and `CreateToolbars()` |
| Toolbar appears in unrelated workbenches or leaks across CATSettings caches | `.dico` declares an add-in interface that has no matching `TIE_<Interface>` binding | Make `.dico` interface registrations exactly match implemented TIE bindings; remove speculative generic add-in registrations |
| Workbench switch or new-document creation hangs during toolbar initialization | Add-in blocks inside access-tree creation, command binding, or `AddToolbarView()` | Add milestone logs at `CreateToolbars()` entry, after access creation, after binding, immediately before `AddToolbarView()`, and on completion |
| Build reports success but DLL did not change | `mkmk` decided output is up to date, or compile step failed while exit code stayed 0 | Compare timestamps for source, `Objects\win_b64\*.obj`, and `win_b64\code\bin\*.dll`; scan log with `scripts/scan_mkmk_log.ps1` |
| `mkmk` exits 0 but log contains errors | `mkmk` does not reliably signal failure by process exit code | Search for `mkmk-ERROR`, `make-ERROR`, `syst-ERROR`, `fatal error`, and `error C` |
| Log mentions `MAB` or `RequestLicensesFromSettings` | RADE/CATIA license context failed before real compilation | Compare real-user/escalated shell environment and RADE settings before changing C++ |
| Link module is ignored as not a direct prerequisite | Missing owning framework in `IdentityCard.h` | Add the owning framework with `AddPrereqComponent("<Framework>", Public);` and rebuild |
| Dictionary exists in source but not runtime | `mkmk -u` did not copy the dictionary | Copy `<Framework>\CNext\code\dictionary\<Framework>.dico` to `win_b64\code\dictionary` |
| Message catalog text is missing or header label is wrong | `.CATNls` not copied or id does not match command/header ids | Check source and runtime `resources\msgcatalog`; verify command header id, catalog/module argument, and `.CATNls` names |
| Updated NLS still shows old text after `mkmk` reports `dummynls` | Existing runtime resource was not overwritten | Compare source and runtime `.CATNls/.CATRsc` hashes or timestamps, then manually sync stale runtime copies |
| Toolbar text is mojibake on Chinese CATIA | Chinese `.CATNls` was written as UTF-8 but read as ANSI | Re-encode Chinese `.CATNls/.CATRsc` as GBK/ANSI, copy to runtime `msgcatalog`, and restart CATIA |
| Only newly appended NLS text is mojibake | A GBK catalog was partially rewritten or appended as UTF-8 | Strict-decode the complete source as GBK, rewrite it in one encoding, sync the runtime copy, and restart CATIA |
| Only one toolbar button appears when two were created | Toolbar access tree overwrote the first child | Use one `SetAccessChild(toolbar, firstStarter)` and chain later starters with `SetAccessNext(firstStarter, secondStarter)` |
| Chinese string literals break VS2008 compile | Source encoding mismatch | Prefer `.CATNls` for Chinese UI text; use ASCII C++ literals when build stability matters |
| Dialog layout constant fails to compile | Constant does not exist in installed V5R21 headers | Check installed header; known supported values include `CATGRID_LEFT`, `CATGRID_RIGHT`, `CATGRID_CENTER`, and `CATGRID_4SIDES` |
| `CATMathPointf` constructor is unresolved at link time | Float math framework is missing | Add the `YN000MFL` link module and its owning framework prerequisite; visualization modules alone are insufficient |
| RADE compliance rejects viewer code | Internal `CATVizViewer` was included or called | Use public `CATViewer` obtained from `CATFrmLayout::GetCurrentLayout()->GetCurrentWindow()->GetViewer()` |
| `CATFeatureImportAgent` or `CATFeatureAgent` is unresolved at link time | Selection-agent UI module is missing | Add `CATMechanicalModelerUI` to `LINK_WITH` and verify the owning framework prerequisite |
| Multiline editor overlaps path inputs, labels, or status rows | Too many mixed controls share one multi-column `CATDlgGridLayout` | Put each input or status row in a `CATDlgFrame`, then stack frames and the multiline editor vertically in one column |
| Toolbar button icon is missing or stale | `.CATRsc`, BMP runtime copy, or `CATGraphicPath` is stale or incomplete | Verify the extension-free `.CATRsc` resource id, compare source and runtime icon hashes, and ensure project graphic paths precede CATIA native paths |
| An unrelated workbench toolbar stops initializing after linking another add-in module | Cross-DLL C++ ABI surface or startup-time hard DLL dependency is too broad | Keep service classes module-private; expose a narrow C bridge and resolve optional modules lazily with `LoadLibraryW()` / `GetProcAddress()` |
| DLL is emitted but the link log contains `LNK4006` or `LNK4088` | Two `.m` sources in the same DLL define colliding global C++ symbols; the default forced link masked the ODR violation | Treat the warning as a failed build gate, find the duplicate symbol, and give internal DTOs responsibility-specific module-unique names |
| Old STL headers fail with unrelated syntax errors after adding CATIA or MFC includes | Compatibility macros reached the VS2008 standard library before its headers | Include required STL headers before CATIA headers where the project permits it; compare with a working translation unit and use the real `mkmk` build as the authority |
| Standalone syntax check reports `WINDOWS.H already included` | The checker force-included MFC and no longer matches the RADE PCH contract | Remove arbitrary `/FIafxwin.h`; reproduce the module's generated PCH and include order before treating the result as a source defect |
| VS2008 `cl` reports internal compiler error `D8030` in a lightweight multi-file test | One command compiled several source files while sharing a `/Fo` output directory | Compile each source separately with `/c`, give each object an explicit path, then link the objects; keep temporary test outputs outside RADE and release trees |

## Layered Diagnosis

1. Project shape: verify `CATIAV5Level.lvl`, `Install_config_win_b64`, framework `IdentityCard.h`, module `Imakefile.mk`, `LocalInterfaces`, and `src`.
2. Official reference: find same-version examples under `C:\DassaultSystemes\CatiaV5R21\CAADoc` and compare project layout, `LINK_WITH`, `.dico`, and `CNext` resources.
3. Build: run `mkmk` with log redirection, then scan the log instead of trusting the exit code.
4. Runtime artifacts: verify DLL, import library, dictionary, and message catalogs under `win_b64`.
5. Launch: use project-local CATEnv plus `CATSTART`, not bare `CNEXT`.
6. UI discovery: open the correct document/workbench before deciding the add-in failed.
7. CATIA logs: inspect `%LOCALAPPDATA%\DassaultSystemes\CATTemp\error.log` after freezes, exits, or missing commands.

## Helper Scripts

Use `scripts/check_caa_project.ps1` for a quick project-shape and runtime-artifact pass:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Carcharoth\.codex\skills\catia-caa-plugin\scripts\check_caa_project.ps1 -ProjectRoot C:\CatiaTest\LYD_GG_DESIGN\<ProjectName>
```

Use `scripts/scan_mkmk_log.ps1` after redirecting a build log:

```powershell
powershell -ExecutionPolicy Bypass -File C:\Users\Carcharoth\.codex\skills\catia-caa-plugin\scripts\scan_mkmk_log.ps1 -LogPath C:\CatiaTest\LYD_GG_DESIGN\<ProjectName>\mkmk_build.log
```

## Real-User MAB Environment Comparison

On this machine, `mkmk` can fail the MAB authorization check under a sandboxed or offline execution identity while succeeding as the real Windows user. Do not use sandboxed `mkmk` as the diagnostic baseline. Run the same command with real-user or escalated execution before treating MAB as a project or C++ failure.

A successful environment observed on this machine has:

- `whoami=desktop-c64rlob\carcharoth`
- `USERNAME=Carcharoth`
- `USERPROFILE=C:\Users\Carcharoth`
- `RADECATSettingPath=C:\Users\Carcharoth\AppData\Roaming\DassaultSystemes\CATSettings\RADE`
- `__COMPAT_LAYER=ElevateCreateProcess`
- `MkmkROOT_PATH=C:\DASSAU~1\RADEV5~1\intel_a`
- `MkmkINSTALL_PATH=C:\DASSAU~1\RADEV5~1`

Treat these values as comparison evidence, not permanent configuration. Confirm current paths and identity before relying on them.

When comparing shells, use delayed expansion so values set by `vcenv.bat` are not hidden by early `%VAR%` expansion:

```bat
cmd /v:on /c "whoami && echo USERNAME=!USERNAME! && echo USERPROFILE=!USERPROFILE! && echo CD=!CD! && echo before_RADECATSettingPath=!RADECATSettingPath! && echo before_COMPAT=!__COMPAT_LAYER! && call C:\DassaultSystemes\caa_work\mytest\test1\ToolsData\VisualStudio2008\vcenv.bat >nul && echo after_RADECATSettingPath=!RADECATSettingPath! && echo after_COMPAT=!__COMPAT_LAYER! && echo TCK_TMP_FILE=!TCK_TMP_FILE! && echo MkmkROOT_PATH=!MkmkROOT_PATH! && echo MkmkINSTALL_PATH=!MkmkINSTALL_PATH! && dir /a "!RADECATSettingPath!""
```

## Guardrails

- Do not modify Dassault public headers unless the user explicitly permits it.
- Do not guess `LINK_WITH` from class names when an official same-version `Imakefile.mk` exists.
- Do not treat a missing button as a C++ bug until runtime `.dico`, `.CATNls`, active workbench, and command id matching are verified.
- Do not treat an `MAB` license message as a compile error.
- Do not accept a produced DLL as proof of a clean link. Scan warnings as well as errors, especially `LNK4006` and `LNK4088`.
