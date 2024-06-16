@echo off
setlocal enabledelayedexpansion

Rem Windows unofficial install script for the Gera programming language.
Rem Requirements:
Rem - Curl installed
Rem - JVM 17+ installed
Rem - C compiler installed
Rem - Git installed
Rem - latest release of 'geralang/gerac' has a file 'gerac.jar' compiled with Java 17

set c_red=[31m
set c_green=[32m
set c_blue=[34m
set c_reset=[0m
set c_bold=[1m

Rem Check that curl is present.
where curl >nul 2>&1 
if %errorlevel% gtr 0 (
    echo %c_red%Curl could not be found!%c_reset%
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
    echo %c_red%Java could not be found!
    echo If it is installed, try specifying its path under the 'GERA_JAVA' variable.%c_reset%
    goto :abort
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
    echo %c_red%%java_path% has version %java_version%, but needs to be Java 17 or later!
    echo If it is installed, try specifying its path under the 'GERA_JAVA' variable.%c_reset%
    goto :abort
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
if defined GERA_CC (
    set cc_path="%GERA_CC%"
)
if [%cc_path%] == [] (
    echo %c_red%No C compiler could be found!
    echo If one is installed, try specifying its path under the 'GERA_CC' variable.%c_reset%
    goto :abort
)
Rem Find a Git implementation at 'GERA_GIT' or 'git'
set git_path=
where git >nul 2>&1
if %errorlevel% equ 0 set git_path=git
where GERA_GIT >nul 2>&1
if %errorlevel% equ 0 set git_path=GERA_GIT
if [%git_path%]==[] (
    echo %c_red%Git could not be found!
    echo If it is installed, try specifying its path under the 'GERA_GIT' variable.%c_reset%
    goto :abort
)

Rem If 'Gera' already exists fail
if exist "%programfiles%\Gera" (
    echo %c_red%A previous partial or full installation of Gera has been detected!
    echo '%programfiles%\Gera' must not exist for the installation to proceed.%c_reset%
    goto :abort
)

Rem Create 'Gera'
echo %c_green%Creating directory '%programfiles%\Gera'...%c_reset%
md "%programfiles%\Gera"
cd "%programfiles%\Gera"
if %errorlevel% gtr 0 (
    echo %c_red%Unable to create directory!%c_reset%
    echo
    echo Note: Did you run as administrator?
    goto :abort
)

Rem Download latest release of 'https://github.com/geralang/gerac'
echo %c_green%Getting latest release of 'https://github.com/geralang/gerac'...%c_reset%
for /f "tokens=2" %%a in ('curl -s "https://api.github.com/repos/geralang/gerac/releases/latest" ^| findstr /l "browser_download_url"') do (
    set gerac_url=%%a
)
set gerac_url= %gerac_url:~1%
set /a url_length=
:link_loop
set last_char=!gerac_url:~%url_length%,1!
if "!last_char!" neq "" (
    set /a url_length+=1
    goto link_loop
)
set /a url_length-=2
set gerac_url=!gerac_url:~1, %url_length%!
curl --progress-bar -L %gerac_url% -o ".\gerac.jar"
if %errorlevel% equ 1 (
    echo %c_red%Unable to get the latest release!%c_reset%
    goto :abort
)

Rem Clone 'https://github.com/geralang/gerap' and its dependencies
echo %c_green%Getting 'https://github.com/geralang/gerap' and its dependencies%c_reset%
call :do_clone "https://github.com/geralang/gerap" "gerap-gh"
call :do_clone "https://github.com/geralang/std" "std-gh"
call :do_clone "https://github.com/geralang/ccoredeps" "ccoredeps-gh"
call :do_clone "https://github.com/typesafeschwalbe/gera-cjson" "gera-cjson-gh"

Rem Build 'gerap' from source
echo %c_green%Compiling 'gerap' from source...%c_reset%
set gera_files=
for /R .\gerap-gh\src %%f in (*.gera, *.gem) do (
    set gera_files=!gera_files! "%%f"
)
for /R .\std-gh\src %%f in (*.gera, *.gem) do (
    set gera_files=!gera_files! "%%f"
)
for /R .\gera-cjson-gh\src %%f in (*.gera, *.gem) do (
    set gera_files=!gera_files! "%%f"
)
%java_path% -jar "gerac.jar" ^
-m "gerap::cli::main" -t "c" -o ".\gerap-gh\gerap.c" ^
%gera_files%
if %errorlevel% neq 0 (
    echo %c_red%Unable to compile 'gerap'!%c_reset%
    goto :abort
)
set c_files=
for /R .\std-gh\src-c %%f in (*.c) do (
    set c_files=!c_files! "%%f"
)
for /R .\gera-cjson-gh\src-c %%f in (*.c) do (
    set c_files=!c_files! "%%f"
)
%cc_path% %c_files% ".\gerap-gh\gerap.c" ".\ccoredeps-gh\coredeps.c" ^
-I .\std-gh\ -I .\gera-cjson-gh\ -I .\ccoredeps-gh\ ^
-O3 -o "gerap.exe" -lDbghelp
if %errorlevel% neq 0 (
    echo %c_red%Unable to compile 'gerap'!%c_reset%
    goto :abort
)
echo %c_green%Successfully compiled 'gerap'!%c_reset%

Rem Set up environmental variables
setx /m GERAP_JAVA_PATH "%java_path%"
setx /m GERAP_GERAC_PATH "%programfiles%\Gera\gerac.jar"
setx /m GERAP_GIT_PATH "%git_path%"
setx /m GERAP_CC_PATH "%cc_path%"

Rem Done!
echo %c_green%Done!%c_reset%
echo %c_bold%Gera has successfully been installed!
echo To start using Gera, simply add '%programfiles%\Gera' to the system environment variables and run 'gerap' in a new cmd window.%c_reset%

exit /b 0
:do_clone
%git_path% clone %~1 %~2 >nul 2>&1
if %errorlevel% equ 1 (
    echo %c_red%Unable to clone %~1!
    goto :abort
)
exit /b 0

:abort
echo %c_red%Stopping installation...%c_reset%
rd /s /q "%programfiles%/Gera" > nul 2>&1
exit /b 1
