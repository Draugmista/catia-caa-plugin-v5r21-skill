# Part Workbench, NLS, Geometry, And Batch Safety

Use this reference when building or debugging CATIA V5R21 CAA tools for the Part workbench, Part Design geometry creation, model-area selection, Chinese NLS text, or batch feature generation.

## Contents

- [Part Workbench Add-ins](#part-workbench-add-ins)
- [Chinese NLS And Encoding](#chinese-nls-and-encoding)
- [Classic Toolbar Icons](#classic-toolbar-icons)
- [Dialogs And Model-Area Selection](#dialogs-and-model-area-selection)
- [GSM Point Creation And Coordinate Reads](#gsm-point-creation-and-coordinate-reads)
- [Relative Geometry And Dependent Sketches](#relative-geometry-and-dependent-sketches)
- [GSM Projection Direction](#gsm-projection-direction)
- [Part Design Pad To Surface](#part-design-pad-to-surface)
- [Rounded Sketch Profiles And Constraint Diagnostics](#rounded-sketch-profiles-and-constraint-diagnostics)
- [Nested Geometrical Sets And Persistent Workflow State](#nested-geometrical-sets-and-persistent-workflow-state)
- [Batch Operation Safety](#batch-operation-safety)
- [External Computation Logs](#external-computation-logs)
- [Temporary 3D Selection Annotations](#temporary-3d-selection-annotations)

## Part Workbench Add-ins

- For a Part workbench toolbar add-in, implement and register `CATIPrtCfgAddin`.
- The `.dico` entry must match add-in class, interface, and module:

```text
<AddinClass> CATIPrtCfgAddin lib<ModuleName>
```

- Keep `.dico` interface declarations one-to-one with the implementation's `TIE_<Interface>` bindings. Do not register an additional generic add-in interface that the class does not implement; CATIA can discover it in the wrong workbench context and persist misleading toolbar state in multiple CATSettings caches.
- For a `DataExtension` add-in, keep the C++ implementation class distinct from the late type registered in the `.dico`. Follow the V5R21 sample pattern:

```cpp
CATImplementClass(ImplementationClass,
                  DataExtension,
                  CATBaseUnknown,
                  AddinLateType);
TIE_CATIPrtCfgAddin(ImplementationClass);
```

Register `AddinLateType`, not `ImplementationClass`, in the `.dico`. A self-extension that uses one name for both roles can initialize in the first editor but fail to recreate command headers in later editors.
- Command headers are owned by the current `CATFrmEditor`; `CreateCommands()` running for each new editor is expected. When debugging a toolbar that becomes empty in later documents, correlate logs by PID/editor lifecycle and verify `CreateCommands()`, each stable command id, and `CreateToolbars()` for every editor. Use `CATAfrGetCommandHeader()` in the current editor to verify the resolved header and icon when needed.
- Instrument add-in initialization at useful boundaries: `CreateCommands()` entry, each command-header registration for small command sets, `CreateToolbars()` entry, access-tree creation, command binding, immediately before `AddToolbarView()`, and completion. Missing completion logs then distinguish a method that was never called from one that blocked internally.
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
- Preserve one encoding across the entire catalog. Appending PowerShell 7 default UTF-8 text to an existing GBK file creates a mixed byte stream that CATIA cannot decode reliably. After scripted edits, validate the complete source with strict GBK decoding when GBK is the project convention.
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
- Do not swap mode panels with substantially different preferred heights in one grid cell using `SetVisibility()`. V5R21 can retain the initially calculated row height and overlap controls after a mode change. Keep both panels in fixed rows and use `SetSensitivity(CATDlgEnable/CATDlgDisable)` to choose the active panel.
- If a single-line `CATDlgEditor` expands into a large blank box, check its grid constraints before adding more sizing calls. `CATGRID_4SIDES` stretches the editor to the whole cell; prefer `CATGRID_LEFT | CATGRID_RIGHT | CATGRID_TOP` for one-line editors, and keep adjacent button areas in separate rows inside the same form frame.
- A multi-select `CATDlgSelectorList` represents membership, not semantic order. When inputs have roles such as first/second, source/target, or P1/P2, provide explicit assignment slots and clear those slots plus list selection when the mode or candidate set changes.

## GSM Point Creation And Coordinate Reads

- `CATIGSMFactory::CreatePoint(const double*)` creates a `CATIGSMPoint`, not necessarily a `CATIGSMPointCoord`.
- If later code must read coordinates through `CATIGSMPointCoord::GetCoordinates()`, create coordinate points with:
  - `CATICkeParmFactory::CreateLength`
  - `CATIGSMFactory::CreatePoint(x, y, z)`
- CATIA length parameters are stored in meters when created through `CreateLength`; convert external millimeter data with `value / 1000.0`.
- `CATICkeInst::AsReal()` also returns the internal meter value. When converting `CATIGSMPointCoord::GetCoordinates()` parameter values back into a millimeter-based calculation model, multiply by `1000.0`.
- `CATIGeometricalElement::GetCharacteristicPoints()` returns geometric `CATMathPoint` coordinates in millimeters. Do not apply the parameter-value conversion again on this fallback path.
- For a relative coordinate point created with `CreatePoint(x, y, z, referencePoint)`, `CATIGSMPointCoord::GetCoordinates()` describes the offset from `referencePoint`, not its evaluated model-space location. Scanners, placement, and export code that need the current position should first use `CATIGeometricalElement::GetCharacteristicPoints()`; use parameter coordinates only when the object is not geometric.
- For old explicit points, `CATIGeometricalElement::GetCharacteristicPoints()` can be used as a fallback. For point features, the bounding-box center can represent the point location.
- If later logic needs line direction inference, keep endpoint point features instead of only creating an anonymous point-to-point line.

## Relative Geometry And Dependent Sketches

- When a geometrical set must move as one unit with a center point, persist one absolute center and create its dependent endpoints with `CATIGSMFactory::CreatePoint(x, y, z, referencePoint)`. Define dependent planes from that center, a major-axis point, and a hidden non-collinear helper point. Retain a separately named zero-offset endpoint when downstream aliases depend on it, even if it coincides geometrically with the center.
- Reuse the same relative-point-and-line helper for interactive creation, automatic creation, and parameter rebuild paths. Equivalent user promises with different internal dependency layouts make reopen and recovery failures difficult to diagnose.
- A sketch that must follow a dependent plane needs an associative `CATISketchPositioning` setup, not a one-time absolute `SetAxisData` call. Configure one-plane support, a projected-point origin, and line-parallel orientation; validate every status returned by `EvalPosition()` before creating the local profile.

## GSM Projection Direction

- For an explicitly directional Generative Shape Design projection, use `CATIGSMFactory::CreateProject(element, support, direction, FALSE, CATGSMNearestSolution)` or configure `CATIGSMProject` with `SetNormal(FALSE)` and `SetDirection()`.
- Do not replace a directional projection requirement with normal projection or manually approximated curves.
- Create projection directions from real scalar components, for example with `CATIGSMFactory::CreateDirection(CreateReal(...), ...)`; do not convert direction components as length parameters.

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

## Rounded Sketch Profiles And Constraint Diagnostics

- For a rectangle with one rounded corner, constrain the envelope rather than the trimmed adjacent line lengths. Use distances between opposite sides for width and height, locate an unaffected corner relative to the sketch absolute H/V axes, and add horizontal/vertical constraints for orientation.
- Preflight a fixed corner radius `R` by requiring both envelope dimensions to be greater than `2R`.
- Constrain and solve the base rectangle before calling `CreateCorner()` and `InsertCorner()`. Place the indication point unambiguously inside the intended corner quadrant, then verify the relimited endpoints and trim directions.
- Do not rely on `InsertCorner()` automatic relations as proof of a fully constrained profile. Explicitly add tangency constraints between the arc and both adjacent sides plus a radius constraint.
- `CATISketch::GetSolvingStatus()` returning `Cst2DDiag_NotChanged` means only that the latest solve did not move geometry. Inspect each constituent curve with `CATI2DCstDiagnostic` and verify its remaining degrees of freedom.
- When batch Sketcher APIs return a generic `E_FAIL`, record a stable item identity and stage. On failure, add the constraint index, trim directions, and solving/constraint diagnostics without logging the complete input row or coordinate payload.

## Nested Geometrical Sets And Persistent Workflow State

- To create a geometrical set inside a specific parent set, use `CATIMechanicalRootFactory::CreateGeometricalSet(name, parent, output, 0)`.
- For a geometrical-set parent, `iPosition=-1` may create a sibling after the parent instead of the intended nested child. Verify the resulting tree shape instead of assuming insertion semantics.
- If workflow state must survive dialog closure, refresh, or CATPart reopen, persist compact stable source identities in the model tree. Do not rely only on dialog memory or encode an ever-growing recursive relationship into display names.
- Keep display names separate from internal identities and dependencies. When users may rename generated geometrical sets, store stable metadata on the generated set with `CATISpecObject::AddAttribute()`, then use `CATISpecAttrAccess::GetAttrKey()` and `SetString` / `SetInteger` for stable ids, direct-source identities, and schema version.
- When scanning persisted applicative attributes, validate field presence, type, schema version, and value. Treat display aliases as UI text, not recovery keys.
- When a mode or derived values become a required downstream contract, increment the schema and validate the required field set atomically. Do not silently supply legacy defaults unless backward compatibility is an explicit, tested requirement.
- Persist derived numeric values as typed attributes such as `tk_double`, ordered by stable input identity rather than UI selection order. Fix units and geometric definitions in the field contract; values with similar names, such as a three-dimensional member length and its projected force arm, are not interchangeable.
- Keep machine-discovery geometry and presentation geometry separate. Preserve a small stable discovery contract across modes, and store mode-specific display features as optional representation rather than making downstream scans depend on them.
- If users need to edit generated feature parameters directly in the CATIA tree but the geometry was created as one-shot point or line features, insert visible CKE parameters as inputs and provide an explicit command to validate and apply parameter edits. Do not assume editing a CKE parameter will automatically rewrite already-created coordinate geometry.
- Store user-facing or downstream business labels separately from numeric computation levels. Persist labels as strings for readers, persist levels as numeric attributes for calculations, and reconcile both after refresh or rebuild.
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
- If a batch item creates a primary result and then fails while creating dependent secondary results, record that partial state explicitly and ask once at the end whether to keep or roll back those primary results. Do not count partial states as ordinary successes or interrupt every loop iteration with a popup.
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
