package e2e

import (
	"testing"
)

func TestExternalWorkload(t *testing.T) {
	client, config, err := createClientGo()
	if err != nil {
		t.Fatal(err)
	}

	clientset = client
	kubeConfig = config

	cmd = "curl -I example.org"

	t.Run("request_external_workload_from_sleep_pod", requestFromSleep)
}
