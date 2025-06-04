# GMEXT-Reddit
Repository for GameMaker's Reddit Extension

This repository was created with the intent of presenting users with the latest version available of the extension (even previous to marketplace updates) and also provide a way for the community to contribute with bug fixes and feature implementation.

This extension will work on HTML5 export.

## About the Extension

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

## Documentation

* Check [the documentation](../../wiki)

The online documentation is regularly updated to ensure it contains the most current information. For those who prefer a different format, we also offer a HTML version. This HTML is directly converted from the GitHub Wiki content, ensuring consistency, although it may follow slightly behind in updates.

We encourage users to refer primarily to the GitHub Wiki for the latest information and updates. The HTML version, included with the extension and within the demo project's data files, serves as a secondary, static reference.

Additionally, if you're contributing new features through PR (Pull Requests), we kindly ask that you also provide accompanying documentation for these features, to maintain the comprehensiveness and usefulness of our resources.
