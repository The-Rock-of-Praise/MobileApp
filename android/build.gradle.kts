allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

subprojects {
    afterEvaluate {
        if (hasProperty("android")) {
            extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
                compileSdkVersion(35)
                defaultConfig {
                    minSdkVersion(23)
                }
            }
        }
    }
}

// Fix for Windows cross-drive Gradle build issue.
val isWindows = System.getProperty("os.name").lowercase().contains("windows")

if (isWindows) {
    val userHome = System.getenv("USERPROFILE") ?: "C:/Users/${System.getProperty("user.name")}"
    val winBuildDir = File("$userHome/flutter_build_cache/${rootProject.name}")
    rootProject.buildDir = winBuildDir
    subprojects {
        project.buildDir = File(winBuildDir, project.name)
    }
} else {
    val newBuildDir = File(rootProject.projectDir, "../build")
    rootProject.buildDir = newBuildDir
    subprojects {
        project.buildDir = File(newBuildDir, project.name)
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
