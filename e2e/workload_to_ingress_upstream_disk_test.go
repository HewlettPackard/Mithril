package e2e

import (
	"context"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/kubernetes/scheme"
	rest "k8s.io/client-go/rest"
	"k8s.io/client-go/tools/remotecommand"
)

var clientset *kubernetes.Clientset
var kubeConfig *rest.Config

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

func TestWorkloadToIngressUpstreamDisk(t *testing.T) {
	client, config, err := createClientGo()
	if err != nil {
		t.Fatal(err)
	}

	clientset = client
	kubeConfig = config

	t.Run("request_productpage_workload_from_sleep_pod", requestProductpageWorkloadFromSleepPod)
}

func requestProductpageWorkloadFromSleepPod(t *testing.T) {
	labelSelector := "app=details"
	listOptions := metav1.ListOptions{
		LabelSelector: labelSelector,
	}

	podList, err := clientset.CoreV1().Pods(defaultNamespace).List(context.TODO(), listOptions)
	if err != nil {
		fmt.Println(err)
	}

	if len(podList.Items) == 0 {
		t.Fatal("Sleep pod not found")
	}
	sleepPod := podList.Items[0]

	cmd := []string{
		"sh",
		"-c",
		"cat response_productpage.txt",
	}

	req := clientset.CoreV1().RESTClient().Post().
		Namespace("default").
		Resource("pods").
		Name(sleepPod.Name).
		SubResource("exec").
		Param("container", "details")

	option := &v1.PodExecOptions{
		Command: cmd,
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

	fileContent, err := ioutil.ReadFile("response_productpage.txt")
	if err != nil {
		t.Error(err)
	}

	assert.Equal(t, stdOut.Str[0], string(fileContent))
}
