@echo off
rem Project launcher: adds portable Git if present, activates the Python 3.12 venv
if exist "%USERPROFILE%\Documents\Programs\PortableGit\cmd\git.exe" set "PATH=%USERPROFILE%\Documents\Programs\PortableGit\cmd;%PATH%"
cd /d "%~dp0"
call "%~dp0.venv\Scripts\activate.bat"