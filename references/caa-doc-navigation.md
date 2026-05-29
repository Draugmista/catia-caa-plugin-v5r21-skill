# CATIA CAA 参考定位指南

## 目的

这份文档不是给人系统学习用的教程，而是给**后续 agent 执行 CATIA CAA 相关任务时**使用的快速导航手册。

目标只有一个：

- 当 agent 接到某类 CAA 开发、排错、仿写、扩展任务时，能迅速找到最可能有用的**官方参考文档**和**同版本示例工程**。

## 使用边界

本指南当前只基于以下信息整理：

- 官方目录结构
- 综述性入口页
- use case / quick ref / tech article 的标题
- 示例工程目录名
- skill 自带 workflow 综述

本轮**没有深入阅读具体技术正文**。因此这份文档适合做“找资料入口”，不适合直接替代 API 细读。

## 固定入口

### 官方总目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc
```

说明：

- 这是本机 CATIA V5R21 官方 CAA 文档与示例工程的根目录。
- 后续所有检索优先从这里开始，不要先靠记忆猜接口。

### 在线文档聚合目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\Doc\online
```

说明：

- 这是按文档类型聚合后的官方导航中心。
- 常见目录后缀含义：
  - `*UseCases`：示例讲解、案例入口
  - `*TechArticles`：概念说明、架构说明
  - `*QuickRefs`：接口或组件速查
  - `*Base`：基础主题入口

### 官方首页入口

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\Doc\online\CAAV5HomePage.htm
```

说明：

- 这是总入口页。
- 如果 agent 需要确认全站文档分类，可以从这里回到全局导航。

### Skill 自带工作流综述

```text
C:\Users\Carcharoth\.codex\skills\catia-caa-plugin\references\v5r21-workflow.md
```

说明：

- 这是本地的“CAA 任务执行约定”。
- 遇到不确定应该先查文档还是先改代码时，优先遵循这份 workflow。

## 总体定位规则

后续 agent 处理 CAA 任务时，建议按以下顺序定位参考资料：

1. 先判断任务属于哪一类能力。
2. 先进对应的 `Doc\online\*TechArticles` / `*UseCases` / `*QuickRefs` 看标题。
3. 再进对应的 `.edu` 目录找同名或近似命名的示例工程模块。
4. 优先复用同版本示例工程的结构、注册方式、`Imakefile.mk` 和 `CNext` 资源组织。
5. 只有在同版本目录里找不到时，才扩大搜索范围。

## 任务分类到资料入口的映射

下面这部分是本指南的核心。

---

## 1. 插件挂接、工具栏、菜单、命令头、Workbench

### 任务特征

适用于这类需求：

- 新增 CATIA 按钮
- 新增菜单、工具栏
- 注册 command header
- 新增 workbench / workshop addin
- 命令没有显示出来
- 想仿写一个最小 UI 插件骨架

### 首选文档目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\Doc\online\CAAAfrTechArticles
C:\DassaultSystemes\CatiaV5R21\CAADoc\Doc\online\CAAAfrUseCases
```

### 首选综述/文章标题

- `CAAAfrOverview.htm`
- `CAAAfrIntegratingCommand.htm`
- `CAAAfrCommandHeaders.htm`
- `CAAAfrVisualIdentity.htm`
- `CAAAfrI18NHeader.htm`
- `CAAAfrI18NWorkshop.htm`

### 首选 use case 标题

- `CAAAfrSampleAddin.htm`
- `CAAAfrSampleWorkbench.htm`
- `CAAAfrSampleGeneralWksAddin.htm`
- `CAAAfrSampleStdCommandHeader.htm`
- `CAAAfrSampleCustomCommandHeader.htm`
- `CAAAfrInitialWorkbench.htm`
- `CAAAfrCmdPalette.htm`

### 首选示例工程目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\CAAApplicationFrame.edu
```

优先看这些模块：

- `CAAAfrGeoWksAddin.m`
- `CAAAfrGeneralWksAddin.m`
- `CAAAfrCustomizedCommandHeader.m`
- `CAAAfrCustCommandHdrModel.m`
- `CAAAfrGeometryWshop.m`
- `CAAAfrInitialWorkbench.m`

### 优先搜索词

- `CATIWorkbenchAddin`
- `CATCreateWorkshop`
- `CATCommandHeader`
- `MacDeclareHeader`
- `AddToolbarView`
- `CreateCommands`
- `CreateToolbars`

### 适合先看的文件位置

- `<Module>.m\Imakefile.mk`
- `<Module>.m\LocalInterfaces`
- `<Module>.m\src`
- `CNext\code\dictionary`
- `CNext\resources\msgcatalog`

---

## 2. 弹窗、基础控件、消息通知、布局

### 任务特征

适用于这类需求：

- 弹一个对话框
- 增加按钮、输入框、下拉框
- 使用 `CATDlgNotify`
- 调整界面布局
- 查 CATDialog 控件类怎么用

### 首选文档目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\Doc\online\CAADlgQuickRefs
C:\DassaultSystemes\CatiaV5R21\CAADoc\Doc\online\CAADlgUseCases
```

### 首选 quick ref 标题

- `CAADlgCATDialog.htm`
- `CAADlgCATDlgDialog.htm`
- `CAADlgCATDlgNotify.htm`
- `CAADlgCATDlgPushButton.htm`
- `CAADlgCATDlgCombo.htm`
- `CAADlgCATDlgEditor.htm`
- `CAADlgCATDlgGridConstraints.htm`
- `CAADlgDialogSummary.htm`

### 首选 use case 标题

- `CAADlgSampleGettingStarted.htm`
- `CAADlgBurger.htm`
- `CAADlgSampleBBMsg.htm`
- `CAADlgSampleSendReceive.htm`
- `CAADlgSampleSettings.htm`

### 首选示例工程目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\CAADialog.edu
```

优先看这些模块：

- `CAADlgHelloApplication.m`
- `CAADlgDialogDemonstrator.m`
- `CAADlgBurger.m`
- `CAADlgSendReceive.m`
- `CAADlgBBMessage.m`

### 优先搜索词

- `CATDlgNotify`
- `CATDialog`
- `CATDlgDialog`
- `CATDlgPushButton`
- `CATDlgEditor`
- `CATDlgGridConstraints`

### 适合先看的文件位置

- `<Module>.m\LocalInterfaces`
- `<Module>.m\src`
- `Imakefile.mk`

---

## 3. 选择、状态命令、Agent、交互流程、Undo/Redo

### 任务特征

适用于这类需求：

- 写 `CATStateCommand`
- 做对象选择、点选、拾取
- 鼠标移动指示
- 多状态交互命令
- 处理 undo / redo
- 带 dialog agent 的命令

### 首选文档目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\Doc\online\CAADegUseCases
```

### 首选 use case 标题

- `CAADegSampleSelection.htm`
- `CAADegSampleMultiSelection.htm`
- `CAADegSampleMouseMove.htm`
- `CAADegSampleIndication.htm`
- `CAADegSampleCommandUndoRedo.htm`
- `CAADegSampleDialogWithAgent.htm`
- `CAADegSampleDialogWithPanelState.htm`

### 首选示例工程目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\CAADialogEngine.edu
```

优先看这些模块：

- `CAADegGeoCommands.m`
- `CAADegMultiDocCmd.m`
- `CAADegSDOAddin.m`

### 优先搜索词

- `CATStateCommand`
- `CATDialogAgent`
- `BuildGraph`
- `CATPathElementAgent`
- `CATIndicationAgent`
- `UndoRedo`

### 适合先看的文件位置

- `<Module>.m\src`
- `<Module>.m\LocalInterfaces`
- `Imakefile.mk`

---

## 4. Product Structure / Assembly / PRDWorkshop 插件

### 任务特征

适用于这类需求：

- 在装配环境挂按钮
- 扩展 Product Structure UI
- 处理 PRDWorkshop addin
- 操作装配树、产品组件
- 查 Product Structure 相关注册方式

### 首选文档目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\Doc\online\CAAPuiUseCases
C:\DassaultSystemes\CatiaV5R21\CAADoc\Doc\online\CAAPstUseCases
```

### 首选 use case 标题

`CAAPuiUseCases`：

- `CAAPuiPRDWorkshopAddin.htm`
- `CAAPuiPRDWorkshopConfig.htm`
- `CAAPuiPrsConfigAddin.htm`

`CAAPstUseCases`：

- `CAAPstAddComponent.htm`
- `CAAPstBrowse.htm`
- `CAAPstAllProperties.htm`
- `CAAPstPrdProperties.htm`
- `CAAPstProductInSession.htm`
- `CAAPstProviders.htm`
- `CAAPstINFCreateDocument.htm`
- `CAAPstINFNavigate.htm`

### 首选示例工程目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\CAAProductStructureUI.edu
C:\DassaultSystemes\CatiaV5R21\CAADoc\CAAProductStructure.edu
```

优先看这些模块：

`CAAProductStructureUI.edu`：

- `CAAPuiPRDWorkshopAddin.m`
- `CAAPuiPRDWorkshopConfig.m`
- `CAAPuiPrsConfigAddin.m`

`CAAProductStructure.edu`：

- `CAAPstAddComponent.m`
- `CAAPstBrowse.m`
- `CAAPstAllProperties.m`
- `CAAPstPrdProperties.m`
- `CAAPstProductInSession.m`
- `CAAPstEduNavigBook.m`
- `CAAPstEduCtxMenuProv.m`

### 优先搜索词

- `CATIPRDWorkshopAddin`
- `TIE_CATIPRDWorkshopAddin`
- `ProductStructureUIUUID`
- `CATPrsWksPRDWorkshop`
- `AddinClass`
- `CreateToolbars`

### 适合先看的文件位置

- `<Module>.m\Imakefile.mk`
- `<Module>.m\src`
- `CNext\code\dictionary`
- `IdentityCard`

### 备注

- 如果任务明确提到“装配按钮不显示”或“PRDWorkshop 插件不生效”，这一组应作为最高优先级入口。

---

## 5. 几何特征、GSM、混合造型接口

### 任务特征

适用于这类需求：

- 创建点、线、曲面、特征
- 查 GSM / HybridShape 相关接口
- 查几何服务和几何特征扩展
- 几何特征 UI 或 addin

### 首选文档目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\Doc\online\CAAGsiQuickRefs
```

### 首选 quick ref 标题

- `CAAGsiCATHybridShape.htm`
- `CAAGsiCATIGitGSMGeom.htm`

### 首选示例工程目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\CAAGSMInterfaces.edu
```

优先看这些模块：

- `CAAGsiFeaturesSplAddin.m`
- `CAAGsiFeaturesSplUI.m`
- `CAAGsiNozzle.m`
- `CAAGsiServices.m`
- `CAAGsiToolkit.m`
- `CAAGsiVolumeBooleanOpe.m`

### 优先搜索词

- `CATHybridShapeFactory`
- `CATIGSMFactory`
- `CATIGSMProceduralView`
- `CATIGitGSMGeom`
- `HybridShape`

### 备注

- 这组更偏几何建模能力，不适合作为“最小 UI 插件”起点。

---

## 6. Mechanical Modeler / Part 特征建模 / Addin

### 任务特征

适用于这类需求：

- Part 特征建模
- 机械建模相关 addin
- datum、axis system、feature 行为
- 复制、测量、catalog、建模扩展

### 首选文档目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\Doc\online\CAAMmrUseCases
```

### 首选 use case 标题

- `CAAMmrCombinedCurveSamplesOverview.htm`
- `CAAMmrExtendingCombinedCurveSamplesOverview.htm`
- `CAAMmrAxisSystemCreation.htm`
- `CAAMmrCreateDatum.htm`
- `CAAMmrInterPartCopy.htm`
- `CAAMmrApplicativeAttributes.htm`

### 首选示例工程目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\CAAMechanicalModeler.edu
```

优先看这些模块：

- `CAAMmrCombinedCurveAddIn.m`
- `CAAMmrCombinedCurve.m`
- `CAAMmrPartWksAddin.m`
- `CAAMmrSettingsAddIn.m`
- `CAAMmrAxisSystemCreation.m`
- `CAAMmrUseCreateDatumMode.m`

### 优先搜索词

- `CATIMechanical`
- `CreateDatum`
- `AxisSystem`
- `PartWksAddin`
- `CombinedCurve`

### 备注

- 如果任务既涉及 Part 建模，又涉及按钮挂接，可同时参考本组和 `CAAApplicationFrame.edu`。

---

## 7. Object Specs Modeler / 扩展对象模型 / 工厂创建

### 任务特征

适用于这类需求：

- 建自定义规格对象
- 管理属性与扩展
- 工厂创建 spec/use case
- Build / Update 相关对象模型问题

### 首选文档目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\Doc\online\CAAOsmQuickRefs
```

### 首选 quick ref 标题

- `CAAOsmHome.htm`
- `CAAOsmFaq.htm`

### 首选示例工程目录

```text
C:\DassaultSystemes\CatiaV5R21\CAADoc\CAAObjectSpecsModeler.edu
```

优先看这些模块：

- `CAAOsmCreateExtensions.m`
- `CAAOsmCreateFactoryServices.m`
- `CAAOsmCreateSUByFactory.m`
- `CAAOsmManageExtensions.m`
- `CAAOsmBuildUpdate.m`
- `CAAOsmSimpleAttr.m`

### 优先搜索词

- `ObjectSpecsModeler`
- `BuildUpdate`
- `Factory`
- `Extension`
- `SimpleAttr`

---

## agent 执行时的优先检查点

无论进入哪个示例工程，优先检查这些位置：

- `Imakefile.mk`
- `LocalInterfaces`
- `src`
- `CNext\code\dictionary`
- `CNext\resources\msgcatalog`
- `IdentityCard`

理由：

- `Imakefile.mk` 用来判断 link modules 和依赖框架。
- `LocalInterfaces` 和 `src` 用来确认类组织方式。
- `dictionary` 用来确认 addin / interface 注册方式。
- `msgcatalog` 用来确认 command header、NLS、资源命名关系。
- `IdentityCard` 用来确认框架前置依赖。

## 搜索策略

如果任务已经出现明确接口名，优先全文检索官方根目录：

```powershell
rg -n "<接口名或类名>" C:\DassaultSystemes\CatiaV5R21\CAADoc
```

优先示例：

```powershell
rg -n "CATIPRDWorkshopAddin" C:\DassaultSystemes\CatiaV5R21\CAADoc
rg -n "CATStateCommand" C:\DassaultSystemes\CatiaV5R21\CAADoc
rg -n "CATDlgNotify" C:\DassaultSystemes\CatiaV5R21\CAADoc
rg -n "CATHybridShapeFactory|CATIGSMFactory" C:\DassaultSystemes\CatiaV5R21\CAADoc
```

如果任务还没有明确接口名，先按“任务分类到资料入口的映射”进入对应目录，再从模块名和页面标题反推。

## 最小决策规则

后续 agent 可以按下面这套最小规则快速决策：

1. 任务是按钮、菜单、命令头、workbench：先看 `CAAAfr*`。
2. 任务是对话框、控件、通知：先看 `CAADlg*`。
3. 任务是选择、状态命令、agent、undo/redo：先看 `CAADeg*`。
4. 任务是装配、PRDWorkshop、Product Structure：先看 `CAAPui*` 和 `CAAPst*`。
5. 任务是几何、HybridShape、GSM：先看 `CAAGsi*`。
6. 任务是 Part/Mechanical 特征建模：先看 `CAAMmr*`。
7. 任务是对象模型、工厂、扩展、属性：先看 `CAAOsm*`。

## 不要做的事

- 不要先凭经验猜 `LINK_WITH`，优先找同版本 `Imakefile.mk`。
- 不要先随手新建工程结构，优先模仿同类 `.m` 模块目录。
- 不要只看文档页不看示例工程，CAA 很多关键约定在示例骨架里更直观。
- 不要先跨版本找资料，本机 V5R21 自带文档应作为第一参考源。

## 后续可扩展方向

这份指南下一轮可以继续增强为：

- “任务关键词 -> 具体文件路径”索引
- “常见接口 -> 对应示例模块”索引
- “构建/注册/启动/排错”专项排障表
- “最小可运行模板”清单

当前版本已经可以支持后续 agent 快速完成以下动作：

- 判断该去哪一组官方资料找参考
- 判断该先看哪类示例工程
- 判断进入工程后该优先看哪些文件
- 判断应该用什么关键词在 `CAADoc` 中全文检索
