@echo off
setlocal enabledelayedexpansion

Rem Windows unofficial install script for the Gera programming language.
Rem Requirements:
Rem - Curl installed
Rem - JVM 17+ installed
Rem - C compiler installed
Rem - Git installed
Rem - latest release of 'geralang/gerac' has a file 'gerac.jar' compiled with Java 17

Rem Check that curl is present.
where curl >nul 2>&1 
if %errorlevel% gtr 0 (
    echo Curl could not be found!
)

Rem Find Java at 'GERA_JAVA' or 'java'
set java_path=
where java >nul 2>&1
if %errorlevel% equ 0 (
    set java_path=java
)
where GERA_JAVA >nul 2>&1
if %errorlevel% equ 0 (
    set java_path=GERA_JAVA
)
if [%java_path%]==[] (
    echo Java could not be found!
    echo If it is installed, try specifying its path under the 'GERA_JAVA' variable.
)

Rem Ensure that Java returns a version 17 or above
for /f "delims=b tokens=2" %%i in ('java --version') do (
    set java_version=%%i
    goto end1
)
:end1
for /f "delims=+" %%i in ("%java_version:~5%") do (
    set java_version=%%i
    goto end2
)
:end2
if %java_version% lss 17 (
    echo %java_path% has version %java_version%, but needs to be Java 17 or later!
    echo If it is installed, try specifying its path under the 'GERA_JAVA' variable.
)

Rem Find a C compiler at 'GERA_CC', 'cc', 'gcc' or 'clang'
set cc_path= 
where clang >nul 2>&1
if %errorlevel% equ 0 (
    set cc_path=clang
)
where gcc >nul 2>&1
if %errorlevel% equ 0 (
    set cc_path=gcc
)
where cc >nul 2>&1
if %errorlevel% equ 0 (
    set cc_path=cc
)
where GERA_CC >nul 2>&1
if %errorlevel% equ 0 (
    set cc_path=GERA_CC
)
if [%cc_path%]==[] (
    echo No C compiler could be found!
    echo If one is installed, try specifying its path under the 'GERA_CC' variable.
)

Rem Find a Git implementation at 'GERA_GIT' or 'git'
set git_path=
where git >nul 2>&1
if %errorlevel% equ 0 set git_path=git
where GERA_GIT >nul 2>&1
if %errorlevel% equ 0 set git_path=GERA_GIT
if [%git_path%]==[] (
    echo Git could not be found!
    echo If it is installed, try specifying its path under the 'GERA_GIT' variable.
)

Rem If 'Gera' already exists fail
if exist "%programfiles%\Gera" (
    echo A previous partial or full installation of Gera has been detected!
    echo '%programfiles%\Gera' must not exist for the installation to proceed.
)

Rem Create 'Gera'
echo Creating directory '%programfiles%\Gera'
cd %programfiles%
md Gera
cd .\Gera
if %errorlevel% gtr 0 (
    echo Unable to create directory!
)

Rem Download latest release of 'https://github.com/geralang/gerac'
echo Getting latest release of 'https://github.com/geralang/gerac'
for /f "tokens=2" %%a in ('curl -s "https://api.github.com/repos/geralang/gerac/releases/latest"^| findstr "gerac.jar"^| findstr "browser_download_url"') do (
    set gerac_url=%%a
)
set gerac_url= %gerac_url:~1%
set /a url_length=1
:link_loop
set last_char=!gerac_url:~%url_length%,1!
if "!last_char!" neq "" (
    set /a url_length+=1
    goto link_loop
)
set /a url_length-=2
set gerac_url=!gerac_url:~1, %url_length%!
curl --progress-bar -L %gerac_url% -o ".\gerac.jar"

pause
