allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
        maven { url = uri("https://repo.repsy.io/mvn/payhere/payhere-mobilesdk-android/") }
    }
}

subprojects {
    afterEvaluate {
        if (hasProperty("android")) {
            extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
                compileSdkVersion(35)
                defaultConfig {
                    minSdkVersion(24)
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
