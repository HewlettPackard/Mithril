package e2e

import (
	"testing"
)

func TestWorkloadToIngressUpstreamDisk(t *testing.T) {
	client, config, err := createClientGo()
	if err != nil {
		t.Fatal(err)
	}

	clientset = client
	kubeConfig = config

	cmd = "curl -I http://istio-ingressgateway.istio-system.svc:8000/status/200"

	t.Run("request_httpbin_from_sleep_pod", requestFromSleep)
}
