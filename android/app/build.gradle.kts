// ---------- 新增：为下面读取 key.properties 做准备 ----------
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
// 【照抄即可】第 3 章生成 key.properties 后自动生效；
//             现在没有这个文件也不报错（下面的 if (keyProps.exists()) 已做了保护）。
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
    // 【必改】换成你自己的正式包名，必须与第 1.4 章 ① 改的一致
    //        （本文件的 namespace 与下面 defaultConfig 的 applicationId 两处都要改，且相同）
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
        // 【必改】正式包名（全网唯一，上架后不可改），与上面的 namespace 保持一致
        applicationId = "com.taoyue.edu"
        minSdk = flutter.minSdkVersion
        // 【按需改】显式固定 targetSdk，便于和各安卓市场要求对齐（第 7 章合规点之一）
        //          34 是稳妥值；若你的 Flutter 版本默认更高，改回 flutter.targetSdkVersion
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ---------- 多环境 flavor：dev / staging / prod ----------
    // 【照抄即可】"env" 是维度名，要和下面每个 flavor 的 dimension 保持一致
    flavorDimensions += "env"
    productFlavors {
        // 【照抄即可，想改名先看这段】create("dev") 里的 "dev" 同时是三样东西：
        //   ① 命令行参数 --flavor dev
        //   ② 资源目录名 android/app/src/dev/
        //   ③ 最终包名后缀（由下面的 applicationIdSuffix 决定）
        //   改一处就得改全部，建议直接用 dev / staging / prod 别改
        create("dev") {
            dimension = "env"
            // 包名后缀是环境隔离的根：三套包可以同时装在一台手机上
            // 【按需改】最终包名 = applicationId + 后缀 = com.taoyue.edu.dev
            applicationIdSuffix = ".dev"
        }
        create("staging") {
            dimension = "env"
            applicationIdSuffix = ".staging"
        }
        create("prod") {
            dimension = "env"
            // 【别动】不写后缀 = 正式包名 com.taoyue.edu，上架的包绝不能加后缀
        }
    }

    // 【照抄即可，第 3 章才真正生效】现在没有 key.properties，signingProps 是空的，
    //                              不会写入任何签名信息，debug 构建完全不受影响
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
            // ⚠ 副作用：第 3 章生成 key.properties 之前，flutter build apk --release 会报错，属正常现象
            signingConfig = signingConfigs.findByName("release")
        }
    }
}

flutter {
    source = "../.."
}