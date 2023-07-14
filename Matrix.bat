@echo off
title Matrix
color 0a
mode 1000
goto Greeting

:Greeting
@REM cls
@REM echo Hello Command.
@REM pause
cls
goto Matrix

:Matrix
echo %random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%%random%
PING 1.1.1.1 -n 1 -w 0.2 >NUL
goto Matrix