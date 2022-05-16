package cmd

import (
	"bytes"
	"fmt"
	"github.com/spf13/cobra"
	"gopkg.in/yaml.v3"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// spireCmd represents the spire command
var spireCmd = &cobra.Command{
	Use:   "spire",
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
		ls := exec.Command("ls", args[0])
		stdout, _ := ls.CombinedOutput()
		if string(stdout) == "" {
			fmt.Println("err: spire files not found")
			os.Exit(1)
		}
		nsArgs := strings.Fields("create namespace spire")
		ns := exec.Command("kubectl", nsArgs...)
		_, _ = ns.CombinedOutput()
		kubeArgs := strings.Fields(string(stdout))
		var command string
		var cmdArgs []string

		if Contains(kubeArgs, "kustomization.yaml") {
			command = fmt.Sprintf("apply -k %s", filepath.Join(args[0]))
			cmdArgs = strings.Fields(command)
			spireInstall := exec.Command("kubectl", cmdArgs[0:]...)

			out, err := spireInstall.CombinedOutput()
			if err != nil {
				println(err.Error())
			}
			print(string(out))
		}

		for i, _ := range kubeArgs {
			if kubeArgs[i][len(kubeArgs[i])-3:] == ".sh" || kubeArgs[i] == "kustomization.yaml" {
				continue
			}
			command = fmt.Sprintf("apply -f %s", filepath.Join(args[0], kubeArgs[i]))
			cmdArgs = strings.Fields(command)
			spireInstall := exec.Command("kubectl", cmdArgs[0:]...)

			out, err := spireInstall.CombinedOutput()
			if err != nil {
				println(err.Error())
			}
			print(string(out))
		}

	},
}

func init() {
	installCmd.AddCommand(spireCmd)

	// Here you will define your flags and configuration settings.
	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// spireCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// spireCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

func UnmarshalAllYamls(in []byte, out *[]interface{}) error {
	r := bytes.NewReader(in)
	decoder := yaml.NewDecoder(r)
	for {
		data := make(map[interface{}]interface{})
		if err := decoder.Decode(&data); err != nil {
			// Break when there are no more documents to decode
			if err != io.EOF {
				return err
			}
			break
		}
		*out = append(*out, data)
	}
	return nil
}

//func old() {
//	yfile, err := ioutil.ReadFile("/mnt/c/Users/alvino/GolandProjects/Mithril/mithrilctl/spire-server.yaml")
//
//	if err != nil {
//		log.Fatal(err)
//	}
//
//	var out []interface{}
//	err3 := UnmarshalAllYamls(yfile, &out)
//	if err3 != nil {
//		fmt.Println("error unmarshilng all yamls err: ", err3.Error())
//	}
//
//	var namespace v1.Namespace
//	var serviceAccount v1.ServiceAccount
//	var clusterRole rbac.ClusterRole
//	var clusterRoleBinding rbac.ClusterRoleBinding
//	var service v1.Service
//	//var statefulSet entity.StatefulSet
//	var test apps.Deployment
//	//err = yaml.Unmarshal(yb, &namespace)
//	//yb, err = yaml.Marshal(namespace)
//	all := ""
//	for i, _ := range out {
//		//fmt.Printf("%v\n", y)
//		yb, err := yaml.Marshal(out[i])
//		if err != nil {
//			fmt.Println("err yaml marsh err: ", err.Error())
//		}
//		if i == 0 {
//			err = yaml.Unmarshal(yb, &namespace)
//			if err != nil {
//				fmt.Println("error unmarshaling namespace")
//			}
//			yb, err = yaml.Marshal(namespace)
//			if err != nil {
//				fmt.Println("error marshaling namespace")
//			}
//			all += "\n" + "---\n" + string(yb)
//			//fmt.Printf("namespace \n%v\n", string(yb))
//		}
//		if i == 1 {
//			err = yaml.Unmarshal(yb, &serviceAccount)
//			if err != nil {
//				fmt.Println("error unmarshaling serviceAccount")
//			}
//			yb, err = yaml.Marshal(serviceAccount)
//			if err != nil {
//				fmt.Println("error marshaling serviceAccount")
//			}
//			all += "\n" + "---\n" + string(yb)
//			//fmt.Printf("serviceAccount \n%v\n", string(yb))
//		}
//		if i == 2 {
//			err = yaml.Unmarshal(yb, &clusterRole)
//			if err != nil {
//				fmt.Println("error unmarshaling clusterRole")
//			}
//			yb, err = yaml.Marshal(clusterRole)
//			if err != nil {
//				fmt.Println("error marshaling clusterRole")
//			}
//			all += "\n" + "---\n" + string(yb)
//			//fmt.Printf("clusterRole \n%v\n", string(yb))
//		}
//		if i == 3 {
//			err = yaml.Unmarshal(yb, &clusterRoleBinding)
//			if err != nil {
//				fmt.Println("error unmarshaling clusterRoleBinding")
//			}
//			yb, err = yaml.Marshal(clusterRoleBinding)
//			if err != nil {
//				fmt.Println("error marshaling clusterRoleBinding")
//			}
//			all += "\n" + "---\n" + string(yb)
//			//fmt.Printf("clusterRoleBinding \n%v\n", string(yb))
//		}
//		if i == 4 {
//			err = yaml.Unmarshal(yb, &service)
//			if err != nil {
//				fmt.Println("error unmarshaling service")
//			}
//			yb, err = yaml.Marshal(service)
//			if err != nil {
//				fmt.Println("error marshaling service")
//			}
//			all += "\n" + "---\n" + string(yb)
//			//fmt.Printf("service \n%v\n", string(yb))
//		}
//		if i == 5 {
//			//err = yaml.Unmarshal(yb, &statefulSet)
//			//if err != nil {
//			//	fmt.Println("error unmarshaling statefulSet")
//			//}
//			//yb, err = yaml.Marshal(statefulSet)
//			//if err != nil {
//			//	fmt.Println("error marshaling statefulSet")
//			//}
//			//all += "\n" + "---\n" + string(yb)
//			err = yaml.Unmarshal(yb, &test)
//			if err != nil {
//				fmt.Println("error unmarshaling statefulSet")
//			}
//			yb, err = yaml.Marshal(test)
//			if err != nil {
//				fmt.Println("error marshaling statefulSet")
//			}
//			all += "\n" + "---\n" + string(yb)
//			//fmt.Printf("statefulSet \n%v\n", string(yb))
//		}
//	}
//	fmt.Printf("%v\n", all)
//}
