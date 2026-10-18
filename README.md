P3reload更新后原帧数限制mod失效，游戏更新后的可执行文件仍是 UE4.27.2 的自定义构建，但 UE4SS 3.0.1 无法自动识别版本。[UE4SS.log](D:/SteamLibrary/steamapps/common/P3R/P3R/Binaries/Win64/UE4SS.log) 里反复出现 `Failed to find EngineVersion`，最终扫描超时，导致 Lua 补丁根本没有加载。

旧脚本只在加载时缓存 `Engine` 和 `KismetSystemLibrary`，之后每 500ms 改一次 `t.MaxFPS`。新版游戏会在菜单/设置切换时重新应用 `FrameRateLimit=60`，旧写法无法稳定拦截。

**在原先基础上允许用户自行修改帧数限制默认200hz**

路径：\单独帧率解锁mod\Mods\Smooth3Reload\Scripts\main.lua，第4行

![image-20261018212422631](C:\Users\Lenovo\AppData\Roaming\Typora\typora-user-images\image-20261018212422631.png)

可以自行修改帧数上限，改为0则没有上限限制（可能GPU占用较高自行考虑）

**mod放置位置**

**Xbox Game Pass版:**
**Extract into Persona 3 Reload/Content/P3R/Binaries/WinGDK/**

**Steam:**
**Extract into Persona 3 Reload/P3R/Binaries/Win64/**
