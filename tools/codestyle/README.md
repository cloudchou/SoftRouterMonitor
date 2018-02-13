# CodeStyle

为了让大家能快速理解团队成员的代码，所以我们需要保持代码风格保持统一

目前Oc代码的CodeStyle基于Google的CodeStyle

目前支持两种工具对我们提交的Oc代码进行自动格w式化:

1.  clang-format 

2.  AppCode

另外我们还需要对pbxproj文件做自动格式化，避免太多冲突，我们使用xUniq对xpbproj文件自动格式化

另外我们统一了代码文件的注释头部分， 请参考代码规范文档

## clang-format

如果使用命令行Git提交，或者用source tree提交代码，请使用这种方式, 可以在提交代码时自动格式化

使用步骤:

1.  安装clang-format 

    ```
    brew install clang-format
    ```

2.  将tools/codestyle/pre-commit下的文件拷贝到.git/hooks目录下

	```
	cp tools/codestyle/pre-commit .git/hooks/
	```

clang的配置文件是工程根目录下的.clang-format，基于google的code style

## AppCode

>AppCode自带的代码格式化工具和clang-format工具格式化同一个文件的结果不同，即使修改配置，也无法使得两种工具格式化的结果保持一致

为了使得AppCode格式化后的代码风格和Clang格式化后的代码风格保持一致，所以我们在用AppCode提交代码的时候不要勾选Reformat code, 而要勾选Run git hooks，这样提交代码时可自动调用pre-commit脚本对要提交的代码格式化。

另有一种方法可手动用快捷键快速格式化要提交的代码，需要对AppCode进行一些设置

1.  首先在Preferences为clang-format建立ExternalTools

    选择Prefernces -> External Tools -> 使用 + 新建

    Name填: clang-format    Ps:可以根据自己喜好修改名字
 
    Program填: $ProjectFileDir$/tools/codestyle/format-changed-files

    WorkingDirectory填: $ProjectFileDir$

    再勾选Open Console等设置

    最后保存

2.  现在就可以通过Tools->clang-format对要提交的代码格式化了

3.  通过Edit->Macros->Start Record Macro录制宏来快速代码格式化

    录制宏开始后，通过Tools->clang-format格式化代码，然后停止录制，

    给这个宏设置一个名字FormatPreCommitFiles

4.  通过keymap给FormatPreCommitFiles分配一个快捷键，比如command+shift+f

5.  此时就可以用快捷键command+shift+f快速对要提交的代码格式化


## pbxproj文件的自动格式化

使用xUnique对Here.xcodeproj/project.pbxproj自动格式化. 项目地址:(xUniq)[https://github.com/truebit/xUnique]

1.  安装xUnique: pip install xUnique
     
2.  将toos/codestyle/pre-commit文件 拷贝到 .git/hooks目录下






