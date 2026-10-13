@echo off
rem Last resort if Play-Mobile-Renderer.bat is also broken (OpenGL instead of Vulkan; paler colours).
start "" "%~dp0GeorgeAdventures.exe" --rendering-method gl_compatibility
