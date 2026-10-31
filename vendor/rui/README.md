# vendor/rui

`moonbit-community/rui@0.4.0` 的**部分**拷贝，供 tuzi 在脱离 rui 之前先把依赖固定在仓库内。
所有文件均为上游原文（仅删除未使用的私有 helper、去掉测试与 fixture），
包路径改为本地 `kokic/tuzi/vendor/rui`，对外 API 与上游一致，因此
`app/browser` 里的 `@rui.xxx` / `@markdown.xxx` 调用点无需修改。

- 上游：https://github.com/moonbit-community/rabbita（子包 `rui`）
- 版本：`moonbit-community/rui@0.4.0`
- 许可：MIT（见 `LICENSE`、`THIRD_PARTY_NOTICES.md`）

## 目录内容

组件（每个文件一个组件，与上游同名）：

```
alert  badge  breadcrumb  button  command  context_menu  dialog  dropdown_menu
empty  field  input  input_group  item  kbd  message_scroller  native_select
progress  scroll_area  select  sonner  spinner  table  tabs  textarea
theme（设计 token + 全局样式表）  toast（toaster 实现，sonner 依赖它）
```

支撑代码（组件共享的内部实现）：

```
dom_internal    DOM 查询 / 焦点 / 键盘事件工具
icon_internal   内联 SVG 图标
interaction     焦点 id / 滚动 id 命名
menu_internal   菜单（dropdown / context menu）共用的状态机与浮层定位
mount_internal  挂载后回调调度
popover         浮层定位、层级栈、top-layer 管理
separator       scroll_area 需要的分隔线
```

子包：

- `markdown/`：`@markdown.markdown` 渲染器（依赖 `moonbit-community/cmark`，
  不是 rabbita 组件，替换成本高，先整体保留）。
- `internal/checkbox_view/`：`markdown/` 渲染任务列表复选框时使用。

## 与上游的差异

1. 组件文件按“tuzi 实际用到的符号 + 传递闭包”挑选，其余组件文件未拷贝
   （accordion、avatar、calendar、carousel、combobox、sidebar、tooltip 等）。
2. 删除了只被未拷贝组件使用的私有 helper（编译器的 `unused_value` 全部清零）。
3. `markdown/` 删除了 `*_test.mbt`、`__fixtures__/` 以及对应的 `pre-build`
   embed 规则，因此 `_build` 里不会再生成 `async_readme_test.mbt` 等文件。
4. `moon.pkg` 的 import 改为本地路径（`markdown` 指向本地 `internal/checkbox_view`），
   并删掉未使用的 `rabbita/sub`、`warnings = "-unused_package"` 以及只给测试用的
   `for "test"` import。
5. `supported_targets` 统一为 `js`（tuzi 的浏览器端只有 js 目标）。

## 升级方式

需要跟随上游时，重新从 `moonbit-community/rui@<新版本>` 拷贝同名文件覆盖，
再跑 `moon check --target js`，按“unbound / undefined”报错补充被新代码引用到的
文件，最后清掉重新出现的 `unused_value` 告警即可。

## 说明

本目录仅作为过渡期的依赖固定点。tuzi 自己的 UI 组件（基于 rabbita）落地后，
应逐个替换 `@rui.*` 调用并删除对应文件，而不是在这里继续加功能。
