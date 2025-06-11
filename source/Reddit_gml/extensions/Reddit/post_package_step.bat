@echo off
set Utils="%~dp0scriptUtils.bat"
set ExtensionPath="%~dp0"

:: ######################################################################################
:: Script Logic

:: Always init the script
call %Utils% scriptInit

:: Version locks
call %Utils% optionGetValue "versionStable" RUNTIME_VERSION_STABLE
call %Utils% optionGetValue "versionBeta" RUNTIME_VERSION_BETA
call %Utils% optionGetValue "versionDev" RUNTIME_VERSION_DEV
call %Utils% optionGetValue "versionLTS" RUNTIME_VERSION_LTS

:: SDK Hash
call %Utils% optionGetValue "processOnRun" PROCESS_ON_RUN
call %Utils% optionGetValue "outputPath" OUTPUT_PATH
call %Utils% optionGetValue "autoCreate" AUTO_CREATE
call %Utils% optionGetValue "autoPlaytest" AUTO_PLAYTEST
call %Utils% optionGetValue "projectName" PROJECT_NAME
call %Utils% optionGetValue "subredditName" SUBREDDIT_NAME

if "%PROCESS_ON_RUN%" == "False" (
    call %Utils% log "INFO" "Process on run is disabled, skipping process..."
    exit 0
)

if "%PROJECT_NAME%" == "" (
    call %Utils% logError "Extension option 'Project Name' is required and cannot be empty."
    exit 1
)

:: Ensure we are on the output path
pushd "%YYoutputFolder%"

:: Check if we have npm installed
call npm --version
if ERRORLEVEL 1 (
    call %Utils% logError "Failed to detect npm, please install npm in your system."
)

:: This will ensure the update of devvit (if it gets out-dated)
call npm install -g devvit
call %Utils% logInformation "Detected devvit tool init processing..."

:: Resolve the output directory
call %Utils% pathResolve "%YYprojectDir%" "%OUTPUT_PATH%" OUTPUT_DIR

:: Make sure we have a devvit project (check for 'main.tsx' to account for deleted projects)
if not exist "%OUTPUT_DIR%/%PROJECT_NAME%/src/main.tsx" (
    call %Utils% logInformation "No devvit project ('%PROJECT_NAME%') was found, in output folder: '%OUTPUT_DIR%'"
    if "%AUTO_CREATE%" == "True" (
        call %Utils% logInformation "Auto create is enabled, creating project..."
        rmdir /s /q "%OUTPUT_DIR%"
        mkdir "%OUTPUT_DIR%"
        pushd "%OUTPUT_DIR%"
        call devvit new "%PROJECT_NAME%" --template web-view-post
        call %Utils% logInformation "Successfully created devvit project."
        popd
    ) else (
        call %Utils% logError "No devvit project was found, enable auto create or create manually (ie.: devvit new "%PROJECT_NAME%" --template web-view-post)."
    )
)

:: Deleting old files
set "WEBROOT_FOLDER=%OUTPUT_DIR%\%PROJECT_NAME%\webroot"
call %Utils% log "INFO" "Deleting previous build..."
del /s /q "%WEBROOT_FOLDER%\*.*" >nul 2>&1
for /d %%a in ("%WEBROOT_FOLDER%\*") do rd /s /q "%%a" >nul 2>&1
call %Utils% log "INFO" "Previous build deleted."

:: Copy files over
call %Utils% log "INFO" "Copying new build..."
xcopy /E /I /Y "%YYoutputFolder%\*" "%WEBROOT_FOLDER%\" >nul
call %Utils% log "INFO" "New build copied."

:: Remove script tag from GameMaker html file
call %Utils% log "INFO" "Tweaking 'index.html' and '%YYprojectName%.js' files..."
pushd "%WEBROOT_FOLDER%"
set "HTML_SCRIPT_TAG=<script>window.onload = GameMaker_Init;</script>"
set "HTML_FILE=index.html"
powershell -Command "(Get-Content '%HTML_FILE%') -replace '%HTML_SCRIPT_TAG%', '' | Set-Content '%HTML_FILE%'"
popd

:: Adding GameMaker runner script to the JS file
pushd "%WEBROOT_FOLDER%/html5game"
set "ONLOAD_SCRIPT=window.onload = GameMaker_Init;"
set "JS_FILE=%YYprojectName%.js"
echo %ONLOAD_SCRIPT% >> %HTML_FILE%
popd

call %Utils% log "INFO" "Changing entry point..."
pushd "%OUTPUT_DIR%\%PROJECT_NAME%\src"
set "OLD_START_PAGE=page.html"
set "NEW_START_PAGE=index.html"
set "TSX_FILE=main.tsx"
powershell -Command "(Get-Content '%TSX_FILE%') -replace '%OLD_START_PAGE%', '%NEW_START_PAGE%' | Set-Content '%TSX_FILE%'"
call %Utils% log "INFO" "Entry point changed."
popd

:: Upload and init playtest (if enabled)
if "%AUTO_PLAYTEST%" == "True" (

    :: Validate subreddit name
    if /i not "%SUBREDDIT_NAME:~0,2%"=="r/" (
        call %Utils% logError "Extension option 'Subreddit Name' is required and must start with 'r/'."
        exit 1
    )

    call %Utils% log "INFO" "auto playtest is enabled, uploading project..."
    start /d "%OUTPUT_DIR%\%PROJECT_NAME%" /wait cmd /k "devvit upload && devvit playtest %SUBREDDIT_NAME%"
    if ERRORLEVEL 1 (
        call %Utils% logError "devvit failed to initialize playtest (unknown error)."
        exit 1
    )
    
    echo "###########################################################################"
    call %Utils% log "INFO" "Project built successfully and devvit project was create..."
    echo "Output Folder: '%OUTPUT_DIR%\%PROJECT_NAME%'"
    echo "Application is ready for playtest, refresh your subreddit page."
    echo "###########################################################################"
    exit 255

) else (
    echo "###########################################################################"
    call %Utils% log "INFO" "Project built successfully and devvit project was create..."
    echo "Output Folder: '%OUTPUT_DIR%\%PROJECT_NAME%'"
    echo "You can playtest it by going to the output folder and using the commands:"
    echo devvit upload
    echo devvit playtest ^<subreddit name^>
    echo "###########################################################################"
    exit 255
)

popd

exit %ERRORLEVEL%
