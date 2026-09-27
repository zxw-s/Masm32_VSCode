.386
.model flat,stdcall
.stack 4096
ExitProcess proto dwExitCode:dword
includelib kernel32.lib

.code
main proc
    mov ecx, 10
L_loop:
    dec ecx
    jnz L_loop
    invoke ExitProcess,0

main endp
end main