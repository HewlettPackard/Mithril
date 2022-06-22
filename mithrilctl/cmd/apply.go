package cmd

import (
	"bytes"
	"context"
	"flag"
	"fmt"
	"io"
	"io/ioutil"
	"os/exec"
	"strings"

	"github.com/spf13/cobra"
	"gopkg.in/yaml.v3"
	apps "k8s.io/api/apps/v1"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"

	//"k8s.io/client-go/tools/clientcmd/api"
	"os"
	"path/filepath"

	"k8s.io/client-go/util/homedir"
)

// applyCmd represents the apply command
var applyCmd = &cobra.Command{
	Use:   "apply",
	Short: "Applies Kubernetes deployments",
	Long: `Command used for applying k8s deployment definitions and creating their
namespaces and required Istio configmaps.`,
	Run: func(cmd *cobra.Command, args []string) {
		if len(args) == 0 {
			cmd.Help()
			os.Exit(0)
		} else if args[0] == "" {
			cmd.Help()
			os.Exit(1)
		}

		client, _, err := CreateClientGo()
		if err != nil {
			fmt.Println("error creating k8s client err: ", err.Error())
		}

		for _, serviceFilePath := range args {
			var out []interface{}
			var objs []string
			var namespaces []string

			yamlFile, err := ioutil.ReadFile(filepath.Join(serviceFilePath))

			if err != nil {
				fmt.Println(err.Error())
			}

			err = UnmarshalAllYamls(yamlFile, &out)
			if err != nil {
				fmt.Println("error unmarshalling yaml file err: ", err.Error())
			}

			for _, y := range out {
				yb, _ := yaml.Marshal(y)
				objs = append(objs, fmt.Sprintf("%v", string(yb)))
			}

			for _, f := range objs {
				decode := scheme.Codecs.UniversalDeserializer().Decode
				obj, _, _ := decode([]byte(f), nil, nil)
				switch o := obj.(type) {
				case *apps.Deployment:
					if o.Namespace == "" {
						o.Namespace = "default"
					}
					if !Contains(namespaces, o.Namespace) {
						namespaces = append(namespaces, o.Namespace)
						configmap := v1.ConfigMap{
							TypeMeta: metav1.TypeMeta{
								Kind:       "ConfigMap",
								APIVersion: "v1",
							},
							ObjectMeta: metav1.ObjectMeta{
								Name:      "istio-ca-root-cert",
								Namespace: o.Namespace,
							},
						}
						namespace := v1.Namespace{
							TypeMeta: metav1.TypeMeta{
								Kind:       "Namespace",
								APIVersion: "v1",
							},
							ObjectMeta: metav1.ObjectMeta{
								Name: o.Namespace,
							},
						}
						createNs, err := client.CoreV1().Namespaces().Create(context.Background(), &namespace, metav1.CreateOptions{})
						if err == nil {
							fmt.Printf(fmt.Sprintf("namespace/%s created\n", createNs.Name))
						}
						createCm, err := client.CoreV1().ConfigMaps(o.Namespace).Create(context.Background(), &configmap, metav1.CreateOptions{})
						if err == nil {
							fmt.Printf(fmt.Sprintf("configmap/%s created\n", createCm.Name))
						}
					}

				case *v1.Pod:
				case *v1.ServiceAccount:
				default:
					//o is unknown for us
				}
			}

			cmd := fmt.Sprintf("apply -f %s", filepath.Join(args[0]))
			cmdArgs := strings.Fields(cmd)

			wlInstall := exec.Command("kubectl", cmdArgs[0:]...)

			output, _ := wlInstall.CombinedOutput()

			fmt.Print(string(output))
		}
	},
}

func init() {
	rootCmd.AddCommand(applyCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// applyCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	//applyCmd.Flags().BoolP("file", "f", false, "for passing a deployment k8s file as input")
}

func CreateClientGo() (*kubernetes.Clientset, *rest.Config, error) {
	var kubeconfig *string
	if home := homedir.HomeDir(); home != "" {
		kubeconfig = flag.String("kubeconfig", filepath.Join(home, ".kube", "config"), "(optional) absolute path to the kubeconfig file")
	} else {
		kubeconfig = flag.String("kubeconfig", "", "absolute path to the kubeconfig file")
	}

	flag.Parse()

	config, err := clientcmd.BuildConfigFromFlags("", *kubeconfig)
	if err != nil {
		return nil, nil, err
	}

	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		return nil, config, err
	}

	return clientset, config, err
}

func Contains(s []string, str string) bool {
	for _, v := range s {
		if v == str {
			return true
		}
	}

	return false
}

func UnmarshalAllYamls(in []byte, out *[]interface{}) error {
	reader := bytes.NewReader(in)
	decoder := yaml.NewDecoder(reader)
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
