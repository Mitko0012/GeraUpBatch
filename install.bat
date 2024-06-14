@echo off

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

Rem Find Java at '$GERA_JAVA' or 'java'
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
    set version=%%i
    goto end1
)
:end1
for /f "delims=+" %%i in ("%version:~5%") do (
    set version=%%i
    goto end2
)
:end2
if version leq 27 (
    echo big fat nuts
)

pause
