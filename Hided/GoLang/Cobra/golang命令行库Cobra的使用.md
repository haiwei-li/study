
<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [1. 简介](#1-简介)
- [2. 组成](#2-组成)
  - [2.1. Command命令](#21-command命令)
  - [2.2. Flag标志](#22-flag标志)
- [3. 安装使用](#3-安装使用)
- [4. Cobra文件结构](#4-cobra文件结构)
  - [4.1. 基本结构](#41-基本结构)
  - [4.2. main.go](#42-maingo)
- [5. 使用Cobra生成器(Generator)](#5-使用cobra生成器generator)
  - [5.1. cobra init](#51-cobra-init)
  - [5.2. cobra add](#52-cobra-add)
  - [5.3. 配置cobra生成器](#53-配置cobra生成器)
- [6. 使用Cobra库手动构建Cobra应用](#6-使用cobra库手动构建cobra应用)
  - [6.1. 创建RootCmd文件](#61-创建rootcmd文件)
    - [6.1.1. 创建 main.go](#611-创建-maingo)
    - [6.1.2. 创建其它的命令](#612-创建其它的命令)
- [7. 处理Flags](#7-处理flags)
  - [7.1. 给命令分配一个标志](#71-给命令分配一个标志)
    - [7.1.1. 持久标志(Persistent Flags)](#711-持久标志persistent-flags)
    - [7.1.2. 本地标志(Local Flags)](#712-本地标志local-flags)
  - [7.2. Bind flag with Config(绑定Flag与Config)](#72-bind-flag-with-config绑定flag与config)
  - [7.3. 必须的标记](#73-必须的标记)
- [8. 位置和自定义参数](#8-位置和自定义参数)
  - [8.1. 位置参数(Positional Arguments)](#81-位置参数positional-arguments)
  - [8.2. 自定义参数](#82-自定义参数)
- [9. 例子](#9-例子)
- [10. help命令](#10-help命令)
  - [10.1. 例子](#101-例子)
  - [10.2. 定义自己的help](#102-定义自己的help)
- [11. 实例](#11-实例)
- [12. 自定义help和usage](#12-自定义help和usage)
- [13. 参考](#13-参考)

<!-- /code_chunk_output -->

# 1. 简介

内容来源于Cobra github介绍. 

Cobra 是一个**创建 CLI 命令行**的 **golang 库**, 比如**git**与**go工具**. 

Cobra同时也是一个程序, 用来生成个人应用框架, 从而开发以Cobra为基础的应用. Docker源码中使用了Cobra. 

Cobra提供的功能:

* 简易的子命令行模式, 如 app server,  app fetch等等
* 完全兼容posix命令行模式
* 嵌套子命令subcommand
* 支持全局, 局部, 串联flags
* 使用Cobra很容易的生成应用程序和命令, 使用cobra create appname和cobra add cmdname
* 如果命令输入错误, 将提供智能建议, 如 app srver, 将提示srver没有, 是否是app server
* 自动生成commands和flags的帮助信息
* 自动生成详细的help信息, 如app help
* 自动识别-h, --help帮助flag
* 自动生成应用程序在bash下命令自动完成功能
* 自动生成应用程序的man手册
* 命令行别名
* 零活定义help和usage信息
* 可选的紧密集成的[viper](http://github.com/spf13/viper) apps

# 2. 组成

Cobra基于三个基本概念commands,arguments和flags. 其中

- commands代表行为, 
- arguments代表数值, 
- flags代表对行为的改变. 

基本模型是

```
APPNAME VERB NOUN --ADJECTIVE
```

或

```
APPNAME COMMAND ARG --FLAG
```

比如下面的例子, **server**是**command**, port是flag:

```
# hugo server --port=1313
```

在下面的命令, 我们告诉Git克隆url地址bare, **clone**是**command**, **URL**是**args**, bare是flags

```
# git clone URL --bare
```

## 2.1. Command命令

Commands是应用程序的中心点. 应用程序支持的每个交互都将包含在命令中, 命令可以具有子命令(children commands), 其分别包含不同的行为. 

在上面的示例中, 'server'是命令. 

[更多关于cobra.Command](https://godoc.org/github.com/spf13/cobra#Command)

Commands的结构如下:

```go
type Command struct {
    Use   string  // The one-line usage message.
    Short string  // The short description shown in the 'help' output.
    Long  string  // The long message shown in the 'help <this-command>' output.
    Run   func(cmd *Command, args []string)  // Run runs the command.
}
```

前三个是不同场景下的说明, 最后一个是要执行的函数. 

**命令**代表**操作**, **参数和标志**是这些**行动的修饰符**. 

## 2.2. Flag标志

Flag是一种修改命令行为的方法. 

Flags用来改变commands的行为. 其完全支持POSIX命令行模式和Go的flag包. 这里的flag使用的是[spf13/pflag](https://github.com/spf13/pflag)包, 具体可以参考[Golang之使用Flag和Pflag](https://o-my-chenjian.com/2017/09/20/Using-Flag-And-Pflag-With-Golang/).

Cobra支持完全符合POSIX标准的标志以及[Go 标志包](https://golang.org/pkg/flag/). Cobra命令可以定义持久保存到子命令和标志的标志, 这些命令和标志仅对该命令可用. 

Go 标志包: https://golang.org/pkg/flag/ 

在上面的例子中, 'port'是flag. 

标志功能由[pflag库](https://github.com/spf13/pflag)提供, pflag库是flag标准库的一个分支, 它兼容POSIX接口. 

pflag库: https://github.com/spf13/pflag

# 3. 安装使用

使用Cobra很简单. 

首先, 使用go get安装最新版本, 这个命令会安装Cobra框架生成工具和依赖.

```
# go get -u github.com/spf13/cobra/cobra
```

golang的工作空间(对应环境变量$GOPATH)

这样就会得到一个**可执行文件**和**项目源码**

```
# echo $GOPATH
/root/go

# pwd
/root/go

# ls bin/
cobra

# ls src/github.com/spf13/cobra/
args.go                   command.go         powershell_completions.go
args_test.go              command_notwin.go  powershell_completions.md
bash_completions.go       command_test.go    powershell_completions_test.go
bash_completions.md       command_win.go     README.md
bash_completions_test.go  doc                shell_completions.go
cobra                     go.mod             zsh_completions.go
cobra.go                  go.sum             zsh_completions.md
cobra_test.go             LICENSE.txt        zsh_completions_test.go
```

将cobra可执行文件添加到系统PATH

```
# vim /root/.bash_profile
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
```

注: 也可以下载cobra的zip包, 丢到GOPATH下对应目录, 然后解决依赖, 再build

然后在你项目里引用Cobra

```go
import "github.com/spf13/cobra"
```

# 4. Cobra文件结构

## 4.1. 基本结构

通常**基于Cobra的应用程序**将遵循下面的**组织结构**, 当然你也可以遵循自己的接口: 

一般用 cobra 命令生成的项目结构如下: 

```
▾ appName/
   ▾ cmd/
       add.go
       your.go
       commands.go
       here.go
     main.go
```

## 4.2. main.go

在Cobra应用程序中, 通常**main.go**文件非常空洞. 它主要只干一件事: **初始化Cobra**. 

```go
// main.go
package main

import (
  "fmt"
  "os"

  "{pathToYourApp}/cmd"
)

func main() {
  cmd.Execute()
}
```

# 5. 使用Cobra生成器(Generator)

Cobra提供自己的程序来创建你的程序并且添加你想要的命令. 

这是最简单的方式把Cobra添加到你的程序里. 

[这里](https://github.com/spf13/cobra/blob/master/cobra/README.md)你能找到相关信息

windows系统下使用: 

go get github.com/spf13/cobra/cobra

或者在文件夹github.com/spf13/cobra/cobra下使用go install在$GOPATH/bin路径下生成cobra.exe可执行命令. 

需要将cobra添加到系统PATH中

## 5.1. cobra init

命令cobra init \[yourApp]将会创建初始化应用, 同时提供正确的文件结构. 同时, 其非常智能, 你只需给它一个绝对路径, 或者一个简单的路径. 

```
# pwd
/root/go/src
# mkdir myapp & cd myapp
# cobra init --pkg-name myapp
Your Cobra applicaton is ready at
/root/go/src/myapp
```

要么

```
cobra init --pkg-name myapp /root/go/src/myapp
```

注: Cobra生成器已经与GOPATH分离, 因此\-\-pkg\-name是必须的.

```
# ls -Ra /root/go/src/myapp
/root/go/src/myapp:
.  ..  cmd  LICENSE  main.go

/root/go/src/myapp/cmd:
.  ..  root.go
```

看一下 main.go

```go
package main

import "myapp/cmd"

func main() {
  cmd.Execute()
}
```

main调用cmd.Execute(), 查看cmd/root.go文件

```go
package cmd

import (
  "fmt"
  "os"
  "github.com/spf13/cobra"

  homedir "github.com/mitchellh/go-homedir"
  "github.com/spf13/viper"

)

var cfgFile string

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
  Use:   "myapp",
  Short: "A brief description of your application",
  Long: `A longer description that spans multiple lines and likely contains
examples and usage of using your application. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
  // Uncomment the following line if your bare application
  // has an action associated with it:
  //    Run: func(cmd *cobra.Command, args []string) { },
}

// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
  if err := rootCmd.Execute(); err != nil {
    fmt.Println(err)
    os.Exit(1)
  }
}

func init() {
  cobra.OnInitialize(initConfig)

  // Here you will define your flags and configuration settings.
  // Cobra supports persistent flags, which, if defined here,
  // will be global for your application.

  rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.myapp.yaml)")


  // Cobra also supports local flags, which will only run
  // when this action is called directly.
  rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
  if cfgFile != "" {
    // Use config file from the flag.
    viper.SetConfigFile(cfgFile)
  } else {
    // Find home directory.
    home, err := homedir.Dir()
    if err != nil {
      fmt.Println(err)
      os.Exit(1)
    }

    // Search config in home directory with name ".myapp" (without extension).
    viper.AddConfigPath(home)
    viper.SetConfigName(".myapp")
  }
  viper.AutomaticEnv() // read in environment variables that match

  // If a config file is found, read it in.
  if err := viper.ReadInConfig(); err == nil {
    fmt.Println("Using config file:", viper.ConfigFileUsed())
  }
}
```

看到 Execute() 函数中调用 RootCmd.Execute(), RootCmd 是开始将组成 Command 结构的一个实例. 

运行看看

```shell
# go run main.go
A longer description that spans multiple lines and likely contains
examples and usage of using your application. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.

subcommand is required
exit status 1
```

空的, 添加一些子命令

## 5.2. cobra add

这个命令用来创建子命令, 子命令就是像下面这样: 

* app serve
* app config
* app config create

在你项目的目录下, 运行下面这些命令: 

```
# cobra add serve
serve created at /root/go/src/myapp
# cobra add config
config created at /root/go/src/myapp
# cobra add create -p 'configCmd'
create created at /root/go/src/myapp
```

项目目录如下:

```
▾ myapp/
  ▾ cmd/
      serve.go
      config.go
      create.go
    main.go
```

再运行程序:

```
# go run main.go
A longer description that spans multiple lines and likely contains
examples and usage of using your application. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.

Usage:
  myapp [command]

Available Commands:
  config      A brief description of your command
  help        Help about any command
  serve       A brief description of your command

Flags:
      --config string   config file (default is $HOME/.myapp.yaml)
  -h, --help            help for myapp
  -t, --toggle          Help message for toggle

Use "myapp [command] --help" for more information about a command.
subcommand is required
exit status 1
```

现在有了三个子命令, 并且都可以使用, 然后**只要添加命令逻辑**就能真正使用了

## 5.3. 配置cobra生成器

https://o-my-chenjian.com/2017/09/20/Using-Cobra-With-Golang/

https://jsharkc.github.io/2017/07/17/cobra%E5%85%A5%E9%97%A8%E5%B0%8F%E6%95%99%E7%A8%8B/

# 6. 使用Cobra库手动构建Cobra应用

手动构建Cobra应用, 需要创建一个**空的main.go**文件和一个**RootCmd文件**. 

你可以选择在合适的地方添加额外的命令. 

例如创建一个Cobra应用cobraapp

## 6.1. 创建RootCmd文件

Cobra**不需要特殊的构造函数**. 简单的就可以创建你的命令. 

理想情况下你把这个放在在 **cobraapp/cmd/root.go**

```go
package cmd

import (
	"fmt"
	"os"

	//"github.com/mitchellh/go-homedir"
	"github.com/spf13/cobra"
	//"github.com/spf13/viper"
)

var RootCmd = &cobra.Command{
	Use:   "haiwei li",
	Aliases: []string{"lhw", "lihaiwei"},
	Short: "call me gerry",
	Long: `A Fast and Flexible Static Site Generator built with
                love by spf13 and friends in Go.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("OK")
	},
}

func Execute() {
	if err := RootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
```

**定义自己的flag**和**config配置**在**init**()函数. 

比如 **cmd/root.go**

```go
// cmd/root.go
import (
  "fmt"
  "os"

  homedir "github.com/mitchellh/go-homedir"
  "github.com/spf13/cobra"
  "github.com/spf13/viper"
)

var cfgFile string

func init() {
  cobra.OnInitialize(initConfig)
  rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.cobra.yaml)")
  rootCmd.PersistentFlags().StringVarP(&projectBase, "projectbase", "b", "", "base project directory eg. github.com/spf13/")
  rootCmd.PersistentFlags().StringP("author", "a", "YOUR NAME", "Author name for copyright attribution")
  rootCmd.PersistentFlags().StringVarP(&userLicense, "license", "l", "", "Name of license for the project (can provide `licensetext` in config)")
  rootCmd.PersistentFlags().Bool("viper", true, "Use Viper for configuration")
  viper.BindPFlag("author", rootCmd.PersistentFlags().Lookup("author"))
  viper.BindPFlag("projectbase", rootCmd.PersistentFlags().Lookup("projectbase"))
  viper.BindPFlag("useViper", rootCmd.PersistentFlags().Lookup("viper"))
  viper.SetDefault("author", "NAME HERE <EMAIL ADDRESS>")
  viper.SetDefault("license", "apache")
}

func initConfig() {
  // Don't forget to read config either from cfgFile or from home directory!
  if cfgFile != "" {
    // Use config file from the flag.
    viper.SetConfigFile(cfgFile)
  } else {
    // Find home directory.
    home, err := homedir.Dir()
    if err != nil {
      fmt.Println(err)
      os.Exit(1)
    }

    // Search config in home directory with name ".cobra" (without extension).
    viper.AddConfigPath(home)
    viper.SetConfigName(".cobra")
  }

  if err := viper.ReadInConfig(); err != nil {
    fmt.Println("Can't read config:", err)
    os.Exit(1)
  }
}
```

我的测试文件

```go
// cobraapp/cmd/root.go
package cmd

import (
	"fmt"
	"os"

	"github.com/mitchellh/go-homedir"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var RootCmd = &cobra.Command{
	Use:   "haiwei li",
	Aliases: []string{"lhw", "lihaiwei"},
	Short: "call me gerry",
	Long: `A Fast and Flexible Static Site Generator built with
                love by spf13 and friends in Go.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Printf("OK")
	},
}

var cfgFile, projectBase, userLicense string

func init() {
	cobra.OnInitialize(initConfig)

	// 在此可以定义自己的flag或者config设置, Cobra支持持久标签(persistent flag), 它对于整个应用为全局
	// 在StringVarP中需要填写`shorthand`, 详细见pflag文档
	RootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (defalut in $HOME/.cobra.yaml)")
	RootCmd.PersistentFlags().StringVarP(&projectBase, "projectbase", "b", "", "base project directory eg. github.com/spf13/")
	RootCmd.PersistentFlags().StringP("author", "a", "YOUR NAME", "Author name for copyright attribution")
	RootCmd.PersistentFlags().StringVarP(&userLicense, "license", "l", "", "Name of license for the project (can provide `licensetext` in config)")
	RootCmd.PersistentFlags().Bool("viper", true, "Use Viper for configuration")

	// Cobra同样支持局部标签(local flag), 并只在直接调用它时运行
	RootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")

	// 使用viper可以绑定flag
	viper.BindPFlag("author", RootCmd.PersistentFlags().Lookup("author"))
	viper.BindPFlag("projectbase", RootCmd.PersistentFlags().Lookup("projectbase"))
	viper.BindPFlag("useViper", RootCmd.PersistentFlags().Lookup("viper"))
	viper.SetDefault("author", "NAME HERE <EMAIL ADDRESS>")
	viper.SetDefault("license", "apache")
}

func Execute() {
	RootCmd.Execute()
}

func initConfig() {
	// 勿忘读取config文件, 无论是从cfgFile还是从home文件
	if cfgFile != "" {
		viper.SetConfigName(cfgFile)
	} else {
		// 找到home文件
		home, err := homedir.Dir()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		// 在home文件夹中搜索以".cobra"为名称的config
		viper.AddConfigPath(home)
		viper.SetConfigName(".cobra")
	}
	// 读取符合的环境变量
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		fmt.Println("Can not read config:", viper.ConfigFileUsed())
	}
}
```
### 6.1.1. 创建 main.go

你需要在**main函数**里执行**rootCmd**. 

通常main.go文件非常空洞. 它主要只干一件事: 初始化Cobra. 

```go
// main.go
package main

import (
  "{pathToYourApp}/cmd"
)

func main() {
  cmd.Execute()
}
```

我的文件

```go
// cobraapp/main.go
package main

import (
	"fmt"
	"os"

	"cjappmanu/cmd"
)

func main() {
	if err := cmd.RootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
```

### 6.1.2. 创建其它的命令

其它的命令通常定义在cmd/目录下的自己文件内

如果你想创建一个version命令, 你可以创建cmd/version.go文件, 并在文件里这么写:

```go
// cmd/version.go
package cmd

import (
  "fmt"

  "github.com/spf13/cobra"
)

func init() {
  rootCmd.AddCommand(versionCmd)
}

var versionCmd = &cobra.Command{
	Use: "version",
	Short: "Print the version number of Haiwei Li's",
	Long: `All software has versions. This is Haiwei Li's`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Haiwei Li Version: v1.0 -- HEAD")
	},
}
```

子命令就是像下面这样: 

* app serve
* app config
* app config create

同时, 可以将命令**添加到父项**中, 这个例子中**RootCmd便是父项**. 只需要添加: 

```
RootCmd.AddCommand(versionCmd)
```

```go
package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

func init() {
	RootCmd.AddCommand(versionCmd)
}

var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print the version number of ChenJian",
	Long:  `All software has versions. This is Hugo's`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Chen Jian Version: v1.0 -- HEAD")
	},
}
```

# 7. 处理Flags

标志提供修饰符控制动作命令如何操作

## 7.1. 给命令分配一个标志

由于flag是在不同的位置定义和使用, 我们需要定义一个变量来关联标志

```
var Verbose bool
var Source string
```

两种方式分配一个标志

### 7.1.1. 持久标志(Persistent Flags)

persistent意思是说这个flag能**任何子命令**下均可使用, 适合**全局flag**: 

'持久'表示每个在**那个命令下的命令**都将能**分配到这个标志**. 

对于**全局标志**, '持久'的标志**绑定在root**上. 

```go
rootCmd.PersistentFlags().BoolVarP(&Verbose, "verbose", "v", false, "verbose output")
```

### 7.1.2. 本地标志(Local Flags)

Cobra**默认只在目标命令上解析标志**, 父命令忽略任何局部标志. 

Cobra同样支持局部标签(local flag), 并只在直接调用它时运行

通过**打开Command.TraverseChildren**, Cobra将会在执行任意目标命令前解析标志

```go
command := cobra.Command{
  Use: "print [OPTIONS] [COMMANDS]",
  TraverseChildren: true,
}
```

```go
RootCmd.Flags().StringVarP(&Source, "source", "s", "", "Source directory to read from")
```

## 7.2. Bind flag with Config(绑定Flag与Config)

使用[viper](https://github.com/spf13/viper)可以绑定flag

```go
var author string

func init() {
  RootCmd.PersistentFlags().StringVar(&author, "author", "YOUR NAME", "Author name for copyright attribution")
  viper.BindPFlag("author", RootCmd.PersistentFlags().Lookup("author"))
}
```

在这个例子中, **永久的标记 author** 被**viper绑定**, 注意, 当用户没有给\-\-author提供值, author不会被赋值. 

## 7.3. 必须的标记

标记默认是可选的, 如果你希望当**一个标记没有设置**时, **命令行报错**, 你可以标记它为必须的

```go
rootCmd.Flags().StringVarP(&Region, "region", "r", "", "AWS region (required)")
rootCmd.MarkFlagRequired("region")
```

# 8. 位置和自定义参数

## 8.1. 位置参数(Positional Arguments)

验证位置参数可以通过 Command的Args字段. 

内置下列验证方法

* NoArgs \- 如果有任何参数, 命令行将会报错. 
* ArbitraryArgs \- 命令行将会接收任何参数.
* OnlyValidArgs \- 如果有如何参数不属于Command的ValidArgs字段, 命令行将会报错. 
* MinimumNArgs(int) \- 如果参数个数少于N个, 命令行将会报错. 
* MaximumNArgs(int) \- 如果参数个数多余N个, 命令行将会报错. 
* ExactArgs(int) \- 如果参数个数不能等于N个, 命令行将会报错. 
* RangeArgs(min, max) \- 如果参数个数不在min和max之间, 命令行将会报错.

## 8.2. 自定义参数

一个设置自定义验证的例子

```go
var cmd = &cobra.Command{
  Short: "hello",
  Args: func(cmd *cobra.Command, args []string) error {
    if len(args) < 1 {
      return errors.New("requires at least one arg")
    }
    if myapp.IsValidColor(args[0]) {
      return nil
    }
    return fmt.Errorf("invalid color specified: %s", args[0])
  },
  Run: func(cmd *cobra.Command, args []string) {
    fmt.Println("Hello, World!")
  },
}
```

# 9. 例子

定义了**3个命令**. **2个在顶级**, 一个(cmdTimes)是其中一个顶级命令的子命令. 

我们仅为**一个命令定义了标记Flag**. 

更多关于flags的文档可以在 https://github.com/spf13/pflag 找到

```go
// main.go
package main

import (
  "fmt"
  "strings"

  "github.com/spf13/cobra"
)

func main() {
  var echoTimes int

  var cmdPrint = &cobra.Command{
    Use:   "print [string to print]",
    Short: "Print anything to the screen",
    Long: `print is for printing anything back to the screen.
For many years people have printed back to the screen.`,
    Args: cobra.MinimumNArgs(1),
    Run: func(cmd *cobra.Command, args []string) {
      fmt.Println("Print: " + strings.Join(args, " "))
    },
  }

  var cmdEcho = &cobra.Command{
    Use:   "echo [string to echo]",
    Short: "Echo anything to the screen",
    Long: `echo is for echoing anything back.
Echo works a lot like print, except it has a child command.`,
    Args: cobra.MinimumNArgs(1),
    Run: func(cmd *cobra.Command, args []string) {
      fmt.Println("Print: " + strings.Join(args, " "))
    },
  }

  var cmdTimes = &cobra.Command{
    Use:   "times [string to echo]",
    Short: "Echo anything to the screen more times",
    Long: `echo things multiple times back to the user by providing
a count and a string.`,
    Args: cobra.MinimumNArgs(1),
    Run: func(cmd *cobra.Command, args []string) {
      for i := 0; i < echoTimes; i++ {
        fmt.Println("Echo: " + strings.Join(args, " "))
      }
    },
  }

  cmdTimes.Flags().IntVarP(&echoTimes, "times", "t", 1, "times to echo the input")

  var rootCmd = &cobra.Command{Use: "app"}
  rootCmd.AddCommand(cmdPrint, cmdEcho)
  cmdEcho.AddCommand(cmdTimes)
  rootCmd.Execute()
}
```

在这个例子里, 由于**没有给rootCmd提供Run**, **单独的root**是**不能运行的**, 必须要有子命令. 

```
# go build main.go

# ./main
Usage:
  app [command]

Available Commands:
  echo        Echo anything to the screen
  help        Help about any command
  print       Print anything to the screen

Flags:
  -h, --help   help for app

Use "app [command] --help" for more information about a command.

# go run main.go
Usage:
  app [command]

Available Commands:
  echo        Echo anything to the screen
  help        Help about any command
  print       Print anything to the screen

Flags:
  -h, --help   help for app

Use "app [command] --help" for more information about a command.

# ./main echo times a -t 2
Echo: a
Echo: a

# go run main.go echo times a -t 2
Echo: a
Echo: a
```

更完整大型程序的例子, 可以查看 [Hugo](http://gohugo.io/).

# 10. help命令

当你的**程序有子命令**时, Cobra 会**自动给你程序添加help命令**. 当你运行'app help', 会调用help命令. 另外, help同样支持其它输入命令. 例如, 你有一个没有任何其它配置的命令叫'create', 当你调用'app help create' Corbra 将会起作用. 

## 10.1. 例子

下面的输入是 Cobra 自动生成的. 除了命令和标志的定义, 其它不再需要. 

```
$ cobra help

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.

Usage:
  cobra [command]

Available Commands:
  add         Add a command to a Cobra Application
  help        Help about any command
  init        Initialize a Cobra Application

Flags:
  -a, --author string    author name for copyright attribution (default "YOUR NAME")
      --config string    config file (default is $HOME/.cobra.yaml)
  -h, --help             help for cobra
  -l, --license string   name of license for the project
      --viper            use Viper for configuration (default true)

Use "cobra [command] --help" for more information about a command.
```

help 就跟其它命令一样, 并没有特殊的逻辑或行为. 事实上, 你也可以提供你自己help如果你想的话. 

## 10.2. 定义自己的help

```go
cmd.SetHelpCommand(cmd *Command)
cmd.SetHelpFunc(f func(*Command, []string))
cmd.SetHelpTemplate(s string)
```

后2个也将适用于任何子命令


# 11. 实例

main.go如下

```go
package main

import (

	"cobraapp/cmd"
)

func main() {
	cmd.RootCmd.Execute()
}
```

root.go如下

```go
// cmd/root.go
package cmd

import (
	"fmt"
	"os"
	"strings"

	homedir "github.com/mitchellh/go-homedir"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var cfgFile string
var echoTimes int

var RootCmd = &cobra.Command{
	Use: "app",
}

var cmdPrint = &cobra.Command{
	Use:   "print [string to print]",
	Short: "Print anything to the screen",
	Long: `print is for printing anything back to the screen.
For many years people have printed back to the screen.`,
	Args: cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Print: " + strings.Join(args, " "))
	},
}

var cmdEcho = &cobra.Command{
	Use:   "echo [string to echo]",
	Short: "Echo anything to the screen",
	Long: `echo is for echoing anything back.
Echo works a lot like print, except it has a child command.`,
	Args: cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Print: " + strings.Join(args, " "))
	},
}

var cmdTimes = &cobra.Command{
	Use:   "times [# times] [string to echo]",
	Short: "Echo anything to the screen more times",
	Long: `echo things multiple times back to the user by providing
a count and a string.`,
	Args: cobra.MinimumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		for i := 0; i < echoTimes; i++ {
			fmt.Println("Echo: " + strings.Join(args, " "))
		}
	},
}

func init() {
	cobra.OnInitialize(initConfig)

	cmdTimes.Flags().IntVarP(&echoTimes, "times", "t", 1, "times to echo the input")

	// 两个顶层的命令, 和一个cmdEcho命令下的子命令cmdTimes
	RootCmd.AddCommand(cmdPrint, cmdEcho)
	cmdEcho.AddCommand(cmdTimes)
}

func Execute() {
	RootCmd.Execute()
}

func initConfig() {
	// 勿忘读取config文件, 无论是从cfgFile还是从home文件
	if cfgFile != "" {
		viper.SetConfigName(cfgFile)
	} else {
		// 找到home文件
		home, err := homedir.Dir()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		// 在home文件夹中搜索以".cobra"为名称的config
		viper.AddConfigPath(home)
		viper.SetConfigName(".cobra")
	}
	// 读取符合的环境变量
	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err != nil {
		fmt.Println("Can not read config:", viper.ConfigFileUsed())
	}
}
```

操作如下

```
# go run main.go
Usage:
  app [command]

Available Commands:
  echo        Echo anything to the screen
  help        Help about any command
  print       Print anything to the screen

Flags:
  -h, --help   help for app

Use "app [command] --help" for more information about a command.



# go run main.go echo -h
echo is for echoing anything back.
Echo works a lot like print, except it has a child command.

Usage:
  app echo [string to echo] [flags]
  app echo [command]

Available Commands:
  times       Echo anything to the screen more times

Flags:
  -h, --help   help for echo

Use "app echo [command] --help" for more information about a command.



# go run main.go echo times -h
echo things multiple times back to the user by providing
a count and a string.

Usage:
  app echo times [# times] [string to echo] [flags]

Flags:
  -h, --help        help for times
  -t, --times int   times to echo the input (default 1)



# go run main.go print HERE I AM
Can not read config:
Print: HERE I AM



# go run main.go echo times WOW -t 3
Can not read config:
Echo: WOW
Echo: WOW
Echo: WOW
```

# 12. 自定义help和usage

待续

https://o-my-chenjian.com/2017/09/20/Using-Cobra-With-Golang/

# 13. 参考

* github主页: https://github.com/spf13/cobra
* https://o-my-chenjian.com/2017/09/20/Using-Cobra-With-Golang/
* Cobra简介: http://time-track.cn/cobra-brief-introduction.html
* golang命令行库cobra的使用: https://www.cnblogs.com/borey/p/5715641.html?hmsr=studygolang.com&utm_medium=studygolang.com&utm_source=studygolang.com
* https://www.jianshu.com/p/7abe7cff5384
* Cobra - Golang命令行库: https://jsharkc.github.io/2017/07/17/cobra%E5%85%A5%E9%97%A8%E5%B0%8F%E6%95%99%E7%A8%8B/
* Golang之使用Cobra: https://o-my-chenjian.com/2017/09/20/Using-Cobra-With-Golang/