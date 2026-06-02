# Product Structure Assembly And CATPart Instance Placement

Use this reference when a CATIA V5R21 CAA command inserts external CATPart instances into a Product, positions instances, refreshes the structure tree, or creates persistent assembly constraints.

## Multi-Workbench Project Organization

- If one plugin framework must support Part and Product Structure / Assembly workbenches, keep one framework and add separate `.m` modules for the different workbench add-ins.
- Register each add-in in the same framework `.dico`, using the matching workbench interface and module library:

```text
<PartAddinClass> CATIPrtCfgAddin lib<PartModule>
<AssemblyAddinClass> CATIPRDWorkshopAddin lib<AssemblyModule>
```

- Sharing one framework keeps CATEnv, launcher, deployment artifacts, and message catalogs consistent. Do not create separate projects unless isolation is intentional.

## Insert External Or Already-Loaded CATPart References

- To insert an external CATPart, open it with `CATDocumentServices::OpenDocument()`, obtain its root `CATIProduct`, and call the target parent Product's `CATIProduct::AddProduct()` with the external reference. The official `CAAPstMovable` sample follows this pattern.
- If a template Part is already loaded and selected in the product tree, do not reopen it. Call `CATIProduct::GetReferenceProduct()` on the selected instance and pass that reference to the target parent's `CATIProduct::AddProduct()`.
- When users select Part instances from the structure tree, a non-modal `CATStateCommand` plus `CATFeatureImportAgent` can restrict selection with:

```cpp
agent->SetOrderedElementType("CATIProduct");
```

- `CATFeatureImportAgent` requires `CATMechanicalModelerUI` in `LINK_WITH`; `CATDialogEngine` alone can leave `CATFeatureImportAgent` or `CATFeatureAgent` symbols unresolved.
- If a user attempts to replace a validated selection with an invalid object, clear the cached valid instance immediately. Do not silently execute against an older selection after reporting validation failure.

## Position Instances With Auditable Transforms

- Use `CATIMovable::SetAbsPosition()` for instance placement.
- When target reference geometry belongs to an already-positioned Product instance, call that instance's `CATIMovable::GetAbsPosition()` and transform local points and directions into assembly absolute coordinates before constructing the new placement.
- For stable, reviewable template-to-target placement, construct source and target right-handed bases from oriented reference geometry, then calculate:

```text
R = B_target * transpose(B_source)
t = targetOrigin - R * sourceOrigin
```

- Pass the documented column-major 12 coefficients to `CATMathTransformation::SetCoefficients()`. This makes axis correspondence explicit instead of relying on opaque bounding-box heuristics.
- If direction matters, require point-to-point lines and read stable orientation with `CATIGSMLinePtPt::GetFirstPoint()` and `GetSecondPoint()`. Do not infer directed line orientation from a bounding box.
- Validate semantic reference geometry, not only feature existence. For a reference plane, use `CATIGeometricalElement::GetGeometryResult()` to obtain `CATPlane`, then verify expected origin and normal relationships.

## Machine-Matching Contracts

- Use stable ASCII aliases for geometrical sets and elements that act as cross-CATPart machine-matching contracts. Keep localized Chinese text for GUI descriptions, not exact model-tree matching keys.
- Use `CATIGSMTool` when scanning ordinary geometrical sets. Do not confuse it with `CATIMechanicalTool`, which represents solid Body tools.
- For external templates, compare `CATIAlias::GetAlias()`, `CATISpecObject::GetName()`, and `GetDisplayName()` when matching reference elements. On failure, report the actual scanned names.

## Verify And Refresh Product Structure Changes

- Do not report assembly success only because `CATIProduct::AddProduct()` returned a handler and `CATIMovable::SetAbsPosition()` succeeded.
- Verify that the target parent's direct-child count increased and rescan for the newly named instance. Assign a stable unique instance name so the product tree can be refreshed and manually verified.
- `CATIProduct::AddProduct()` updating structure does not guarantee immediate tree or 3D viewer refresh. After interactive batch insertion:
  - call `CATIRedrawEvent::Redraw()` on the root Product to refresh the navigation tree;
  - send a `CATModify` visual notification;
  - call the current public `CATViewer::Draw()`.
- Tree and viewer refresh support requires the appropriate navigator and visualization modules, including `CATObjectModelerNavigator` and `CATVisualization`.

## Persistent Assembly Constraints

- A positioned Product instance is not the same as a constrained assembly instance.
- To persist assembly relationships, obtain Product connectors for geometry in each instance context with `GetProductConnector()`, then create Product-level constraints with `CreateConstraint(...)`.
- For coincident oriented lines, set `CATCstAttr_Orientation` explicitly to `CATCstVal_Orient_Same` when same direction is required. Use plane coincidence constraints for assembly planes.
- Constraint creation modules require `CATAssemblyInterfaces` and `CATConstraintModelerItf` in `LINK_WITH`. The framework `IdentityCard.h` should declare `CATAssemblyInterfaces`, `ConstraintModelerInterfaces`, and `ConstraintModeler`.

## Transactional Batch CATPart Creation

- Geometry services used by Product-level orchestration should accept an explicit target `CATDocument`. Do not hard-wire a single-Part geometry kernel to the current editor.
- To create a CATPart under an active Product without simulating UI actions:
  - call `CATDocumentServices::New("Part")`;
  - use `CATIDocRoots::GiveDocRoots()` to obtain the root `CATIProduct`;
  - set a stable `PartNumber`;
  - call the parent Product's `AddProduct()`.
- Detect an active assembly document by querying `IID_CATIProduct` on roots returned by `CATIDocRoots::GiveDocRoots()`. Do not depend on `CATIDocDescriptor::GetDocType()` text containing `Product`; V5R21 document-type text can vary by context.
- Before creating multiple Parts, preflight filenames, target paths, and parent Product conflicts.
- During execution, record every created instance, document, and output file. If any item fails, roll back in reverse order: remove inserted instances, remove new documents from the session, and delete files created by the current batch.
