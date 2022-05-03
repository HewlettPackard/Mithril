package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/spf13/cobra"
)

// istioCmd represents the istio command
var istioCmd = &cobra.Command{
	Use:   "istio",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			cmd.Help()
			os.Exit(0)
		} else if args[0] == "" {
			cmd.Help()
			os.Exit(0)
		} else if len(args) > 1 {
			fmt.Println("error too many arguments")
			os.Exit(1)
		}
		nsArgs := strings.Fields("create namespace istio-system")
		ns := exec.Command("kubectl", nsArgs...)
		_, _ = ns.CombinedOutput()

		cfgMapArgs := strings.Fields("create configmap -n istio-system istio-ca-root-cert")
		cfg := exec.Command("kubectl", cfgMapArgs...)
		_, _ = cfg.CombinedOutput()

		command := fmt.Sprintf("install -f %s --skip-confirmation", args[0])
		cmdArgs := strings.Fields(command)
		installIstio := exec.Command("istioctl", cmdArgs[0:]...)
		stderr, _ := installIstio.StderrPipe()
		installIstio.Start()

		scanner := bufio.NewScanner(stderr)
		if scanner.Scan() {
			for scanner.Scan() {
				fmt.Println(scanner.Text())
			}
		}

		if err := scanner.Err(); err != nil {
			fmt.Println(err)
		}
	},
}

func init() {
	installCmd.AddCommand(istioCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// istioCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// istioCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
