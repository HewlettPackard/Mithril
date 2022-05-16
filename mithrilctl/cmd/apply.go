package cmd

import (
	"context"
	"flag"
	"fmt"
	"github.com/spf13/cobra"
	"gopkg.in/yaml.v3"
	"io/ioutil"
	apps "k8s.io/api/apps/v1"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	"os/exec"
	"strings"

	//"k8s.io/client-go/tools/clientcmd/api"
	"k8s.io/client-go/util/homedir"
	"os"
	"path/filepath"
)

// applyCmd represents the apply command
var applyCmd = &cobra.Command{
	Use:   "apply",
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
			os.Exit(1)
		}
		client, _, err := createClientGo()
		if err != nil {
			fmt.Println("error creating k8s client err: ", err.Error())
		}
		for _, serviceFilePath := range args {

			yfile, err := ioutil.ReadFile(filepath.Join(serviceFilePath))

			if err != nil {
				fmt.Println(err.Error())
			}

			var out []interface{}
			err = UnmarshalAllYamls(yfile, &out)
			if err != nil {
				fmt.Println("error unmarshilng yaml file err: ", err.Error())
			}

			var objs []string
			for _, y := range out {
				yb, _ := yaml.Marshal(y)
				objs = append(objs, fmt.Sprintf("%v", string(yb)))
			}
			//println(fmt.Sprintf("%+v", objs))

			var nms []string
			for _, f := range objs {
				decode := scheme.Codecs.UniversalDeserializer().Decode
				obj, _, _ := decode([]byte(f), nil, nil)
				//println(f)
				switch o := obj.(type) {
				case *apps.Deployment:
					// o is the Deployment
					//ob, _ := yaml.Marshal(o)
					//println(fmt.Sprintf("%+v", string(ob)))
					if o.Namespace == "" {
						o.Namespace = "default"
					}
					if !Contains(nms, o.Namespace) {
						nms = append(nms, o.Namespace)
						cm := v1.ConfigMap{
							TypeMeta: metav1.TypeMeta{
								Kind:       "ConfigMap",
								APIVersion: "v1",
							},
							ObjectMeta: metav1.ObjectMeta{
								Name:      "istio-ca-root-cert",
								Namespace: o.Namespace,
							},
						}
						n := v1.Namespace{
							TypeMeta: metav1.TypeMeta{
								Kind:       "Namespace",
								APIVersion: "v1",
							},
							ObjectMeta: metav1.ObjectMeta{
								Name: o.Namespace,
							},
						}
						createNm, err := client.CoreV1().Namespaces().Create(context.Background(), &n, metav1.CreateOptions{})
						if err == nil {
							fmt.Printf(fmt.Sprintf("namespace/%s created\n", createNm.Name))
						}
						createCfg, err := client.CoreV1().ConfigMaps(o.Namespace).Create(context.Background(), &cm, metav1.CreateOptions{})
						if err == nil {
							fmt.Printf(fmt.Sprintf("configmap/%s created\n", createCfg.Name))
						}
					}

				case *v1.Pod:
					// o is a pod
				//case *v1beta1.RoleBinding:
				//case *v1beta1.ClusterRole:
				//case *v1beta1.ClusterRoleBinding:
				case *v1.ServiceAccount:
				default:
					//o is unknown for us
				}
			}
			command := fmt.Sprintf("kube-inject --filename %s | kubectl apply -f -", filepath.Join(args[0]))
			cmdArgs := strings.Fields(command)
			//println(command)
			//for _, m := range cmdArgs {
			//	println(m)
			//}
			wlInstall := exec.Command("istioctl", cmdArgs[0:]...)

			oute, err := wlInstall.CombinedOutput()
			if err != nil {
				println(err.Error())
			}
			print(string(oute))
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

func createClientGo() (*kubernetes.Clientset, *rest.Config, error) {
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
