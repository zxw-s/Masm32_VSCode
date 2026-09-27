.386
.model flat,stdcall
.stack 4096

GetStdHandle proto dwStdHandle:dword
WriteConsoleA proto hConsoleOutput:dword, lpBuffer:ptr byte, nNumberOfCharsToWrite:dword, lpNumberOfCharsWritten:ptr dword, lpReserved:dword
ExitProcess proto dwExitCode:dword

includelib kernel32.lib

.data
msg db "Hello VSCode MASM!",0Ah
msg_len equ $ - msg
written dd ?

.code
main proc
    invoke GetStdHandle, -11
    invoke WriteConsoleA, eax, offset msg, msg_len, offset written, 0
    invoke ExitProcess,0
main endp
end main