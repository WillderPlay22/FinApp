// android/build.gradle.kts

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configuración de directorios de compilación
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 🔥 EL PARCHE PARA ISAR (Colocado ANTES de la evaluación de la app) 🔥
subprojects {
    afterEvaluate {
        // Detectamos si es la librería "isar_flutter_libs"
        if (project.name == "isar_flutter_libs") {
            try {
                // Forzamos la configuración moderna que Isar necesita
                configure<com.android.build.gradle.LibraryExtension> {
                    // 1. Arregla el error "Namespace not specified"
                    namespace = "dev.isar.isar_flutter_libs"
                    // 2. Arregla el error "lStar not found" forzando SDK 35
                    compileSdk = 35
                }
            } catch (e: Exception) {
                // Si falla la configuración, imprimimos pero no detenemos todo
                println("No se pudo configurar Isar automáticamente: $e")
            }
        }
    }
}

// Esto debe ir después del parche
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}