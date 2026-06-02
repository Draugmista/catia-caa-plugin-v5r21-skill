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

## Classic Toolbar Icons

- Reference command icons from `.CATRsc` with an extension-free resource id:

```text
HeaderClass.HeaderId.Icon.Normal = "I_MyCommand" ;
```

- Store committed source icons under `CNext\resources\graphic\icons\normal\`. For immediate local testing, sync them to `win_b64\resources\graphic\icons\normal\`.
- Ensure project `CATGraphicPath` includes the project's `resources\graphic` and `resources\graphic\icons` paths before CATIA's native graphic paths.
- CATIA V5R21 official CAA samples use classic `22x22` BMP toolbar icons. For a matching visual style, use 16-color 4bpp indexed BMP files with `#C0C0C0` as the toolbar background color.
- If starting from generated or high-resolution art, remove the background, resize, and reduce the palette before wiring the icon into `.CATRsc`. Do not point `.CATRsc` directly at a high-resolution PNG.

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
- In V5R21 dialogs that mix path editors, browse buttons, radio buttons, status rows, and a multiline message editor, do not attach every control directly to one multi-column `CATDlgGridLayout`. Automatic expansion can make the multiline editor overlap other cells.
- Put each path-input row, option area, and read-only status row in its own `CATDlgFrame`, then stack those frames and the multiline editor vertically in a single column. This layout is easier to extend and more stable under V5R21 sizing behavior.

## GSM Point Creation And Coordinate Reads

- `CATIGSMFactory::CreatePoint(const double*)` creates a `CATIGSMPoint`, not necessarily a `CATIGSMPointCoord`.
- If later code must read coordinates through `CATIGSMPointCoord::GetCoordinates()`, create coordinate points with:
  - `CATICkeParmFactory::CreateLength`
  - `CATIGSMFactory::CreatePoint(x, y, z)`
- CATIA length parameters are stored in meters when created through `CreateLength`; convert external millimeter data with `value / 1000.0`.
- `CATICkeInst::AsReal()` also returns the internal meter value. When converting `CATIGSMPointCoord::GetCoordinates()` parameter values back into a millimeter-based calculation model, multiply by `1000.0`.
- `CATIGeometricalElement::GetCharacteristicPoints()` returns geometric `CATMathPoint` coordinates in millimeters. Do not apply the parameter-value conversion again on this fallback path.
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

## Nested Geometrical Sets And Persistent Workflow State

- To create a geometrical set inside a specific parent set, use `CATIMechanicalRootFactory::CreateGeometricalSet(name, parent, output, 0)`.
- For a geometrical-set parent, `iPosition=-1` may create a sibling after the parent instead of the intended nested child. Verify the resulting tree shape instead of assuming insertion semantics.
- If workflow state must survive dialog closure, refresh, or CATPart reopen, persist compact stable source identities in the model tree. Do not rely only on dialog memory or encode an ever-growing recursive relationship into display names.
- Keep display names separate from internal identities and dependencies. When users may rename generated geometrical sets, store stable metadata on the generated set with `CATISpecObject::AddAttribute()`, then use `CATISpecAttrAccess::GetAttrKey()` and `SetString` / `SetInteger` for stable ids, direct-source identities, and schema version.
- When scanning persisted applicative attributes, validate field presence, type, schema version, and value. Treat display aliases as UI text, not recovery keys.
- For consume-once workflows, validate persisted outputs in dependency order before building the consumed-source set. Corrupt results must not lock inputs; duplicate consumers should be resolved deterministically.
- Prefer direct references to original source geometry when the workflow expects current source data. Persist copies only when a deliberate snapshot is required.

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

## External Computation Logs

- Keep debug-only logs outside the CATPart. Writing temporary diagnostics into the model tree mixes business state with debugging state.
- For geometry commands with long calculation chains, log both successful and failed operations. Useful fields include stable input identity, source coordinates, tolerance decisions, intermediate vectors, weighted results, and the last reached feature-creation stage.
- Refresh logs should include available candidates, consumed identities, and exclusion reasons so model-tree edits and state recovery can be observed without copying source geometry.
- File logs are best-effort diagnostics. A filesystem write failure may be reported, but it must not block refresh, validation, or geometry creation.
- On Chinese Windows, a UTF-8 BOM append-only log under CATTemp is a practical default. If the command has a dialog, expose locate-log and clear-log actions for repeatable debugging.

## Temporary 3D Selection Annotations

- Interaction-only 3D text should not be persisted into the CATPart. Create a `CAT3DCustomRep`, add `CAT3DAnnotationTextGP`, and display it temporarily through the current public `CATViewer::AddRep()`.
- Clean up in this order: `RemoveRep()`, rep `Destroy()`, then viewer `Draw()`. Once the text GP is added to the rep, let the rep own its lifecycle.
- Make annotation reps non-pickable so helper labels cannot participate in later selection.
- For labels near a selected point, a `BOTTOM_CENTER` anchor can place text naturally above the point without persistent geometry or scale-dependent coordinate offsets.
- Constructing `CATMathPointf` directly requires the `YN000MFL` link module. `CATVisualization`, `CATViz`, or `CATMathStream` alone do not resolve that float math constructor.
- Do not include or call internal `CATVizViewer`. RADE CAA compliance checks reject it. Obtain the public viewer through `CATFrmLayout::GetCurrentLayout()->GetCurrentWindow()->GetViewer()`.
