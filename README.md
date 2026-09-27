# VSCode MASM（x86‑32位）完整配置

> VSCode本身**不带汇编器**，需要手动安装  ml.exe （MASM汇编器） + 链接器link.exe。
> 
> ⚠️ MASM(ml.exe)是微软工具，依赖**Windows SDK / Build Tools for Visual Studio**，只支持Windows。
> 
> 目标：32位MASM  `.asm` ，汇编→链接→运行，VSCode内终端直接跑，支持调试。

## 一、先安装必备工具（必须）

**安装 Build Tools for Visual Studio**

下载：Visual Studio Build Tools

安装时勾选：

- **使用C++的桌面开发**

这个会装上： `ml.exe` (32位masm)、 `ml64.exe` 、 `link.exe` 、**Windows SDK库文件** `kernel32.lib` 。

⚠️ 不要直接用普通cmd，ml、link需要环境变量，**必须使用「x86 Native Tools Command Prompt for VS 2022」终端**。普通powershell找不到ml.exe。

## 二、VSCode安装扩展

打开VSCode扩展市场安装2个插件：

1. **MASM for x86 x64**：汇编语法高亮、代码提示

2. **Code Runner**（可选，快速运行）

> 不推荐只用Code Runner，它不会加载VS的编译环境，ml会报找不到。优先用task.json任务编译。

## 三、新建项目文件夹

新建文件夹，例如 `MasmVscode` ，用VSCode打开这个文件夹。

新建文件  `hello32.asm` ，粘贴测试代码：

```asm6502
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
```

## 四、工作区 .vscode 配置

### 配置 tasks.json 编译任务（核心）

 `Ctrl+Shift+P`  → 输入  `Tasks: Configure Task`  → 创建`tasks.json`从模板 → 选择「Others」。

用下面的全部替换  `tasks.json` ：

> ⚠️修改下面路径为本机的实际路径！

```json
{
    "version": "2.0.0",
    "tasks": [
        // ========== x86 32位 MASM (ml.exe)【Ctrl+Shift+B 默认】 ==========
        {
            "label": "ml-assemble-x86",
            "type": "process",
            "command": "C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx86\\x86\\ml.exe",
            "args": [
                "/c",
                "/coff",
                "/Zi",
                "/I",
                "C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\include",
                "/I",
                "C:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.28000.0\\um",
                "${file}",
                "/Fo${fileDirname}\\${fileBasenameNoExtension}.obj"
            ],
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "echo": true
            }
        },
        {
            "label": "ml-link-x86",
            "type": "process",
            "command": "C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx86\\x86\\link.exe",
            "args": [
                "/SUBSYSTEM:CONSOLE",
                //"/ENTRY:main",
                "/DEBUG",
                "/LIBPATH:C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\lib\\x86",
                "/LIBPATH:C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\10.0.28000.0\\um\\x86",
                "user32.lib",
                "kernel32.lib",
                "${fileDirname}\\${fileBasenameNoExtension}.obj",
                "/OUT:${fileDirname}\\${fileBasenameNoExtension}.exe"
            ],
            "dependsOn": [
                "ml-assemble-x86"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "echo": true
            }
        },
        // ========== 运行任务：编译后执行 + pause ==========
        {
            "label": "masm-run-x86",
            "type": "process",
            "command": "${fileBasenameNoExtension}.exe",
            "args": [],
            "options": {
                "cwd": "${fileDirname}"
            },
            "dependsOn": [
                "ml-link-x86"
            ],
            "group": {
                "kind": "test",
                "isDefault": true
            },
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "panel": "new",
                "close": false
            },
        },
        // ========== 清理：obj / exe / pdb ==========
        {
            "label": "clean asm",
            "type": "shell",            
            "command": "del \"${fileBasenameNoExtension}.obj\" \"${fileBasenameNoExtension}.exe\" \"${fileBasenameNoExtension}.pdb\" 2>nul",
            "options": {
                "cwd": "${fileDirname}"
            },
            "problemMatcher": [],
            "presentation": {
                "reveal": "silent"
            }
        }
    ]
}
```

#### 使用

1.  `Ctrl+Shift+B`  → 选择  `ml-link-x86` ：汇编+链接生成`hello.exe`

2.  `Ctrl+Shift+P`  → `Tasks: Run Task` →  `masm-run-x86` ：编译并运行程序，`pause`防止窗口一闪而过

3.  `clean asm` ：清理obj、exe文件

简单区分记忆：

- `type:shell`：交给 vscode 内置 shell 处理，会自动加 cmd /d，`&`/`&&`这类符号容易炸
- `type:process`：直接调用程序，**参数数组原样传递**，控制权交给 cmd，适合这种命令行场景

记住关键点：

- 凡是调用 `cmd` 带 `&`/`&&` 命令，一律用 `"type":"process"`
- 修改 `tasks.json` 后，**重载任务 / 重启 VSCode**，否则会读取旧缓存
- 汇编器：VS 自带`ml.exe`，SDK 提供 win32 库，**不需要 masm32 包**（想用 invoke 宏的时候再加 masm32 的 inc）

⚠️`warning LNK4258`：**同时存在两处入口定义，link 只认其中一个，忽略另一个**

> 汇编源码里写了 `END main`（或者 `END main@0`），这个会自动给链接器指定入口符号；
> 同时在 tasks 的 link 参数又手动加了 `/ENTRY:main`，两者冲突，链接器报这个警告。
> 
> 核心规则：**不要同时在两个地方指定入口点**
> 
> 删掉 tasks 里 link 的 `/ENTRY:main`
> 
> 链接入口交给汇编文件 `END 入口标号` 来控制，不用在 link 命令行写。

**执行成功输出**

```plaintext
Microsoft (R) Macro Assembler Version 14.42.34433.0
Copyright (C) Microsoft Corporation. All rights reserved.

 Assembling: hello.asm
Microsoft (R) Incremental Linker Version 14.42.34433.0
Copyright (C) Microsoft Corporation. All rights reserved.

hello.exe
Hello VSCode MASM!
请按任意键继续 . . .
```

### 配置launch.json（F5调试，可选）

> ⚠️ 前提：
> 
> 1.需要安装插件 C/C++ Extension Pack，生成 launch.json ，使用Windows调试器调试exe，可以看寄存器、内存。
> 
> 2.需要安装第三方扩展 **Native Windows Debugging (dbgeng)**
> 
> 3.安装扩展：`svnscha.vscode-dap-dbgeng`，重启 VSCode（dbgeng 才会识别）
> 
> 4.F5调试，必须先构建生成exe；调试可查看寄存器。
> 
> VSCode调试MASM体验不如Visual Studio，适合写代码编译；调试建议还是用VS。

 `cppdbg + gdb`，是 GCC/MinGW 调试器，**不适合调试 MASM+link 编译出来的 Windows PE 程序**。
MASM + link.exe 生成的 exe，推荐用微软原生调试器：**`cppvsdbg`（VS Debugger / vsdbg）**，不需要装 MinGW、不需要 gdb。但汇编指令级调试弱于 dbgeng。

**`dbgeng`** 是 WinDbg 的底层调试引擎，这个扩展提供 `type: "dbgeng"`，底层调用系统 `dbgeng.dll`（WinDbg 引擎），专门调试原生 Windows 程序，看寄存器、单步汇编指令、反汇编视图很强，非常适合MASM 汇编调试

> **编译时一定要带 `/DEBUG`**（tasks.json link 参数里加上，生成 pdb 符号文件，否则源码断点很难正常映射）

可以使用三套配置，调试下拉框自由切换调试器。

> 建议：日常快速调试可以用 cppvsdbg；**深度汇编指令跟踪、看寄存器**就切换 dbgeng。

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "MASM-32 | cppvsdbg(微软官方vsdbg)",
            "type": "cppvsdbg",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${fileDirname}",
            "externalConsole": true
        },
        {
            "name": "MASM-32 | DbgEng(WinDbg引擎)",
            "type": "dbgeng",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${fileDirname}",
            "symbolPath": [
                "${fileDirname}",
                "SRV*C:\\symcache*https://msdl.microsoft.com/download/symbols"
            ]
        },
        {
            "name": "MASM-32 | MinGW GDB（不推荐，仅用于对比）",
            "type": "cppdbg",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${fileDirname}",
            "externalConsole": true,
            "MIMode": "gdb",
            "miDebuggerPath": "E:\\mingw64\\bin\\gdb.exe",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ]
        }
    ]
}
```

> 如果找不到符号，可以手动增加 `symbolPath`，配置微软符号服务器
> 
> 扩展是第三方项目，偶尔稳定性不如 cppvsdbg，适合**专门学汇编、想看寄存器 / 反汇编**场景。

#### 常见踩坑

1. 找不到 dbgeng.dll：核对 Windows Kits Debuggers 组件是否安装，路径是否和你电脑一致
2. F5 报找不到 exe：确认 tasks.json 里`masm-link`编译成功，有生成 exe 和 pdb
3. 看不到源码断点：编译参数必须带`/Zi`（你 tasks.json 里 ml 已经配置好了）

#### 备选方案（不装插件）

如果不想用 dap-dbgeng 插件，**不用 launch.json，直接用 WinDbg 手动打开 exe 调试**，稳定性最高。

#### 使用说明

1. 打开 `Hello64.asm`
2. `Ctrl+Shift+B` 编译，会生成：`obj` + `exe` + `pdb`
3. F5 左边下拉框，自由切换 3 种调试器
   - ✅ 日常调试：`cppvsdbg`
   - ✅ 汇编深度单步看寄存器：`DbgEng`
   - ⚠️ 仅对比测试：MinGW GDB（不推荐正式调试 MASM 程序）
4. `symbolPath` 会自动下载 Windows 系统符号，缓存到`C:\symcache`

#### 快捷键小提示

- F5：继续运行
- F11：单步进入（汇编指令单步，dbgeng 这个最好用）
- F10：单步跳过

#### 三种调试器对比：`cppvsdbg` / `dbgeng(WinDbg引擎)` / `gdb(MinGW)`

> 目标场景：**VSCode 调试 ml/ml64 + link.exe 编译出来的MASM Windows EXE**

| 项目               | cppvsdbg（微软vsdbg）               | dbgeng（svnscha扩展，WinDbg引擎）                         | gdb（MinGW-w64）                                      |
| ---------------- | ------------------------------- | -------------------------------------------------- | --------------------------------------------------- |
| 底层引擎             | vsdbg（Visual Studio调试引擎）        | dbgeng.dll（WinDbg原生引擎）                             | MinGW gdb                                           |
| 适用程序             | MSVC/MASM/link生成PE（原生Windows程序） | 原生Windows PE，和WinDbg完全同源                           | 主要用于GCC编译程序；勉强能附加Windows PE                         |
| 安装方式             | 微软C/C++扩展自带，**无需额外装软件**         | VSCode扩展`svnscha.vscode-dap-dbgeng`，系统自带dbgeng.dll | 单独下载MinGW-w64                                       |
| x64汇编调试          | ✅ 良好，可查看寄存器、源码断点                | ⭐ **最强**。指令单步、反汇编、寄存器、内存查看，WinDbg全套能力，最适合学汇编       | ⚠️ 勉强能用，对Windows x64调用约定、PE、API符号支持差，容易断点异常、寄存器显示错乱 |
| 源码断点(.pdb)       | ✅ 原生完美支持                        | ✅ 需要pdb，符号配置好即可                                    | ❌ 对微软link生成的pdb支持很差                                 |
| Windows API/系统符号 | ✅ 支持微软符号服务器                     | ✅ 原生支持微软符号服务器，WinDbg同款                             | ❌ 对Windows系统符号适配弱                                   |
| 内核调试             | ❌ 仅用户态                          | ✅ 支持内核调试（一般汇编学习用不到）                                | ❌ 用户态only                                           |
| 稳定性              | ⭐ 高，官方维护                        | 中等，第三方DAP封装，偶尔bug                                  | 中等，跨平台移植来的，Windows原生程序容易踩坑                          |
| 上手难度             | 低，界面友好，VS风格调试                   | 偏高，部分操作习惯是WinDbg风格                                 | 中等，但**不适合你的MASM项目**                                 |
| 推荐场景             | 日常快速调试、看C+汇编混合代码                | **汇编学习首选**，单步指令、观察寄存器、逆向类调试                        | GCC编译程序；**不推荐MASM+link生成的exe**                      |

#### 总结

1. **`cppvsdbg`**：省心首选，官方稳定，写汇编快速调试足够，开箱即用。
2. **`dbgeng`**：汇编深度调试首选，WinDbg引擎，指令级调试最强；代价是第三方扩展，偶尔不稳定。
3. **`MinGW gdb`**：**不适合你当前MASM+link项目**，只是GCC配套调试器，Windows原生PE适配差，没必要继续用。

#### 补充使用建议

- 平时写代码简单调试：用`cppvsdbg`，少折腾
- 需要单步汇编指令、仔细观察寄存器、内存：切换`dbgeng`
- 直接抛弃MinGW gdb这套配置，避免奇怪断点/符号报错

## 五、⚠️高频踩坑

**坑1：'ml' 不是内部或外部命令**

原因：没有执行 `VsDevCmd.bat` 加载VS编译环境。`tasks.json`里面必须调用这个bat。tasks.json 写**完整绝对路径**，不要只写 ml.exe

**坑2：LNK1561: 必须定义入口点**

link参数加上 `/entry:main` ，asm代码末尾  `end main` ，名字必须一致。

**坑3：LNK1104: 无法打开文件 kernel32.lib**

- Windows SDK没有装好，重新安装Build Tools，勾选Windows SDK。
- 检查 `/LIBPATH:D:\masm32\lib` 路径是否正确
- masm32 的 lib 文件夹要有 kernel32.lib user32.lib

**坑4：.model flat,stdcall 语法报错**

确认  `-arch=x86` ，调用的是32位ml.exe，不是ml64.exe。64位不支持 `.model` 、 `invoke` 。

**坑5： gdb 无法调试 32 位 exe**

❌不要用 64 位 gdb，必须 i686 (32 位) 版本 gdb。

**坑6：汇编报错 cannot open file windows.inc**

- `/I D:\masm32\include` 参数路径正确；检查文件夹下确实存在 windows.inc。

**坑7：externalConsole 控制台一闪而过**

程序结尾不要直接退出，可以加 `invoke Sleep,5000` 暂停，调试模式下外部控制台会停留。

**坑8：exe运行一闪而过**

运行命令加  `pause` ，上面tasks已经处理。

**坑9：中文乱码**

MASM 默认 GBK 编码。VSCode 右下角把文件编码改为 `GBK`，不要 UTF‑8，否则字符串中文乱码。

---

## 六、简化一键运行（可选 Code‑Runner 配置）

settings.json

```json
"code-runner.executorMap": {
    "asmx86": "cd $dir && del \"$fileNameWithoutExt.obj\" \"$fileNameWithoutExt.exe\" 2>nul && \"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx86\\x86\\ml.exe\" /c /coff /I \"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\include\" /I \"C:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.28000.0\\um\" \"$fileName\" /Fo\"$fileNameWithoutExt.obj\" && \"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx86\\x86\\link.exe\" /SUBSYSTEM:CONSOLE /LIBPATH:\"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\lib\\x86\" /LIBPATH:\"C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\10.0.28000.0\\um\\x86\" \"$fileNameWithoutExt.obj\" /OUT:\"$fileNameWithoutExt.exe\" && \"$fileNameWithoutExt.exe\"",
},
"code-runner.runInTerminal": true
```

### 使用说明

1. 复制粘贴到 VSCode `settings.json`
2. 打开 `.asm` 文件
   - 右键 Run Code：默认执行 **ml64 x64 汇编**
   - CodeRunner 右上角下拉切换执行器：`asmx86` / `masm32`
3. 执行逻辑：

```plaintext
删除旧obj、exe → 汇编 → 链接 → 直接运行exe
```

> ⚠️ 重要区分
> 
> - **CodeRunner（Run Code）**：编译 + 直接运行，**不带 /DEBUG，不会生成 pdb，不能 F5 调试**
> - **Ctrl+Shift+B（tasks.json）**：带 `/DEBUG`，生成 pdb，用于 F5 调试（cppvsdbg/dbgeng/gdb 三套调试器）

---

## 另一个备选方案：NASM（跨平台，Intel语法）

如果你不想装庞大的VS Build Tools，可以用NASM，体积小。但NASM**不是MASM，没有invoke宏**，API调用要手动push参数。

> 现在这套是正宗微软MASM  ml.exe ，和VS项目完全一致。

## 小练习代码

新建loop.asm测试循环：

```asm
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
```

接下来可以：

1. 写几道MASM练习题；

2. 讲stdcall手动push参数，不用invoke。

# VSCode MASM（x86‑64）完整配置

> 目标：VSCode 编写 **64位MASM汇编**，`.asm`，使用微软 `ml64.exe`（MASM64汇编器）+64位`link.exe`，生成 x64 exe，支持调试。
> ⚠️重要区别：
> 
> - 32位：`ml.exe`，`.model flat,stdcall`，寄存器 EAX/EBX，调用约定 `stdcall` / `invoke`
> - 64位：`ml64.exe`，**没有 .model flat,stdcall、没有 invoke**，寄存器 RAX/RBX，微软x64调用约定，手动压栈传参。
>   ml64 **不支持 invoke 宏**，这是新手最大坑。

## 一、获取 ml64.exe 与 64‑bit link.exe

> masm32 只有32位工具，**没有ml64**。ml64来自【Visual Studio 生成工具】

1. 下载：Visual Studio Build Tools（微软官方）
   勾选：**使用C++的桌面开发** 安装后工具路径示例（版本号会变）：

```plaintext
C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.42.34433\bin\Hostx64\x64\
├─ ml64.exe     ✅64位MASM汇编器
└─ link.exe     ✅64位链接器
```

配套头文件&库：

```plaintext
C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.42.34433\include
C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.42.34433\lib\x64
C:\Program Files (x86)\Windows Kits\10\Include\10.0.22621.0\um
C:\Program Files (x86)\Windows Kits\10\Lib\10.0.22621.0\um\x64
```

> 需要用到 Windows SDK 的 `kernel32.lib user32.lib` x64版本。

> ✅不建议把这些加到系统PATH，tasks.json写绝对路径，避免版本冲突。

## 二、VSCode插件安装

扩展商店安装：

1. **x86 and x86‑64 Assembly**：汇编语法高亮（支持64位MASM）

2. Code Runner（可选，快速运行）

3. Native Debug / C/C++ 扩展：用于调试64位程序
   
   > 调试需要 **64位 gdb**（mingw‑w64 的 x86_64‑w64‑mingw32‑gdb.exe）

## 三、工作区 .vscode 配置

新建项目文件夹，打开VSCode，新建 `.vscode`，下面两个文件：`tasks.json`、`launch.json`

### 1. tasks.json 编译+链接 ml64

> ⚠️修改下面路径为本机的实际路径！

```json
{
    "version": "2.0.0",
    "tasks": [
        // ========== x64 64位 MASM (ml64.exe)【Ctrl+Shift+B 默认】 ==========
        {
            "label": "ml64-assemble-x64",
            "type": "process",
            "command": "C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx64\\x64\\ml64.exe",
            "args": [
                "/c",
                "/Zi",
                "/I",
                "C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\include",
                "/I",
                "C:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.28000.0\\um",
                "${file}",
                "/Fo${fileDirname}\\${fileBasenameNoExtension}.obj"
            ],
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "echo": true
            }
        },
        {
            "label": "ml64-link-x64",
            "type": "process",
            "command": "C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx64\\x64\\link.exe",
            "args": [
                "/SUBSYSTEM:CONSOLE",
                "/ENTRY:main",
                "/DEBUG",
                "/LIBPATH:C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\lib\\x64",
                "/LIBPATH:C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\10.0.28000.0\\um\\x64",
                "user32.lib",
                "kernel32.lib",
                "${fileDirname}\\${fileBasenameNoExtension}.obj",
                "/OUT:${fileDirname}\\${fileBasenameNoExtension}.exe"
            ],
            "dependsOn": [
                "ml64-assemble-x64"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "echo": true
            }
        },
        // ========== 运行任务：编译后执行 + pause ==========
        {
            "label": "masm-run-x64",
            "type": "process",
            "command": "${fileBasenameNoExtension}.exe",
            "args": [],
            "options": {
                "cwd": "${fileDirname}"
            },
            "dependsOn": [
                "ml64-link-x64"
            ],
            "group": {
                "kind": "test",
                "isDefault": true
            },
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "panel": "new",
                "close": false
            },
        },
        // ========== 清理：obj / exe / pdb ==========
        {
            "label": "clean asm",
            "type": "shell",
            "command": "cmd /c del /f \"${fileBasenameNoExtension}.obj\" \"${fileBasenameNoExtension}.exe\" \"${fileBasenameNoExtension}.pdb\" \"${fileBasenameNoExtension}.ilk\" 2>nul",
            "options": {
                "cwd": "${fileDirname}"
            },
            "problemMatcher": [],
            "presentation": {
                "reveal": "always"
            }
        }
    ]
}
```

参数说明

- `/c`：只汇编，不自动链接
- `/coff`：输出COFF目标文件
- `/I`：头文件搜索目录
- `/Fo`：输出obj
- `/SUBSYSTEM:CONSOLE` 控制台；GUI程序改为 `WINDOWS`
- `/LIBPATH`：x64库路径

> 使用：`Ctrl+Shift+B` → 执行 `ml64-link-x64`，生成 x64 exe。

### 2. launch.json 调试64位exe

> F5调试，必须先构建生成exe；调试可查看 RAX RBX RIP 等64位寄存器。

同时使用三套配置，调试下拉框自由切换调试器。

> 建议：日常快速调试可以用 cppvsdbg；**深度汇编指令跟踪、看寄存器**就切换 dbgeng。

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "MASM-x64 | cppvsdbg(微软官方vsdbg)",
            "type": "cppvsdbg",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${fileDirname}",
            "externalConsole": true
        },
        {
            "name": "MASM-x64 | DbgEng(WinDbg引擎)",
            "type": "dbgeng",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${fileDirname}",
            "symbolPath": [
                "${fileDirname}",
                "SRV*C:\\symcache*https://msdl.microsoft.com/download/symbols"
            ]
        },
        {
            "name": "MASM-x64 | MinGW GDB（不推荐，仅用于对比）",
            "type": "cppdbg",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${fileDirname}",
            "externalConsole": true,
            "MIMode": "gdb",
            "miDebuggerPath": "E:\\mingw64\\bin\\gdb.exe",
            "targetArchitecture": "x64",   // 新增这一行，告诉调试器是64位，消除警告
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ]
        }
    ]
}
```

## 四、最小可运行示例 Hello64.asm（MASM x64）

> ⚠️x64 MASM **没有 .model flat,stdcall；没有 invoke**。
> Windows x64调用约定：前4个参数依次 RCX, RDX, R8, R9；剩余参数栈上；栈必须16字节对齐。

```asm
; test64.asm MASM x64 示例，弹出消息框
extrn MessageBoxA:PROC
extrn ExitProcess:PROC

.data
szText  db  'Hello MASM x64!',0
szTitle db  'x64 Demo',0

.code
main PROC
    ; MessageBoxA(hWnd, lpText, lpCaption, uType)
    ; RCX=0(NULL), RDX=文本, R8=标题, R9=MB_OK(0)
    sub rsp, 28h        ; 栈对齐 + shadow space，x64必须！
    mov rcx, 0
    lea rdx, szText
    lea r8, szTitle
    mov r9, 0
    call MessageBoxA

    mov rcx, 0
    call ExitProcess
main ENDP
END
```

> 关键点：`sub rsp,28h` shadow space，**缺少会直接崩溃**。

1. 保存 test64.asm
2. Ctrl+Shift+B → ml64‑link，生成 test64.exe
3. F5调试，断点打在main，观察 RSP、RCX、RDX寄存器。

## 五、Code‑Runner 一键运行（可选 settings.json）

```json
"code-runner.executorMap": {
    "asmx64": "cd $dir && del \"$fileNameWithoutExt.obj\" \"$fileNameWithoutExt.exe\" 2>nul && \"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx64\\x64\\ml64.exe\" /c /I \"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\include\" /I \"C:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.28000.0\\um\" \"$fileName\" /Fo\"$fileNameWithoutExt.obj\" && \"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx64\\x64\\link.exe\" /SUBSYSTEM:CONSOLE /LIBPATH:\"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\lib\\x64\" /LIBPATH:\"C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\10.0.28000.0\\um\\x64\" user32.lib kernel32.lib \"$fileNameWithoutExt.obj\" /OUT:\"$fileNameWithoutExt.exe\" && \"$fileNameWithoutExt.exe\"",
},
"code-runner.runInTerminal": true
```

## 六、常见坑汇总

1. **ml64 报错 error A2008: syntax error : .model**
   
   > ✔ml64不支持 `.model flat,stdcall`，直接删掉。

2. **error A2008: syntax error : invoke**
   
   > ✔ml64没有invoke宏，必须手动设置寄存器+call。

3. 运行exe直接崩溃，无报错
   
   > ✔大概率忘记 `sub rsp,28h` shadow space，Windows x64 ABI强制要求。

4. link LNK1104 cannot open kernel32.lib
   
   > ✔确认 `/LIBPATH` 指向 **x64版本库**，不要用32位masm32的lib。

5. ml64: cannot open include file
   
   > ✔tasks.json中 `/I` 的SDK、VC include路径核对版本号。

6. 中文乱码
   
   > MASM工具默认GBK；VSCode右下角编码改为 `GBK`，不要UTF‑8。

7. gdb无法调试64位程序
   
   > ✔使用mingw‑w64 64位gdb，不要32位gdb。

## 配套练习题

1. 修改示例，弹窗显示自定义文字。
2. 在main开头、call MessageBoxA前后下断点，观察 RSP 数值变化，理解 shadow space。
3. 删除 `sub rsp,28h`，运行程序观察崩溃现象。
4. 写代码调用 `Sleep` API，让弹窗停留几秒再退出。

# .vscode/tasks.json 32/64位 多链接器合并版

## .vscode/tasks.json（x86 /x64 / MASM32）

**三套完整任务组**：**x86(ml.exe)** + **x64(ml64.exe)** + **MASM32**，一键切换，和 code-runner 三套执行器配套。

- `tasks.json`：三套编译任务，**生成 pdb，用于 F5 调试**（launch.json 里 cppvsdbg/dbgeng/gdb）
- ~~~~`launch.json`：3 个调试器切换，调试下拉框自由切换调试器
- `settings.json` CodeRunner：三套执行器，RunCode 直接编译 + 运行（不生成 pdb，只快速跑程序）

> 小提示：
> 如果想**默认 Ctrl+Shift+B 切换为 x64 版本**，只要把 `group.isDefault:true` 移动到 `ml-link-x86` 上即可。
> 
> MASM32 自带的库很多，写传统 32 位 win32 汇编时直接用这套任务，符号 pdb 齐全，可以 F5 调试。

⚠️修改下面路径为本机的实际路径！

```json
{
    "version": "2.0.0",
    "tasks": [
        // ========== x86 32位 MASM (ml.exe)【Ctrl+Shift+B 默认】 ==========
        {
            "label": "ml-assemble-x86",
            "type": "process",
            "command": "C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx86\\x86\\ml.exe",
            "args": [
                "/c",
                "/coff",
                "/Zi",
                "/I",
                "C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\include",
                "/I",
                "C:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.28000.0\\um",
                "${file}",
                "/Fo${fileDirname}\\${fileBasenameNoExtension}.obj"
            ],
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "echo": true
            }
        },
        {
            "label": "ml-link-x86",
            "type": "process",
            "command": "C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx86\\x86\\link.exe",
            "args": [
                "/SUBSYSTEM:CONSOLE",
                //"/ENTRY:main",
                "/DEBUG",
                "/LIBPATH:C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\lib\\x86",
                "/LIBPATH:C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\10.0.28000.0\\um\\x86",
                "user32.lib",
                "kernel32.lib",
                "${fileDirname}\\${fileBasenameNoExtension}.obj",
                "/OUT:${fileDirname}\\${fileBasenameNoExtension}.exe"
            ],
            "dependsOn": [
                "ml-assemble-x86"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "echo": true
            }
        },
        // ========== x64 64位 MASM (ml64.exe) ==========
        {
            "label": "ml64-assemble-x64",
            "type": "process",
            "command": "C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx64\\x64\\ml64.exe",
            "args": [
                "/c",
                "/Zi",
                "/I",
                "C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\include",
                "/I",
                "C:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.28000.0\\um",
                "${file}",
                "/Fo${fileDirname}\\${fileBasenameNoExtension}.obj"
            ],
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "echo": true
            }
        },
        {
            "label": "ml64-link-x64",
            "type": "process",
            "command": "C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx64\\x64\\link.exe",
            "args": [
                "/SUBSYSTEM:CONSOLE",
                "/ENTRY:main",
                "/DEBUG",
                "/LIBPATH:C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\lib\\x64",
                "/LIBPATH:C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\10.0.28000.0\\um\\x64",
                "user32.lib",
                "kernel32.lib",
                "${fileDirname}\\${fileBasenameNoExtension}.obj",
                "/OUT:${fileDirname}\\${fileBasenameNoExtension}.exe"
            ],
            "dependsOn": [
                "ml64-assemble-x64"
            ],
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "echo": true
            }
        },
        // ========== MASM32 32位 ==========
        {
            "label": "masm32-assemble",
            "type": "process",
            "command": "C:\\masm32\\bin\\ml.exe",
            "args": [
                "/c",
                "/coff",
                "/Zi",
                "/I",
                "C:\\masm32\\include",
                "${file}",
                "/Fo${fileDirname}\\${fileBasenameNoExtension}.obj"
            ],
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "echo": true
            }
        },
        {
            "label": "masm32-link",
            "type": "process",
            "command": "C:\\masm32\\bin\\link.exe",
            "args": [
                "/SUBSYSTEM:CONSOLE",
                "/ENTRY:main",
                "/DEBUG",
                "/LIBPATH:C:\\masm32\\lib",
                "user32.lib",
                "kernel32.lib",
                "${fileDirname}\\${fileBasenameNoExtension}.obj",
                "/OUT:${fileDirname}\\${fileBasenameNoExtension}.exe"
            ],
            "dependsOn": [
                "masm32-assemble"
            ],
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "echo": true
            }
        },
        // ========== 运行任务：编译后执行 + pause ==========
        {
            "label": "masm-run-x86",
            "type": "process",
            "command": "${fileBasenameNoExtension}.exe",
            "args": [],
            "options": {
                "cwd": "${fileDirname}"
            },
            "dependsOn": [
                "ml-link-x86"
            ],
            "group": {
                "kind": "test",
                "isDefault": true
            },
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "panel": "new",
                "close": false
            },
        },
        {
            "label": "masm-run-x64",
            "type": "process",
            "command": "${fileBasenameNoExtension}.exe",
            "args": [],
            "options": {
                "cwd": "${fileDirname}"
            },
            "dependsOn": [
                "ml64-link-x64"
            ],
            "group": {
                "kind": "test",
                "isDefault": true
            },
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "panel": "new",
                "close": false
            },
        },
        {
            "label": "masm-run-masm32",
            "type": "process",
            "command": "${fileBasenameNoExtension}.exe",
            "args": [],
            "options": {
                "cwd": "${fileDirname}"
            },
            "dependsOn": [
                "ml-link-x86"
            ],
            "group": {
                "kind": "test",
                "isDefault": true
            },
            "problemMatcher": "$msCompile",
            "presentation": {
                "reveal": "always",
                "panel": "new",
                "close": false
            },
        },
        // ========== 清理：obj / exe / pdb ==========
        {
            "label": "clean asm",
            "type": "shell",
            "command": "cmd /c del /f \"${fileBasenameNoExtension}.obj\" \"${fileBasenameNoExtension}.exe\" \"${fileBasenameNoExtension}.pdb\" \"${fileBasenameNoExtension}.ilk\" 2>nul",
            "options": {
                "cwd": "${fileDirname}"
            },
            "problemMatcher": [],
            "presentation": {
                "reveal": "always"
            }
        }
    ]
}
```

### 使用方法

1. 默认构建 `Ctrl+Shift+B` → **ml64-link-x64（x64 汇编 + 链接，带 pdb 调试信息）**
2. 在 VSCode 任务面板可以手动选择其他任务：
   - `ml-link-x86`：编译 32 位
   - `masm-run-x64`：编译 x64 并直接运行 exe（会 pause，看输出）
   - `masm-run-x86`：编译 x86 并运行
   - `clean asm`：一键清理产物
3. `/Zi` 汇编 + `/DEBUG` 链接，生成 pdb，完美配合三套调试器（cppvsdbg/dbgeng/gdb）F5 调试

## .vscode/tasks.json（NASM 32/64位）

> Windows平台，支持 3套工具链：
> 
> 1. `gcc`（MinGW）
> 2. `ld`（MinGW ld 链接器，不经过gcc包装）
> 3. `link.exe`（微软MASM链接器，Visual Studio BuildTools的link）
> 
> 任务命名规则： `build-[x32/x64]-[gcc/ld/mslink]` 输出文件：`xxx_x32_gcc.exe` / `xxx_x64_mslink.exe` 互不覆盖

⚠️ 环境前置要求

1. `nasm.exe` 加入系统PATH
2. MinGW-w64：提供gcc、ld；32位编译需要安装32bit库
3. `link.exe`：**必须在VS开发者终端**启动VSCode，否则找不到link.exe
4. 调试器：`cppvsdbg`（微软调试器，支持寄存器窗口）

```json
{
    "version": "2.0.0",
    "tasks": [
        // ===================== X64 NASM 汇编任务 =====================
        {
            "label": "nasm-build-x64",
            "type": "shell",
            "command": "nasm",
            "args": [
                "-f",
                "win64",
                "-g",
                "${file}",
                "-o",
                "${fileDirname}\\${fileBasenameNoExtension}.obj"
            ],
            "presentation": {
                "echo": true,
                "reveal": "always",
                "panel": "shared"
            },
            "problemMatcher": {
                "owner": "nasm",
                "fileLocation": "absolute",
                "pattern": {
                    "regexp": "^(.*):(\\d+):(\\d+):\\s+(warning|error):\\s+(.*)$",
                    "file": 1,
                    "line": 2,
                    "column": 3,
                    "severity": 4,
                    "message": 5
                }
            }
        },
        {
            "label": "nasm-link-x64-gcc",
            "type": "shell",
            "command": "gcc",
            "args": [
                "${fileDirname}\\${fileBasenameNoExtension}.obj",
                "-o",
                "${fileDirname}\\${fileBasenameNoExtension}.exe",
                "-nostartfiles"
            ],
            "dependsOn": "nasm-build-x64",
            "presentation": {
                "echo": true,
                "reveal": "always"
            },
            "problemMatcher": "$gcc"
        },
        {
            "label": "nasm-link-x64-ld",
            "type": "shell",
            "command": "ld",
            "args": [
                "${fileDirname}\\${fileBasenameNoExtension}.obj",
                "-o",
                "${fileDirname}\\${fileBasenameNoExtension}.exe"
            ],
            "dependsOn": "nasm-build-x64",
            "presentation": {
                "echo": true,
                "reveal": "always"
            },
            "problemMatcher": "$gcc"
        },
        {
            "label": "nasm-link-x64-mslink",
            "type": "shell",
            "command": "link.exe",
            "args": [
                "${fileDirname}\\${fileBasenameNoExtension}.obj",
                "/OUT:${fileDirname}\\${fileBasenameNoExtension}.exe",
                "/ENTRY:main",
                "/DEBUG"
            ],
            "dependsOn": "nasm-build-x64",
            "presentation": {
                "echo": true,
                "reveal": "always"
            },
            "problemMatcher": "$msCompile"
        },
        // ===================== X32 NASM 汇编任务 =====================
        {
            "label": "nasm-build-x32",
            "type": "shell",
            "command": "nasm",
            "args": [
                "-f",
                "win32",
                "-g",
                "${file}",
                "-o",
                "${fileDirname}\\${fileBasenameNoExtension}.obj"
            ],
            "presentation": {
                "echo": true,
                "reveal": "always",
                "panel": "shared"
            },
            "problemMatcher": {
                "owner": "nasm",
                "fileLocation": "absolute",
                "pattern": {
                    "regexp": "^(.*):(\\d+):(\\d+):\\s+(warning|error):\\s+(.*)$",
                    "file": 1,
                    "line": 2,
                    "column": 3,
                    "severity": 4,
                    "message": 5
                }
            }
        },
        {
            "label": "nasm-link-x32-gcc",
            "type": "shell",
            "command": "gcc",
            "args": [
                "-m32",
                "${fileDirname}\\${fileBasenameNoExtension}.obj",
                "-o",
                "${fileDirname}\\${fileBasenameNoExtension}.exe",
                "-nostartfiles"
            ],
            "dependsOn": "nasm-build-x32",
            "presentation": {
                "echo": true,
                "reveal": "always"
            },
            "problemMatcher": "$gcc"
        },
        {
            "label": "nasm-link-x32-ld",
            "type": "shell",
            "command": "ld",
            "args": [
                "${fileDirname}\\${fileBasenameNoExtension}.obj",
                "-o",
                "${fileDirname}\\${fileBasenameNoExtension}.exe"
            ],
            "dependsOn": "nasm-build-x32",
            "presentation": {
                "echo": true,
                "reveal": "always"
            },
            "problemMatcher": "$gcc"
        },
        {
            "label": "nasm-link-x32-mslink",
            "type": "shell",
            "command": "link.exe",
            "args": [
                "${fileDirname}\\${fileBasenameNoExtension}.obj",
                "/OUT:${fileDirname}\\${fileBasenameNoExtension}.exe",
                "/ENTRY:main",
                "/DEBUG"
            ],
            "dependsOn": "nasm-build-x32",
            "presentation": {
                "echo": true,
                "reveal": "always"
            },
            "problemMatcher": "$msCompile"
        },
        // ===================== 一键编译+运行任务 =====================
        {
            "label": "build-run-x64-gcc",
            "type": "shell",
            "command": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "dependsOn": "nasm-link-x64-gcc",
            "presentation": {
                "echo": true,
                "reveal": "always"
            }
        },
        {
            "label": "build-run-x64-ld",
            "type": "shell",
            "command": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "dependsOn": "nasm-link-x64-ld",
            "presentation": {
                "echo": true,
                "reveal": "always"
            }
        },
        {
            "label": "build-run-x64-mslink",
            "type": "shell",
            "command": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "dependsOn": "nasm-link-x64-mslink",
            "presentation": {
                "echo": true,
                "reveal": "always"
            }
        },
        {
            "label": "build-run-x32-gcc",
            "type": "shell",
            "command": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "dependsOn": "nasm-link-x32-gcc",
            "presentation": {
                "echo": true,
                "reveal": "always"
            }
        },
        {
            "label": "build-run-x32-ld",
            "type": "shell",
            "command": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "dependsOn": "nasm-link-x32-ld",
            "presentation": {
                "echo": true,
                "reveal": "always"
            }
        },
        {
            "label": "build-run-x32-mslink",
            "type": "shell",
            "command": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "dependsOn": "nasm-link-x32-mslink",
            "presentation": {
                "echo": true,
                "reveal": "always"
            }
        }
    ]
}
```

### 关键说明

1. `-f win64`：生成Windows 64位obj目标文件；Linux改成`elf64`
2. `dependsOn`：任务依赖顺序：汇编 → 链接 → 运行
3. 调试用`cppvsdbg`（VS调试器），可以**直接在VSCode调试面板看到x64寄存器窗口**
4. 前提：系统PATH里能找到 `nasm.exe` 和 `gcc.exe`

### 使用方法

1. 打开`asm`程序
2. Ctrl+Shift+B，选择`nasm-build`，或者`build-and-run`一键编译运行
3. F5启动调试，左侧调试面板就可以查看rax/rbx/rsp等寄存器

### 配套 launch.json（全部6种程序调试配置）

> launch.json 放**多组调试配置**；tasks.json 放**多组编译任务**，自由切换：
> 
> - NASM + GCC（32/64）
> - NASM + ld（MinGW ld，32/64）
> - NASM + MSLINK（微软 link.exe，32/64，PDB，搭配 cppvsdbg）

> 核心规则
> 
> 1. GCC / MinGW ld → 输出 DWARF 调试信息 → **type: cppdbg (GDB)**，命令：`i r` / `info registers`
> 2. MSLINK (link.exe) → 输出 PDB 调试信息 → **type: cppvsdbg**，命令：`>r`

```json
{
    "version": "0.2.0",
    "configurations": [
        // 1. NASM x86(32) + GCC (cppdbg)
        {
            "name": "NASM x32 GCC",
            "type": "cppdbg",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${workspaceFolder}",
            "externalConsole": false,
            "preLaunchTask": "nasm-link-x32-gcc",
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ]
        },
        // 2. NASM x86 + MinGW ld (cppdbg)
        {
            "name": "NASM x32 ld",
            "type": "cppdbg",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${workspaceFolder}",
            "externalConsole": false,
            "preLaunchTask": "nasm-link-x32-ld",
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ]
        },
        // 3. NASM x86 + MSLINK (cppvsdbg，PDB)
        {
            "name": "NASM x32 MSLINK",
            "type": "cppvsdbg",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${workspaceFolder}",
            "externalConsole": false,
            "preLaunchTask": "nasm-link-x32-mslink",
            "symbolSearchPath": "${workspaceFolder}"
        },
        // 4. NASM x64 + GCC (cppdbg)
        {
            "name": "NASM x64 GCC",
            "type": "cppdbg",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${workspaceFolder}",
            "externalConsole": false,
            "preLaunchTask": "nasm-link-x64-gcc",
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ]
        },
        // 5. NASM x64 + MinGW ld (cppdbg)
        {
            "name": "NASM x64 ld",
            "type": "cppdbg",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${workspaceFolder}",
            "externalConsole": false,
            "preLaunchTask": "nasm-link-x64-ld",
            "MIMode": "gdb",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ]
        },
        // 6. NASM x64 + MSLINK (cppvsdbg，PDB)
        {
            "name": "NASM x64 MSLINK",
            "type": "cppvsdbg",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${workspaceFolder}",
            "externalConsole": false,
            "preLaunchTask": "nasm-link-x64-mslink",
            "symbolSearchPath": "${workspaceFolder}"
        }
    ]
}
```

## ✅ 三种链接器简单对比

| 链接器      | 工具来源          | 特点                          |
| -------- | ------------- | --------------------------- |
| gcc      | MinGW-w64     | 最常用，底层调用ld，自动处理入口，入门首选      |
| ld       | MinGW-w64     | 直接链接器，没有C运行时包装，底层汇编学习       |
| link.exe | VS BuildTools | 微软原生链接器，和MASM配套，Windows原生PE |

# CodeRunner settings.json 片段

```json
"code-runner.runInTerminal": true,
"code-runner.executorMap": {
    "asmx64": "cd $dir && del \"$fileNameWithoutExt.obj\" \"$fileNameWithoutExt.exe\" 2>nul && \"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx64\\x64\\ml64.exe\" /c /I \"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\include\" /I \"C:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.28000.0\\um\" \"$fileName\" /Fo\"$fileNameWithoutExt.obj\" && \"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx64\\x64\\link.exe\" /SUBSYSTEM:CONSOLE /LIBPATH:\"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\lib\\x64\" /LIBPATH:\"C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\10.0.28000.0\\um\\x64\" user32.lib kernel32.lib \"$fileNameWithoutExt.obj\" /OUT:\"$fileNameWithoutExt.exe\" && \"$fileNameWithoutExt.exe\"",
    "asmx86": "cd $dir && del \"$fileNameWithoutExt.obj\" \"$fileNameWithoutExt.exe\" 2>nul && \"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx86\\x86\\ml.exe\" /c /coff /I \"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\include\" /I \"C:\\Program Files (x86)\\Windows Kits\\10\\Include\\10.0.28000.0\\um\" \"$fileName\" /Fo\"$fileNameWithoutExt.obj\" && \"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\bin\\Hostx86\\x86\\link.exe\" /SUBSYSTEM:CONSOLE /LIBPATH:\"C:\\Program Files\\Microsoft Visual Studio\\18\\Community\\VC\\Tools\\MSVC\\14.51.36231\\lib\\x86\" /LIBPATH:\"C:\\Program Files (x86)\\Windows Kits\\10\\Lib\\10.0.28000.0\\um\\x86\" \"$fileNameWithoutExt.obj\" /OUT:\"$fileNameWithoutExt.exe\" && \"$fileNameWithoutExt.exe\"",
    "masm32": "cd $dir && del \"$fileNameWithoutExt.obj\" \"$fileNameWithoutExt.exe\" 2>nul && \"C:\\masm32\\bin\\ml.exe\" /c /coff /I \"C:\\masm32\\include\" \"$fileName\" /Fo\"$fileNameWithoutExt.obj\" && \"C:\\masm32\\bin\\link.exe\" /SUBSYSTEM:CONSOLE /LIBPATH:\"C:\\masm32\\lib\" \"$fileNameWithoutExt.obj\" /OUT:\"$fileNameWithoutExt.exe\" && \"$fileNameWithoutExt.exe\""
}
```

### 用【自定义运行命令】来执行 x64/x86/masm32

配置不变，不用改 settings，想跑 x86 汇编时：

1. 按 `Ctrl+Shift+P`
2. 输入 `Run Code: Run Custom Command`
3. 输入：`asmx86` 回车，就会执行 x86 那套脚本
   同理输入 `masm32` 跑 masm32。

> 缺点：不能点右上角 Run Code 一键切换；点 Run Code 永远跑预设的那个。

## 两套环境区分

- `tasks.json`：**带 /Zi + /DEBUG，生成 pdb 符号文件，用于 F5 调试（cppvsdbg/dbgeng）**，Ctrl+Shift+B 触发
- `code-runner`：**不带调试信息，快速编译 + 直接运行 exe，不能用来 F5 调试**，右键 Run Code 触发

# 从 x64 Native Tools Command Prompt for VS20XX启动 VSCode

**只要使用 MSVC（cl.exe / link.exe）编译C/C++，并且不想手动配置 INCLUDE、LIB、PATH 环境变量，就必须从这个专用终端启动 VSCode。**

## ✅ 核心原理

`x64 Native Tools Command Prompt for VS2022` 本质是一个**批处理脚本**，启动时自动设置一套**x64平台专用环境变量**：

1. `PATH`：添加 `cl.exe`、`link.exe`、`nasm.exe`（自己额外装的）所在目录
2. `INCLUDE`：头文件搜索路径（`stdio.h` 等系统头文件）
3. `LIB`：系统库路径（`kernel32.lib`、`libcmt.lib` 等链接库）

> 如果**直接双击VSCode图标打开**：
> 继承的是Windows默认环境，**没有设置 MSVC 的 INCLUDE / LIB**。
> 运行 `cl.exe` 会报错找不到头文件，链接时找不到系统库。

## 📌 必须用这个方式启动的场景

1. **使用 `cl.exe`、`link.exe` 做编译链接（当前这个C+NASM项目）** 也就是你现在的 cppvsdbg 调试项目。
   
   - 需要 `cl` 找到 `<stdio.h>`
   - 需要 `link` 找到系统 `.lib` 库
     ✅ 从 x64 工具终端启动 VSCode，环境变量自动就绪。

2. **编译64位原生Windows程序（x64）** 区分：
   
   - `x64 Native Tools`：编译 **x64（64位）** 程序（我们现在这个）
   
   - `x86 Native Tools`：编译 **x86（32位）** 程序
     
     > 不要混用：x86工具集编译出来是32位程序。

3. **在 VSCode tasks.json 里直接调用 `cl.exe` / `link.exe`（type:process）** 也就是你现在这套任务配置，进程直接调用 `cl.exe`，进程会继承VSCode的环境变量。
   
   - 从工具终端启动VSCode → VSCode继承环境 → tasks里启动的 `cl/link` 继承环境 ✔
   - 双击打开VSCode → 缺少INCLUDE/LIB → cl找不到头文件 ❌

4. **使用MSVC的各种工具：rc.exe资源编译器、mt.exe清单工具、dumpbin.exe查看PE文件** 这些工具都依赖VS预设环境变量。

## 📌 不需要从这个终端启动 VSCode 的场景

1. 使用 **MinGW-w64 gcc/g++**，不使用MSVC cl
2. 使用纯解释型语言：Python、JS等
3. 只做代码阅读，**不调用 cl.exe/link.exe** 编译
4. 已经手动把 `INCLUDE` / `LIB` / `PATH` 全部配置到系统环境变量（不推荐，容易和x86环境冲突）

## ⚠️ 常见踩坑

1. **在 x64 Native Tools 终端里面直接敲 code .** ✅ 正确：VSCode继承这套x64编译环境。

2. **先打开VSCode，再在VSCode内置终端打开x64工具环境** ❌ 对**tasks.json type:process任务无效！**
   
   > VSCode的tasks进程继承的是**VSCode主进程**的环境，不是VSCode内置终端的环境。
   > 内置终端加载了环境，**只对内置终端里手动敲命令生效，不影响tasks编译任务**！这是很多人踩的大坑。

> 重点：`tasks.json` 的 `type:process` 任务环境 = VSCode主进程的环境。
> 所以必须**启动VSCode这个程序本身之前，先加载好MSVC环境**。

## 🧪 验证环境是否正确加载（在VSCode内置终端输入）

```
cl.exe
```

如果输出版本信息，说明环境正常；提示不是内部命令，说明环境没加载成功。

## 备选方案：不想每次都从x64工具终端启动VSCode

如果嫌每次打开麻烦，可以在 tasks.json build-c/build-link 任务里，**先调用VS的环境脚本**加载环境（比较麻烦，不推荐新手），或者直接用CMake+VSCode插件自动加载环境。

## 小结

> 只要在 VSCode tasks.json 直接调用 `cl.exe` / `link.exe`（type:process）编译64位原生Windows程序，**就必须从 x64 Native Tools Command Prompt for VS2022 启动 VSCode**。内置终端加载环境对tasks任务无效。

# VSCode查看x64寄存器（Windows，GDB/MinGW64）

> 重点：**微软官方C/C++插件(cppdbg)本身没有独立的寄存器窗口**，两种方案：
> 
> ①调试控制台输入GDB命令查看寄存器（最简单，无需额外插件）；
> 
> ②安装插件调出图形化寄存器面板（推荐汇编/x64底层调试）

## 前置条件

1. 安装扩展：`C/C++`（微软官方）
2. 安装：MinGW-w64，带gdb（x64），配置环境变量
3. `.vscode/launch.json` 调试适配器类型为 `cppdbg`，程序编译必须带 `-g` 调试信息

```bash
gcc -g test.c -o test.exe
```

4. 程序**断点暂停**后才能查看寄存器（运行状态下无法读取）

## 方案1：Debug控制台输入GDB命令（LLDB，无需插件，首选）

1. F5启动调试，触发断点，程序暂停
2. 底部切换到 **调试控制台(Debug Console)**
3. 输入gdb命令（前面加 `-` 告诉VSCode这是gdb原生命令）

```bash
# 查看全部x64通用寄存器 rax rbx rcx rdx rsi rdi rbp rsp rip ...
-registers

# 只看单个寄存器
-registers rax
-registers rip
-registers rsp
```

> 简写（GDB原生）

```bash
info registers
info registers rax
```

`info registers` 输出所有x64寄存器、标志位eflags，十六进制+十进制。

## 方案2：插件图形化寄存器窗口（推荐，独立面板）

推荐插件：**StackScope**，专门提供独立寄存器视图、内存窗口、反汇编，支持x64，适配cppdbg+GDB

1. `Ctrl+Shift+X` 扩展商店搜索 `StackScope` 安装
2. F5调试，命中断点暂停
3. `Ctrl+Shift+P` 打开命令面板，输入：`StackScope: Focus Registers View`
4. 左侧多出独立寄存器面板，自动列出所有x64寄存器：`rax,rbx,rcx,rdx,rsi,rdi,rsp,rbp,rip,r8~r15,eflags`，支持直接修改寄存器值

其他备选插件：

- GDB UI：自带寄存器+反汇编视图，gdb/lldb通用
- vGDB：GDB增强插件，寄存器查看，Linux兼容性更好，Windows稳定性一般

## 方案3：反汇编窗口配合寄存器（原生C/C++插件自带）

1. 断点暂停
2. 命令面板输入 `C/C++: Open Disassembly View`，打开反汇编窗口
3. 反汇编视图可以看到 `rip` 指向的指令，配合Debug控制台`info registers`查看寄存器状态

## ✅ launch.json 最小模板（MinGW64 gdb）

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Debug x64",
            "type": "cppdbg",
            "request": "launch",
            "program": "${workspaceFolder}/test.exe",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${workspaceFolder}",
            "environment": [],
            "externalConsole": false,
            "MIMode": "gdb",
            "miDebuggerPath": "gdb.exe",
            "setupCommands": [
                {
                    "description": "启用gdb美化输出",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ]
        }
    ]
}
```

## 常见坑

1. 优先使用顶部菜单【调试 → 调试窗口 → 寄存器】，面板查看寄存器最稳，不会报错
2. 右键源码 → 打开反汇编，可以同时看汇编源码 + 机器指令
3. ❌ 程序没暂停：必须断点命中才能读寄存器，运行中无效，不要在程序运行状态输入寄存器表达式，会报错。**必须断住**
4. ❌ 编译没加 `-g`：缺少调试信息，gdb无法读取寄存器
5. ❌ 用MinGW32的gdb：只能看到32位寄存器，**必须MinGW-w64**
6. ❌ 调试控制台不加 `-`：不加 `-` VSCode会当成表达式，不是gdb命令

## x64寄存器速记（调试时重点看）

- `rip`：指令指针（当前执行地址）
- `rsp`：栈指针
- `rbp`：栈基址
- `rax`：函数返回值
- `rcx,rdx,r8,r9`：Windows x64调用前4个参数

# 配套 GUI 快捷键（不用敲命令）

- F5：继续运行到下一个断点
- F10：Step Over 单步跳过（不进入子函数）
- F11：Step Into 单步进入（跳进汇编函数）
- Shift+F11：Step Out 跳出当前函数
- Shift+F5：停止调试

# cppvsdbg（VSCode微软调试器）调试表达式

> ⚠️ 硬性前提：**程序必须停在断点（黄色箭头）**，否则所有寄存器表达式都会报 `Evaluation in global scope not supported.` 输入位置：VSCode 的 **调试控制台（Debug Console）**

## 一、查看寄存器（最常用）

```
@rax
@rcx
@rdx
@rsp
@rbp
@rip
@eflags
```

单独查看标志位：

```
@eflags & 0x0001   // CF 进位标志
@eflags & 0x0040   // ZF 零标志
@eflags & 0x0080   // SF 符号标志
@eflags & 0x0800   // OF 溢出标志
```

## 二、查看栈内存（Windows x64，栈向下增长）

```
*(unsigned long long*)@rsp         // 栈顶8字节
*(unsigned long long*)(@rsp + 8)   // rsp+8
*(unsigned long long*)(@rsp + 16)
*(unsigned long long*)(@rsp + 24)
*(unsigned long long*)(@rsp + 32)  // shadow space 影子空间
```

## 三、查看C变量

```
res
&res
```

## 四、函数与地址

```
asm_add                // 获取汇编函数 asm_add 的起始地址
&asm_add
```

## 五、Watch监视面板（推荐，一次性添加，断点自动刷新）

复制下面全部，粘贴到Watch窗口，不用每次手动输入：

```
@rip
@rax
@rcx
@rdx
@rsp
@rbp
@eflags
@eflags & 0x0001
@eflags & 0x0040
*(unsigned long long*)@rsp
```

# MASM x64汇编 + C 混合代码（Windows + cppdbg，适配VSCode调试查看寄存器）

> MASM64（ml64.exe）语法，Windows x64调用约定：前4参数 RCX, RDX, R8, R9；返回值 RAX
> 文件：`main.c` + `asm_func.asm`（MASM）

## 1. main.c

```c
#include <stdio.h>

// 声明外部汇编函数
extern long long asm_add(long long a, long long b);

int main(void)
{
    long long res = 0;
    // ✅ F9在这里打断点，F11可以步入汇编函数
    res = asm_add(100, 200);
    printf("asm_add(100,200) = %lld\n", res);
    return 0;
}
```

## 2. asm_func.asm（MASM x64）

```asm
; asm_func.asm MASM64
.CODE
asm_add PROC
    push rbp
    mov  rbp, rsp

    mov  rax, rcx   ; 第一个参数 a → rax
    add  rax, rdx   ; rax = a + b

    pop  rbp
    ret
asm_add ENDP
END
```

## 3. 编译命令（需要 ml64.exe，VS生成工具自带）

> 打开 **x64 Native Tools Command Prompt for VS**（不能用普通cmd，否则找不到ml64）

```bash
; 汇编：asm_func.asm → asm_func.obj
ml64 asm_func.asm /c /Zi

; 链接C文件 + obj，带调试信息
cl /utf-8 /Zi main.c asm_func.obj
```

- `/Zi`：生成完整调试符号，GDB/VSCode调试器才能查看寄存器、断点
- `/c`：只汇编，不链接
- `/utf-8`：告诉 MSVC：**源代码文件使用 UTF-8 编码**，直接消除 C4819 警告。

> 输出文件：`main.exe`

## 4. .VSCode launch.json 配置（用cppdbg调试，查看x64寄存器）

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "MASM-x64 | cppvsdbg(微软官方vsdbg)",
            "type": "cppvsdbg",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": true,
            "cwd": "${fileDirname}",
            "externalConsole": true
        }
    ]
}
```

## 5. VSCode调试操作，观察寄存器

1. 在 `res = asm_add(100,200);` 打断点 F9
2. F5启动调试，命中断点
3. F11 单步进入汇编函数 `asm_add`
4. 底部【调试控制台】输入cppvsdbg命令查看寄存器

```bash
>r
```

✅ 预期现象：

- `rcx = 100`（第一个参数）
- `rdx = 200`（第二个参数）
- 执行 `mov rax, rcx` → rax = 100
- 执行 `add rax, rdx` → rax = 300（返回值）
- `push rbp` 执行后，`rsp` 栈指针**减小8字节**（x64栈宽度8字节）

## ⚠️ MASM x64 重要注意点

1. ml64 **不支持 .MODEL 伪指令**（32位MASM才有，x64直接写 .CODE）
2. Windows x64 调用约定：**栈必须16字节对齐**，本例简单演示暂时忽略对齐
3. 必须使用 **ml64.exe**，不是ml.exe（ml是32位MASM）
4. 编译工具：安装Visual Studio时勾选「使用C++的桌面开发」，自带ml64

## 进阶练习版本（栈操作，观察rsp变化）

如果想练习 push/pop，可以写一个MASM x64示例，专门观察 `rsp` 寄存器变化。

# NASM x64汇编 + C混合测试代码（Windows + cppvsdbg）

> 用途：打断点，在VSCode调试时观察 `rax/rsp/rip` 等x64寄存器变化
> 文件：`main.c` 和 `asm_func.asm`

## 1. main.c

```c
#include <stdio.h>

// 声明外部汇编函数
extern long long asm_add(long long a, long long b);

int main(void)
{
    long long res = 0;
    // 建议在此行下断点 F9
    res = asm_add(100, 200);
    printf("asm_add(100,200) = %lld\n", res);
    return 0;
}
```

## 2. asm_func.asm（NASM 语法，Windows x64）

```nasm
; Windows x64调用约定：前4参数 RCX, RDX, R8, R9
; 返回值存入 RAX
section .text
global asm_add

asm_add:
    push rbp
    mov rbp, rsp

    mov rax, rcx    ; 取第一个参数 a → rax
    add rax, rdx    ; rax = a + b

    pop rbp
    ret
```

## 3. .vscode/tasks.json 64位

### .vscode/tasks.json

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "clean",
            "type": "process",
            "command": "cmd.exe",
            "args": [
                "/c",
                "del /f /q *.obj *.exe *.pdb 2>nul"
            ],
            "presentation": {
                "echo": true,
                "reveal": "always",
                "panel": "shared"
            },
            "problemMatcher": []
        },
        {
            "label": "build-asm",
            "type": "process",
            "command": "nasm.exe",
            "args": [
                "-f",
                "win64",
                "-g",
                "asm_func.asm",
                "-o",
                "asm_func.obj"
            ],
            "dependsOn": [
                "clean"
            ],
            "presentation": {
                "echo": true,
                "reveal": "always",
                "panel": "shared"
            },
            "problemMatcher": {
                "owner": "nasm",
                "fileLocation": "absolute",
                "pattern": {
                    "regexp": "^(.*):(\\d+):(\\d+):\\s+(warning|error):\\s+(.*)$",
                    "file": 1,
                    "line": 2,
                    "column": 3,
                    "severity": 4,
                    "message": 5
                }
            }
        },
        {
            "label": "build-c",
            "type": "process",
            "command": "cl.exe",
            "args": [
                "/utf-8",
                "/Zi",
                "/c",
                "/Fo:main.obj",
                "main.c"
            ],
            "dependsOn": [
                "build-asm"
            ],
            "presentation": {
                "echo": true,
                "reveal": "always",
                "panel": "shared"
            },
            "problemMatcher": "$msCompile"
        },
        {
            "label": "link-all",
            "type": "process",
            "command": "link.exe",
            "args": [
                "/DEBUG",
                "main.obj",
                "asm_func.obj",
                "/OUT:main.exe"
            ],
            "dependsOn": [
                "build-c"
            ],
            "presentation": {
                "echo": true,
                "reveal": "always",
                "panel": "shared"
            },
            "problemMatcher": "$msCompile"
        }
    ]
}
```

### .vscode/tasks.json（NASM 64位，cppvsdbg）

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "C+NASM x64 cppvsdbg",
            "type": "cppvsdbg",
            "request": "launch",
            "program": "${workspaceFolder}\\main.exe",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${workspaceFolder}",
            "externalConsole": false,
            "preLaunchTask": "link-all",
            "symbolSearchPath": "${workspaceFolder}"
        }
    ]
}
```

## 4. 编译脚本（PowerShell / CMD，可选）

> 需要安装 NASM，并把 nasm.exe 加入环境变量

```bash
# 汇编 .asm 文件，输出obj目标文件
nasm -f win64 asm_func.asm -o asm_func.obj

# 链接c和obj，生成带调试信息的exe
gcc -g main.c asm_func.obj -o main.exe
```

- `-g`：生成调试符号，cppvsdbg才能读取寄存器
- `-f win64`：生成Windows x64目标文件

## 5. VSCode调试操作步骤

代码：C调用 `asm_add(100,200)`

1. 在 `main.c`：`asm_add(100,200);` 打红点断点，F5运行，命中

2. F11 进入汇编函数 `asm_add`

3. 此时：
   
   - `@rcx` = 100（第一个参数）
   
   - `@rdx` = 200（第二个参数）
     
     > Windows x64 ABI：前两个整型参数放在 RCX、RDX

4. 单步F10执行 `add rax, r8`，观察 `@rax` 和 `@eflags`（ZF/CF）

5. Shift+F11：跳出汇编函数，回到C代码

> 观察：
> 
> - `rcx = 100`，`rdx = 200`（Windows x64调用约定）
> - 步入汇编函数（F11单步进入），每执行一条汇编指令，再次执行 `>r`，看 `rax` 的变化
> - 执行完 `add rax, rdx` 后，rax = 300（返回值）

## 6. 重点观察寄存器清单

| 寄存器 | 作用     | 预期值    |
| --- | ------ | ------ |
| rcx | 第1参数   | 100    |
| rdx | 第2参数   | 200    |
| rax | 函数返回值  | 300    |
| rsp | 栈指针    | 栈地址    |
| rbp | 栈基址    | 栈地址    |
| rip | 当前指令地址 | 汇编指令地址 |

## 7. 小练习

1. F11 单步进入 `asm_add`，看 `rip` 跳转到汇编代码
2. 单步执行 `mov rax, rcx`，观察rax变化
3. 单步执行 `add rax, rdx`，rax变为300
4. 执行 `ret`，回到C代码，`res` 被赋值

修改汇编代码做减法，制造**零标志ZF**或者**进位CF**，然后单步调试观察 `@eflags` 的变化，适合练习标志位。

## 8.常见坑

1. ❌ NASM用elf64：Linux格式，Windows链接报错，必须 `win64`
2. ❌ 编译不带 `-g`：GDB无法正常调试
3. ❌ MinGW32：只能32位，必须MinGW-w64 x64
4. ❌ 调用约定混淆：Windows x64不是寄存器传参rcx/rdx，和Linux System V（rdi,rsi）不一样！
