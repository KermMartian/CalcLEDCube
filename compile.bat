@echo off
cls
echo ---------------------------------------------------------
echo               Doors CS Assembler/Compiler    
echo                       Version 2.0          
echo      Written by Christopher "Kerm Martian" Mitchell      
echo                 http://www.Cemetech.net      
echo ---------------------------------------------------------
echo ----- Assembling for the TI-83/84 Plus...
pushd ..\..\
echo #define TI83P >tasm\zztemp.asm
echo .binarymode TI8X >>tasm\zztemp.asm
set input=source\calcledcube\main.asm
set output=ledcube.8xp
set varname=LEDCUBE
call :UpCase varname
echo .variablename %varname% >>tasm\zztemp.asm
if exist %input%.asm (
	type %input%.asm >>tasm\zztemp.asm
) else (
	if exist %input%.z80 (
		type %input%.z80 >>tasm\zztemp.asm
	) else (
		if exist %input% (
			type %input% >>tasm\zztemp.asm
		) else (
			echo ----- '%input%', '%input%.asm', and '%input%.z80' not found!
			goto ERRORS
		)
	)
)
cd tasm
brass zztemp.asm ..\exec\%output% -l ..\list\%varname%.list.html
if errorlevel 1 goto ERRORS
cd..
rem cd exec
rem ..\tasm\binpac8x.py %1.bin
color 02
echo ----- %varname% for the TI-83/84 Plus Assembled and Compiled.
color 07
echo TI-83 Plus version is %output%
goto DONE
:ERRORS
color 04
echo ----- There were errors.
color 07
rem cd..
:DONE
del tasm\zztemp.asm >nul
popd
rem del %1.bin >nul
rem cd..
GOTO:EOF

:UpCase
:: Subroutine to convert a variable VALUE to all UPPER CASE.
:: The argument for this subroutine is the variable NAME.
FOR %%i IN ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF