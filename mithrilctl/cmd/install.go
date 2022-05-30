package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"mithril/pkg/istio"
	"mithril/pkg/spire"
	"os"
)

var spinner = NewSpinner(os.Stderr)

// installCmd represents the install command
var installCmd = &cobra.Command{
	Use:   "install",
	Short: "Installs Mithril",
	Long:  `Command used to install Istio integrated with SPIRE on a Kubernetes cluster`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println(fmt.Sprintf(" %s ", "Installing Mithril ⚒️ ..."))
		spinner.SetSuffix(fmt.Sprintf(" %s ", "Deploying SPIRE 🗝️"))
		go func() {
			spinner.Start()
		}()
		spire.DeploySpire()
		fmt.Fprint(spinner.writer, "\r")
		successFormat := " \x1b[32m✓\x1b[0m %s\n"
		fmt.Fprintf(spinner.writer, successFormat, "Deploying SPIRE 🗝️")
		spinner.SetSuffix(fmt.Sprintf(" %s ", "Deploying Istio 🛡️"))
		istio.DeployIstio()
		fmt.Fprint(spinner.writer, "\r")
		successFormat = " \x1b[32m✓\x1b[0m %s\n"
		fmt.Fprintf(spinner.writer, successFormat, "Deploying Istio 🛡️")
		spinner.Stop()
	},
}

func init() {
	rootCmd.AddCommand(installCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// installCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// installCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
