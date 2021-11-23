package e2e

import (
	"net/http"
	"testing"

	"gotest.tools/assert"
)

func TestFederation(t *testing.T) {
	t.Run("request_productpage_workload", requestSecureProductpageWorkload)
}

func requestSecureProductpageWorkload(t *testing.T) {
	clientset, config, err := createClientGo()
	if err != nil {
		t.Fatal(err)
	}

	cmd := "/opt/spire/bin/spire-server x509 mint -spiffeID spiffe://domain.test/myservice -socketPath /run/spire/sockets/server.sock --write /tmp"
	_, _, err = execInContainer(clientset, config, "app=spire-server", "spire-server", "spire2", cmd)
	if err != nil {
		t.Fatal(err)
	}

	cmd = "cat /tmp/svid.pem"
	svidPEM, _, err := execInContainer(clientset, config, "app=spire-server", "spire-server", "spire2", cmd)
	if err != nil {
		t.Fatal(err)
	}

	cmd = "cat /tmp/key.pem"
	keyPEM, _, err := execInContainer(clientset, config, "app=spire-server", "spire-server", "spire2", cmd)
	if err != nil {
		t.Fatal(err)
	}

	httpClient, err := createSecureHttpClient(svidPEM, keyPEM)

	if err != nil {
		t.Fatal(err)
	}

	resp, err := httpClient.Get("https://localhost:7000/productpage")

	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()

	assert.Equal(t, resp.StatusCode, http.StatusOK)

}
