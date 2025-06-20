@echo off
REM === Flutter Web Deploy Script ===

echo.
echo =======================================
echo   🚀  Building Flutter Web with base href
echo =======================================
flutter build web --base-href="/travellio/"
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Flutter build failed!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo =======================================
echo   🔀  Switching to gh-pages branch
echo =======================================
git checkout gh-pages
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Failed to checkout gh-pages branch!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo =======================================
echo   📂  Copying build/web to gh-pages root
echo =======================================
xcopy /E /H /Y /C build\web\* .\
IF %ERRORLEVEL% NEQ 0 (
    echo ❌ Copy failed!
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo =======================================
echo   ✅  Committing & pushing to gh-pages
echo =======================================
git add .
git commit -m "Auto deploy latest build"
git push origin gh-pages --force

echo.
echo =======================================
echo   🔙  Switching back to main branch
echo =======================================
git checkout main

echo.
echo =======================================
echo   🎉  DONE! Deployed to GitHub Pages:
echo   👉  https://payalivare.github.io/travellio/
echo =======================================
pause
