package e2e

import (
	"context"
	"crypto/tls"
	"errors"
	"flag"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/kubernetes/scheme"
	rest "k8s.io/client-go/rest"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/tools/remotecommand"
	"k8s.io/client-go/util/homedir"
)

var clientset *kubernetes.Clientset
var kubeConfig *rest.Config

var istioctlVersion = "1.10"
var defaultNamespace = "default"
var statusOK = "HTTP/1.1 200 OK"
var cmd string

type Writer struct {
	Str []string
}

func (w *Writer) Write(p []byte) (n int, err error) {
	str := string(p)
	if len(str) > 0 {
		w.Str = append(w.Str, str)
	}
	return len(str), nil
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
func createSecureHttpClient(certBytes, keyBytes string) (*http.Client, error) {
	cert, err := tls.X509KeyPair([]byte(certBytes), []byte(keyBytes))

	if err != nil {
		return nil, err
	}

	client := &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{
				Certificates:       []tls.Certificate{cert},
				InsecureSkipVerify: true,
			},
		},
	}

	return client, nil
}

func buildCmd(command string) []string {
	cmd := []string{
		"sh",
		"-c",
		command,
	}
	return cmd
}

func requestFromSleep(t *testing.T) {
	labelSelector := "app=sleep"
	listOptions := metav1.ListOptions{
		LabelSelector: labelSelector,
	}

	podList, err := clientset.CoreV1().Pods(defaultNamespace).List(context.TODO(), listOptions)
	if err != nil {
		t.Error("Error when listing pods")
	}

	if len(podList.Items) == 0 {
		t.Fatal("Sleep pod not found")
	}
	sleepPod := podList.Items[0]

	command := buildCmd(cmd)

	req := clientset.CoreV1().RESTClient().Post().
		Namespace(defaultNamespace).
		Resource("pods").
		Name(sleepPod.Name).
		SubResource("exec").
		Param("container", "sleep")

	option := &v1.PodExecOptions{
		Command: command,
		Stdin:   true,
		Stdout:  true,
		Stderr:  true,
		TTY:     true,
	}
	option.Stdin = false
	req.VersionedParams(option,
		scheme.ParameterCodec,
	)

	executor, err := remotecommand.NewSPDYExecutor(kubeConfig, http.MethodPost, req.URL())
	if err != nil {
		t.Error(err)
	}

	stdOut := new(Writer)
	os.Stderr.Sync()

	err = executor.Stream(remotecommand.StreamOptions{
		Stdin:             nil,
		Stdout:            stdOut,
		Stderr:            os.Stderr,
		Tty:               false,
		TerminalSizeQueue: nil,
	})
	if err != nil {
		t.Error(err)
	}

	// stdOut should contain a status code response from a request using the "-I" parameter
	assert.Contains(t, stdOut.Str[0], statusOK)
}

func execInContainer(clientset *kubernetes.Clientset, config *rest.Config, labelSelector, container, namespace, cmd string) (string, string, error) {

	podList, err := clientset.CoreV1().
		Pods(namespace).
		List(context.TODO(), metav1.ListOptions{LabelSelector: labelSelector})

	if err != nil {
		return "", "", err
	}

	if len(podList.Items) == 0 {
		return "", "", errors.New("pod not found")
	}
	pod := podList.Items[0]

	command := buildCmd(cmd)

	req := clientset.CoreV1().
		RESTClient().
		Post().
		Namespace(namespace).
		Resource("pods").
		Name(pod.Name).
		SubResource("exec").
		Param("container", container).
		VersionedParams(&v1.PodExecOptions{
			Command: command,
			Stdout:  true,
			Stderr:  true,
		}, scheme.ParameterCodec)

	executor, err := remotecommand.NewSPDYExecutor(config, http.MethodPost, req.URL())
	if err != nil {
		return "", "", err
	}

	stdOut := new(Writer)
	stdErr := new(Writer)
	os.Stderr.Sync()

	err = executor.Stream(remotecommand.StreamOptions{
		Stdin:             nil,
		Stdout:            stdOut,
		Stderr:            stdErr,
		TerminalSizeQueue: nil,
	})
	if err != nil {
		return "", "", nil
	}

	return strings.Join(stdOut.Str, "\n"), strings.Join(stdErr.Str, "\n"), nil
}
