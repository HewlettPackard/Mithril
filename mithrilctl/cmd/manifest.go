package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"k8s.io/utils/exec"
	"os"
	"strings"
)

// manifestCmd represents the manifest command
var manifestCmd = &cobra.Command{
	Use:   "manifest",
	Short: "Get manifest from a helm release",
	Long:  `Command for getting helm manifests from releases`,
	Run: func(cmd *cobra.Command, args []string) {
		spiref, _ := cmd.Flags().GetBool("spire")
		istiof, _ := cmd.Flags().GetBool("istio")
		if spiref {
			command := fmt.Sprintf("get manifest spire-server")
			cmdArgs := strings.Fields(command)
			cmd := exec.New()
			spireInstall := cmd.Command("helm", cmdArgs[0:]...)
			out, err := spireInstall.CombinedOutput()
			if err != nil {
				fmt.Printf("\nerror getting SPIRE server manifest err: %s", err)
			}
			fmt.Fprintf(os.Stderr, "%s", out)

			command = fmt.Sprintf("get manifest spire-agent")
			cmdArgs = strings.Fields(command)
			cmd = exec.New()
			spireInstall = cmd.Command("helm", cmdArgs[0:]...)
			out, err = spireInstall.CombinedOutput()
			if err != nil {
				fmt.Printf("\nerror getting SPIRE agent manifest err: %s", err)
			}
			fmt.Fprintf(os.Stderr, "%s", out)
		}
		if istiof {
			command := fmt.Sprintf("get manifest base")
			cmdArgs := strings.Fields(command)
			cmd := exec.New()
			spireInstall := cmd.Command("helm", cmdArgs[0:]...)
			out, err := spireInstall.CombinedOutput()
			if err != nil {
				fmt.Printf("\nerror getting istio base manifest err: %s", err)
			}
			fmt.Fprintf(os.Stderr, "%s", out)

			command = fmt.Sprintf("get manifest istiod -n istio-system")
			cmdArgs = strings.Fields(command)
			cmd = exec.New()
			spireInstall = cmd.Command("helm", cmdArgs[0:]...)
			out, err = spireInstall.CombinedOutput()
			if err != nil {
				fmt.Printf("\nerror getting istiod manifest err: %s", err)
			}
			fmt.Fprintf(os.Stderr, "%s", out)

			command = fmt.Sprintf("get manifest ingressgateway -n istio-system")
			cmdArgs = strings.Fields(command)
			cmd = exec.New()
			spireInstall = cmd.Command("helm", cmdArgs[0:]...)
			out, err = spireInstall.CombinedOutput()
			if err != nil {
				fmt.Printf("\nerror getting istio ingressgateway manifest err: %s", err)
			}
			fmt.Fprintf(os.Stderr, "%s", out)
		}
		//istio, _ := cmd.Flags().GetString("spire")
	},
}

func init() {
	getCmd.AddCommand(manifestCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// manifestCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	manifestCmd.Flags().BoolP("spire", "", false, "Selects spire manifests")
	manifestCmd.Flags().BoolP("istio", "", false, "Selects istio manifests")
}
