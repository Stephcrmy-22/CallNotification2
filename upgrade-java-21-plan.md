Upgrade to Java 21 (LTS) — Plan

Summary
-------
This document describes a safe, repeatable plan to upgrade the repository's Java runtime to Java 21 (LTS).

Repository snapshot (detected automatically)
- Path: /Users/admin/Desktop/DevProjects/CallNotif/agora_voice_call
- Build systems detected: Gradle (android/, app/ modules)
- Currently-detected Java level: Java 11 (found in `android/app/build.gradle.kts` as `JavaVersion.VERSION_11`)
- Notable files: `android/app/build.gradle.kts`, `android/gradle/wrapper/gradle-wrapper.properties`, `ios/.zshrc` (sets JAVA_HOME to 1.8)

Why generate_upgrade_plan failed
--------------------------------
I attempted to run the automated `generate_upgrade_plan` tool, but it failed due to the repository being classified as an unsupported project type (intellij). The automated upgrade tool requires a Maven or Gradle wrapper project structure in the analyzed root; in our workspace the presence of IDE project metadata caused the tool to abort.

What I did instead
------------------
- Ran automated repo analysis to find Gradle modules and where Java compatibility is set.
- Created this manual upgrade plan that follows the same safe checks the automated tool would perform.

Assumptions (made conservatively)
- The Android module is the only module that actually sets Java compatibility to 11. Other modules are Flutter-related or not affected.
- We will not change Android Gradle Plugin (AGP) or Kotlin versions in this small change. If AGP or Kotlin versions require updating to be compatible with Java 21, that will be called out as a follow-up.
- You can install JDK 21 on your macOS environment and optionally update CI to use it.

Contract (inputs / outputs / success criteria)
- Input: repository at current commit on `main`, local macOS dev machine.
- Outputs: a documented plan (`upgrade-java-21-plan.md`), suggested file edits for Gradle files, commands to install JDK 21, verification steps.
- Success criteria: `java -version` reports Java 21 on developer machine/CI, Gradle build succeeds for non-Android-only modules, Flutter Android build either succeeds or the repo remains unchanged if Android requires older Java.

Upgrade steps (high-level)
1. Install JDK 21 on dev machine and CI (macOS instructions below).
2. Update Gradle wrapper if needed to a Gradle version that supports Java 21. (Do not upgrade blindly — test locally.)
3. For pure-Java/Gradle modules: enable Gradle toolchains or set source/target compatibility to 21.
4. For Android modules: verify AGP supports Java 21. If not supported, leave Android compile options at Java 11 and only use JDK 21 as the runtime for tooling (Gradle daemon), or update AGP and Kotlin first.
5. Run builds and tests, fix any compilation issues, and update CI definitions.
6. Commit changes to a new branch and open a PR.

Conservative per-module guidance
- android/app (Android Flutter module)
  - Current lines found:
    - `sourceCompatibility = JavaVersion.VERSION_11`
    - `targetCompatibility = JavaVersion.VERSION_11`
  - Recommendation:
    - Keep Android module at Java 11 unless you've confirmed the Android Gradle Plugin (AGP) version used by the project supports Java 21. Many AGP versions only guarantee Java 11 support.
    - If you decide to proceed, update `compileOptions` to JavaVersion.VERSION_21, and verify Kotlin's `jvmTarget` is set to a compatible value (Kotlin 1.8+ may be required). Better approach: update Gradle toolchain for Java compilation if applicable.

- Other Gradle modules (if any)
  - Add a `java { toolchain { languageVersion.set(JavaLanguageVersion.of(21)) } }` block (Kotlin DSL syntax) in module `build.gradle.kts` where the `java` plugin is applied.

Concrete file edits (examples)
- Example (Kotlin DSL) — enable toolchain for a Java module:
  java {
    toolchain {
      languageVersion.set(JavaLanguageVersion.of(21))
    }
  }

- Example (Android `build.gradle.kts`) — conservative (only do if AGP supports it):
  android {
    compileOptions {
      sourceCompatibility = JavaVersion.VERSION_21
      targetCompatibility = JavaVersion.VERSION_21
    }
    kotlinOptions {
      jvmTarget = "21"
    }
  }

Gradle wrapper
--------------
- The Gradle wrapper `distributionUrl` may need to be bumped to a recent Gradle version that supports Java 21. I recommend testing with Gradle 8.6+ (confirm exact compatibility for your AGP version).
- File to inspect/update: `android/gradle/wrapper/gradle-wrapper.properties` (change distributionUrl to e.g. `https\://services.gradle.org/distributions/gradle-8.6-bin.zip`).

macOS install commands (recommended)
- Option A — Homebrew (Eclipse Temurin 21):

  brew tap homebrew/cask-versions
  brew install --cask temurin21

  # set JDK 21 as default for current shell
  export JAVA_HOME=$(/usr/libexec/java_home -v 21)
  java -version

- Option B — SDKMAN (useful for switching JDKs):

  curl -s "https://get.sdkman.io" | bash
  source "$HOME/.sdkman/bin/sdkman-init.sh"
  sdk install java 21.0.0-tem
  sdk use java 21.0.0-tem
  java -version

Notes on CI / macOS dotfiles
- I found `ios/.zshrc` sets `JAVA_HOME` to Java 1.8. Update any per-platform dotfiles or CI images accordingly to point to Java 21 when you want the repo to use it.

Verification (smoke)
1. Locally run `java -version` -> should show `21`.
2. From repo root run Gradle build for the module(s):
   - `./gradlew -p android assembleDebug` (or the appropriate task). If Android build fails due to unsupported Java level, revert Android compile options and only run Gradle/daemon with Java 21.
3. Run Flutter build for Android: `flutter build apk` (if you use Flutter tooling ensure Flutter supports gradle/java changes)

Rollback plan
- If build breaks, restore files from the branch or revert the commits. Keep commits small and on a feature branch.

Next actions I can take for you (pick one or more)
- A) Create a feature branch and apply safe textual changes (add `upgrade-java-21-plan.md` — already created) and optionally update `android/app/build.gradle.kts` to Java 21 (risky for Android) and/or bump Gradle wrapper. Then run a local Gradle build and report output.
- B) Only update docs and provide exact patch suggestions (no code changes). Safer if you want to review first.
- C) Attempt `generate_upgrade_plan` again after removing or isolating IntelliJ metadata (I can try to run it against a cleaned workspace copy). This may allow the automated tool to run.

If you'd like me to proceed with edits and verification, tell me which option (A/B/C) you prefer. If you want me to proceed automatically, I'll: create a branch `upgrade/java-21`, update Gradle wrapper to a conservative newer Gradle (8.6), add the Gradle toolchain line to non-Android modules, leave Android module untouched unless you confirm.

Requirements coverage
- Use `generate_upgrade_plan`: FAILED (tool returned "Unsupported project type: intellij").
- Produce an upgrade plan to Java 21: DONE (this file).


Prepared by automated assistant — let me know which next action to run (apply changes, only docs, or re-run the automated planner after cleaning).