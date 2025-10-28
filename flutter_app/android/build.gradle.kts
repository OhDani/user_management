import org.gradle.api.tasks.Delete

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Thiết lập buildDirectory mới
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.buildDir = newBuildDir.asFile

subprojects {
    // Thiết lập buildDir riêng cho từng module con
    buildDir = File(rootProject.buildDir, project.name)

    // Nếu muốn evaluation dựa trên :app
    evaluationDependsOn(":app")
}

// Task clean
tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
