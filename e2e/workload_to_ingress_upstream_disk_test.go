package e2e

import (
	"context"
	"fmt"
	"os"
	"testing"

	"gotest.tools/assert"
	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	rest "k8s.io/client-go/rest"
	"k8s.io/client-go/tools/remotecommand"
	"k8s.io/kubectl/pkg/scheme"
)

var clientset *kubernetes.Clientset
var kubeConfig *rest.Config

func TestWorkloadToIngressUpstreamDisk(t *testing.T) {
	client, config, err := createClientGo()
	if err != nil {
		t.Fatal(err)
	}

	clientset = client
	kubeConfig = config

	t.Run("deploy_poc", deployPOC)
	t.Run("request_productpage_workload_from_sleep_pod", requestProductpageWorkloadFromSleepPod)
}

func requestProductpageWorkloadFromSleepPod(t *testing.T) {
	labelSelector := "app=sleep"
	listOptions := metav1.ListOptions{
		LabelSelector: labelSelector,
	}

	pods, err := getPodByOptions(listOptions, clientset)
	if err != nil {
		t.Fatal(err)
	}

	if len(pods) == 0 {
		t.Fatal("Sleep pod not found")
	}
	sleepPod := pods[0]

	hostname := getHostname()
	command := fmt.Sprintf("echo %v\n", hostname)

	cmd := []string{
		"sh",
		"-c",
		command,
	}
	req := clientset.CoreV1().RESTClient().Post().Resource("pods").Name(sleepPod.Name).
		Namespace(defaultNamespace).SubResource("exec")
	execOptions := &v1.PodExecOptions{
		Command: cmd,
		Stdin:   true,
		Stdout:  true,
		Stderr:  true,
		TTY:     true,
	}
	execOptions.Stdin = false
	req.VersionedParams(
		execOptions,
		scheme.ParameterCodec,
	)
	exec, err := remotecommand.NewSPDYExecutor(kubeConfig, "POST", req.URL())
	if err != nil {
		t.Fatal(err)
	}
	err = exec.Stream(remotecommand.StreamOptions{
		Stdin:  os.Stdin,
		Stdout: os.Stdout,
		Stderr: os.Stderr,
	})
	if err != nil {
		t.Fatal(err)
	}
}

func deployPOC(t *testing.T) {
	pods, err := clientset.CoreV1().Pods("").List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		t.Error(err)
	}

	assert.Equal(t, len(pods.Items), 20)
}
