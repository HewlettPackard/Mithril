package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"gopkg.in/yaml.v3"
	"mithril/entity"
	"mithril/util"
	"os"
	"path/filepath"

	"github.com/spf13/viper"
)

var cfgFile string

// rootCmd represents the base command when called without any subcommands
var rootCmd = &cobra.Command{
	Use:   "mithril",
	Short: "CLI tool to simplify Mithril deployment",
	Long:  `Mithril configuration command line utility for managing SPIRE and Istio installations`,
	// Uncomment the following line if your bare application
	// has an action associated with it:
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			cmd.Help()
			os.Exit(0)
		}
	},
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
	rootCmd.CompletionOptions.DisableDefaultCmd = true
	//rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.mithril.yaml)")

	// Cobra also supports local flags, which will only run
	// when this action is called directly.
	rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	// Find home directory.
	home := util.GetHomeDir()

	_, err := os.Stat(filepath.Join(home, ".mithril", "config.yaml"))
	// If a config file is not found, initialize the config file
	if err != nil {
		err = initializeConfigFile(home)
		if err != nil {
			fmt.Println(fmt.Errorf("unable to initialize config file err: %s", err.Error()))
			os.Exit(1)
		}
	}

	// Search config in home directory with name ".mithril" (without extension).
	viper.AddConfigPath(filepath.Join(home, ".mithril"))
	viper.SetConfigName("config")
	viper.SetConfigType("yaml")

	viper.AutomaticEnv() // read in environment variables that match

	// If a config file is found, read it in.
	if err = viper.ReadInConfig(); err != nil {
		fmt.Println("error reading config file err: ", err.Error())
	}

	mithrilPath := viper.GetString("mithrilPath")

	if mithrilPath == "" {
		fmt.Println("\033[31mPath for Mithril repository is not set!\033[0m")
		fmt.Print("\n\033[34mEnter the path for your Mithril repository: \033[0m")
		fmt.Scanf("%s", &mithrilPath)
		newCfg := entity.Config{
			MithrilPath: mithrilPath,
		}
		yb, _ := yaml.Marshal(newCfg)
		err = os.WriteFile(filepath.Join(home, ".mithril", "config.yaml"), yb, 0777)
		if err != nil {
			fmt.Println("unable to set config file err: ", err.Error())
			os.Exit(1)
		}

		fmt.Println("Mithril path set in config file", filepath.Join(home, ".mithril", "config.yaml"))
		os.Exit(0)
	}
}

func initializeConfigFile(home string) error {
	_ = os.Mkdir(filepath.Join(home, ".mithril"), 0777)

	cfg := entity.Config{
		MithrilPath: "",
	}
	jb, _ := yaml.Marshal(cfg)
	err := os.WriteFile(filepath.Join(home, ".mithril", "config.yaml"), jb, 0777)
	if err != nil {
		return err
	}

	return nil
}
