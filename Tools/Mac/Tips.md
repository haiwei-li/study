<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 不/显示隐藏文件](#1-不显示隐藏文件)
- [2. 剪切功能实现](#2-剪切功能实现)
- [3. 重命名功能](#3-重命名功能)
- [4. keychain](#4-keychain)

<!-- /code_chunk_output -->

# 1. 不/显示隐藏文件

第一种:

在 macOS Sierra, 我们可以使用快捷键 ⌘⇧.(Command + Shift + .) 来快速(在 Finder 中)显示和隐藏隐藏文件了.

第二种:

在终端使用:

```
//显示隐藏文件
defaults write com.apple.finder AppleShowAllFiles -bool true
//不显示隐藏文件
defaults write com.apple.finder AppleShowAllFiles -bool false
```

最后需要重启 Finder:

```
重启 Finder: 窗口左上角的苹果标志-->强制退出-->Finder-->重新启动
```

# 2. 剪切功能实现

第一种: 配合 Option 键

第一步: 在你要剪切的项目上右键单击, 选择「复制」选项.

第二步: 转到你需要粘贴的目录, 右键单击, 此时按住 Option 键, 你会发现菜单中的「粘贴到此处」项变成了「移动到此处」. 单击之来移动项目.

你会发现该需要移动的项目已经从原来的目录消失.

第二种: 快捷键组合

上面的鼠标操作你有没有觉得有那么一丁点繁琐?那么来吧. 我们可以使用快捷键组合来达到相同的目的.

你只需选中目标文件, 然后使用 Command+C 复制, 然后用 Command +Option+V 将其移动到目标目录.

# 3. 重命名功能

选中文件, 然后回车, 重命名后回车确认.

就是用鼠标点击一下文件, 就是选中文件, 然后隔一秒钟之后我们再用鼠标点击你刚才选中的文件的文件名就可以对这个文件进行重命名了

# 4. keychain

"xxx wants to access key "com.apple.xxx.xxx" in your keychain"

1. Open Keychain Access.
2. Search for XcodeDeviceMonitor.
3. Drag the item to the System Keychain on left.
4. Enter admin password.