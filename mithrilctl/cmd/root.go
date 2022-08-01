package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"mithril/pkg"
	"os"
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

// initConfig adds and updates Mithril helm charts
func initConfig() {
	// adds Mithril helm charts
	err := pkg.AddMithril()
	if err != nil {
		fmt.Printf(err.Error())
		os.Exit(1)
	}

	// updates Mithril helm charts
	err = pkg.UpdateMithril()
	if err != nil {
		fmt.Printf(err.Error())
		os.Exit(1)
	}
}
