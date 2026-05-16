# 图片资源说明

## 焚香动画组件（incense-burner）

路径：`miniprogram/assets/images/`

### 1. incense-burner.png（香炉图片，必须）

| 属性 | 说明 |
|------|------|
| 文件名 | `incense-burner.png` |
| 尺寸 | 建议 **300×300 px**，宽高比约 1:1 |
| 格式 | PNG（支持透明背景） |
| 内容要求 | 香炉主体居中，**顶部需留出至少 150px 空白区域**供香棒插入 |
| 设计建议 | 国风简约香炉外形（铜炉/瓷炉），可带纹理和阴影 |

> 香炉顶部留空的作用：组件会在图片上方渲染 CSS 香棒（高 360rpx），
> 香炉图片的顶部空白区域正好作为香插入香炉的视觉连接。

### 2. incense-stick.png（香棒图片，可选）

| 属性 | 说明 |
|------|------|
| 文件名 | `incense-stick.png` |
| 尺寸 | 建议 **20×200 px** |
| 格式 | PNG（透明背景） |
| 说明 | 如提供此图片，香棒将使用图片渲染；否则使用 CSS 棕色渐变渲染 |

---

## TabBar 图标（可选）

路径：`miniprogram/assets/images/`

| 文件名 | 尺寸 | 说明 |
|--------|------|------|
| `tab-task.png` | 81×81 px | 任务页普通状态 |
| `tab-task-active.png` | 81×81 px | 任务页选中状态 |
| `tab-calendar.png` | 81×81 px | 日历页普通状态 |
| `tab-calendar-active.png` | 81×81 px | 日历页选中状态 |
| `tab-stats.png` | 81×81 px | 统计页普通状态 |
| `tab-stats-active.png` | 81×81 px | 统计页选中状态 |
| `tab-setting.png` | 81×81 px | 设置页普通状态 |
| `tab-setting-active.png` | 81×81 px | 设置页选中状态 |

> 图标颜色：普通状态 `#8c7b6c`，选中状态 `#d4a373`

---

## 音频资源（可选）

路径：`miniprogram/assets/audio/`

```
audio/
├── white_noise/
│   ├── rain.mp3    （雨声）
│   ├── wave.mp3    （海浪声）
│   ├── fire.mp3    （篝火声）
│   └── guqin.mp3   （古琴声）
└── rest_bell/
    ├── guzheng.mp3 （古筝音）
    ├── bowl.mp3    （钵音）
    └── bird.mp3    （鸟鸣声）
```
