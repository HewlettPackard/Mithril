package e2e

import (
	"context"
	"fmt"
	"os"
	"testing"

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

	podName := getClientPodName()
	command := "ls"

	hostname := getHostname()
	fmt.Printf(hostname)

	cmd := []string{
		"sh",
		"-c",
		command,
	}
	req := clientset.CoreV1().RESTClient().Post().Resource("pods").Name(podName).
		Namespace("default").SubResource("exec")
	option := &v1.PodExecOptions{
		Command: cmd,
		Stdin:   true,
		Stdout:  true,
		Stderr:  true,
		TTY:     true,
	}
	option.Stdin = false
	req.VersionedParams(
		option,
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

func getClientPodName() string {
	labelSelector := "app=sleep"

	options := metav1.ListOptions{
		LabelSelector: labelSelector,
	}
	podList, _ := clientset.CoreV1().Pods("default").List(context.TODO(), options)
	for _, podInfo := range (*podList).Items {
		clientPod := fmt.Sprintf("pods-name=%v\n", podInfo.Name)
		fmt.Printf("pods-status=%v\n", podInfo.Status.Phase)
		fmt.Printf("pods-condition=%v\n", podInfo.Status.Conditions)

		fmt.Printf(clientPod)
	}

	return "details-v1-6c54b96547-tptlm"
}

func deployPOC(t *testing.T) {
	pods, err := clientset.CoreV1().Pods("").List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		t.Error(err)
	}

	for i, podItem := range pods.Items {
		fmt.Println(i, podItem.Name)
	}

	fmt.Printf("There are %d pods in the cluster\n", len(pods.Items))
}
