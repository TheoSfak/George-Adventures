@echo off
echo ===== George Adventures: installing tools (Godot + Git) =====
where winget >nul 2>nul
if errorlevel 1 (
  echo winget not found. Install "App Installer" from the Microsoft Store, then run this again.
  pause
  exit /b 1
)
echo.
echo [1/2] Godot Engine...
winget install --id GodotEngine.GodotEngine -e --accept-package-agreements --accept-source-agreements
echo.
echo [2/2] Git...
winget install --id Git.Git -e --accept-package-agreements --accept-source-agreements
echo.
echo Done. Close and reopen your terminal, then open project.godot with Godot and press F5.
pause
