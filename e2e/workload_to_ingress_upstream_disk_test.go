package e2e

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"testing"

	v1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/tools/remotecommand"
	"k8s.io/kubectl/pkg/scheme"
)

func TestWorkloadToIngressUpstreamDisk(t *testing.T) {
	t.Run("getClientPodName", getClientPodName)
	t.Run("deploy_poc", deployPOC)
	t.Run("exec", execInsideCluster)
	t.Run("request_productpage_workload_from_sleep_pod", requestProductpageWorkloadFromSleepPod)
}

func execInsideCluster(t *testing.T) {
	clientset, config, err := CreateClientGo()
	if err != nil {
		t.Error(err)
	}

	podName := "details-v1-fd855b89b-jmvt6"
	command := "ls"

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
	exec, err := remotecommand.NewSPDYExecutor(config, "POST", req.URL())
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

func getClientPodName(t *testing.T) {
	clientset, _, err := CreateClientGo()
	if err != nil {
		t.Error(err)
	}

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
}

func requestProductpageWorkloadFromSleepPod(t *testing.T) {
	out, err := exec.Command("hostname", "-I").Output()
	if err != nil {
		t.Fatal(err)
	}

	ipList := string(out)
	hostname := ipList[:strings.IndexByte(ipList, ' ')]

	fmt.Println(hostname)
}

func deployPOC(t *testing.T) {
	clientset, _, err := CreateClientGo()
	if err != nil {
		t.Error(err)
	}

	pods, err := clientset.CoreV1().Pods("").List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		t.Fatal(err)
	}

	fmt.Printf("There are %d pods in the cluster\n", len(pods.Items))
}
