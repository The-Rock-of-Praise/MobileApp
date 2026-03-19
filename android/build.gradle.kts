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
// When the project is on a different drive (e.g. E:) than the pub cache (C:),
// Gradle fails because source and output roots differ. We force all build output
// onto C: (the user home drive) on Windows, and keep the default elsewhere (CI/Linux).
val isWindows = System.getProperty("os.name").lowercase().contains("windows")

if (isWindows) {
    val userHome = System.getenv("USERPROFILE") ?: "C:/Users/${System.getProperty("user.name")}"
    val winBuildDir = File("$userHome/flutter_build_cache/${rootProject.name}")
    rootProject.layout.buildDirectory.value(rootProject.layout.dir(provider { winBuildDir }))
    subprojects {
        val subBuildDir = File("$userHome/flutter_build_cache/${rootProject.name}/${project.name}")
        project.layout.buildDirectory.value(project.layout.dir(provider { subBuildDir }))
    }
} else {
    val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
    rootProject.layout.buildDirectory.value(newBuildDir)
    subprojects {
        val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
        project.layout.buildDirectory.value(newSubprojectBuildDir)
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
