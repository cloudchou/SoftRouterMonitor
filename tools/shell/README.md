# shell目录

如果经常需要在命令行操作，可以通过如下命令添加一些常用函数放在shell里，这样可以在命令行使用快捷命令操作

```
source tools/shell/functions.fish #根据自己使用的终端类型选择functions.fish或者functions.sh，目前暂时不支持zsh，可以自己添加
```

目前脚本提供的常用快捷操作函数有:

1.  jgmain 快速跳转工程主目录

2.  jgroot 快速跳转到workspace所在的根目录

3.  autobuild 命令行构建

    需要输入参数, autobuild -c Debug|Release -s formal|test 

    例如 autobuild -c Debug -s formal

4.  autoclean 命令行清理