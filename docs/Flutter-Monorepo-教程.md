# Flutter Monorepo 多 Package + melos + CI 质量门禁（Quality Gate）完整落地教程

> 目标读者：从零开始，跟着每一步照做就能跑通。所有命令、文件名、文件内容都已给全。
> 适用场景：把简历里提到的「Monorepo 多 Package + melos + CI 质量门禁」从概念变成"我真做过、我能讲清、我能复现"。

---

## 第一部分：为什么要用这套技术（背景）

### 1.1 单包工程（你现在很可能就是这样）有什么痛点

绝大多数 Flutter 项目一开始都是**单包**，也就是一个 `pubspec.yaml` + 一个 `lib/`：

```
my_app/
├─ lib/
│  ├─ feature/   # 页面代码
│  ├─ data/      # 数据层
│  └─ model/     # 模型
├─ test/
├─ pubspec.yaml
└─ android/ ios/ ...
```

当项目只有几个人、功能少时，这样没问题。但当团队变大、业务变多，会踩到这些坑：

| 痛点 | 具体表现 |
|------|---------|
| **耦合严重** | UI 代码直接 `import` 数据层、数据库代码直接散落在页面里，改一处崩一片 |
| **编译慢** | 每次改动哪怕只动一行工具代码，整个 app 都要全量编译、全量跑测试 |
| **无法独立测试/复用** | 想单独把"播放器模块"抽出来给别的 App 用，发现它扯着整个项目的依赖 |
| **依赖管理混乱** | 所有第三方库挤在一个 pubspec，版本升级互相牵连，谁都不敢动 |
| **边界不清晰** | 新人不知道"网络层放哪、业务逻辑放哪"，代码风格和分层渐渐失控 |
| **无法做 CI 差异化门禁** | 想"只改 core 就跑 core 的测试、只改 UI 才跑 UI 测试"，单包做不到 |

### 1.2 Monorepo 是什么

**Monorepo（单体仓库）**：把**多个相互独立的 Dart/Flutter 包**放进**同一个 git 仓库**，用目录区分。

```
mono_app/              # 这是一个 git 仓库
├─ packages/
│  ├─ core/            # 纯 Dart：常量、工具、通用模型（最底层，谁都不依赖）
│  ├─ domain/          # 纯 Dart：业务实体、用例（依赖 core）
│  ├─ data/            # 数据层：Dio 请求、SQLite、Repository（依赖 core/domain）
│  ├─ feature/         # Flutter：页面、状态管理、UI 组件（依赖上面所有）
│  └─ app/             # Flutter：最终的可运行 App，装配所有 feature
└─ melos.yaml          # melos 配置（组织管理这些包）
```

一句话记忆：**Monorepo = 一个仓库 + 多个 package，按依赖方向分层。**

依赖方向永远是**单向的**（core ← domain ← data ← feature ← app），谁都不许反向 import，这就是分层的意义。

### 1.3 melos 是什么

`melos` 是 **Dart/Flutter 官方的 Monorepo 管理工具**。它帮你解决"一个仓库里有很多包"带来的麻烦：

| 问题 | melos 的解决方案 |
|------|-----------------|
| 几十个包要一个个 `cd` 进去手动操作 | `melos bootstrap` 一键按依赖顺序安装 |
| 想全仓库跑测试/格式化/检查 | `melos run test` / `melos run format` 一键并行跑所有包 |
| 包之间依赖关系要管理 | `melos` 帮你链接本地包，改 core 立刻在 app 生效 |
| CI 里要快速定位改动影响范围 | `melos run --scope` 只对指定包或受影响包执行 |

### 1.4 为什么分层要用 core / domain / data / feature / app

这是业内（含大厂）常见的一种**清晰分层**，每一层职责单一：

- **core**：与业务无关的底层。常量、dart 工具、错误类型、通用小部件。
- **domain**：**业务内核**。实体（Entity）、仓库抽象接口（Repository 接口）、用例（UseCase）。**不依赖任何框架和第三方库**，可独立测试。
- **data**：**domain 的实现**。用 Dio 调接口、用 SQLite 存数据，实现 domain 里定义的接口。可替换、可 mock。
- **feature**：**按业务功能切片**的 Flutter 页面层（如 `feature/auth`、`feature/course`、`feature/player`），用 Riverpod 管理状态、引用 data。
- **app**：**最终组装物**。声明所有 feature、初始化依赖注入、跳路由，`flutter run` 跑的就是它。

好处：**改 data 里的数据库不用动 UI；换播放器内核只动 feature/player；core 和 domain 可以被任意 Flutter App 直接复用。**

### 1.5 CI 质量门禁（Quality Gate）是什么

**质量门禁**：在代码被合并 / 发布之前，用自动化流水线强制执行一系列"检查关卡"，**任何一道不过就阻止合入**，把坏代码挡在发布前。

典型的门禁关卡：

```
① flutter analyze        静态分析，代码风格/潜在 bug 检查
② dart format --set-exit-if-changed   格式是否规范
③ flutter test           单元/Widget 测试是否全绿
④ (可选) 代码覆盖率阈值   如要求 >80%
⑤ build                   三端能否编译通过
```

CI（持续集成）工具：GitHub Actions、GitLab CI、Jenkins 任选。教程用 **GitHub Actions** 举例（最普及、无服务器成本、看得见）。

---

## 第二部分：动手之前，先装好环境（前置准备）

> 下面所有操作都在命令行（终端）执行。Windows 用 PowerShell / CMD，Mac/Linux 用 Terminal。

### 2.1 检查 Flutter 是否装好

打开终端输入：

```bash
flutter --version
```

能看到版本号（如 `Flutter 3.10.x`）即正常。若提示找不到命令，先去 [flutter.dev](https://flutter.dev) 装 Flutter 并配好 PATH 再继续。

### 2.2 启用 Flutter 的 melos 依赖

从 Flutter 3.19 起支持 `melos`（早期叫 `pub workspace`）作为本地包管理。先看版本：

```bash
flutter --version
# 希望是 3.19 或更高
```

### 2.3 安装 melos

melos 是一个全局 Dart 工具，一次性装好：

```bash
dart pub global activate melos
```

装完可以验证：

```bash
melos --version
```

> 若提示 `melos 不是内部或外部命令`，是因为全局 bin 目录没进 PATH。运行下面命令看它装到哪，然后手动加进 PATH 即可：
> ```bash
> dart pub global list
> ```

### 2.4 （可选）确认 git

```bash
git --version
```

有即可。教程后续涉及仓库初始化。

---

## 第三部分：从零搭一个 Monorepo（手把手）

我们从**空白目录**开始，搭一个最小的可运行三层 Monorepo：`core`（纯 Dart）+ `data`（纯 Dart，模拟请求）+ `app`（Flutter，可 run）。

### 3.1 创建工程根目录

```bash
mkdir mono_app
cd mono_app
git init
```

> 这一步后所有命令都在 `mono_app` 内执行。

### 3.2 建目录结构

在 `mono_app` 里创建 `packages` 目录：

```bash
mkdir packages
```

最终结构会是这样（先记着，下面逐个建）：

```
mono_app/
├─ packages/
│  ├─ core/
│  ├─ data/
│  └─ app/
├─ melos.yaml
├─ .gitignore
└─ pubspec.yaml        # 根级 workspace 声明（可选，Flutter 3.19+ 推荐）
```

### 3.3 创建 core 包（最底层，纯 Dart）

#### 第一步：进入并创建目录

```bash
cd packages
mkdir core
cd core
```

#### 第二步：写 core 的 pubspec.yaml

创建 `core/pubspec.yaml`：

```yaml
name: core
description: 最底层，纯 Dart，无任何第三方依赖。
version: 0.0.1
publish_to: none

environment:
  sdk: ^3.0.0

dev_dependencies:
  lints: ^4.0.0
  test: ^1.25.0
```

> `publish_to: none` 表示不发布到 pub.dev，仅内部使用。

#### 第三步：写一个简单的核心代码

创建 `core/lib/app_config.dart`：

```dart
/// 全 App 共享的基础配置（最底层，谁都能用）
class AppConfig {
  const AppConfig({required this.appName, this.baseUrl});

  final String appName;
  final String? baseUrl;
}
```

#### 第四步：给 core 写一个单元测试（后面 CI 会跑它）

创建 `core/test/app_config_test.dart`：

```dart
import 'package:test/test.dart';
import 'package:core/app_config.dart';

void main() {
  test('AppConfig 可以创建', () {
    const config = AppConfig(appName: 'mono_app');
    expect(config.appName, 'mono_app');
    expect(config.baseUrl, isNull);
  });
}
```

core 包建好了。**记住 core 不依赖任何别的东西，也不依赖 Flutter**——这是它能在任意 App 里复用的前提。

### 3.4 创建 data 包（依赖 core）

回到 `packages` 目录创建 data。

```bash
cd ..            # 回到 packages
mkdir data
cd data
```

创建 `data/pubspec.yaml`：

```yaml
name: data
description: 数据层，依赖 core。
version: 0.0.1
publish_to: none

environment:
  sdk: ^3.0.0

dependencies:
  core:
    path: ../core        # 关键：path 依赖，引用本地 core 包

dev_dependencies:
  lints: ^4.0.0
  test: ^1.25.0
```

> `core: path: ../core` 是**本地包依赖**的写法，让 data 直接使用同仓库的 core。

创建 `data/lib/course_repository.dart`：

```dart
import 'package:core/app_config.dart';

/// 模拟从"服务端"获取课程列表的仓库
class CourseRepository {
  CourseRepository({required AppConfig config}) : _config = config;

  final AppConfig _config;

  Future<List<String>> fetchCourses() async {
    // 真实项目里这里是 Dio 请求
    return <String>['Flutter 入门', '状态管理进阶', 'Monorepo 实战'];
  }

  String get host => _config.baseUrl ?? 'https://default.example.com';
}
```

创建 `data/test/course_repository_test.dart`：

```dart
import 'package:test/test.dart';
import 'package:core/app_config.dart';
import 'package:data/course_repository.dart';

void main() {
  test('fetchCourses 返回课程', () async {
    final repo = CourseRepository(config: const AppConfig(appName: 'x'));
    final courses = await repo.fetchCourses();
    expect(courses.length, 3);
  });

  test('host 使用 baseUrl', () {
    final repo = CourseRepository(
      config: const AppConfig(appName: 'x', baseUrl: 'https://api.qq.com'),
    );
    expect(repo.host, 'https://api.qq.com');
  });
}
```

data 建好了。

### 3.5 创建 app 包（Flutter，最终可运行）

回到 `packages` 创建 app。app 是 Flutter 工程，用 `flutter create` 生成最省事。

```bash
cd ..            # 回到 packages
flutter create --project-name app --platforms=android,ios app
```

> 想少生成几个平台目录可以加 `--platforms`，这里只生成 android、ios。想要 web/鸿蒙可后续再 `flutter create --platforms=web .` 补充。

生成的 app 自带 `pubspec.yaml`，我们**改一下**，加入对 data 的依赖：

打开 `app/pubspec.yaml`，在 `dependencies` 里加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  data:
    path: ../data        # 引用本地 data 包
```

> 原模板自带的 `cupertino_icons` 可留可删，教程示例不强依赖它。

然后改造 `app/lib/main.dart`（用 `write_to_file` 覆盖也行，这里给出完整内容）：

```dart
import 'package:flutter/material.dart';
import 'package:core/app_config.dart';
import 'package:data/course_repository.dart';

void main() {
  const config = AppConfig(appName: 'mono_app');
  final repo = CourseRepository(config: config);
  runApp(MyApp(repo: repo));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.repo});

  final CourseRepository repo;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monorepo Demo',
      home: Scaffold(
        appBar: AppBar(title: const Text('Monorepo 分层演示')),
        body: FutureBuilder<List<String>>(
          future: repo.fetchCourses(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final courses = snapshot.data ?? [];
            return ListView.builder(
              itemCount: courses.length,
              itemBuilder: (_, i) => ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(courses[i]),
                subtitle: Text('host: ${repo.host}'),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

> 注意：这里为了演示依赖注入，直接在 `main()` 里手工 new 并往下传。真实大项目会用 Riverpod 的 `ProviderScope` + Provider 注入，本教程聚焦 Monorepo，状态管理不展开。

### 3.6 写 melos.yaml（核心配置文件）

回到**根目录** `mono_app/`（不是 packages），创建 `melos.yaml`：

```bash
cd ../..     # 回到 mono_app 根
```

创建 `melos.yaml`：

```yaml
name: mono_app
packages:
  - packages/**          # 告诉 melos：packages 下的所有目录都是子包

scripts:
  ## ---- 以下命令可用 melos run xxx 一键执行 ----

  # 1) 静态分析所有包
  analyze:
    exec: dart analyze .
    description: 运行所有子包的静态分析

  # 2) 格式化检查
  format:
    exec: dart format --output=none --set-exit-if-changed .
    description: 检查所有子包代码格式是否符合规范
    # --set-exit-if-changed：只要有改动就返回非 0，CI 用来拦截未格式化的代码

  # 3) 跑所有子包测试
  test:
    exec: flutter test
    description: 运行所有子包测试
    concurrency: 4        # 并行度，加快速度

  # 4) 只跑 core 的测试（演示 --scope 精确控制）
  "test:core":
    exec: flutter test
    scope: core           # 只对 core 包生效
```

> 配置要点解释：
> - `exec: dart analyze .` —— melos 会依次进入**每个子包**并执行该命令。
> - `scope` 字段用于**把命令限定在某个包**，实现"只改 core 就只跑 core"。

### 3.7 写 .gitignore（根级）

创建 `mono_app/.gitignore`（合并 Flutter + Dart 的常见忽略项）：

```gitignore
# Dart
.dart_tool/
.packages
pubspec.lock          # 库包通常忽略；应用包可保留

# Flutter（app 包）
**/android/app/build/
**/build/

# 编辑器
.idea/
.vscode/
*.iml

# 系统
.DS_Store
Thumbs.db
```

> `pubspec.lock`：纯库包一般忽略；若根目录把它作为 workspace，可保留。本教程库包忽略即可。

### 3.8 bootstrap：把本地包全部串起来（关键一步）

现在用 melos 把 core / data / app 三者的依赖一次性安装并本地链接。

```bash
melos bootstrap
```

> 它做了什么：自动识别 `packages/**`，按依赖顺序给每个包执行 `pub get`，并建立**本地包之间的 path 链接**，让 app 里 `import 'package:data/...'` 能直接解析到本地源码。

看到类似 `✓ core`、`✓ data`、`✓ app` 即成功。以后**新增了包或改了依赖**，都重新跑一次 `melos bootstrap`。

### 3.9 验证：跑一下看看能不能运行

**（1）全仓库测试：**

```bash
melos run test
```

预期：core、data 的测试全部通过（app 模板自带的 test 也可能跑）。

**（2）全仓库静态分析：**

```bash
melos run analyze
```

预期无 error（warning 不影响，但 CI 建议 0 error）。

**（3）真正把 App 跑起来：**

```bash
cd packages/app
flutter run
```

有连接设备/模拟器就能看到三条课程列表从 data 层取出的效果——**这就是"分层后依然能跑通"的证明**。

---

## 第四部分：在真实项目里怎么用（从你这套在线教育 App 迁移的视角）

教程 3 是"从零建"，这里是"**已有单包工程怎么往 Monorepo 拆**"，给一个可落地的迁移路径，**不要一次性大重构**（风险大、难回滚）。建议按下面顺序小步推进。

### 4.1 渐进式拆包原则

1. **先定目录、别急着动代码**：先在旧 `lib/` 里按 `core / domain / data / feature / app` 建空目录，把现有代码**按职责移动**到对应目录（只移动 import 路径，不改逻辑）。
2. **拆到一定规模再独立成包**：当某个目录（如 data）足够稳定、边界清晰了，才把它抽成独立 package。
3. **用 `melos run --scope` 精准测试**：改 `data` 就只跑 `data` 的测试，回滚面小。

### 4.2 对照你项目的目录建议

| 你现有目录 | Monorepo 建议去处 |
|-----------|------------------|
| `lib/data/model/*.dart`（Banner/Course/Order...） | 底层模型放 **core** 或 **domain**（若含 UI 无关字段） |
| `lib/data/`（Dio 请求、网络层） | **data** 包 |
| 业务页面（首页/课程详情/下单） | **feature** 包（按业务切片 `feature/home`、`feature/course`、`feature/order`） |
| `lib/` 入口、路由、整体装配 | **app** 包 |
| 播放器、Riverpod 状态 | **feature/player**、**feature** |

### 4.3 关键点：不要在 Monorepo 里 commit 生成的 build 目录

`.gitignore` 里必须忽略 `build/`、`.dart_tool/`，否则仓库会迅速膨胀、CI 拉取极慢。

---

## 第五部分：CI 质量门禁（Quality Gate）落地

我们用 **GitHub Actions** 举例（最普及、免费、可视化强）。把工作流文件放到 `mono_app/.github/workflows/ci.yml`。

### 5.1 完整工作流文件内容

创建目录并写入：

```bash
mkdir -p .github/workflows
```

创建 `.github/workflows/ci.yml`：

```yaml
name: CI / Quality Gate

# 什么时候触发：push 到主干 + 所有 PR
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  quality-gate:
    name: 质量门禁（analyze / format / test / build）
    runs-on: ubuntu-latest
    timeout-minutes: 30

    steps:
      # 1) 检出代码
      - name: 检出代码
        uses: actions/checkout@v4

      # 2) 装 Flutter（pin 住版本，保证 CI 与本地一致）
      - name: 安装 Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.19.0'          # 换成你项目用的版本
          channel: 'stable'

      # 3) 装 melos
      - name: 安装 melos
        run: dart pub global activate melos

      # 4) 安装所有子包依赖并本地链接
      - name: melos bootstrap
        run: melos bootstrap

      # 5) 关卡 ①：静态分析 —— 有 error 直接失败
      - name: 静态分析
        run: melos run analyze

      # 6) 关卡 ②：格式检查 —— 未格式化直接失败
      - name: 格式检查
        run: melos run format

      # 7) 关卡 ③：全量测试 —— 有挂直接失败
      - name: 单元测试
        run: melos run test

      # 8) 关卡 ④（可选）：构建 app 验证可编译
      - name: 构建 App（Android debug）
        working-directory: packages/app
        run: flutter build apk --debug

      # 9) 汇总结果（可选：配合分支保护策略，只有全绿才能合入）
      - name: 完成
        run: echo "✅ 所有质量门禁通过"
```

### 5.2 开启"分支保护"让门禁真正生效（关键一步）

光有 yml 还不够，要让"不过就不让合 PR"得在 **GitHub 仓库设置**里开分支保护：

1. 打开仓库 → `Settings` → `Branches` → `Add branch protection rule`。
2. `Branch name pattern` 填 `main`。
3. 勾选 **`Require status checks to pass before merging`**。
4. 勾选上面的 CI 任务名（如 `quality-gate`）。
5. 保存。

> 之后只要 analyze / format / test / build 任一不过，**PR 就合不进去**——这就是真正的"质量门禁"，坏代码无法偷偷上线。

### 5.3 门禁没过的常见报错与修复

| CI 报错 | 原因 | 解决 |
|---------|------|------|
| `Target of URI hasn't been generated: 'package:data/...'` | 没 bootstrap / 本地包没链接 | 在 CI 里确保先 `melos bootstrap` 再跑测试 |
| `dart format` 步骤返回非 0 | 有代码没格式化 | 本地跑 `melos run format` 或 `dart format .` 修完再提交 |
| `flutter analyze` 有 error | 静态分析不过 | 本地跑 `melos run analyze`，按报错修 |
| 找不到 `melos` | 全局 bin 没进 PATH | CI 用 `dart pub global activate melos` 后，确认 runner 的 PATH 生效 |
| Flutter 版本不一致导致构建失败 | CI 与本地版本不同 | 在 `flutter-action` 里 pin 固定版本 |

---

## 第六部分：日常开发工作流（顺一遍感觉）

把整套串起来，日常是这样循环的：

```bash
# 1. 改了 core / data 的代码
# 2. 本地快速验证（可只跑受影响包，也可全跑）
melos run test           # 全量
# 或精准：melos run test --scope=core

# 3. 格式化 + 静态分析确保本地是绿的（提前避免 CI 报错）
melos run format         # 不行就 dart format .
melos run analyze

# 4. 跑通 App 看效果
cd packages/app && flutter run

# 5. 提交 → 推 PR → GitHub 自动跑 CI 质量门禁
git add -A
git commit -m "feat: xxx"
git push origin your-branch
# → PR 全绿才能 merge 到 main
```

---

## 第七部分：常见疑问速查（FAQ）

**Q1：core/domain/data/feature/app 都要用独立 package 吗？会不会太过度？**
不一定每层都拆成独立 package。小项目可以先只拆 `core`（纯 Dart）和 `app`（Flutter）两层，`domain`/`data`/`feature` 先作为 `app` 内的目录。**等某层稳定了、或要被多端复用再拆**，避免过早抽象。

**Q2：core 能不能 import Flutter？**
**不能**。core/domain 是纯 Dart，一旦 import Flutter 就无法被非 Flutter 场景复用、也难独立测试。UI 组件应放 feature 层。

**Q3：melos 和 pub workspace 是什么关系？**
Flutter 3.19+ 提供了 `pub workspace` 内置支持，但 **melos** 更成熟、提供 `scripts`、`--scope`、跨包命令编排等能力。大厂简历和实操常写 melos，本教程用 melos。

**Q4：data 层到底放 Dio 还是 Repository？**
两者都放，但职责分开：**Repository 接口定义在 domain**（只定义"能做什么"），**Dio/SQLite 的具体实现在 data**（实现"怎么做"）。这样换数据库不影响 UI，也便于 mock 测试。

**Q5：只改一个包，全仓库 CI 都要跑一遍，太慢了怎么办？**
用 `--scope` 精确控制，或配置 melos 只对受影响包执行。示例已在 `melos.yaml` 里给了 `test:core`。

**Q6：为什么要 ignore `pubspec.lock`？**
纯库包（core/data）的 lock 会被依赖方解析，committing 会导致本地包更新不生效。而 **app（可执行应用）应保留 lock** 保证构建可复现。

---

## 总结（面试能一句话讲清）

> "我用 **Monorepo** 把客户端拆成 **core / domain / data / feature / app** 多个 package，用 **melos** 统一管理依赖、命令和本地链接；配合 CI 配置了 **analyze / format / test / build** 的 **Quality Gate**，配合分支保护规则，保证任何未通过检查的代码都无法合并，实现按包分层解耦 + 自动化质量兜底。"

**落地顺序速查（照做就能成）：**

1. `flutter create` 建 app → 手写 core、data 两个纯 Dart 包
2. 根目录写 `melos.yaml`
3. `melos bootstrap` 串起所有包
4. `melos run analyze / format / test` 本地全绿
5. 提交 `.github/workflows/ci.yml` 到 GitHub
6. 开分支保护规则，门禁生效 ✅
