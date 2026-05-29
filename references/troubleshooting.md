# CATIA CAA V5R21 Troubleshooting

Use this reference after the normal workflow stalls. Prefer diagnosing the first failing layer instead of patching code blindly.

## Fast Symptom Map

| Symptom | First suspects | First checks |
| --- | --- | --- |
| CATIA opens as a blank gray frame | Launched bare `CNEXT.exe`; base CATIA environment was not loaded | Use `CATSTART.exe -run "CNEXT.exe" -env <EnvName> -direnv <Project>\CATEnv`; confirm base `CATDLLPath`, `CATDictionaryPath`, `CATMsgCatalogPath`, and `PATH` remain present |
| CATIA UI is normal but plugin button is missing | `.dico` not copied, wrong add-in interface, wrong target workbench, NLS/header id mismatch | Check runtime `win_b64\code\dictionary`, source `.dico`, add-in class, `TIE_CAT...`, command header id, and active workbench/document type |
| Build reports success but DLL did not change | `mkmk` decided output is up to date, or compile step failed while exit code stayed 0 | Compare timestamps for source, `Objects\win_b64\*.obj`, and `win_b64\code\bin\*.dll`; scan log with `scripts/scan_mkmk_log.ps1` |
| `mkmk` exits 0 but log contains errors | `mkmk` does not reliably signal failure by process exit code | Search for `mkmk-ERROR`, `make-ERROR`, `syst-ERROR`, `fatal error`, and `error C` |
| Log mentions `MAB` or `RequestLicensesFromSettings` | RADE/CATIA license context failed before real compilation | Compare real-user/escalated shell environment and RADE settings before changing C++ |
| Link module is ignored as not a direct prerequisite | Missing owning framework in `IdentityCard.h` | Add the owning framework with `AddPrereqComponent("<Framework>", Public);` and rebuild |
| Dictionary exists in source but not runtime | `mkmk -u` did not copy the dictionary | Copy `<Framework>\CNext\code\dictionary\<Framework>.dico` to `win_b64\code\dictionary` |
| Message catalog text is missing or header label is wrong | `.CATNls` not copied or id does not match command/header ids | Check source and runtime `resources\msgcatalog`; verify command header id, catalog/module argument, and `.CATNls` names |
| Chinese string literals break VS2008 compile | Source encoding mismatch | Prefer `.CATNls` for Chinese UI text; use ASCII C++ literals when build stability matters |
| Dialog layout constant fails to compile | Constant does not exist in installed V5R21 headers | Check installed header; known supported values include `CATGRID_LEFT`, `CATGRID_RIGHT`, `CATGRID_CENTER`, and `CATGRID_4SIDES` |

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

## Guardrails

- Do not modify Dassault public headers unless the user explicitly permits it.
- Do not guess `LINK_WITH` from class names when an official same-version `Imakefile.mk` exists.
- Do not treat a missing button as a C++ bug until runtime `.dico`, `.CATNls`, active workbench, and command id matching are verified.
- Do not treat an `MAB` license message as a compile error.
