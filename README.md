### P3R帧数补丁

P3reload更新后原帧数限制mod失效，游戏更新后的可执行文件仍是 UE4.27.2 的自定义构建，但 UE4SS 3.0.1 无法自动识别版本。[UE4SS.log](D:/SteamLibrary/steamapps/common/P3R/P3R/Binaries/Win64/UE4SS.log) 里反复出现 `Failed to find EngineVersion`，最终扫描超时，导致 Lua 补丁根本没有加载。

旧脚本只在加载时缓存 `Engine` 和 `KismetSystemLibrary`，之后每 500ms 改一次 `t.MaxFPS`。新版游戏会在菜单/设置切换时重新应用 `FrameRateLimit=60`，旧写法无法稳定拦截，该模组修正了这一点

### **在原先基础上允许用户自行修改帧数限制（默认200hz）**

路径：\单独帧率解锁mod\Mods\Smooth3Reload\Scripts\main.lua，第4行：

```
4.local TARGET_FPS = 200
```

可以自行修改帧数上限，改为0则没有上限限制（可能GPU占用较高自行考虑）

### **mod放置位置**

Xbox Game Pass版:
Extract into Persona 3 Reload/Content/P3R/Binaries/WinGDK/

Steam:
Extract into Persona 3 Reload/P3R/Binaries/Win64/

原mod/方法：Smooth 3 Reload - https://gamebanana.com/mods/494137 

Better Ambient Occlusion (RTAO or GTAO) - https://www.nexusmods.com/persona3reload/mods/5

可参考b站视频https://www.bilibili.com/video/BV1Fj421D7oq/

### 说明

代码修改测试采用**deepseekv4.1-flash**，本项目仅用于个人非商业性质的学习、研究与技术测试，不代表游戏开发商或相关权利人的官方立场。如出现知识产权相关纠纷，由模组使用者自行承担相关责任。涉及原mod作者的部分，其版权及使用条件仍以相应权利人的声明和许可为准，如确有mod作者认为侵权，请联系下架。

