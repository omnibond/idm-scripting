@if not "%ProgramFiles(x86)%"=="" goto x86
"%ProgramFiles%\WinRAR\WinRar" u Scripting-WinDomain.zip @Scripting-WinDomain.lst
@goto end

:x86
"%ProgramFiles(x86)%\WinRAR\WinRar" u Scripting-WinDomain.zip @Scripting-WinDomain.lst

:end

