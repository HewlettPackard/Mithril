package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"mithril/pkg/istio"
	"mithril/pkg/spire"
	"mithril/util"
	"os"
	"time"
)

var spinner = util.NewSpinner(os.Stderr)

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

		time.Sleep(time.Millisecond * 500)
		err := spire.DeploySpire()
		fmt.Fprint(spinner.Writer, "\r")
		successFormat := " \x1b[32m✓\x1b[0m %s\n"
		failureFormat := " \033[31mx\x1b[0m %s\n"

		if err != nil {
			fmt.Fprintf(spinner.Writer, failureFormat, "Deploying SPIRE 🗝️")
		} else {
			fmt.Fprintf(spinner.Writer, successFormat, "Deploying SPIRE 🗝️")
		}
		spinner.Stop()
		spinner.SetSuffix(fmt.Sprintf(" %s ", "Deploying Istio 🛡️"))
		go func() {
			spinner.Start()
		}()

		time.Sleep(time.Millisecond * 500)
		err = istio.DeployIstio()
		fmt.Fprint(spinner.Writer, "\r")
		if err != nil {
			fmt.Fprintf(spinner.Writer, failureFormat, "Deploying Istio 🛡️")
		} else {
			fmt.Fprintf(spinner.Writer, successFormat, "Deploying Istio 🛡️")
		}
		spinner.Stop()
		if err == nil {
			fmt.Fprintf(spinner.Writer, "\nIstio automatic injection is enabled in all namespaces!\nStart using Mithril by deploying a workload\n")
		}
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
