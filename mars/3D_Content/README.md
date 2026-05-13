# Rotation Puzzle Level

## Description
A 3D rotation puzzle level template built with **Godot 4**.
The player drags the mouse to rotate a model. When the model aligns to the target angle, a win effect triggers (fade to black transition to the next level).

## Requirements
- Godot 4.x (4.2 or above recommended)

## How to Use
1. Download or Clone this repository
2. Open `project.godot` with Godot 4
3. Run the main scene `main.tscn`

## How to Customize

### Set the Target Angle
Select the `PuzzleObject` node in the scene tree, then adjust in the Inspector panel:
- `Target Rotation` — the angle the player needs to rotate to (X, Y, Z)
- `Rot Threshold` — the margin of error for a successful match (degrees), default 5.0

**Tip:** Run the game, manually rotate the model to the desired position, press **F1** to record the current angle, then copy that value into `Target Rotation`.

### Change the Next Scene
Open `pivot_point.gd` and find the `_on_win()` function:
```gdscript
func _on_win():
    _start_glow_then_fade("res://scenes/next_level.tscn")  # ← change to your next scene path
```

### Parameters Reference
| Parameter | Description | Default |
|---|---|---|
| `target_rotation` | Target angle | (20, 3.2, 0) |
| `rot_threshold` | Match threshold (degrees) | 5.0 |
| `rotate_speed` | Mouse drag rotation speed | 0.5 |
| `snap_threshold` | Distance to start auto-snapping (degrees) | 15.0 |
| `snap_speed` | Auto-snap speed | 5.0 |

## Debug Shortcuts
Available in debug builds only:

| Key | Function |
|---|---|
| F1 | Save current angle as target rotation |
| F2 | Jump to target angle (test win condition) |
| F3 | Reset rotation to (0, 0, 0) |

## File Structure
| File | Description |
|---|---|
| `main.tscn` | Main scene |
| `pivot_point.gd` | Rotation control + win logic script |
| `yinghuo.fbx` | 3D model file |
| `yinghuo_openPBR_shader1_*.png` | Model textures (BaseColor / Emissive / Height / Metallic / Normal / Roughness) |
| `puzzle.png` | Reference image |

----------------------------------------------------------------------------
# 旋转解谜关卡 / Rotation Puzzle Level

## 介绍
这是一个基于 **Godot 4** 的3D旋转解谜关卡模板。
玩家通过拖拽鼠标旋转模型，当模型对齐到目标角度时触发通关效果（黑屏过渡到下一关）。

## 环境要求
- Godot 4.x（推荐 4.2 或以上）

## 使用方法
1. 下载或 Clone 这个仓库
2. 用 Godot 4 打开 `project.godot`
3. 运行主场景 `main.tscn`

## 如何自定义关卡

### 修改目标角度
在场景树中选中 `PuzzleObject` 节点，在右侧 Inspector 面板里调整：
- `Target Rotation` — 玩家需要旋转到的目标角度（X, Y, Z）
- `Rot Threshold` — 判定成功的误差范围（度），默认 5.0

**推荐做法：** 在游戏运行时手动把模型转到目标位置，然后按 **F1** 记录当前角度，再把这个角度填入 `Target Rotation`。

### 修改下一关场景
打开 `pivot_point.gd`，找到 `_on_win()` 函数：
```gdscript
func _on_win():
    _start_glow_then_fade("res://scenes/下一关.tscn")  # ← 改成你的下一关路径
```

### 可调参数一览
| 参数 | 说明 | 默认值 |
|---|---|---|
| `target_rotation` | 目标角度 | (20, 3.2, 0) |
| `rot_threshold` | 判定误差范围（度） | 5.0 |
| `rotate_speed` | 鼠标拖拽旋转速度 | 0.5 |
| `snap_threshold` | 开始自动吸附的距离（度） | 15.0 |
| `snap_speed` | 自动吸附速度 | 5.0 |

## 调试快捷键
运行时可用以下快捷键（仅 Debug 模式下有效）：

| 按键 | 功能 |
|---|---|
| F1 | 记录当前角度为目标角度 |
| F2 | 跳转到目标角度（测试通关） |
| F3 | 重置旋转到 (0, 0, 0) |

## 文件说明
| 文件 | 说明 |
|---|---|
| `main.tscn` | 主场景 |
| `pivot_point.gd` | 旋转控制 + 通关逻辑脚本 |
| `yinghuo.fbx` | 模型文件 |
| `yinghuo_openPBR_shader1_*.png` | 模型贴图（BaseColor / Emissive / Height / Metallic / Normal / Roughness） |
| `puzzle.png` | 参考图 |
