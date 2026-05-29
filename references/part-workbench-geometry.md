# Part Workbench, NLS, Geometry, And Batch Safety

Use this reference when building or debugging CATIA V5R21 CAA tools for the Part workbench, Part Design geometry creation, model-area selection, Chinese NLS text, or batch feature generation.

## Part Workbench Add-ins

- For a Part workbench toolbar add-in, implement and register `CATIPrtCfgAddin`.
- The `.dico` entry must match add-in class, interface, and module:

```text
<AddinClass> CATIPrtCfgAddin lib<ModuleName>
```

- Toolbar access trees use one child plus siblings:

```cpp
SetAccessChild(pToolbarContainer, pFirstStarter);
SetAccessNext(pFirstStarter, pSecondStarter);
```

- Do not call `SetAccessChild` twice on the same toolbar container; the second call can replace the first button.
- `MacDeclareHeader(HeaderClass)` plus `new HeaderClass(headerId, moduleNameOrCatalog, commandClass, NULL)` creates command headers.
- NLS keys should use the header class and header id:

```text
HeaderClass.HeaderId.Title = "..." ;
HeaderClass.HeaderId.ShortHelp = "..." ;
```

- If CATIA displays internal ids such as the command id instead of user-facing labels, inspect `CATMsgCatalogPath`, runtime `.CATNls` copies, and key names before changing C++.

## Chinese NLS And Encoding

- On Chinese Windows with CATIA V5R21, `.CATNls` and `.CATRsc` files containing Chinese user-visible text should usually be GBK/ANSI encoded. UTF-8 Chinese may be read as ANSI and display as mojibake.
- Keep C++ source literals ASCII when possible. Put Chinese UI labels in `.CATNls`; if source text must include Chinese, prove the VS2008/mkmk encoding path first.
- Follow CATIA-style NLS formatting with semicolons:

```text
SomeCatalog.SomeKey.Title = "中文标题" ;
```

- Local CATIA environments used for plugin testing should include both source and runtime message catalog paths before CATIA's native path:

```text
CATMsgCatalogPath=<Project>\<Framework>\CNext\resources\msgcatalog;<Project>\win_b64\resources\msgcatalog;<CATIA>\win_b64\resources\msgcatalog
```

- For immediate local testing, copying updated `.CATNls` and `.CATRsc` files to `win_b64\resources\msgcatalog` is acceptable, but do not commit `win_b64`.
- After NLS changes, restart CATIA. If stale toolbar labels remain, consider CATIA toolbar customization/cache state before changing code.

## Dialogs And Model-Area Selection

- Pure GUI commands can derive from `CATDlgDialog`.
- Commands that need model-area object selection should derive from `CATStateCommand` and use a selection agent such as `CATFeatureImportAgent`.
- Useful surface/face selection settings:

```cpp
agent->SetOrderedElementType("CATIMfBiDimResult");
agent->AddOrderedElementType("CATSurface");
agent->AddOrderedElementType("CATFace");
agent->AddOrderedElementType("CATShell");
agent->SetBehavior(CATDlgEngWithPrevaluation | CATDlgEngWithCSO | CATDlgEngOneShot);
agent->SetAgentBehavior(MfPermanentBody | MfLastFeatureSupport | MfRelimitedFeaturization);
```

- Validate every row index returned by `CATDlgSelectorList::GetSelect(int*, size)` before indexing local arrays.
- For batch commands, prefer a detailed result pane for normal details and reserve `CATDlgNotify` popups for failures or user-actionable summaries.

## GSM Point Creation And Coordinate Reads

- `CATIGSMFactory::CreatePoint(const double*)` creates a `CATIGSMPoint`, not necessarily a `CATIGSMPointCoord`.
- If later code must read coordinates through `CATIGSMPointCoord::GetCoordinates()`, create coordinate points with:
  - `CATICkeParmFactory::CreateLength`
  - `CATIGSMFactory::CreatePoint(x, y, z)`
- CATIA length parameters are stored in meters when created through `CreateLength`; convert external millimeter data with `value / 1000.0`.
- For old explicit points, `CATIGeometricalElement::GetCharacteristicPoints()` can be used as a fallback. For point features, the bounding-box center can represent the point location.
- If later logic needs line direction inference, keep endpoint point features instead of only creating an anonymous point-to-point line.

## Part Design Pad To Surface

- Create a pad from a sketch with `CATIPrtFactory::CreatePad(sketchSpec)`.
- Use `CATIPad`/`CATIPrism` operations to set direction and an up-to-surface limit:

```cpp
spPad->ModifyDirection(CATMathDirection(x, y, z));
spPad->ModifyEndType(catUpToSurfaceLimit);
spPad->ModifyEndInit(surfaceSpec);
```

- Set the current feature before pad creation so the result lands under the intended body:

```cpp
pPart->SetCurrentFeature(bodySpec);
```

- Repeated execution should not blindly delete or overwrite existing generated pads. Skip and report duplicates unless the user explicitly asks for replacement.

## Batch Operation Safety

- Do not let one failing geometry abort a batch. Wrap each risky feature creation/update independently:

```cpp
CATTry
{
  // Create feature, modify limits, update.
}
CATCatch(CATMfErrUpdate, error)
{
  // Record update diagnostic, Flush(error), continue.
}
CATCatch(CATError, error)
{
  // Record CATIA error details, Flush(error), continue.
}
CATCatchOthers
{
  // Record generic failure, continue.
}
CATEndTry;
```

- Keep per-item failure details separate from normal success details. Show success/failure/skipped counts in the dialog and report only important failures in popups.
- Release raw interfaces on all success and failure paths.
