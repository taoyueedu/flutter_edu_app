# 三端全渠道上架与 CI/CD 落地教程（GitHub Actions 版）

> 目标读者：想把「iOS + 安卓（华为 / 小米 / OPPO / vivo / 应用宝）+ 鸿蒙（HarmonyOS NEXT / 华为应用市场）全渠道上架 + CI/CD」从简历口号变成"我真做过、我能讲清、我能复现"的 Flutter 开发者。
> 本文档基于本仓库（`flutter_edu_app`，应用名「桃悦智科」）的真实目录编写，所有命令、文件名、文件内容都已给全，**一步步照做即可**。
> 本机环境：Windows。文章会明确标注"这一步必须在 Windows / Mac / 云端"做。
> ⚠️ 正文第 1~9 章 + 附录 A/B/C 为「iOS + Android」双端主线；**第 10 章 + 附录 D** 为新增的鸿蒙（HarmonyOS NEXT）第四端。鸿蒙适配用的是 **OpenHarmony SIG 维护的 Flutter 定制版引擎**（官方 Flutter SDK 尚不直接支持鸿蒙，详见第 10 章 10.1），因此第 10 章是独立的一条接入线，完成后 iOS / Android / HarmonyOS 三端共享同一份 Dart 业务代码。

---

## 目录

- 第 0 章 先看明白全局（5 分钟）
- 第 1 章 仓库与本地环境准备（1~2 小时）
- 第 2 章 多环境隔离：flavor + dart-define（半天）
- 第 3 章 签名与密钥安全：keystore / 证书（半天）
- 第 4 章 质量门禁：PR 流水线（30 分钟）
- 第 5 章 Debug 包自动产出：合并 main 流水线（30 分钟）
- 第 6 章 Release 流水线：多渠道签名打包 + 产物归档（重点，1 天）
- 第 7 章 合规清单化闭环（半天 ~ 按审核周期）
- 第 8 章 发版可追溯闭环
- 第 9 章 从零走一遍：端到端演练 + 验收清单
- 第 10 章 鸿蒙（HarmonyOS NEXT）端接入 + CI（重点，含真实工程改动，1~2 天）
- 附录 A GitHub Secrets 全量对照表
- 附录 B 各安卓市场开通时需要的材料与签名信息
- 附录 C 落地操作卡：7 份文件照着抄（直接粘贴，无需回正文翻找）
- 附录 D 鸿蒙落地操作卡：用定制 Flutter 引擎产出 HAP + 签名 + CI（照着抄）

---

## 第 0 章 先看明白全局（5 分钟）

### 0.1 你要实现的最终效果

你最终会得到**三条互不干扰的自动化流水线** + **一套可归档可追溯的发版记录**：

```
┌──────────────────────────────────────────────────────────────────┐
│ 第 1 条：PR 质量门禁（每次提 PR 自动触发）                          │
│   flutter pub get → flutter analyze → flutter test                 │
│   analyze 有 1 个 error 或测试有 1 个失败 → 直接标红，不许合并       │
├──────────────────────────────────────────────────────────────────┤
│ 第 2 条：合并到 main 自动出 Debug 包（内部测试自取）                 │
│   push main → 自动构建 staging 环境 debug APK → 上传为可下载的 artifact     │
├──────────────────────────────────────────────────────────────────┤
│ 第 3 条：Release 发布（手动填版本号触发）                           │
│   构建 prod 签名包（aab + apk）→ 打进 commit hash / 构建号          │
│   → 产物自动挂到 GitHub Release + artifact 归档 → 下载上传各市场    │
│   （iOS job 在 macOS 机器上出 ipa，可选自动上传 App Store Connect）  │
└──────────────────────────────────────────────────────────────────┘
```

同时你会完成：
1. **多环境隔离**：`dev` / `staging` / `prod` 三套配置，API 域名、Android 包名后缀、桌面显示名/图标互相区分，环境切错会导致连不上或走错服务器，逼着你把"环境"做成工程概念而不是注释。
2. **密钥不进代码库**：Android 签名 keystore、iOS 证书全部以 base64 形式放进 GitHub Secrets，构建时注入，`.gitignore` 兜底。
3. **合规 checklist 闭环**：iOS / Android / 国内商店的审核要求逐项列清单、指定 owner、留验收截图。
4. **发版可追溯**：每个包内嵌 `版本号 + 构建号 + commit hash`，产物文件名也带这些信息，线上出问题能一步回溯到代码提交。

> 先声明边界（面试也按这个说）：上传到各安卓市场、App Store 最终点"提交审核"这一步**仍是人工操作**（各平台审核后台不接受统一 API 一键代传，且提交审核需要人工核对材料），流水线负责的是"从代码到合格产物的自动化 + 全程留痕"。这就是"半自动"。

### 0.2 需要的账号、工具、钱（先准备好再动手）

| 用途 | 账号 / 工具 | 成本 | 什么时候要 |
|---|---|---|---|
| 托管代码 + 跑流水线 | GitHub 账号（免费） | 免费，私有仓库需付费或改用免费公开仓库（练习建议公开） | 第 1 章 |
| Android 构建 | 本机 Flutter SDK（已装）、JDK 17（随 Android Studio 自带） | 免费 | 一直在用 |
| iOS 构建 | **一台 macOS**（GitHub Actions 的 macos runner 可代替，免费额度 2000 分钟/月） | 练习 0 元 / 正式可用免费额度 | 第 6 章 iOS |
| iOS 上架 | Apple Developer 账号 | ¥688/年 | 第 6 章 iOS |
| Android 上架 | 华为开发者、小米开放平台、OPPO 开放平台、vivo 开放平台、腾讯应用宝开放平台 各注册一个 | 华为/小米/OPPO/vivo 首次有认证费或按要求缴纳（以各平台当前政策为准），应用宝免费 | 第 7 章 |
| 国内合规 | 软著（可选加急代办）、APP 备案（用云厂商免费通道）、隐私政策页面 | 软著几百~上千元 | 第 7 章 |
| GitHub CLI | `gh`（可选，方便在 PowerShell 里操作 Secret/Release） | 免费 | 第 3、6 章 |

> 练习提示：如果只是想先跑通流水线，Android 部分（第 1~6 章的 Android job）在 Windows + 免费 GitHub 仓库即可全部完成，一个安卓市场账号都不用注册；iOS 部分可以先只搭 workflow，等有 Mac 或想真上架再走完整签名。

### 0.3 本教程的命名约定

| 项 | 本教程示例 | 你要换成的值 |
|---|---|---|
| 仓库名 | `flutter_edu_app` | 你的仓库名 |
| 应用中文名 | 桃悦智科 | 你的应用名 |
| Android/iOS 正式包名 | `com.taoyue.edu` | 你的正式包名（**全网唯一**，先想好再改，上架后不能改） |
| 后端域名（示例） | `https://api.taoyue.com` | 你的 staging / prod 域名 |
| GitHub 分支 | `main` | 你的主分支 |

> 后面所有代码里的 `taoyue` / `桃悦智科` / `com.taoyue.edu` 都要替换成你自己的。正式包名规则：必须是你拥有的域名反写（如公司域名 `taoyue.com` → `com.taoyue.edu`），**不能**用 `com.example.*` 上架。

### 0.4 关键词速查（先扫一眼，后面遇到再回来看）

| 词 | 一句话解释 |
|---|---|
| CI/CD | 持续集成 / 持续交付。代码一提交就自动 检查→构建→产出包 |
| GitHub Actions | GitHub 内置的 CI 工具。在仓库建一个 `.github/workflows/*.yml` 文件，GitHub 就按文件里的"剧本"跑任务 |
| workflow | 一份 yml 就是一个流水线剧本 |
| job / step | workflow 里有多个 job（可理解为"干活的机器"），每个 job 里多个 step（一步步命令） |
| runner | 干活的那台机器。Linux（免费）构建安卓；macOS 构建 iOS |
| artifact | 流水线产出的文件（apk / aab / ipa / 日志），可在 Actions 页面下载 |
| Secrets | GitHub 的"保险柜"，存密码/证书，只有 workflow 能用，任何人看不到原文 |
| flavor | Android 的多环境/多渠道编译变体，可让不同变体有不同的包名后缀、图标、名称 |
| dart-define | `flutter build` 时的编译期参数，`--dart-define=KEY=value` 可把值注入 Dart 代码 |
| keystore | Android 的签名文件（.jks/.keystore），没它 Android 应用装不上、更不可能上架 |
| provisioning profile | iOS 的"上架许可证"，配合证书（.p12）给 ipa 签名 |
| Privacy Manifest | Apple 要求 App 声明的隐私数据清单文件 `PrivacyInfo.xcprivacy` |
| targetSdk | Android 应用声明"我适配到哪个 Android 版本"，各市场有最低要求 |
| 64 位 so | Android 应用的本地库（.so）必须提供 64 位版本，否则 2021 年后上不了主流市场 |
| APP 备案 | 2023 年 8 月起国内安卓市场强制要求：App 上线前须完成工信部 APP 备案 |

---

## 第 1 章 仓库与本地环境准备（1~2 小时）

> 目标：把项目推到 GitHub，保证本地一条命令能跑出 apk，并处理掉"测试必红"的历史遗留问题。这一章做完，你才有资格谈 CI。

### 1.1 把项目变成 git 仓库并推到 GitHub

如果项目还不是 git 仓库，先初始化：

```powershell
cd e:\projects\2507A\flutter_edu_app
git init
git add -A
git commit -m "chore: 项目基线（CI/CD 落地前）"
```

在 GitHub 网页上新建一个空仓库（不勾选任何初始化文件），然后推上去：

```powershell
git branch -M main
git remote add origin https://github.com/<你的用户名>/flutter_edu_app.git
git push -u origin main
```

### 1.2 本地基线验证：先保证"能编译、测试能过"

打开 PowerShell，在项目根目录依次执行：

```powershell
flutter doctor
flutter pub get
flutter analyze
flutter test
```

预期结果：
- `flutter analyze`：应输出 `No issues found!`。如果报错，先把代码错误改完再继续（这是你未来每一版 PR 都会被自动卡的条件，现在先人工过一次）。
- `flutter test`：**当前仓库大概率会失败**。原因：`test/widget_test.dart` 还是 Flutter 脚手架生成的模板，它引用了不存在的 `MyApp`，而本项目真正的根组件叫 `TaoyueEduApp`（在 `lib/app.dart`）。

修复方法：把 `test/widget_test.dart` 整个替换成下面这个"冒烟测试"（断言能启动 App 且底部导航渲染出来）。这个测试不依赖网络，永远稳定：

```dart
// test/widget_test.dart
// 冒烟测试：App 能正常启动，主框架（底部导航）渲染出来。
// 说明：项目根组件是 TaoyueEduApp（lib/app.dart），不是脚手架模板的 MyApp。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_edu_app/app.dart';

void main() {
  testWidgets('App 启动冒烟测试：能看到底部导航「首页」', (WidgetTester tester) async {
    await tester.pumpWidget(const TaoyueEduApp());

    // 底部导航四个 Tab 文案是稳定的（见 lib/ui/main/main_page.dart）
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
}
```

保存后再跑：

```powershell
flutter test
```

看到类似 `All tests passed!` 就说明基线 OK。

> 你以后每次面试都能讲这个故事：**"脚手架默认的 counter 测试和真实 App 对不上，跑 CI 必红——这正说明单测门禁必须先落到真实项目上，而不是摆样子。"**

再确认 Android 能出包：

```powershell
flutter build apk --debug
```

产物在 `build\app\outputs\flutter-apk\app-debug.apk`。**看到这个文件 = 本机构建链路通。**

### 1.3 .gitignore 补上密钥兜底规则

打开根目录 `.gitignore`，在文件末尾追加（防止以后手滑把密钥提交上去）：

```gitignore
# ---- 签名与密钥：绝不入库 ----
**/*.keystore
**/*.jks
**/*.key
**/key.properties
**/android/app/upload-keystore.jks
**/*.p12
**/*.mobileprovision
**/*.cer

# ---- 本地环境文件 ----
**/ios/exportOptions/*.local.plist
```

保存。这条是"保险丝"，后面几章真正做密钥时它负责兜底。

### 1.4 规范化：包名 + 桌面名称 + iOS 显示名

脚手架默认把包名写成了 `com.example.flutter_edu_app`，上架是**不行的**。本章统一改成你的正式包名（示例 `com.taoyue.edu`）。

> 先搜索确认要改哪些地方：`flutter_edu_app`、`com.example` 会散落在 android/ios 多处，逐个改容易漏。最稳的办法是按下面 4 个文件改，然后全局搜一遍兜底。

**① Android 的 namespace 和 applicationId —— `android/app/build.gradle.kts`**

把第 9 行和第 24 行改成正式包名：

```kotlin
namespace = "com.taoyue.edu"
// ...
applicationId = "com.taoyue.edu"
```

> 改完 `MainActivity.kt` 的 `package` 行如果 IDE 报错，把目录 `android/app/src/main/kotlin/com/example/flutter_edu_app/` 移动到 `android/app/src/main/kotlin/com/taoyue/edu/`，并把文件内 `package com.example.flutter_edu_app` 改成 `package com.taoyue.edu`。

**② Android 桌面显示名 —— `android/app/src/main/AndroidManifest.xml`**

现在 `android:label="flutter_edu_app"`（桌面图标下显示的是英文工程名），改成引用字符串资源：

```xml
    <application
        android:label="@string/app_name"
        android:name="${applicationName}"
        android:usesCleartextTraffic="true"
        android:icon="@mipmap/ic_launcher">
```

**③ 新建字符串资源 —— `android/app/src/main/res/values/strings.xml`**

如果该文件不存在就新建（目录已存在）：

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">桃悦智科</string>
</resources>
```

**④ iOS 显示名 —— `ios/Runner/Info.plist`**

把 `CFBundleDisplayName` 从 `Flutter Edu App` 改成中文名：

```xml
	<key>CFBundleDisplayName</key>
	<string>桃悦智科</string>
```

**⑤ 兜底检查**：全局搜一遍还有没有漏网的旧名

```powershell
# 在仓库根目录执行，逐个核对残留的 com.example / flutter_edu_app（排除 build/ 目录）
rg "com\.example|flutter_edu_app" --glob "!build/**" --glob "!.dart_tool/**"
```

预期只剩：`pubspec.yaml` 的 `name: flutter_edu_app`（这是 Dart 包名，**不用改**）、`test/widget_test.dart` 的 import 路径、`README.md` 等无害引用。

### 1.5 验证第 1 章完成

```powershell
flutter analyze          # No issues found!
flutter test             # All tests passed!
flutter build apk --debug  # 出包成功
git add -A && git commit -m "chore: 包名/显示名规范化 + 冒烟测试基线" && git push
```

**完成标志**：GitHub 仓库里能看到这次提交，且代码是"干净可构建"的。到这一步你已经有资格开第 2 章了。

---

## 第 2 章 多环境隔离：flavor + dart-define（半天）

> 目标：让 `dev`（本地开发）/ `staging`（内测）/ `prod`（上架）三套环境能共存，切环境不靠改代码，靠**构建参数**。API 域名不同、Android 包名后缀不同、桌面图标/名称可区分。

### 2.1 先定三套环境的口径（写进 README，全组统一说法）

| 环境 | flavor 名 | Android applicationId | 用途 | API 域名示例 |
|---|---|---|---|---|
| dev | `dev` | `com.taoyue.edu.dev` | 开发者本机联调 | 默认 127.0.0.1:8000 |
| staging | `staging` | `com.taoyue.edu.staging` | 内部验收/测试 | `https://staging-api.taoyue.com` |
| prod | `prod` | `com.taoyue.edu` | 各市场上架 | `https://api.taoyue.com` |

记忆：**包名后缀 = 环境开关**。三套能同时装在一台手机上（包名不同），永远不会"把 staging 当正式版发给用户"。

### 2.2 Dart 侧：从编译参数读取配置（改 1 个文件）

当前 `lib/core/constants/app_config.dart` 把域名硬编码成了 `127.0.0.1:8000`。我们把它改成"优先读编译参数、不传就用本机地址"，这样 `lib/core/network/api_client.dart` 里所有 `AppConfig.baseUrl` 的引用**一行都不用改**（字段还是 `const`）。

把整个文件替换为：

```dart
/// 全局配置
/// 三套环境（dev / staging / prod）的值在构建时用 --dart-define 注入：
///   dev:     默认值，无需注入
///   staging: flutter run --dart-define=APP_ENV=staging \
///                        --dart-define=API_BASE_URL=https://staging-api.taoyue.com
///   prod:    flutter build apk --dart-define=APP_ENV=prod \
///                        --dart-define=API_BASE_URL=https://api.taoyue.com
/// 可追溯字段（COMMIT_HASH / BUILD_NUMBER）由 CI 注入，见第 8 章。
class AppConfig {
  AppConfig._();

  /// 当前构建环境：dev / staging / prod
  static const String env =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  /// 后端地址
  /// - 默认值保留本机调试地址（Windows 桌面 / 真机）
  /// - Android 模拟器访问宿主机请传 --dart-define=API_BASE_URL=http://10.0.2.2:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// 本次构建对应的 git commit（短哈希），用于线上回溯，CI 注入
  static const String commitHash =
      String.fromEnvironment('COMMIT_HASH', defaultValue: 'unknown');

  /// 本次构建号（自动递增），CI 注入
  static const String buildNumber =
      String.fromEnvironment('BUILD_NUMBER', defaultValue: '0');

  /// 是否为正式环境（决定日志、测试入口等行为）
  static bool get isProd => env == 'prod';

  /// 分页大小
  static const int pageSize = 10;

  /// 超时时间（秒）
  static const int connectTimeout = 10;
  static const int receiveTimeout = 15;

  /// 本地 Token 存储 key
  static const String tokenKey = 'taoyue_token';
  static const String userKey = 'taoyue_user';
}
```

验证（这条命令在任何环境都能立刻跑通，域名仍是本机）：

```powershell
flutter analyze
```

### 2.3 Android 侧：productFlavors（改 1 个文件）

把 `android/app/build.gradle.kts` 整体替换为下面内容。它相比原来多了：`flavorDimensions` + 三个 `productFlavors`（dev/staging/prod）、显式固定 `targetSdk`（第 7 章合规需要）、从 `key.properties` 读签名（第 3 章才用到，现在先留着配置不报错）：

```kotlin
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------- 签名信息：只从 key.properties 读取（本地）或 CI 动态生成 ----------
// 该文件已被 .gitignore 忽略，绝不允许提交到仓库。
fun loadSigningProperties(): Properties {
    val props = Properties()
    val keyProps = rootProject.file("key.properties")
    if (keyProps.exists()) {
        props.load(FileInputStream(keyProps))
    }
    return props
}
val signingProps = loadSigningProperties()

android {
    namespace = "com.taoyue.edu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // 正式包名（全网唯一，上架后不可改）
        applicationId = "com.taoyue.edu"
        minSdk = flutter.minSdkVersion
        // 显式固定 targetSdk，便于和各安卓市场要求对齐（第 7 章合规点之一）
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ---------- 多环境 flavor：dev / staging / prod ----------
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            // 包名后缀是环境隔离的根：三套包可以同时装在一台手机上
            applicationIdSuffix = ".dev"
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
        }
        create("prod") {
            dimension = "env"
            // 无后缀 = 正式包名 com.taoyue.edu
        }
    }

    signingConfigs {
        create("release") {
            val storeFileProp = signingProps.getProperty("storeFile")
            if (storeFileProp != null) {
                storeFile = file(storeFileProp)
                storePassword = signingProps.getProperty("storePassword")
                keyAlias = signingProps.getProperty("keyAlias")
                keyPassword = signingProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // 有 key.properties（本地）或 CI 注入时才启用正式签名；
            // 没有签名配置时 release 构建会失败——这是故意的，防止产出未签名包。
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

flutter {
    source = "../.."
}
```

> `targetSdk = 34` 说明：Android 上架主流市场的最低 targetSdk 要求逐年抬高（华为/小米/OPPO/vivo/应用宝均要求达到各自规定值，最新以各平台 2024 年后公告为准，通常 ≥ 33）。`34` 是稳妥值；若你用的 Flutter 版本默认更高，可保留 `flutter.targetSdkVersion`。面试被问就答："项目显式固定 targetSdk 到市场要求值并跟随官方升级节奏"。

### 2.4 三套桌面名称（让手机一眼分辨）

每个 flavor 都有独立的资源目录，放同名 `strings.xml` 即可覆盖主目录里的 `app_name`。

新建 `android/app/src/dev/res/values/strings.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">桃悦智科-dev</string>
</resources>
```

新建 `android/app/src/staging/res/values/strings.xml`：

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">桃悦智科-staging</string>
</resources>
```

`prod` 不需要建（继承第 1 章在主目录定义的"桃悦智科"）。

### 2.5 三套图标（可选但建议做，简历点"图标区分"靠它）

原理：`src/<flavor>/res/mipmap-*` 里的同名 `ic_launcher.png` 会自动覆盖主目录图标。做法：

1. 准备三张 1024×1024 的 PNG 源图，放到 `assets/icon/`（新建目录）：
   - `assets/icon/dev.png`（建议底色上印"DEV"）
   - `assets/icon/staging.png`（建议印"STAGING"）
   - `assets/icon/prod.png`（正式图标）
2. 用下面脚本一键生成三套各密度图标到对应 flavor 目录（Windows PowerShell，保存为 `tool/gen_flavor_icons.ps1`）：

```powershell
# tool/gen_flavor_icons.ps1
# 用法：powershell -ExecutionPolicy Bypass -File tool/gen_flavor_icons.ps1
# 前置：assets/icon/dev.png staging.png prod.png（1024x1024）
Add-Type -AssemblyName System.Drawing

$targets = @(
    @{ Flavor = 'dev';     Src = 'assets/icon/dev.png' },
    @{ Flavor = 'staging'; Src = 'assets/icon/staging.png' },
    @{ Flavor = 'prod';    Src = 'assets/icon/prod.png' }
)

# Android launcher icon 各密度尺寸（px）
$densities = @(
    @{ Dpi = 'mdpi';    Size = 48 },
    @{ Dpi = 'hdpi';    Size = 72 },
    @{ Dpi = 'xhdpi';   Size = 96 },
    @{ Dpi = 'xxhdpi';  Size = 144 },
    @{ Dpi = 'xxxhdpi'; Size = 192 }
)

foreach ($t in $targets) {
    $srcPath = Join-Path $PSScriptRoot '..' $t.Src
    if (-not (Test-Path $srcPath)) {
        Write-Host "缺少源图: $($t.Src)，跳过 $($t.Flavor)" -ForegroundColor Yellow
        continue
    }
    $img = [System.Drawing.Image]::FromFile((Resolve-Path $srcPath))
    foreach ($d in $densities) {
        $outDir = Join-Path $PSScriptRoot '..' "android/app/src/$($t.Flavor)/res/mipmap-$($d.Dpi)"
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
        $bmp = New-Object System.Drawing.Bitmap $img, $d.Size, $d.Size
        $outFile = Join-Path $outDir 'ic_launcher.png'
        $bmp.Save($outFile, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        Write-Host "生成 $outFile"
    }
    $img.Dispose()
}
Write-Host "完成。三套图标已写入对应 flavor 的 res 目录。"
```

3. 在项目根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File tool\gen_flavor_icons.ps1
```

> 若你没有 System.Drawing（PowerShell 7 在部分系统缺该程序集），退路是：手动把源图缩放成 192px 后，用 Android Studio 的 Image Asset（右键 `res` → New → Image Asset）分别生成到 `src/dev/res`、`src/staging/res`、`src/prod/res`，路径填对应目录即可。

### 2.6 验证第 2 章完成

依次构建三套 debug 包（Windows 上都能跑）：

```powershell
flutter build apk --debug --flavor dev
flutter build apk --debug --flavor staging
flutter build apk --debug --flavor prod
```

产物应出现在 `build\app\outputs\flutter-apk\`，文件名分别是 `app-dev-debug.apk`、`app-staging-debug.apk`、`app-prod-debug.apk`。

装到模拟器或真机（如 dev 包）：

```powershell
flutter install --debug --flavor dev
```

或直接 `adb install build\app\outputs\flutter-apk\app-dev-debug.apk`。

**完成标志**：三套包都能出、都能装；手机桌面上 `桃悦智科-dev` / `桃悦智科-staging` / `桃悦智科` 三个图标并存且图标可区分。

跑 staging/prod 时带域名注入试一把（会连不上你的域名是正常的，只要不报编译错即可）：

```powershell
flutter build apk --debug --flavor staging --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging-api.taoyue.com
```

提交这一章成果：

```powershell
git add -A
git commit -m "feat(ci): 引入 dev/staging/prod 三环境 flavor + dart-define 注入"
git push
```

---

## 第 3 章 签名与密钥安全：keystore / 证书（半天）

> 目标：Android 正式签名 keystore + iOS 证书（Distribution + 描述文件）全部**不落仓库**：本地用被 gitignore 的 `key.properties`，CI 用 GitHub Secrets。密钥丢失 = 线上 App 永远无法更新，所以本章反复强调备份。

### 3.1 Android 生成 keystore（Windows 可做，只做一次，终生使用）

打开 PowerShell，在 `android/app` 目录执行（密码自己换成足够强的，**务必记到密码管理器**）：

```powershell
cd e:\projects\2507A\flutter_edu_app\android\app
keytool -genkeypair -v `
  -keystore upload-keystore.jks `
  -alias upload `
  -keyalg RSA -keysize 2048 -validity 10950 `
  -storepass "换成你自己的强密码" -keypass "换成你自己的强密码" `
  -dname "CN=桃悦智科, OU=移动研发部, O=桃悦智科, L=Beijing, ST=Beijing, C=CN"
```

`-validity 10950` = 30 年。命令成功后目录里出现 `upload-keystore.jks`。

**立刻做双份备份**（这是整个教程里唯一"丢了就完蛋"的文件）：
1. U 盘 / 网盘加密压缩包放一份；
2. 密码管理器里记录 `storePassword`、`keyPassword`、`keyAlias=upload`、keystore 文件本身；
3. 换一台电脑验证能用它签名（第 3.3 节验证命令跑一遍）。

### 3.2 本地 key.properties（不入库）

在 `android/key.properties`（注意：在 `android/` 目录下，不是 `android/app/`）新建：

```properties
storePassword=第3.1步设的 storepass
keyPassword=第3.1步设的 keypass
keyAlias=upload
storeFile=app/upload-keystore.jks
```

> 路径说明：`android/app/build.gradle.kts` 里的 `file(storeFileProp)` 是相对 `android/app` 模块目录的，所以 keystore 在 `android/app/upload-keystore.jks`，key.properties 写在 `android/` 下，相对引用写 `app/upload-keystore.jks`。

确认已被 gitignore 兜底（第 1.3 章已加规则）：

```powershell
git check-ignore android/key.properties android/app/upload-keystore.jks
```

两条路径都应被打印出来（= 已忽略）。**如果没打印，先别继续，回第 1.3 章补 .gitignore。**

### 3.3 验证正式签名能出包（Windows 可做）

```powershell
flutter build apk --release --flavor prod
```

产物：`build\app\outputs\flutter-apk\app-prod-release.apk`。

验证签名（JDK 自带 keytool）：

```powershell
keytool -printcert -jarfile build\app\outputs\flutter-apk\app-prod-release.apk
```

能看到证书 CN=桃悦智科 就是成功。**顺手把输出的 SHA1 / SHA256 / MD5 抄下来**——第 7 章各安卓市场开通时，要把签名 MD5/SHA1 填进华为/小米/OPPO/vivo/应用宝的开发者后台。

### 3.4 iOS 证书与描述文件（需要一台 Mac，可放到最后做）

iOS 无 Mac 无法在本地出 ipa，但**证书材料现在就可以准备好**，第 6 章 CI 直接用。以下在任意一台装有 Xcode 的 Mac 上做一次：

1. 打开 <https://developer.apple.com/account>（需 Apple Developer 账号，¥688/年）。
2. **Certificates** → 新建 `Apple Distribution` 类型证书（上架 ipa 用它），下载 `.cer`，双击导入钥匙串。
3. 在钥匙串里右键该证书 → 导出为 `.p12`，**必须设导出密码**（CI 注入要用）。
4. **Identifiers** → 注册 App ID：Bundle ID 填 `com.taoyue.edu`（和 Android applicationId 同值，或按你 iOS 命名习惯）。
5. **Provisioning Profiles** → 新建 `App Store` 类型描述文件，关联上面的 App ID 和 Distribution 证书，下载 `.mobileprovision`。
6. 用 Xcode 对项目做一次"真上架前演练"：Archive → Distribute App → App Store Connect → 手动签名（Manual），跑通一次后把 Xcode 生成的 `exportOptions.plist` 复制一份到仓库 `ios/exportOptions/AppStore.plist`（它只含 method/teamID/签名方式，不含密钥，可以入库）。模板见下：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>teamID</key>
	<string>你的10位TeamID（Apple后台成员页可见）</string>
	<key>signingStyle</key>
	<string>manual</string>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>uploadSymbols</key>
	<true/>
</dict>
</plist>
```

> 只有导出 ipa 这一步需要 Mac；把 `.p12` 和 `.mobileprovision` 两个文件转成 base64 字符串（第 3.5 节）后，**后续打包全部由 GitHub 的 macOS 机器自动完成**，你不需要在自己电脑装 iOS 环境。

### 3.5 把密钥转成 Secrets（第 6 章 CI 用，现在先存好）

用 GitHub CLI（推荐，先 `gh auth login`）：

```powershell
# 1) Android keystore 转 base64
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\upload-keystore.jks")) | gh secret set ANDROID_KEYSTORE_BASE64

# 2) iOS p12 转 base64（在 Mac 上执行对应命令，或在本机先把 p12 拷过来再执行）
[Convert]::ToBase64String([IO.File]::ReadAllBytes("cert.p12")) | gh secret set APPLE_CERT_P12_BASE64
gh secret set APPLE_CERT_P12_PASSWORD        # 提示输入 p12 导出密码

# 3) iOS 描述文件
[Convert]::ToBase64String([IO.File]::ReadAllBytes("Distribution.mobileprovision")) | gh secret set APPLE_PROVISION_PROFILE_BASE64
```

没有 `gh` 的替代法：在 GitHub 仓库页 `Settings → Secrets and variables → Actions → New repository secret`，把 base64 字符串手动粘贴进去（keystore 一般 3~6KB，base64 后远小于 GitHub 单 Secret 64KB 上限，放心）。

**验证 Secrets 是否设置成功**：

```powershell
gh secret list
```

应能看到 `ANDROID_KEYSTORE_BASE64`、`APPLE_CERT_P12_BASE64`、`APPLE_CERT_P12_PASSWORD`、`APPLE_PROVISION_PROFILE_BASE64`。

> 第 6 章 workflow 会把这些 Secret 拼回文件并放到 CI 机器上。现在先别纠结"CI 怎么用"，第 4~5 章先跑通不需要密钥的两条流水线。

### 3.6 验证第 3 章完成

- [ ] `flutter build apk --release --flavor prod` 成功，`keytool -printcert` 能读出证书；
- [ ] `git check-ignore` 确认 key.properties 和 jks 被忽略；
- [ ] `gh secret list` 能看到 4 个 Secrets；
- [ ] （Mac）已产出 `.p12` + `.mobileprovision` + `ios/exportOptions/AppStore.plist`。

提交（注意别把 keystore 提交进去）：

```powershell
git add -A
git commit -m "chore(ci): 签名配置与密钥管理规范（key.properties gitignore + 双份备份）"
git push
```

> 面试必答题：**"密钥怎么不进代码库？"** —— "Android keystore 以 base64 存 GitHub Secrets，CI 里拼回文件；iOS 的 p12 和描述文件同样走 Secrets。本地用一个被 gitignore 的 key.properties，Gradle 里做了空值保护，没有密钥时 release 构建会直接失败，杜绝误用 debug 签名上架。"

---

## 第 4 章 质量门禁：PR 流水线（30 分钟）

> 目标：每次有人提 Pull Request（PR），GitHub 自动跑 `flutter analyze` + `flutter test`，**有 1 个 error 或 1 个测试失败就标红**，不许合并。这就是流水线第 1 段。

### 4.1 workflow 文件放哪、长什么样

所有流水线剧本都放在 `.github/workflows/` 目录，一个 `.yml` 文件 = 一条流水线。GitHub 每 5 分钟扫一次仓库，发现新文件/改动就生效。

先建目录：

```powershell
mkdir .github\workflows
```

### 4.2 创建质量门禁剧本

新建 `.github/workflows/quality-gate.yml`，内容如下（**整段复制，不要改缩进**）：

```yaml
name: PR 质量门禁

# 触发条件：任何 PR（目标分支是 main）
on:
  pull_request:
    branches: [ main ]

permissions:
  contents: read

jobs:
  quality-gate:
    name: flutter analyze + test
    runs-on: ubuntu-latest
    steps:
      - name: 检出代码
        uses: actions/checkout@v4

      - name: 安装 Flutter（稳定版，含缓存）
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: 安装依赖
        run: flutter pub get

      # 质量门禁第 1 关：静态检查。有任何 error 输出即失败
      - name: 静态检查 flutter analyze
        run: flutter analyze

      # 质量门禁第 2 关：单元测试。有任何失败用例即失败
      - name: 单元测试 flutter test
        run: flutter test
```

这个文件做了什么（面试讲法）：

| 关键行 | 含义 |
|---|---|
| `on: pull_request` | 只在 PR 时触发，直推 main 不触发（直推会先被分支保护拦，见 4.5） |
| `runs-on: ubuntu-latest` | 免费 Linux 机器，Android 打包足够 |
| `subosito/flutter-action@v2` | 社区标准 Flutter 安装 action，自动缓存 SDK 与 pub 依赖 |
| `flutter analyze` | 静态检查，有 error 就非零退出 → 整个 job 失败 |
| `flutter test` | 跑 `test/` 下所有测试，红一个就失败 |

### 4.3 在本地先等价跑一遍（避免浪费 GitHub 分钟数）

```powershell
flutter pub get
flutter analyze
flutter test
```

确保两行都绿（analyze 输出 `No issues found!`，test 输出 `All tests passed!`），再提交 workflow 文件：

```powershell
git add .github/workflows/quality-gate.yml
git commit -m "ci: PR 质量门禁（analyze + test）"
git push
```

### 4.4 验证：真的会拦人

1. 在 GitHub 网页上新建一个分支并改一行代码，发起 PR 到 `main`（比如改 `lib/app.dart` 里一行注释）。
2. PR 页会立刻出现 `PR 质量门禁` 检查，约 2~4 分钟跑完，绿色 ✅。
3. 恶意验证（可选但强烈建议做一次，你会对"门禁"有体感）：在任意 dart 文件里加一行 `final unused = 1;`，再开一个 PR → 检查变红 ❌，点进去能看到 `flutter analyze` 步骤标红和报错信息。

**完成标志**：PR 页有绿色的质量门禁徽标；坏代码的 PR 会被标红。

### 4.5 分支保护：让"标红"变成"真·不能合并"（可选，建议做）

光有检查还不够，要禁止**绕过检查直接合并 / 直推 main**。做法（网页操作）：

1. GitHub 仓库 → `Settings` → `Branches` → `Add branch protection rule`；
2. Branch name pattern 填 `main`；
3. 勾选：
   - `Require a pull request before merging`（直推 main 被禁）；
   - `Require status checks to pass before merging` → 搜索并勾选 `flutter analyze + test`；
   - 建议勾 `Do not allow bypassing the above settings`。

> 注意：分支保护是仓库功能。**私有仓库**需要 GitHub Pro（$4/月）；**公开仓库免费**。练习期建议直接用公开仓库或先跳过本节，PR 上的红/绿状态本身就是质量信号。

---

## 第 5 章 Debug 包自动产出：合并 main 流水线（30 分钟）

> 目标：只要代码合并到 `main`，GitHub 自动构建一份 **staging 环境、debug 签名**的 APK 并上传成 artifact，测试同学自己去 Actions 页面点下载，**再也不用找开发要包**。这就是流水线第 2 段。

### 5.1 为什么用 staging 环境

第 2 章定了：`dev` 的默认域名是本机 `127.0.0.1`（只有开发者自己机器有用），所以合并主分支后的"自动包"要用 `staging` 环境（连 staging 服务器），这样任何人装上都能直接体验真数据。

### 5.2 创建主分支构建剧本

新建 `.github/workflows/build-debug.yml`：

```yaml
name: 主分支自动出 Debug 包（内部分发）

# 触发条件：代码合并/推送到 main
on:
  push:
    branches: [ main ]

permissions:
  contents: read

jobs:
  build-debug-apk:
    name: 构建 staging debug APK
    runs-on: ubuntu-latest
    steps:
      - name: 检出代码
        uses: actions/checkout@v4

      - name: 安装 Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: 安装依赖
        run: flutter pub get

      # 主分支代码也要求过测试（双保险）
      - name: 单元测试
        run: flutter test

      - name: 计算构建信息
        id: info
        run: |
          echo "short_sha=${GITHUB_SHA::7}" >> "$GITHUB_OUTPUT"
          echo "build_number=$(git rev-list --count HEAD)" >> "$GITHUB_OUTPUT"

      - name: 构建 staging debug APK
        run: |
          flutter build apk --debug --flavor staging \
            --dart-define=APP_ENV=staging \
            --dart-define=API_BASE_URL=https://staging-api.taoyue.com \
            --dart-define=COMMIT_HASH=${{ steps.info.outputs.short_sha }} \
            --dart-define=BUILD_NUMBER=${{ steps.info.outputs.build_number }}

      - name: 上传 artifact（Actions 页可直接下载）
        uses: actions/upload-artifact@v4
        with:
          name: app-staging-debug
          path: build/app/outputs/flutter-apk/app-staging-debug.apk
          retention-days: 30
```

几个要点：
- `git rev-list --count HEAD`：数出仓库历史总提交数，作为**自动递增的构建号**（第 8 章追溯会用到）。
- `COMMIT_HASH` / `BUILD_NUMBER` 是打进 App 的编译期常量（第 2.2 节已在 `AppConfig` 预留），第 8 章做追溯展示。
- `upload-artifact@v4` 把 apk 挂到本次运行页面，`retention-days: 30`（30 天后自动清理——正式包长期归档靠第 6 章的 GitHub Release）。

### 5.3 提交并验证

```powershell
git add .github/workflows/build-debug.yml
git commit -m "ci: 合并 main 自动构建 staging debug 包"
git push
```

推送本身就会触发这条流水线。打开 GitHub 仓库 → `Actions` 标签，能看到正在跑的 `主分支自动出 Debug 包`。

跑完后：点进运行 → 页面底部 `Artifacts` → 下载 `app-staging-debug`（zip，解压出 apk）。

本机验证安装（插着手机或开着模拟器）：

```powershell
adb install build\app\outputs\flutter-apk\app-staging-debug.apk
```

**完成标志**：每次 push main 后 Actions 里自动出现一个可下载的 apk artifact；手机桌面出现"桃悦智科-staging"图标。

---

## 第 6 章 Release 流水线：多渠道签名打包 + 产物归档（重点，1 天）

> 目标：合并 PR、自动包都只是铺垫。本章做的**第 3 段流水线**才是"发版"核心：
> 手动填一个版本号 → 自动产出 **正式签名** 的 `.aab`（Google Play 之外也能用，华为/小米等多数市场支持）+ `.apk`（各市场通用）+ `.ipa`（iOS）→ 所有产物文件名带 `版本号+构建号+commit` → 自动挂到 GitHub Release 归档。

### 6.1 先补齐密钥 Secrets（第 3 章只存了 keystore 本体，还差密码）

在 PowerShell 里补两个密码 Secret（就是第 3.1 步设的 storepass / keypass）：

```powershell
gh secret set ANDROID_KEYSTORE_PASSWORD   # 粘贴 storePassword
gh secret set ANDROID_KEY_PASSWORD        # 粘贴 keyPassword
```

同时补一个 iOS 用的随机 keychain 密码（CI 机器上钥匙串的临时口令，随便生成一串）：

```powershell
$kp = -join ((48..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
$kp | gh secret set KEYCHAIN_PASSWORD
```

最终 Secrets 全量清单见**附录 A**，动手前先对照补齐。

### 6.2 Android Release 剧本：aab + apk

新建 `.github/workflows/release-android.yml`：

```yaml
name: Android Release（正式签名 aab + apk）

# 手动触发：填版本号后运行
on:
  workflow_dispatch:
    inputs:
      version:
        description: '发布版本号（格式 x.y.z，如 1.2.0）'
        required: true
        type: string

permissions:
  contents: write   # 需要写 Release

jobs:
  release-android:
    name: 构建并归档 Android 正式包
    runs-on: ubuntu-latest
    steps:
      - name: 检出代码
        uses: actions/checkout@v4

      - name: 安装 Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: 安装依赖
        run: flutter pub get

      - name: 门禁检查（发布前再兜一次底）
        run: |
          flutter analyze
          flutter test

      - name: 计算版本与构建信息
        id: info
        run: |
          VERSION="${{ inputs.version }}"
          # 校验 x.y.z
          if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "版本号格式错误：$VERSION（应为 x.y.z）"
            exit 1
          fi
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"
          echo "short_sha=${GITHUB_SHA::7}" >> "$GITHUB_OUTPUT"
          echo "build_number=$(git rev-list --count HEAD)" >> "$GITHUB_OUTPUT"

      # ---------- 签名：从 Secrets 恢复 keystore + key.properties ----------
      - name: 注入签名文件
        env:
          KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
          KEYSTORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
        run: |
          echo "$KEYSTORE_BASE64" | base64 --decode > android/app/upload-keystore.jks
          printf 'storePassword=%s\nkeyPassword=%s\nkeyAlias=upload\nstoreFile=app/upload-keystore.jks\n' \
            "$KEYSTORE_PASSWORD" "$KEY_PASSWORD" > android/key.properties

      # ---------- 构建正式签名产物（prod flavor） ----------
      - name: 构建 appbundle（aab）
        run: |
          flutter build appbundle --release --flavor prod \
            --build-name=${{ steps.info.outputs.version }} \
            --build-number=${{ steps.info.outputs.build_number }} \
            --dart-define=APP_ENV=prod \
            --dart-define=API_BASE_URL=https://api.taoyue.com \
            --dart-define=COMMIT_HASH=${{ steps.info.outputs.short_sha }} \
            --dart-define=BUILD_NUMBER=${{ steps.info.outputs.build_number }}

      - name: 构建 universal apk
        run: |
          flutter build apk --release --flavor prod \
            --build-name=${{ steps.info.outputs.version }} \
            --build-number=${{ steps.info.outputs.build_number }} \
            --dart-define=APP_ENV=prod \
            --dart-define=API_BASE_URL=https://api.taoyue.com \
            --dart-define=COMMIT_HASH=${{ steps.info.outputs.short_sha }} \
            --dart-define=BUILD_NUMBER=${{ steps.info.outputs.build_number }}

      # ---------- 产物重命名：文件名就是追溯信息 ----------
      - name: 归集产物（命名带 版本-构建号-commit）
        run: |
          mkdir -p dist
          VER=${{ steps.info.outputs.version }}
          BN=${{ steps.info.outputs.build_number }}
          SHA=${{ steps.info.outputs.short_sha }}
          cp build/app/outputs/bundle/prodRelease/app-prod-release.aab "dist/taoyue-edu_${VER}_${BN}_${SHA}_prod.aab"
          cp build/app/outputs/flutter-apk/app-prod-release.apk "dist/taoyue-edu_${VER}_${BN}_${SHA}_prod.apk"
          ls -lh dist/

      # ---------- 归档：挂到 GitHub Release（自动建 v1.2.0 这个 Release） ----------
      - name: 创建 Release 并挂载产物
        uses: softprops/action-gh-release@v2
        with:
          tag_name: v${{ steps.info.outputs.version }}
          name: v${{ steps.info.outputs.version }}
          generate_release_notes: true
          files: dist/*

      # ---------- 备份：同时传一份 artifact（运行页留底） ----------
      - name: 上传构建日志与产物备份
        uses: actions/upload-artifact@v4
        with:
          name: android-release-${{ inputs.version }}
          path: |
            dist/*
            build/app/outputs/*.log
          retention-days: 90
```

> 说明：`softprops/action-gh-release` 会自动创建（或更新）`v1.2.0` 这个 tag 与 Release，把 `dist/` 下所有文件挂成 Release 资产，并基于上一次 tag 自动生成发布说明。Release 资产**永久保留**，这就是长期归档。

### 6.3 iOS Release 剧本：签名 ipa（需要配好第 3.4 节材料）

新建 `.github/workflows/release-ios.yml`：

```yaml
name: iOS Release（正式签名 ipa）

on:
  workflow_dispatch:
    inputs:
      version:
        description: '发布版本号（格式 x.y.z，如 1.2.0，须与 Android 一致）'
        required: true
        type: string

permissions:
  contents: write

jobs:
  release-ios:
    name: 构建并归档 iOS 正式包
    # iOS 构建必须用苹果生态：GitHub 的 macos runner
    runs-on: macos-14
    steps:
      - name: 检出代码
        uses: actions/checkout@v4

      - name: 安装 Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: 安装依赖
        run: flutter pub get

      - name: 计算版本与构建信息
        id: info
        run: |
          VERSION="${{ inputs.version }}"
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"
          echo "short_sha=${GITHUB_SHA::7}" >> "$GITHUB_OUTPUT"
          echo "build_number=$(git rev-list --count HEAD)" >> "$GITHUB_OUTPUT"

      # ---------- 证书与描述文件注入（Secrets → 系统钥匙串） ----------
      - name: 导入 Apple 证书与描述文件
        env:
          P12_BASE64: ${{ secrets.APPLE_CERT_P12_BASE64 }}
          P12_PASSWORD: ${{ secrets.APPLE_CERT_P12_PASSWORD }}
          PROFILE_BASE64: ${{ secrets.APPLE_PROVISION_PROFILE_BASE64 }}
          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
        run: |
          # 1) 还原证书与描述文件
          echo "$P12_BASE64" | base64 --decode > cert.p12
          echo "$PROFILE_BASE64" | base64 --decode > profile.mobileprovision

          # 2) 建临时钥匙串并设为默认
          security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain

          # 3) 导入 p12（允许 codesign 使用）
          security import cert.p12 -k build.keychain -P "$P12_PASSWORD" \
            -T /usr/bin/codesign -T /usr/bin/security
          security set-key-partition-list -S apple-tool:,apple:,codesign: -s \
            -k "$KEYCHAIN_PASSWORD" build.keychain

          # 4) 安装描述文件
          mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
          cp profile.mobileprovision "$HOME/Library/MobileDevice/Provisioning Profiles/"

      # ---------- 构建签名 ipa（使用第 3.4 节导出的 exportOptions.plist） ----------
      - name: 构建 ipa
        run: |
          flutter build ipa --release \
            --export-options-plist=ios/exportOptions/AppStore.plist \
            --build-name=${{ steps.info.outputs.version }} \
            --build-number=${{ steps.info.outputs.build_number }} \
            --dart-define=APP_ENV=prod \
            --dart-define=API_BASE_URL=https://api.taoyue.com \
            --dart-define=COMMIT_HASH=${{ steps.info.outputs.short_sha }} \
            --dart-define=BUILD_NUMBER=${{ steps.info.outputs.build_number }}

      - name: 归集产物（命名带 版本-构建号-commit）
        run: |
          mkdir -p dist
          VER=${{ steps.info.outputs.version }}
          BN=${{ steps.info.outputs.build_number }}
          SHA=${{ steps.info.outputs.short_sha }}
          IPA=$(ls build/ios/ipa/*.ipa | head -1)
          cp "$IPA" "dist/taoyue-edu_${VER}_${BN}_${SHA}_prod.ipa"
          ls -lh dist/

      # 可选：同时归档 dSYM（崩溃符号，日后 symbolicate 用）
      - name: 归档 dSYM（可选）
        if: always()
        run: |
          mkdir -p dsym_out
          find build/ios/archive -name "*.dSYM" -exec cp -R {} dsym_out/ \; 2>/dev/null || true
          find dsym_out -name "*.dSYM" | head

      - name: 上传 dSYM（可选）
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: ios-dSYMs-${{ inputs.version }}
          path: dsym_out
          retention-days: 90

      # ---------- 归档：挂到同名 Release（先跑 Android 那个，这里只是追加） ----------
      - name: 挂载 ipa 到 Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: v${{ steps.info.outputs.version }}
          files: dist/*

      # ---------- 可选：直接上传 App Store Connect（需要 API Key，见附录 A） ----------
      # 想全自动上传就取消下面这段注释并配好 3 个 Secret；否则产物人工传即可
      # - name: 上传 App Store Connect（altool）
      #   env:
      #     API_KEY: ${{ secrets.APPLE_API_KEY_BASE64 }}
      #     API_KEY_ID: ${{ secrets.APPLE_API_KEY_ID }}
      #     API_ISSUER: ${{ secrets.APPLE_API_ISSUER }}
      #   run: |
      #     echo "$API_KEY" | base64 --decode > AuthKey.p8
      #     IPA=$(ls dist/*.ipa | head -1)
      #     xcrun altool --upload-app -f "$IPA" -t ios \
      #       --apiKey "$API_KEY_ID" --apiIssuer "$API_ISSUER" --verbose
```

> 两个坑提前说：
> 1. `exportOptions.plist` 必须是你本地（Mac）用 Xcode 真实导出成功过的那份（第 3.4 节第 6 步），CI 只是重复同一套签名参数。
> 2. iOS job 首次跑会下载整套 Xcode 组件，耗时约 15~30 分钟，属正常。

### 6.4 执行一次完整的 Release（操作剧本）

1. 确保所有 Secrets 已配齐（对照附录 A）。
2. 确保第 4、5 章的代码都已合并进 main。
3. GitHub → `Actions` → 左侧 `Android Release` → `Run workflow` → 填版本 `1.0.0` → 绿色按钮运行。
4. 等 android job 全部步骤通过（约 5~10 分钟）。
5. 左侧切到 `iOS Release`，同样填 `1.0.0` 运行（若 iOS 材料没配齐，可跳过，Android 包先走全渠道）。
6. 打开仓库 `Releases` 页：能看到 `v1.0.0` 这条 Release，Assets 里躺着 `taoyue-edu_1.0.0_<构建号>_<commit>_prod.aab`、同名 `.apk`、同名 `.ipa`。

**完成标志**：Release 页出现 v1.0.0，且三个文件名的"版本号、构建号、commit"三要素齐全。

### 6.5 拿到了包，接下来发到哪

| 平台 | 传哪个文件 | 说明 |
|---|---|---|
| 华为应用市场 | `.aab` 或 `.apk` | 华为支持 aab 上传（按后台指引） |
| 小米 / OPPO / vivo / 应用宝 | `.apk` | 用 universal apk，兼容所有 ABI |
| App Store | `.ipa` | 用 App Store Connect 的 Transporter 上传，或用第 6.3 节可选步骤自动传 |
| Google Play（如出海） | `.aab` | Play Console 只收 aab |

各商店后台注册时的签名 MD5/SHA1 填写用第 3.3 节 `keytool -printcert` 抄下来的值。

> 面试讲法：**"流水线自动化到'签名产物归档'这一环，上传各商店后台和提交审核是人工半自动——因为每个市场的后台规则、物料要求都不同，不存在一套通用 API；自动化把最耗时最容易错的'打版本、签名、命名、归档、留痕'全接管了，发版效率提升是明显的，而且每个版本都能回溯。"**（不要编具体分钟数，除非你真测过。）

---

## 第 7 章 合规清单化闭环（半天 ~ 按审核周期）

> 目标：把"各平台审核要求"从某个人脑子里的一团浆糊，变成**一张表、每项有 owner、有完成状态、有验收截图**。审核被打回时，你能立刻说出"哪一项差在哪、谁负责补、证据在哪"。

### 7.1 建合规仓库目录（先搭架子）

建目录：

```powershell
mkdir docs\compliance\证据截图
```

在 `docs/compliance/README.md` 里放一张总表（模板，直接复制改）：

```markdown
# 上架合规总台账

> 原则：每一项 = 一个 owner + 一条状态 + 一张验收截图。
> 更新规则：状态变化当天更新；截图命名规范见文末。

## 一、通用材料（Android + iOS 都要）

| # | 材料 | 要求说明 | Owner | 状态 | 验收截图 | 备注 |
|---|------|---------|-------|------|---------|------|
| C1 | APP 备案号 | 服务器所在云厂商控制台完成，取得备案号 | 运维/你 | ☐ | 截图-备案.png | 安卓市场上架硬门槛 |
| C2 | 软件著作权 | 软著证书（可加急代办） | 你 | ☐ | 截图-软著.png | 各商店必传 |
| C3 | 隐私政策 | 独立 URL + App 内可达 + 首次启动弹窗展示 | 法务/你 | ☐ | 截图-隐私弹窗.png | iOS 与安卓都要 |
| C4 | 用户协议 | 同上要求 | 法务/你 | ☐ | 截图-协议页.png | |
| C5 | 应用图标 + 截图 | 图标各尺寸、截图 5~8 张（真机不同机型） | 设计/你 | ☐ | 截图-素材库.png | |
| C6 | 内容分级/适龄 | 按产品实际填写（教育类一般填全年龄段，若含特定内容如实选） | 你 | ☐ | 截图-分级页.png | |

## 二、Android 专项

| # | 材料 | 要求说明 | Owner | 状态 | 验收截图 | 备注 |
|---|------|---------|-------|------|---------|------|
| A1 | 签名 MD5/SHA1 | keytool 输出，各商店后台填写 | 你 | ☐ | 截图-签名哈希.png | 见第 3.3 |
| A2 | targetSdk | 显式固定 ≥ 市场要求（本教程 34） | 你 | ☐ | 截图-targetSdk.png | build.gradle.kts |
| A3 | 64 位 so | apk 内含 arm64-v8a | 你 | ☐ | 截图-abi检查.png | 见 7.4 命令 |
| A4 | 权限最小化 | 只声明用到的权限，且与隐私政策一致 | 你 | ☐ | 截图-权限声明.png | |
| A5 | 加固 | 部分市场建议/要求（华为、应用宝有加固通道） | 你 | ☐ | 截图-加固.png | 可选，按各市场规则 |

## 三、iOS 专项

| # | 材料 | 要求说明 | Owner | 状态 | 验收截图 | 备注 |
|---|------|---------|-------|------|---------|------|
| I1 | Privacy Manifest | ios/Runner/PrivacyInfo.xcprivacy | 你 | ☐ | 截图-隐私清单.png | 见 7.3 |
| I2 | 第三方 SDK 隐私声明 | 集成统计/推送/登录 SDK 的声明齐全 | 你 | ☐ | 截图-sdk清单.png | |
| I3 | 登录合规 | 若接微信/QQ 等第三方登录，必须同时提供 "Sign in with Apple" | 你 | ☐ | 截图-apple登录.png | App Store 审核硬规则 |
| I4 | 账号注销 | 设置页提供"注销账号"且能走通 | 你 | ☐ | 截图-注销.png | App Store 审核硬规则 |
| I5 | 内容分级 | App Store Connect 里如实填写年龄分级问卷 | 你 | ☐ | 截图-分级问卷.png | |

## 截图命名规范

`证据截图/<类别>_<日期>.png`，如 `证据截图/iOS隐私清单_2026-09-05.png`。
</markdown>
```

### 7.2 逐项怎么做（傻瓜版）

**C1 APP 备案**：如果你有云服务器（腾讯云/阿里云等），登录云厂商控制台 → ICP 备案系统 → 提交 App 备案（需要 Android/iOS 的包名、签名 MD5、SHA1、SHA256 等信息），约 1~3 周出号。这是国内安卓市场上架的硬门槛，**没有备案号基本不用谈上架**，尽早启动。

**C2 软著**：在中国版权保护中心或代办机构申请"计算机软件著作权登记证书"。办理周期长（官方 60 个工作日左右），通常走加急代办，几百到一两千元不等。可以先登记再开发完（登记内容用"软件名称 + 版本 + 部分代码/文档"）。

**C3/C4 隐私政策与用户协议**：写成网页放在你的域名下（或托管在 GitHub Pages），App 内"我的 → 设置"能打开，首次启动弹窗展示并"同意后继续"。里面要写：收集哪些信息、用途、第三方 SDK 共享、存储与安全、用户权利（含注销路径）、联系方式。

**A1 签名哈希**：第 3.3 节 `keytool -printcert -jarfile ...` 的输出里有 `MD5 / SHA1 / SHA256`，把它们填进每个商店后台的"应用签名"栏。

**A2 targetSdk**：第 2.3 节已经写死在 `build.gradle.kts`。改法：`targetSdk = 34`（或市场要求的更高值）。截图存证即可。

**A3 64 位 so**（重要，检查命令）：

```powershell
# Windows：tar 可以读 apk 内部的目录清单
tar -tf build\app\outputs\flutter-apk\app-prod-release.apk | findstr "lib/"

# 或（macOS / Linux）
# unzip -l build/app/outputs/flutter-apk/app-prod-release.apk | grep "lib/"
```

输出里应看到 `lib/arm64-v8a/...`（必须）和 `lib/armeabi-v7a/...`、`lib/x86_64/...`（可选）。**只要缺 arm64-v8a 就上不了主流市场**。截图存证。

**I1 Privacy Manifest（iOS）**：新建 `ios/Runner/PrivacyInfo.xcprivacy`（模板）：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- 声明的隐私数据类型：按 App 实际收集情况填写 -->
	<key>NSPrivacyCollectedDataTypes</key>
	<array/>

	<!-- 用到的"必需原因 API"：按实际填，模板只示例（文件时间戳） -->
	<key>NSPrivacyAccessedAPITypes</key>
	<array>
		<dict>
			<key>NSPrivacyAccessedAPIType</key>
			<string>NSPrivacyAccessedAPICategoryFileTimestamp</string>
			<key>NSPrivacyAccessedAPITypeReasons</key>
			<array>
				<string>3B52.1</string>
			</array>
		</dict>
	</array>

	<!-- 第三方 SDK 隐私清单：若 App 内嵌 SDK（统计/推送/登录），
	     在 <key>NSPrivacyTracking</key> 等节点按 Apple 要求补充，
	     并把 SDK 自带或你的 PrivacyInfo 一并归档 -->
	<key>NSPrivacyTracking</key>
	<false/>
	<key>NSPrivacyTrackingDomains</key>
	<array/>
</dict>
</plist>
```

然后在 Xcode 里把该文件加入 Runner target（File → Add Files to "Runner"），构建验证通过后提交。**只要 App 用了文件时间戳、UserDefaults、系统 boot time 等"必需原因 API"且没声明原因，审核会被打回**。加第三方 SDK（如友盟统计、极光推送、微信/支付宝 SDK）时，把各 SDK 官方的 PrivacyInfo 声明合并进来。

**I3 登录合规**：如果 App 有"微信登录"等第三方登录入口而没有 Apple 登录，App Store 审核必被打回。Flutter 做法是集成 `sign_in_with_apple` 包，把"Apple 登录"作为登录方式之一，与微信/手机号并列。

### 7.3 全渠道上架顺序建议（少走弯路）

1. **先 iOS（App Store）**：审核最严但规则最清晰，iOS 过了说明产品成熟度可以；
2. 同时跑安卓各市场申请（每个市场审核独立，约 1~7 天）；
3. 每个市场首次审核被打回时，把打回原因抄录到 7.1 台账对应行，**补完再重新提交**。

> 面试讲法：**"合规是清单化闭环——每个平台的审核要求拆成 owner 明确的条目，验收截图留档。被打回不等于灾难，是清单没覆盖到，补进去下次就不踩。全渠道首版审核一次过，靠的不是运气，是这份清单提前把'必踩点'排掉了。"**

---

## 第 8 章 发版可追溯闭环

> 目标：线上任何一个包，都能在 10 秒内回答三件事——**这是哪个版本？第几次构建？哪一次 commit 出的？**

### 8.1 一个包的三重身份

| 身份 | 存哪 | 谁看 | 怎么生成 |
|---|---|---|---|
| versionName（用户可见版本） | Android `versionName` / iOS `CFBundleShortVersionString` | 用户、客服 | Release 时填的 `1.2.0`，已由第 6 章 `--build-name` 注入 |
| versionCode / buildNumber（构建序号） | Android `versionCode` / iOS `CFBundleVersion` | 商店、追溯 | `git rev-list --count HEAD` 自动递增，第 6 章 `--build-number` 注入 |
| commitHash（代码指纹） | 打进 App 的 `AppConfig.commitHash` | 开发、排查 | `GITHUB_SHA` 前 7 位，第 6 章 `--dart-define` 注入 |

第 2.2 节 `AppConfig` 已经预留了 `commitHash` / `buildNumber` / `env` 三个字段。这一章把它们变成"看得到"的证据。

### 8.2 让构建信息看得见（两步，均含代码）

**第 1 步：启动日志（必做，一行代码）**。改 `lib/main.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_edu_app/app.dart';
import 'core/constants/app_config.dart';

void main() {
  // 发版追溯：启动时打印本次构建的三重身份（flutter run 控制台 / adb logcat 可见）
  debugPrint(
    '【构建信息】env=${AppConfig.env} '
    'baseUrl=${AppConfig.baseUrl} '
    'build=${AppConfig.buildNumber} '
    'commit=${AppConfig.commitHash}',
  );
  runApp(const TaoyueEduApp());
}
```

**第 2 步（可选）**：做一个"构建信息"对话框，放在"我的"页给测试/客服看。新建 `lib/core/utils/build_info_dialog.dart`：

```dart
import 'package:flutter/material.dart';
import '../constants/app_config.dart';

/// 展示当前安装包的构建信息（用于测试反馈、线上排查）
void showBuildInfoDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('构建信息'),
      content: Text(
        '环境：${AppConfig.env}\n'
        '服务器：${AppConfig.baseUrl}\n'
        '构建号：${AppConfig.buildNumber}\n'
        'commit：${AppConfig.commitHash}',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}
```

然后在"我的"页（`lib/ui/mine/mine_page.dart`）加一个入口 `ListTile`，onTap 调用 `showBuildInfoDialog(context)` 即可（找到你现有的设置列表，仿照其它条目加一项）。

### 8.3 产物文件名 = 归档索引

第 6 章产物命名规则已落地：`taoyue-edu_<版本>_<构建号>_<commit短哈希>_prod.aab / .apk / .ipa`。

例如：`taoyue-edu_1.2.0_347_a1b2c3d_prod.apk` 可读作"桃悦智科 1.2.0 版、仓库第 347 次提交、commit a1b2c3d 出品的正式包"。

### 8.4 线上问题回溯路径（把流程写进团队文档）

```
用户/客服反馈异常
   │  ① 问一句：App 里"我的→构建信息"截图（或版本号）
   ▼
拿到 "版本 1.2.0 / 构建号 347 / commit a1b2c3d"
   │  ② GitHub Releases 页找到 v1.2.0，核对 commit 前缀一致
   ▼
   │  ③ 本地：git checkout a1b2c3d   ← 精确回到那个代码快照
   ▼
   │  ④ 看 Release 发布说明 + 该 commit 关联的 PR（质量门禁记录都在）
   ▼
定位根因 / 决定热修分支从哪切
```

全程不需要"猜是哪个包"，所有中间产物（日志、dSYM、构建记录）都挂在同一条 Release 下。

---

## 第 9 章 从零走一遍：端到端演练 + 验收清单

### 9.1 演练剧本（一口气把整条链路走通）

1. 从 main 拉一个分支：`git checkout -b feat/fix-login`
2. 改代码 → 本地 `flutter analyze` + `flutter test` 通过
3. `git push` 并开 PR 到 main → 等 `PR 质量门禁` 绿
4. 合并 PR（若配了分支保护，必须绿才能合）
5. 合并瞬间自动触发"主分支自动出 Debug 包" → 去 Actions 下载 staging debug apk 装上自测
6. 确认 staging 体验 OK → 回到 main，跑 `Android Release` workflow，填 `1.0.0`
7. 等产物进 Release v1.0.0 → 下载 aab/apk → 本地 `adb install` 装正式签名包验证一遍
8. 有 Mac 和证书时，再跑 `iOS Release` workflow 拿 ipa → 传 App Store Connect
9. 更新第 7 章合规台账，逐项贴验收截图 → 提交各市场审核
10. 打回 → 改清单、补证据、重新提交

### 9.2 本教程产生的完整文件清单

| 文件 | 作用 | 创建章节 |
|---|---|---|
| `.github/workflows/quality-gate.yml` | PR 质量门禁 | 第 4 章 |
| `.github/workflows/build-debug.yml` | main 自动出 debug 包 | 第 5 章 |
| `.github/workflows/release-android.yml` | Android 正式 aab+apk + Release 归档 | 第 6 章 |
| `.github/workflows/release-ios.yml` | iOS 正式 ipa + Release 归档 | 第 6 章 |
| `android/key.properties`（不入库） | 本地签名密码 | 第 3 章 |
| `android/app/upload-keystore.jks`（不入库） | Android 签名文件 | 第 3 章 |
| `android/app/build.gradle.kts`（改） | flavor + targetSdk + 签名读取 | 第 2/3 章 |
| `android/app/src/{dev,staging}/res/values/strings.xml` | 三套桌面名称 | 第 2 章 |
| `android/app/src/{dev,staging,prod}/res/mipmap-*/ic_launcher.png` | 三套图标 | 第 2 章 |
| `lib/core/constants/app_config.dart`（改） | dart-define 环境注入 | 第 2 章 |
| `lib/main.dart`（改） | 启动打印构建信息 | 第 8 章 |
| `lib/core/utils/build_info_dialog.dart`（可选） | 构建信息弹窗 | 第 8 章 |
| `test/widget_test.dart`（改） | 冒烟测试替代模板测试 | 第 1 章 |
| `ios/Runner/PrivacyInfo.xcprivacy` | iOS 隐私清单 | 第 7 章 |
| `ios/exportOptions/AppStore.plist` | iOS 签名导出参数 | 第 3 章 |
| `docs/compliance/README.md` + `证据截图/` | 合规台账 | 第 7 章 |
| `tool/gen_flavor_icons.ps1` | 三套图标生成脚本 | 第 2 章 |

### 9.3 常见问题 FAQ

| 现象 | 原因 / 解法 |
|---|---|
| PR 上了但质量门禁不出现 | workflow 文件必须**已经存在于 main 分支**上才会在 PR 生效——先把它合并进 main，之后新 PR 才触发 |
| `flutter analyze` 一直红 | 逐个修；`flutter analyze` 在项目里有任何 issue 都会非零退出，保持 `No issues found!` 为准 |
| `flutter test` 红 | 若报 `MyApp is not defined`，是模板测试没替换，用第 1.2 节文件 |
| 构建报 `No product flavor named "dev"` | `build.gradle.kts` 没保存 / Android Studio 没做 Gradle Sync；或命令拼错 flavor 名 |
| release 构建失败、无签名 | 本地没 `android/key.properties` 或 CI 没注入 Secret（第 3.2 / 6.1） |
| keytool 报 Keystore was tampered / password incorrect | 密码输错或 keystore 文件损坏，回第 3.1 用备份重试 |
| 找不到 `app-prod-release.aab` | 先 `dir build\app\outputs\bundle\prodRelease` 确认构建确实成功 |
| iOS 报 `No profiles for 'com.taoyue.edu' were found` | 描述文件的 App ID 与工程 Bundle ID 不匹配，或类型不是 App Store，回第 3.4 重导 |
| Actions 里看不到 Release 产物 | 检查 workflow 是否真的跑成功；Release 在仓库 `Releases` 页看，Artifact 在每次运行页底部 |
| 装不上 staging 包 | 手机已有同包名不同签名包需先卸载；或 `adb uninstall com.taoyue.edu.staging` |
| Windows 跑不了 iOS workflow | iOS 构建只能在 GitHub 的 macos runner 上跑，本地 Windows 只负责写文件与提交 |
| Secret 设了但 workflow 说拿不到 | Secret 名大小写写错；仓库级 Secret 对 fork 的 PR 默认不生效（安全设计） |

---

## 附录 A GitHub Secrets 全量对照表

在仓库 `Settings → Secrets and variables → Actions` 添加（全部为仓库级 secret）。

| Secret 名 | 内容 | 何时需要 | 在哪个 workflow 用 |
|---|---|---|---|
| `ANDROID_KEYSTORE_BASE64` | upload-keystore.jks 的 base64 | 必须 | release-android |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 的 storePassword | 必须 | release-android |
| `ANDROID_KEY_PASSWORD` | keystore 的 keyPassword | 必须 | release-android |
| `APPLE_CERT_P12_BASE64` | iOS Distribution 证书 p12 的 base64 | 出 iOS 包时 | release-ios |
| `APPLE_CERT_P12_PASSWORD` | p12 导出密码 | 出 iOS 包时 | release-ios |
| `APPLE_PROVISION_PROFILE_BASE64` | App Store 描述文件 base64 | 出 iOS 包时 | release-ios |
| `KEYCHAIN_PASSWORD` | CI 临时钥匙串密码（随机串即可） | 出 iOS 包时 | release-ios |
| `APPLE_API_KEY_BASE64` | App Store Connect API Key（.p8）base64 | 可选：自动上传 ASC | release-ios（可选段） |
| `APPLE_API_KEY_ID` | API Key ID | 可选：自动上传 ASC | release-ios（可选段） |
| `APPLE_API_ISSUER` | API Issuer ID | 可选：自动上传 ASC | release-ios（可选段） |

## 附录 B 各安卓市场开通 checklist（通用部分）

以下字段几乎所有安卓市场开通/上架时都会要求，先备齐再注册：

- [ ] 营业执照（企业主体）或身份证（个人主体，个人上架限制多，建议企业主体）
- [ ] APP 备案号（第 7 章 C1）
- [ ] 软著证书（第 7 章 C2）
- [ ] 隐私政策 URL
- [ ] 应用图标 + 5~8 张应用截图（不同机型/分辨率更佳）
- [ ] 签名 MD5 / SHA1 / SHA256（第 3.3 节 keytool 输出）
- [ ] 应用包名：`com.taoyue.edu`
- [ ] 内容分级与适龄信息

各市场差异提醒（务必以各平台开发者文档为准，此处只列共性"注意点"）：
- **华为**：注意鸿蒙版本适配声明；提供加固与鸿蒙工具链入口；
- **小米**：审核侧重权限与隐私一致性，SDK 合规检查较细；
- **OPPO / vivo**：会要求提供目标用户、应用功能描述，人工审核材料较多；
- **应用宝（腾讯）**：需要先"认领/注册应用"，部分类目要求企业资质。

> 铁律：**任何市场要求提交"签名信息"时，填的一定是第 3.3 节 keytool 查出来的那组值，和 CI 里 Secrets 对应的是同一个 keystore。** 换 keystore = 应用换身份，老用户将无法覆盖安装更新，务必保管好。

---

---

## 附录 C 落地操作卡：7 份文件照着抄（不用回正文翻找）

> 用法：**从头到尾按顺序执行**，每个小节是一份文件。①建好/存好路径 → ②把代码块整段复制进文件 → ③跑该小节末尾的验证命令。正文各章讲"为什么"，本附录只负责"怎么抄"。创建/保存用你熟悉的编辑器（VS Code / Android Studio 均可），PowerShell 只用来跑验证命令。
>
> 顺序理由：01~03 是本机可验证的工程改动（先做，CI 之前必须保证它们本地是绿的）；04~07 是流水线文件（做完 push，GitHub 开始干活）。

### 01/07 覆盖 `test/widget_test.dart`（第 1.2 节）

路径：`test/widget_test.dart`（存在，用新内容整体覆盖）

```dart
// test/widget_test.dart
// 冒烟测试：App 能正常启动，主框架（底部导航）渲染出来。
// 说明：项目根组件是 TaoyueEduApp（lib/app.dart），不是脚手架模板的 MyApp。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_edu_app/app.dart';

void main() {
  testWidgets('App 启动冒烟测试：能看到底部导航「首页」', (WidgetTester tester) async {
    await tester.pumpWidget(const TaoyueEduApp());

    // 底部导航四个 Tab 文案是稳定的（见 lib/ui/main/main_page.dart）
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
  });
}
```

验证：`flutter test` → 输出 `All tests passed!`

### 02/07 覆盖 `lib/core/constants/app_config.dart`（第 2.2 节）

路径：`lib/core/constants/app_config.dart`（存在，用新内容整体覆盖）

```dart
/// 全局配置
/// 三套环境（dev / staging / prod）的值在构建时用 --dart-define 注入：
///   dev:     默认值，无需注入
///   staging: flutter run --dart-define=APP_ENV=staging \
///                        --dart-define=API_BASE_URL=https://staging-api.taoyue.com
///   prod:    flutter build apk --dart-define=APP_ENV=prod \
///                        --dart-define=API_BASE_URL=https://api.taoyue.com
/// 可追溯字段（COMMIT_HASH / BUILD_NUMBER）由 CI 注入，见第 8 章。
class AppConfig {
  AppConfig._();

  /// 当前构建环境：dev / staging / prod
  static const String env =
      String.fromEnvironment('APP_ENV', defaultValue: 'dev');

  /// 后端地址
  /// - 默认值保留本机调试地址（Windows 桌面 / 真机）
  /// - Android 模拟器访问宿主机请传 --dart-define=API_BASE_URL=http://10.0.2.2:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  /// 本次构建对应的 git commit（短哈希），用于线上回溯，CI 注入
  static const String commitHash =
      String.fromEnvironment('COMMIT_HASH', defaultValue: 'unknown');

  /// 本次构建号（自动递增），CI 注入
  static const String buildNumber =
      String.fromEnvironment('BUILD_NUMBER', defaultValue: '0');

  /// 是否为正式环境（决定日志、测试入口等行为）
  static bool get isProd => env == 'prod';

  /// 分页大小
  static const int pageSize = 10;

  /// 超时时间（秒）
  static const int connectTimeout = 10;
  static const int receiveTimeout = 15;

  /// 本地 Token 存储 key
  static const String tokenKey = 'taoyue_token';
  static const String userKey = 'taoyue_user';
}
```

验证：`flutter analyze` → `No issues found!`（`api_client.dart` 无需改动，它用的字段都在）

### 03/07 覆盖 `android/app/build.gradle.kts`（第 2.3 节）

路径：`android/app/build.gradle.kts`（存在，用新内容整体覆盖）

```kotlin
import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ---------- 签名信息：只从 key.properties 读取（本地）或 CI 动态生成 ----------
// 该文件已被 .gitignore 忽略，绝不允许提交到仓库。
fun loadSigningProperties(): Properties {
    val props = Properties()
    val keyProps = rootProject.file("key.properties")
    if (keyProps.exists()) {
        props.load(FileInputStream(keyProps))
    }
    return props
}
val signingProps = loadSigningProperties()

android {
    namespace = "com.taoyue.edu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // 正式包名（全网唯一，上架后不可改）
        applicationId = "com.taoyue.edu"
        minSdk = flutter.minSdkVersion
        // 显式固定 targetSdk，便于和各安卓市场要求对齐（第 7 章合规点之一）
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ---------- 多环境 flavor：dev / staging / prod ----------
    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            // 包名后缀是环境隔离的根：三套包可以同时装在一台手机上
            applicationIdSuffix = ".dev"
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
        }
        create("prod") {
            dimension = "env"
            // 无后缀 = 正式包名 com.taoyue.edu
        }
    }

    signingConfigs {
        create("release") {
            val storeFileProp = signingProps.getProperty("storeFile")
            if (storeFileProp != null) {
                storeFile = file(storeFileProp)
                storePassword = signingProps.getProperty("storePassword")
                keyAlias = signingProps.getProperty("keyAlias")
                keyPassword = signingProps.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // 有 key.properties（本地）或 CI 注入时才启用正式签名；
            // 没有签名配置时 release 构建会失败——这是故意的，防止产出未签名包。
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

flutter {
    source = "../.."
}
```

> 若你的 MainActivity 目录还是旧包名路径，执行第 1.4 节第①点的目录迁移步骤，否则 IDE 报错。

验证（三套 debug 都出包即成功）：

```powershell
flutter build apk --debug --flavor dev
flutter build apk --debug --flavor staging
flutter build apk --debug --flavor prod
```

### 04/07 新建 `.github/workflows/quality-gate.yml`（第 4 章）

路径：`.github/workflows/quality-gate.yml`（新建，文件不存在）

```yaml
name: PR 质量门禁

# 触发条件：任何 PR（目标分支是 main）
on:
  pull_request:
    branches: [ main ]

permissions:
  contents: read

jobs:
  quality-gate:
    name: flutter analyze + test
    runs-on: ubuntu-latest
    steps:
      - name: 检出代码
        uses: actions/checkout@v4

      - name: 安装 Flutter（稳定版，含缓存）
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: 安装依赖
        run: flutter pub get

      # 质量门禁第 1 关：静态检查。有任何 error 输出即失败
      - name: 静态检查 flutter analyze
        run: flutter analyze

      # 质量门禁第 2 关：单元测试。有任何失败用例即失败
      - name: 单元测试 flutter test
        run: flutter test
```

验证：push 本文件后，随便开一个 PR 到 main，PR 页出现绿色的 `flutter analyze + test`。

### 05/07 新建 `.github/workflows/build-debug.yml`（第 5 章）

路径：`.github/workflows/build-debug.yml`（新建）

```yaml
name: 主分支自动出 Debug 包（内部分发）

# 触发条件：代码合并/推送到 main
on:
  push:
    branches: [ main ]

permissions:
  contents: read

jobs:
  build-debug-apk:
    name: 构建 staging debug APK
    runs-on: ubuntu-latest
    steps:
      - name: 检出代码
        uses: actions/checkout@v4

      - name: 安装 Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: 安装依赖
        run: flutter pub get

      # 主分支代码也要求过测试（双保险）
      - name: 单元测试
        run: flutter test

      - name: 计算构建信息
        id: info
        run: |
          echo "short_sha=${GITHUB_SHA::7}" >> "$GITHUB_OUTPUT"
          echo "build_number=$(git rev-list --count HEAD)" >> "$GITHUB_OUTPUT"

      - name: 构建 staging debug APK
        run: |
          flutter build apk --debug --flavor staging \
            --dart-define=APP_ENV=staging \
            --dart-define=API_BASE_URL=https://staging-api.taoyue.com \
            --dart-define=COMMIT_HASH=${{ steps.info.outputs.short_sha }} \
            --dart-define=BUILD_NUMBER=${{ steps.info.outputs.build_number }}

      - name: 上传 artifact（Actions 页可直接下载）
        uses: actions/upload-artifact@v4
        with:
          name: app-staging-debug
          path: build/app/outputs/flutter-apk/app-staging-debug.apk
          retention-days: 30
```

验证：push 本文件到 main，Actions 页自动出现 `主分支自动出 Debug 包`，跑完底部 Artifacts 可下载 apk。

### 06/07 新建 `.github/workflows/release-android.yml`（第 6.2 节）

路径：`.github/workflows/release-android.yml`（新建）

```yaml
name: Android Release（正式签名 aab + apk）

# 手动触发：填版本号后运行
on:
  workflow_dispatch:
    inputs:
      version:
        description: '发布版本号（格式 x.y.z，如 1.2.0）'
        required: true
        type: string

permissions:
  contents: write   # 需要写 Release

jobs:
  release-android:
    name: 构建并归档 Android 正式包
    runs-on: ubuntu-latest
    steps:
      - name: 检出代码
        uses: actions/checkout@v4

      - name: 安装 Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: 安装依赖
        run: flutter pub get

      - name: 门禁检查（发布前再兜一次底）
        run: |
          flutter analyze
          flutter test

      - name: 计算版本与构建信息
        id: info
        run: |
          VERSION="${{ inputs.version }}"
          # 校验 x.y.z
          if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "版本号格式错误：$VERSION（应为 x.y.z）"
            exit 1
          fi
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"
          echo "short_sha=${GITHUB_SHA::7}" >> "$GITHUB_OUTPUT"
          echo "build_number=$(git rev-list --count HEAD)" >> "$GITHUB_OUTPUT"

      # ---------- 签名：从 Secrets 恢复 keystore + key.properties ----------
      - name: 注入签名文件
        env:
          KEYSTORE_BASE64: ${{ secrets.ANDROID_KEYSTORE_BASE64 }}
          KEYSTORE_PASSWORD: ${{ secrets.ANDROID_KEYSTORE_PASSWORD }}
          KEY_PASSWORD: ${{ secrets.ANDROID_KEY_PASSWORD }}
        run: |
          echo "$KEYSTORE_BASE64" | base64 --decode > android/app/upload-keystore.jks
          printf 'storePassword=%s\nkeyPassword=%s\nkeyAlias=upload\nstoreFile=app/upload-keystore.jks\n' \
            "$KEYSTORE_PASSWORD" "$KEY_PASSWORD" > android/key.properties

      # ---------- 构建正式签名产物（prod flavor） ----------
      - name: 构建 appbundle（aab）
        run: |
          flutter build appbundle --release --flavor prod \
            --build-name=${{ steps.info.outputs.version }} \
            --build-number=${{ steps.info.outputs.build_number }} \
            --dart-define=APP_ENV=prod \
            --dart-define=API_BASE_URL=https://api.taoyue.com \
            --dart-define=COMMIT_HASH=${{ steps.info.outputs.short_sha }} \
            --dart-define=BUILD_NUMBER=${{ steps.info.outputs.build_number }}

      - name: 构建 universal apk
        run: |
          flutter build apk --release --flavor prod \
            --build-name=${{ steps.info.outputs.version }} \
            --build-number=${{ steps.info.outputs.build_number }} \
            --dart-define=APP_ENV=prod \
            --dart-define=API_BASE_URL=https://api.taoyue.com \
            --dart-define=COMMIT_HASH=${{ steps.info.outputs.short_sha }} \
            --dart-define=BUILD_NUMBER=${{ steps.info.outputs.build_number }}

      # ---------- 产物重命名：文件名就是追溯信息 ----------
      - name: 归集产物（命名带 版本-构建号-commit）
        run: |
          mkdir -p dist
          VER=${{ steps.info.outputs.version }}
          BN=${{ steps.info.outputs.build_number }}
          SHA=${{ steps.info.outputs.short_sha }}
          cp build/app/outputs/bundle/prodRelease/app-prod-release.aab "dist/taoyue-edu_${VER}_${BN}_${SHA}_prod.aab"
          cp build/app/outputs/flutter-apk/app-prod-release.apk "dist/taoyue-edu_${VER}_${BN}_${SHA}_prod.apk"
          ls -lh dist/

      # ---------- 归档：挂到 GitHub Release（自动建 v1.2.0 这个 Release） ----------
      - name: 创建 Release 并挂载产物
        uses: softprops/action-gh-release@v2
        with:
          tag_name: v${{ steps.info.outputs.version }}
          name: v${{ steps.info.outputs.version }}
          generate_release_notes: true
          files: dist/*

      # ---------- 备份：同时传一份 artifact（运行页留底） ----------
      - name: 上传构建日志与产物备份
        uses: actions/upload-artifact@v4
        with:
          name: android-release-${{ inputs.version }}
          path: |
            dist/*
            build/app/outputs/*.log
          retention-days: 90
```

### 07/07 新建 `.github/workflows/release-ios.yml`（第 6.3 节，可选但建议）

路径：`.github/workflows/release-ios.yml`（新建）

```yaml
name: iOS Release（正式签名 ipa）

on:
  workflow_dispatch:
    inputs:
      version:
        description: '发布版本号（格式 x.y.z，如 1.2.0，须与 Android 一致）'
        required: true
        type: string

permissions:
  contents: write

jobs:
  release-ios:
    name: 构建并归档 iOS 正式包
    # iOS 构建必须用苹果生态：GitHub 的 macos runner
    runs-on: macos-14
    steps:
      - name: 检出代码
        uses: actions/checkout@v4

      - name: 安装 Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: 安装依赖
        run: flutter pub get

      - name: 计算版本与构建信息
        id: info
        run: |
          VERSION="${{ inputs.version }}"
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"
          echo "short_sha=${GITHUB_SHA::7}" >> "$GITHUB_OUTPUT"
          echo "build_number=$(git rev-list --count HEAD)" >> "$GITHUB_OUTPUT"

      # ---------- 证书与描述文件注入（Secrets → 系统钥匙串） ----------
      - name: 导入 Apple 证书与描述文件
        env:
          P12_BASE64: ${{ secrets.APPLE_CERT_P12_BASE64 }}
          P12_PASSWORD: ${{ secrets.APPLE_CERT_P12_PASSWORD }}
          PROFILE_BASE64: ${{ secrets.APPLE_PROVISION_PROFILE_BASE64 }}
          KEYCHAIN_PASSWORD: ${{ secrets.KEYCHAIN_PASSWORD }}
        run: |
          # 1) 还原证书与描述文件
          echo "$P12_BASE64" | base64 --decode > cert.p12
          echo "$PROFILE_BASE64" | base64 --decode > profile.mobileprovision

          # 2) 建临时钥匙串并设为默认
          security create-keychain -p "$KEYCHAIN_PASSWORD" build.keychain
          security default-keychain -s build.keychain
          security unlock-keychain -p "$KEYCHAIN_PASSWORD" build.keychain

          # 3) 导入 p12（允许 codesign 使用）
          security import cert.p12 -k build.keychain -P "$P12_PASSWORD" \
            -T /usr/bin/codesign -T /usr/bin/security
          security set-key-partition-list -S apple-tool:,apple:,codesign: -s \
            -k "$KEYCHAIN_PASSWORD" build.keychain

          # 4) 安装描述文件
          mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
          cp profile.mobileprovision "$HOME/Library/MobileDevice/Provisioning Profiles/"

      # ---------- 构建签名 ipa（使用第 3.4 节导出的 exportOptions.plist） ----------
      - name: 构建 ipa
        run: |
          flutter build ipa --release \
            --export-options-plist=ios/exportOptions/AppStore.plist \
            --build-name=${{ steps.info.outputs.version }} \
            --build-number=${{ steps.info.outputs.build_number }} \
            --dart-define=APP_ENV=prod \
            --dart-define=API_BASE_URL=https://api.taoyue.com \
            --dart-define=COMMIT_HASH=${{ steps.info.outputs.short_sha }} \
            --dart-define=BUILD_NUMBER=${{ steps.info.outputs.build_number }}

      - name: 归集产物（命名带 版本-构建号-commit）
        run: |
          mkdir -p dist
          VER=${{ steps.info.outputs.version }}
          BN=${{ steps.info.outputs.build_number }}
          SHA=${{ steps.info.outputs.short_sha }}
          IPA=$(ls build/ios/ipa/*.ipa | head -1)
          cp "$IPA" "dist/taoyue-edu_${VER}_${BN}_${SHA}_prod.ipa"
          ls -lh dist/

      # 可选：同时归档 dSYM（崩溃符号，日后 symbolicate 用）
      - name: 归档 dSYM（可选）
        if: always()
        run: |
          mkdir -p dsym_out
          find build/ios/archive -name "*.dSYM" -exec cp -R {} dsym_out/ \; 2>/dev/null || true
          find dsym_out -name "*.dSYM" | head

      - name: 上传 dSYM（可选）
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: ios-dSYMs-${{ inputs.version }}
          path: dsym_out
          retention-days: 90

      # ---------- 归档：挂到同名 Release（先跑 Android 那个，这里只是追加） ----------
      - name: 挂载 ipa 到 Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: v${{ steps.info.outputs.version }}
          files: dist/*
```

### 附录 C 收尾检查单（全部文件落地后）

- [ ] 本地 `flutter analyze`、`flutter test` 全绿（01~03 做完即应如此）
- [ ] 04~07 四个 yml 已 push 到 GitHub main 分支
- [ ] Actions 页能看到 3 条 workflow（quality-gate 等 PR 才触发，平时显示正常）
- [ ] `android/key.properties` 与 keystore 仍被 gitignore（第 3.2 验证过 `git check-ignore`）
- [ ] Secrets 已按附录 A 配齐（Android 三项 + iOS 四项）
- [ ] 按第 6.4 节操作剧本跑一次 Android Release，拿到 `taoyue-edu_x.y.z_<构建号>_<commit>_prod.aab / .apk`

> 全教程完（第 1~9 章 + 附录 A/B/C 为 iOS + Android 双端主线）。做完这九章，你手里就有一套"能讲、能演示、能复现"的双端全渠道上架与 CI/CD 体系：PR 质量门禁 → main 自动 debug 包 → Release 签名产物自动归档，全程密钥不进库、每个包可回溯到 commit，合规有台账有截图。
>
> 下面第 10 章 + 附录 D 是追加的**鸿蒙（HarmonyOS NEXT）第四端**接入线，独立成章，不影响上面已完成的 iOS / Android 体系。

---

## 第 10 章 鸿蒙（HarmonyOS NEXT）端接入 + CI（重点，1~2 天）

> 目标：把同一个 Flutter 工程「桃悦智科」接上鸿蒙 HarmonyOS NEXT（API 12+ / 鸿蒙 5.0），在你的**真实仓库**里生成 `ohos/` 平台工程，本地能构建出签名 HAP、能在模拟器/真机跑，再补一条 HarmonyOS 的 CI workflow 自动出签名 HAP 产物，最后梳理华为应用市场（AppGallery）的上架与合规要点。
>
> 本章和前面 1~9 章的关系（面试也按这个说）：
> 1. **共享 Dart 业务代码**：iOS / Android / HarmonyOS 三端都跑同一份 `lib/` 代码，`AppConfig`、接口层、页面全部复用。鸿蒙接入主要是**平台侧**（多出一个 `ohos/` 目录 + 一套鸿蒙构建工具链）。
> 2. **不是官方默认能力**：官方 Flutter SDK 默认**不支持**鸿蒙。鸿蒙适配走的是 **OpenHarmony SIG 团队维护的定制版 Flutter 引擎**（代码在 gitee `openharmony-sig/flutter_flutter`）。所以第 10 章第 1 节先讲清楚工具链怎么来，否则你在默认 flutter 下 `flutter create --platform=ohos` 会直接失败。
> 3. **CI 是"追加一条 job"而非"改原来三条"**：鸿蒙产的是 `.hap`（对应安卓的 `.apk`）、签名用华为的 `.p12/.cer/.p7b`（对应安卓 keystore / iOS 证书），构建器在 Linux 就能跑，所以第 6 章的 Release 里可以再加一个 HarmonyOS job（或独立一条 workflow）。本章给独立 workflow，便于隔离故障。

### 10.0 本章需要的账号、工具、钱

| 用途 | 账号 / 工具 | 成本 | 什么时候要 |
|---|---|---|---|
| 鸿蒙 Flutter 定制引擎 | OpenHarmony SIG 的 `flutter_flutter`（免费克隆） | 免费 | 10.2 |
| IDE + SDK + 构建器 | DevEco Studio（华为官方 IDE，含 HarmonyOS SDK / Node / hvigor / ohpm） | 免费（商业版/个人版按需） | 10.2 |
| 命令行构建 HAP | DevEco Studio 内置 `hvigorw`，或全局安装 | 免费 | 10.4 |
| 签名证书 | 在 AppGallery Connect（AGC）实名开发者账号里申请 | 个人开发者免费/按华为政策 | 10.5 |
| 上架 | 华为开发者联盟账号（AppGallery Connect） | 免费认证，上架无一次性年费 | 10.6 |
| 国内合规 | 软著、APP 备案、鸿蒙应用检测报告 | 软著数百~千元（可复用第 7 章那本） | 10.6 |

> 练习提示：如果只想先"把鸿蒙跑起来 + CI 出 HAP"，10.1~10.4 + 10.7 在 Windows（本机）+ Linux（CI）就能完成，**用 DevEco 自动生成的 debug 签名**即可，连 AGC 开发者账号都不用注册。真上架才需要走 10.5 的正式签名和 10.6 的 AGC 流程。

### 10.1 先搞清楚：为什么默认 Flutter 跑不了鸿蒙

#### 10.1.1 现状（2025~2026）

- **官方 Flutter SDK 不开箱支持鸿蒙**。`flutter doctor` 不会出现 HarmonyOS，`flutter create` 默认不产出 `ohos` 平台。
- 鸿蒙适配来自 **OpenHarmony SIG 的 `flutter_flutter`**（一个基于官方 Flutter 加了 ohos 平台的分支）。业界叫法有「Flutter-OH」「FlutterOHOS」「flutter_flutter ohos」。它**替换**你平时用的 flutter 可执行文件（不冲突，是可单独切换的一套 SDK）。
- 接入方式分两种：
  - **A. 新建鸿蒙工程**：`flutter create` 时带上 ohos 平台，从零生成 `ohos/` 目录。
  - **B. 存量工程增量接入**：在你现有工程根目录执行 `flutter config --enable-harmony` 后，再 `flutter create --platform=ohos .`，给已有工程**补出**鸿蒙平台目录（不破坏 android/ios/lib）。本项目就是走这条（B）。
- 官方和鸿蒙 SIG 的同步节奏在加快，**教程给的命令、目录、文件名会随版本微调**，但"定制引擎 → enable-harmony → create --platform=ohos → hvigor 构建 HAP"这条主线是稳定的。

#### 10.1.2 一句话给面试官

> "鸿蒙 NEXT 不支持官方 Flutter 直接编包，我用的是 OpenHarmony SIG 维护的 flutter_flutter 定制引擎切到 ohos 分支；先在 `flutter config --enable-harmony` 打开开关，再用 `flutter create --platform=ohos .` 在现有工程上补出 ohos 平台工程，然后走 DevEco 的 hvigor 命令产出签名 HAP。业务代码三端共享，鸿蒙只多一套平台工程和签名链路。"

### 10.2 安装鸿蒙工具链（本机 Windows）

> 顺序别乱：**先装 DevEco Studio（自带 SDK/hvigor/ohpm），再装定制 Flutter 引擎，再 enable-harmony**。官方 Flutter 与鸿蒙定制 Flutter 建议分开两套，切换用 `flutter` 的 channel 或显式 PATH。

#### 步骤 1：安装 DevEco Studio

1. 打开华为开发者官网，下载 **DevEco Studio NEXT**（随装 HarmonyOS SDK）。你的机型/模拟器是 HarmonyOS NEXT（API 12+）就装对应 NEXT 版。
2. 安装时选择组件里勾选：**DevEco Studio、HarmonyOS SDK、Node.js、Command Line Tools（hvigorw/ohpm）**。
3. 首次启动会引导下载 HarmonyOS SDK（含 `hvigor`、`ohpm`、模拟器镜像）。记下 SDK 目录，后面要配 `DEVECO_SDK_HOME`。
4. 验证 IDE 内打开任意鸿蒙工程能同步构建（确保 SDK 完整）。

> 如果你已有 Android Studio，两者可以共存；鸿蒙工程请始终用 DevEco Studio 打开。

#### 步骤 2：克隆并切换鸿蒙定制 Flutter 引擎

在 PowerShell 里把鸿蒙 flutter 克隆到独立目录（不要覆盖你平时的官方 flutter）：

```powershell
cd E:\
git clone https://gitee.com/openharmony-sig/flutter_flutter.git flutter_ohos
cd flutter_ohos

# 列出可用的 ohos 分支/tag，挑一个"稳定版 ohos 版本"（教程按 3.27.4-ohos-1.0.4 示例，以你 clone 后实际可见为准）
git tag | findstr ohos
git checkout 3.27.4-ohos-1.0.4
```

> 版本对不上会导致 `flutter create --platform=ohos` 失败或跑不起来。**以你在 gitee 仓库可见的最新稳定 ohos 标签为准**，替换上面 `3.27.4-ohos-1.0.4`。

#### 步骤 3：启用鸿蒙平台并确认

把鸿蒙 flutter 加进 PATH（临时示例，正式可写到用户环境变量）：

```powershell
$env:Path = "E:\flutter_ohos\bin;" + $env:Path

# 确认已是鸿蒙版 flutter
flutter --version

# 打开鸿蒙平台开关（一次性，会写进 flutter 配置）
flutter config --enable-harmony

# 确认 HarmonyOS 出现在 doctor 里
flutter doctor
```

> `flutter doctor` 若能列出 HarmonyOS / ohos 相关项（而不是报错），说明开关已生效。若提示找不到鸿蒙 SDK，补配环境变量：
> ```powershell
> $env:DEVECO_SDK_HOME = "C:\Program Files\Huawei\DevEco Studio\sdk"
> ```

### 10.3 存量工程接入：给「桃悦智科」补出 ohos 平台

在你**本仓库根目录**（必须用鸿蒙版 flutter，见 10.2 步骤 3）：

```powershell
cd E:\projects\2507A\flutter_edu_app

# 确保用的是鸿蒙 flutter
flutter --version

# 给现有工程补生成 ohos 平台（只新增，不改 android/ios/lib）
flutter create --platform=ohos .
```

命令跑完，仓库会多出一个 `ohos/` 平台目录（这是鸿蒙工程，跟 `android/`、`ios/` 平级）：

```
flutter_edu_app/
├── lib/                 # 业务代码（三端共享，不动）
├── android/ ios/ web/ ...   # 原有平台，不动
├── ohos/                # ★ 新增的鸿蒙平台工程
│   ├── AppScope/
│   │   └── app.json5    # 应用级：bundleName、版本、图标
│   ├── entry/           # HAP 入口模块
│   │   ├── src/main/
│   │   │   ├── ets/     # ArkTS 页面 + Flutter 容器
│   │   │   ├── module.json5   # 模块：包名后缀、权限、targetSdk
│   │   │   └── resources/
│   │   └── build-profile.json5  # 模块级构建 + 签名引用
│   ├── build-profile.json5      # ★ 工程级签名配置（p12/cer/p7b 在这）
│   ├── hvigorfile.ts
│   ├── hvigorfile.ts 副本(入口)
│   ├── oh-package.json5   # ohos 依赖声明
│   └── ...
```

> 第 10.3 生成的是一份能编译的最小鸿蒙壳，真正要用 DevEco 打开 `ohos/` 目录跑通一次、确认 SDK/依赖同步，再做后续签名和 CI。

#### 工程结构名词速查（面试口径）

| 概念 | 对应安卓 | 说明 |
|---|---|---|
| `entry` 模块 | 安卓 app 模块 | HAP 的宿主模块，含 ArkTS 与 Flutter 容器 |
| `bundleName` | applicationId / 包名 | 鸿蒙的"包名"，写在 `AppScope/app.json5` |
| `module.json5` | AndroidManifest.xml | 模块配置：权限、名称 |
| `build-profile.json5` | build.gradle.kts 签名段 | 签名材料 + 构建参数 |
| `oh-package.json5` | pubspec.yaml（依赖） | ohos 侧依赖 |
| `.hap` | `.apk` | 最终安装/上架包 |

### 10.4 本地构建 HAP 并真机/模拟器跑通

#### 10.4.1 用 DevEco Studio 首次同步（推荐，跑通依赖）

1. 用 DevEco Studio 打开 `E:\projects\2507A\flutter_edu_app\ohos`。
2. 等它自动执行 `ohpm install` 与工程同步（首次较慢）。
3. 若报缺依赖，在 `ohos/` 下手动执行：`ohpm install`。

#### 10.4.2 命令行构建 HAP（CI 也这么跑）

在 `ohos/` 目录下（PowerShell 用 `hvigorw.bat`，Linux/macOS 用 `./hvigorw`）：

```powershell
cd E:\projects\2507A\flutter_edu_app\ohos

# debug 签名（DevEco 自动生成的本地调试证书），先跑通
.\hvigorw.bat assembleHap --mode module -p product=default -p buildMode=debug --no-daemon
```

构建成功后的产物路径（看 `build-profile.json5` 的 module 名，默认是 `entry`）：

```
ohos/entry/build/default/outputs/default/
└── entry-default-signed.hap      # 带签名（本地 debug 证书）的 HAP
```

#### 10.4.3 在模拟器/真机运行

- 模拟器：DevEco 里启动 HarmonyOS 模拟器后，IDE 直接 Run。
- 真机：鸿蒙手机开开发者模式 → 连 USB → DevEco 里选择设备 Run。
- 命令行调试参考（DevEco 的 `hdc` 工具，等价安卓 adb）：
  ```powershell
  hdc list targets
  hdc install ohos/entry/build/default/outputs/default/entry-default-signed.hap
  ```

> 到这里，你已经在**真实仓库**上把同一份 Flutter 代码跑到了鸿蒙。第 10.3/10.4 产出的只是 debug 签名的 HAP，只能本机/模拟器用，**不能上架**。要上架，必须走 10.5 的正式签名。

### 10.5 正式签名：从 AGC 申请证书并配置到工程

鸿蒙上架包必须是**正式签名 HAP**（跟安卓 release 必须正式 keystore 一个道理）。签名材料三件套：`.p12`（私钥库）、`.cer`（公钥证书）、`.p7b`（profile 描述文件），都在 AppGallery Connect 生成/下载。

#### 步骤 1：在 AGC 创建应用拿到应用信息

1. 打开 AppGallery Connect（developer.huawei.com → 我的项目），实名认证开发者。
2. 新建项目 → 新建应用。**应用包名填 `com.taoyue.edu`**（建议与安卓正式包名一致，便于品牌统一；鸿蒙的 bundleName 就是反向域名）。
3. 平台选 HarmonyOS。

#### 步骤 2：生成并下载证书三件套

1. 按 AGC 指引生成**密钥库 .p12**（自选密码，妥善保存，丢了无法补签）与 **证书请求 .csr**。
2. AGC 签发**发布证书 .cer**，用于签名。
3. 创建**发布 Profile**，绑定证书与应用，下载得到 **.p7b**。

#### 步骤 3：把签名材料写进工程

把 `.p12`、`.cer`、`.p7b` 放到仓库**被 gitignore 的位置**（建议放 `ohos/` 下的一个忽略目录，或跟 keystore 一样交给 CI 注入，绝不提交）。随后编辑工程级 `ohos/build-profile.json5` 的 `signingConfigs`，把**路径与密码占位符**填进去（占位符由 CI/环境变量填充，本地用真实值填一遍跑通）。

> 完整可复制的 `build-profile.json5` 示例放在**附录 D** 的第 D-3 步。这里只讲原理：本地开发时把 `storePassword` / `keyPassword` 填成本机环境变量或真实密码都行（本机不提交就没事），但**CI 里必须用 `${{ secrets.* }}` 注入、并让 hvigor 从环境变量读**，杜绝明文入库。

#### 步骤 4：构建正式签名 HAP

```powershell
cd E:\projects\2507A\flutter_edu_app\ohos
.\hvigorw.bat assembleHap --mode module -p product=default -p buildMode=release --no-daemon
```

成功后在产物目录得到 **`entry-default-signed.hap`**（release、正式签名）。这个才是能上架华为应用市场的包。

> 常见坑：只生成了 `entry-default-unsigned.hap`（未签名）说明 `build-profile.json5` 的签名材料路径/密码没配对，或 `-p buildMode=release` 但签名 config 没指向 release。先回 DevEco 里把「自动签名」勾上跑一遍，确认能出 signed，再回命令行复现。

### 10.6 华为应用市场上架（AppGallery Connect）

拿到正式签名 HAP 后，到 AGC 的「应用上架」里走一遍：

| 阶段 | 要交的东西 | 备注 |
|---|---|---|
| 基本信息 | 应用名、图标（1 套多尺寸）、截图、简介 | 图标建议用第 2 章那套品牌图衍生 |
| 版本信息 | 上传签名 HAP，填版本号 | 版本号与 iOS/Android 对齐，可追溯见 10.9 |
| 隐私 | 隐私政策链接、收集权限声明 | 复用第 7 章已备好的隐私政策页 |
| 合规 | 软著证书、**HarmonyOS 专项检测报告** | 华为对鸿蒙应用有隐私/安全检测 |
| 备案 | APP 备案号（复用第 7 章办的那次工信部备案） | 上架需填写已备案信息 |
| 提交审核 | 等华为审核 | 首次务必核对「签名 HAP + 包名 + 截图 + 备案」四项一致 |

> 鸿蒙上架审核与安卓市场审核类似，核心也是**包能装、权限合规、隐私明确、有备案**。第 7 章的合规清单基本可复用，鸿蒙特有的几点在第 10.8 单独列。

### 10.7 HarmonyOS CI：自动产出签名 HAP

与第 6 章安卓 Release 同理，鸿蒙 CI 也是一个手动触发的 workflow，在 **Linux runner**（免费）上装鸿蒙 SDK + 定制 Flutter → 注入证书 → `hvigorw assembleHap --mode module -p buildMode=release` → 把 `*.hap` 挂到 Release。

> **前提**：这台 CI 机器要能访问 DevEco 的 SDK。社区/官方给的是通过下载 HarmonyOS SDK command-line 包 + Node + hvigorw 来搭无头环境。为降低教程上手成本，第 10.7 的 workflow 采用「下载 HarmonyOS SDK 压缩包（华为官方命令行版本）+ 定制 Flutter + 全局 hvigor」的方式，**需要你先把 SDK 以可下载形式放好**（或用自建镜像），详见附录 D 第 D-4 步的 Secrets/说明。

完整 workflow 文件在**附录 D 第 D-4 步**，这里给出它的执行逻辑：

```
release-harmonyos.yml 执行逻辑
────────────────────────────────────────────
1. Linux runner
2. 检出代码（flutter create --platform=ohos 已在本地提交，ohos/ 目录随仓库入库）
3. 装 JDK(17) + 定制 flutter（clone openharmony-sig/flutter_flutter + checkout ohos tag）
4. flutter config --enable-harmony
5. 下载 HarmonyOS SDK 到 runner，设 DEVECO_SDK_HOME
6. 注入签名：从 Secrets 还原 .p12/.cer/.p7b + 生成带 env 密码的 build-profile.json5
7. ohos/ 下执行 hvigorw assembleHap --mode module -p buildMode=release
8. 把 entry-*-signed.hap 重命名（带 版本-构建号-commit）挂到 GitHub Release
────────────────────────────────────────────
```

> ⚠️ 诚实边界（写简历别吹过头）：鸿蒙无头 CI 的搭建比安卓复杂，SDK 获取和证书注入是最大工作量。如果面试官深问，你应能说清"HAP 用 hvigorw 命令行出、签名走 AGC 的 p12/p7b、Linux runner 可行"，而**不要**声称"一条龙自动传到华为市场"——AGC 上传同样主要靠人工点提交（与第 0.1 的'半自动'口径一致）。

### 10.8 鸿蒙合规清单（专项）

在复用第 7 章清单基础上，鸿蒙端多这几项，逐项留截图：

| 合规项 | 说明 | 谁负责 | 验收截图 |
|---|---|---|---|
| 鸿蒙应用检测 | 华为要求提交前的安全/隐私自检 | 开发者 | 检测报告通过页 |
| 权限最小化 | `module.json5` 里权限尽量少、逐条有用途 | 开发者 | module.json5 权限列表 |
| 隐私政策 | 在鸿蒙 App 内可打开，URL 与安卓一致 | 运营 | App 内隐私页截图 |
| APP 备案 | 复用第 7 章工信部备案号，勿单独再办 | 合规 | 备案号 + 审核通过截图 |
| bundleName 唯一 | `com.taoyue.edu` 全网唯一、与 AGC 一致 | 开发者 | AGC 应用信息页 |
| 版本对齐 | 鸿蒙版本号 = iOS/Android 的 x.y.z | 开发 | 三端版本表 |

### 10.9 发版可追溯 + 验收清单

鸿蒙包的追溯与第 8 章同套路：HAP 产物文件名带上 `版本-构建号-commit`（workflow 里做），`AppConfig` 里注入的 `COMMIT_HASH` / `BUILD_NUMBER` 对三端通用（第 2 章已加，鸿蒙端 Dart 代码直接用，无需改）。

第 10 章做完的验收清单：

- [ ] `ohos/` 目录已在仓库里（`flutter create --platform=ohos` 产物已提交）
- [ ] 本机 DevEco 能打开 `ohos/` 并 Run 到模拟器/真机
- [ ] `hvigorw assembleHap ... -p buildMode=release` 能产出 **`entry-default-signed.hap`**（正式签名）
- [ ] AGC 已建应用（bundleName=`com.taoyue.edu`），三件套证书已下载
- [ ] 手动触发 `release-harmonyos.yml` 成功，Release 上有带版本号的 `.hap`
- [ ] 三端（iOS/Android/HarmonyOS）都注入同一份 `COMMIT_HASH`/`BUILD_NUMBER`，出问题能回溯

---

## 附录 D 鸿蒙落地操作卡：用定制 Flutter 引擎产出 HAP + 签名 + CI（照着抄）

> 本附录是第 10 章的可复现操作卡，**按顺序执行**：D-1 装工具 → D-2 补 ohos 平台 → D-3 配置签名 → D-4 建 CI workflow。第 10 章讲"为什么"，本附录负责"怎么抄、文件放哪、内容是什么"。

### D-0 先把要用到的仓库级忽略规则配好（防证书入库）

编辑仓库根 `.gitignore`，追加：

```gitignore
# HarmonyOS 签名材料，绝不入库
ohos/**/*.p12
ohos/**/*.cer
ohos/**/*.p7b
ohos/**/*.csr
harmonyos-keyfiles/
```

### D-1 安装并切换鸿蒙工具链（本机 Windows）

```powershell
# 1) 装 DevEco Studio NEXT（含 HarmonyOS SDK / Node / hvigor / ohpm），记下 SDK 路径
# 2) 克隆鸿蒙定制 flutter
cd E:\
git clone https://gitee.com/openharmony-sig/flutter_flutter.git flutter_ohos
cd flutter_ohos
git tag | findstr ohos          # 看有哪些 ohos tag
git checkout 3.27.4-ohos-1.0.4  # 换成你可见的稳定 ohos tag

# 3) 切到鸿蒙 flutter 并开开关
$env:Path = "E:\flutter_ohos\bin;" + $env:Path
flutter config --enable-harmony
flutter doctor                     # 应能看到 HarmonyOS/ohos
```

### D-2 给现有工程补出 ohos 平台

在仓库根目录（务必用鸿蒙版 flutter）：

```powershell
cd E:\projects\2507A\flutter_edu_app
flutter create --platform=ohos .
```

成功后 `ohos/` 出现。提交这个新目录：

```powershell
git add ohos/
git commit -m "feat(harmonyos): 生成 ohos 平台工程（flutter create --platform=ohos）"
```

### D-3 配置正式签名（build-profile.json5 示例）

把 AGC 下载的 `.p12` / `.cer` / `.p7b` 放到仓库内的忽略目录（示例 `harmonyos-keyfiles/`，已被 D-0 gitignore）：

```
harmonyos-keyfiles/
├── taoyue-release.p12
├── taoyue-release.cer
└── taoyue-release.p7b
```

编辑 `ohos/build-profile.json5`，把 `signingConfigs` 部分改成像下面这样（**密码用占位符，本地先临时填真实值跑通，CI 里由 Secrets 注入**；各字段结构以你 DevEco 实际生成的一致为准，重点是把路径/密码指向你的文件与密钥别名）：

```json5
{
  app: {
    signingConfigs: [
      {
        name: 'default',
        type: 'HarmonyOS',
        material: {
          // 相对 ohos/ 目录的证书路径
          certpath: '../harmonyos-keyfiles/taoyue-release.cer',
          storePassword: '${HARMONY_KEYSTORE_PASSWORD}', // 占位符，CI 里换成 secrets 注入
          keyAlias: 'taoyue_release',
          keyPassword: '${HARMONY_KEY_PASSWORD}',
          profile: '../harmonyos-keyfiles/taoyue-release.p7b',
          signAlg: 'SHA256withECDSA',
          storeFile: '../harmonyos-keyfiles/taoyue-release.p12'
        }
      }
    ]
  }
}
```

> 注意：`build-profile.json5` 里的 `signAlg`、`keyAlias` 要以你 AGC/DevEco 实际生成的为准；不同 DevEco 版本字段略有差异。**本地务必先跑通一次 release 签名**再上 CI，避免把"没配对的签名"推到流水线里空转。

本地构建正式签名 HAP：

```powershell
cd E:\projects\2507A\flutter_edu_app\ohos
.\hvigorw.bat assembleHap --mode module -p product=default -p buildMode=release --no-daemon
# 产物：entry/build/default/outputs/default/entry-default-signed.hap
```

### D-4 HarmonyOS CI：`release-harmonyos.yml`（新建）

> 前置：这台 Linux runner 需要能拿到 HarmonyOS SDK 命令行版并设 `DEVECO_SDK_HOME`。教程假设你在 GitHub Actions 里用一个「下载 HarmonyOS SDK 的命令行 tar」步骤完成（SDK 官方提供 command-line 下载；若网络受限请改用自建镜像/缓存）。签名证书走 Secrets，密码经环境变量注入 hvigor。

在 `.github/workflows/` 下新建 `release-harmonyos.yml`：

```yaml
name: HarmonyOS Release（正式签名 HAP）

# 手动触发：填版本号后运行，建议与 Android/iOS 同版本号
on:
  workflow_dispatch:
    inputs:
      version:
        description: '发布版本号（x.y.z，如 1.2.0，须与三端一致）'
        required: true
        type: string

permissions:
  contents: write

env:
  FLUTTER_OHOS_VERSION: '3.27.4-ohos-1.0.4'   # 换成你实际使用的 ohos tag

jobs:
  release-harmonyos:
    name: 构建并归档 HarmonyOS 正式 HAP
    runs-on: ubuntu-latest
    steps:
      - name: 检出代码
        uses: actions/checkout@v4

      # ---- 1) 鸿蒙定制 Flutter 引擎 ----
      - name: 安装鸿蒙 Flutter 引擎
        run: |
          git clone https://gitee.com/openharmony-sig/flutter_flutter.git "$HOME/flutter_ohos"
          cd "$HOME/flutter_ohos"
          git checkout "$FLUTTER_OHOS_VERSION"
          echo "$HOME/flutter_ohos/bin" >> "$GITHUB_PATH"

      - name: 安装 JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: 启用鸿蒙平台
        run: |
          flutter config --enable-harmony
          flutter --version

      # ---- 2) 下载并配置 HarmonyOS SDK（command-line 版）----
      # 说明：SDK 命令行列式可从华为官方获取；本步按你实际可下载的 URL/包名调整。
      - name: 下载 HarmonyOS SDK
        run: |
          mkdir -p "$HOME/harmonyos-sdk"
          echo "下载 command-line SDK 到 $HOME/harmonyos-sdk ..."  # 替换为你实际来源
          # curl -L <SDK_URL> -o "$HOME/harmonyos-sdk/sdk.zip" && unzip -q ...
        env:
          OHOS_SDK_URL: ${{ secrets.HARMONY_SDK_URL }}   # 你的 SDK 下载地址/签名后的链接
      - name: 配置 SDK 环境
        run: |
          echo "DEVECO_SDK_HOME=$HOME/harmonyos-sdk" >> "$GITHUB_ENV"
          echo "$HOME/harmonyos-sdk/command-line-tools/bin" >> "$GITHUB_PATH"

      # ---- 3) 注入鸿蒙签名证书（Secrets → 工作区忽略目录）----
      - name: 注入签名证书
        env:
          P12_B64: ${{ secrets.HARMONY_CERT_P12_B64 }}     # .p12 base64
          CER_B64: ${{ secrets.HARMONY_CERT_CER_B64 }}     # .cer base64
          P7B_B64: ${{ secrets.HARMONY_PROFILE_P7B_B64 }}  # .p7b base64
          STORE_PW: ${{ secrets.HARMONY_KEYSTORE_PASSWORD }}
          KEY_PW: ${{ secrets.HARMONY_KEY_PASSWORD }}
          KEY_ALIAS: ${{ secrets.HARMONY_KEY_ALIAS }}
        run: |
          mkdir -p harmonyos-keyfiles
          echo "$P12_B64" | base64 --decode > harmonyos-keyfiles/release.p12
          echo "$CER_B64" | base64 --decode > harmonyos-keyfiles/release.cer
          echo "$P7B_B64" | base64 --decode > harmonyos-keyfiles/release.p7b
          # 用真实值覆盖 build-profile.json5 里的占位符（脚本见下方说明）

      # ---- 4) 计算版本与追溯信息 ----
      - name: 计算版本信息
        id: info
        run: |
          VERSION="${{ inputs.version }}"
          if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then echo "版本格式错误"; exit 1; fi
          echo "version=$VERSION" >> "$GITHUB_OUTPUT"
          echo "short_sha=${GITHUB_SHA::7}" >> "$GITHUB_OUTPUT"
          echo "build_number=$(git rev-list --count HEAD)" >> "$GITHUB_OUTPUT"

      # ---- 5) 安装 ohos 依赖并构建正式签名 HAP ----
      - name: 构建签名 HAP
        working-directory: ohos
        run: |
          ohpm install
          ./hvigorw assembleHap --mode module -p product=default -p buildMode=release --no-daemon

      # ---- 6) 归集产物（命名带 版本-构建号-commit）----
      - name: 归集 HAP
        run: |
          mkdir -p dist
          VER=${{ steps.info.outputs.version }}
          BN=${{ steps.info.outputs.build_number }}
          SHA=${{ steps.info.outputs.short_sha }}
          find ohos/entry/build -name "*-signed.hap" | while read f; do
            cp "$f" "dist/taoyue-edu_${VER}_${BN}_${SHA}_harmonyos.hap"
          done
          ls -lh dist/

      # ---- 7) 挂到 GitHub Release（与 Android/iOS 同一个 v x.y.z）----
      - name: 挂载 HAP 到 Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: v${{ steps.info.outputs.version }}
          files: dist/*
```

> 第 3 步用真实值覆盖占位符的脚本：为保持 yml 简洁，可在注入后用一个 `sed`（Linux）把 `${HARMONY_KEYSTORE_PASSWORD}` 等占位符替换为 secrets 值，再写回 `ohos/build-profile.json5`。示例（可加进第 3 步 run 末尾）：
> ```bash
> sed -i "s|\${HARMONY_KEYSTORE_PASSWORD}|$STORE_PW|g; s|\${HARMONY_KEY_PASSWORD}|$KEY_PW|g; s|taoyue_release|$KEY_ALIAS|g" ohos/build-profile.json5
> ```
> 本机已把签名文件放 `harmonyos-keyfiles/` 且路径写的是 `../harmonyos-keyfiles/...`，CI 里同样生成该目录即可复用同一份 build-profile.json5（保持占位符版本提交到仓库，密码始终不落盘）。

### D-5 GitHub Secrets：鸿蒙相关新增项

在 AGC 准备并加入仓库 Secrets（方法同第 3/附录 A：`gh secret set <名字>` 或网页端）：

| Secret | 值 | 说明 |
|---|---|---|
| `HARMONY_CERT_P12_B64` | `.p12` 的 base64 | 私钥库 |
| `HARMONY_CERT_CER_B64` | `.cer` 的 base64 | 发布证书 |
| `HARMONY_PROFILE_P7B_B64` | `.p7b` 的 base64 | Profile |
| `HARMONY_KEYSTORE_PASSWORD` | p12 库密码 | 构建时经 env 注入 |
| `HARMONY_KEY_PASSWORD` | 密钥别名密码 | 构建时经 env 注入 |
| `HARMONY_KEY_ALIAS` | 密钥别名 | 构建时经 env 注入 |
| `HARMONY_SDK_URL` | SDK 下载地址 | 供 CI 拉取 command-line SDK |

在 Windows PowerShell 生成 base64 的示例（任选其一文件示范）：

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("E:\path\taoyue-release.p12")) > p12.b64
Get-Content p12.b64 -Raw | gh secret set HARMONY_CERT_P12_B64
```

### D-6 附录 D 收尾检查单

- [ ] `ohos/` 目录已提交到仓库；`.gitignore` 已忽略 p12/cer/p7b
- [ ] 本机用鸿蒙定制 flutter 跑通 `flutter create --platform=ohos`
- [ ] DevEco 能 Run 到模拟器/真机；`hvigorw assembleHap` 产出 **signed.hap**
- [ ] AGC 正式证书三件套已下载、build-profile.json5 本地 release 签名跑通
- [ ] Secrets 已按 D-5 配齐；手动跑 `release-harmonyos.yml` 成功且 Release 上出现 `.hap`
- [ ] HAP 已能通过 10.6 的 AGC 上架流程提交

> 全教程（含鸿蒙）完。现在你手里是一套**三端**（iOS / Android / HarmonyOS）都能讲、能演示、能复现的上架与 CI/CD 体系：三端共享同一份 Dart 业务代码，各端一套签名与 CI job，包都带 版本+构建号+commit 可回溯，密钥全部走 Secrets 不进库，合规有清单有截图。



