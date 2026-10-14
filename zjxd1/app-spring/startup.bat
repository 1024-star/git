@echo off
setlocal
title app-spring 一键启动

echo ========================================
echo   app-spring 一键启动脚本 (Spring Boot)
echo   后端端口: 9900
echo ========================================
echo.

cd /d "%~dp0"

if not exist "pom.xml" (
    echo [错误] 未在当前目录找到 pom.xml，请确认 startup.bat 位于 app-spring 项目根目录。
    pause
    exit /b 1
)

set "JAVA_CMD="
if defined JAVA_HOME (
    if exist "%JAVA_HOME%\bin\java.exe" set "JAVA_CMD=%JAVA_HOME%\bin\java.exe"
)
if not defined JAVA_CMD if exist "D:\tools\JDK\bin\java.exe" set "JAVA_CMD=D:\tools\JDK\bin\java.exe"
if not defined JAVA_CMD (
    where java >nul 2>nul
    if not errorlevel 1 set "JAVA_CMD=java"
)
if not defined JAVA_CMD (
    echo [错误] 未找到 Java 运行环境，请安装 JDK 并设置 JAVA_HOME。
    pause
    exit /b 1
)

rem ---- 2. 显示 Java 版本（仅提示，不做版本限制）----
set "LINE="
for /f "tokens=*" %%i in ('"%JAVA_CMD%" -version 2^>^&1') do (
    if not defined LINE set "LINE=%%i"
)
set "VER=%LINE:"=%"
echo 使用 Java: %VER%

rem 让 Maven Wrapper 使用同一个 JDK（仅当定位到具体路径时）
echo "%JAVA_CMD%" | findstr /i "\\bin\\java.exe" >nul
if not errorlevel 1 (
    set "JAVA_HOME=%JAVA_CMD:\bin\java.exe=%"
)

set "FORCE_BUILD=0"
if /i "%~1"=="rebuild" set "FORCE_BUILD=1"
if /i "%~1"=="clean" set "FORCE_BUILD=1"

set "JAR=target\app-spring-0.0.1-SNAPSHOT.jar"
set "NEED_BUILD=0"
if %FORCE_BUILD%==1 set "NEED_BUILD=1"
if not exist "%JAR%" set "NEED_BUILD=1"

if %NEED_BUILD%==1 (
    if not exist "mvnw.cmd" (
        echo [错误] 未找到 mvnw.cmd，无法构建项目。
        pause
        exit /b 1
    )
    echo.
    echo [1/2] 正在 Maven 构建（跳过测试，首次需联网下载依赖）...
    call mvnw.cmd clean package -DskipTests
    if errorlevel 1 (
        echo.
        echo [错误] 构建失败，请检查上方错误信息。
        pause
        exit /b 1
    )
) else (
    echo.
    echo [跳过构建] 已存在 %JAR%，直接启动。如需重新构建请运行: startup.bat rebuild
)

if not exist "%JAR%" (
    for /f "delims=" %%f in ('dir /b target\*.jar 2^>nul ^| findstr /v "\.original"') do set "JAR=target\%%f"
)
if not exist "%JAR%" (
    echo [错误] 未找到可启动的 jar 包，请运行: startup.bat rebuild
    pause
    exit /b 1
)

echo.
echo [提示] 启动前请确认：
echo   1^) MySQL 已启动（默认 localhost:3306）
echo   2^) 已导入 sql/zjxd_app_schema.sql 建库建表

powershell -NoProfile -Command "try { if (-not (Test-NetConnection -ComputerName 127.0.0.1 -Port 3306 -WarningAction SilentlyContinue -InformationLevel Quiet)) { exit 1 } } catch { exit 0 }" >nul 2>nul
if errorlevel 1 (
    echo [警告] 本机 3306 端口未检测到 MySQL，可能无法连接数据库。
)

echo.
echo [2/2] 正在启动应用（端口 9900）...
echo 访问地址: http://localhost:9900
echo 按 Ctrl+C 停止运行
echo.

"%JAVA_CMD%" -jar "%JAR%" --server.port=9900
set "RC=%errorlevel%"
if not "%RC%"=="0" (
    echo.
    echo [提示] 应用已停止（退出码 %RC%）。
    pause
)

endlocal
