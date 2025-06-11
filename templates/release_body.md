## IMPORTANT

- This extension is compatible with the GM 2022.0.1 LTSr2.
- This extension is to be used with GM 2023.4 and future releases.
- Works with **HTML5** export.

## CHANGES SINCE ${releaseOldVersion}

https://github.com/YoYoGames/GMEXT-Reddit/compare/${releaseOldVersion}...${releaseNewVersion}

## DESCRIPTION

> [!IMPORTANT]
> **GMEXT-Reddit is a build-time helper, not an API wrapper.**

* **Devvit bridge** – Lightweight wrapper that hooks into the build & run process and avoid manual calls to Devvit tooling.
* **One-click build & run** – The extension plugs into GameMaker’s pipeline so that **Build ► Run** automatically  
  1. compiles your game,  
  2. arranges the folder structure Reddit expects,  
  3. fires up a Devvit playtest command, and  
  4. hot-reloads your module for rapid testing.  
* **Ready-to-ship packaging** – On each successful build it emits the ZIP bundle required for Reddit mini-app submissions, so you can upload immediately.  
* **No extra APIs** – Apart from the minimal Devvit stubs needed for compilation, the extension adds **zero** new Reddit or OAuth endpoints. Any additional calls you need can be inserted manually into the generated JavaScript.  
* **Manual tweaks encouraged** – The exported files are intentionally human-readable. Feel free to adjust iframe dimensions, CSP headers, or pull in external libraries before publishing.

Because every transformation happens at *build time*, you keep coding entirely in GML with no extra runtime dependencies or performance overhead.

## FEATURES 

* **Process On Run**: Build, package and playtest your game on every run (can be disabled).

* **Create Project**: Creates the Reddit project if it doesn't exist (based on the project name).

* **Auto Playtest**: Uploads the compiled project so it can be playtested.

## DOCUMENTATION

Guides on how to set up a Reddit developer account and your own subreddit can be found in the official [Reddit Developers](https://developers.reddit.com/docs/quickstart) documentation.