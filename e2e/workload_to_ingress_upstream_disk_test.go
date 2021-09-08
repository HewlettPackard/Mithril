package e2e

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestWorkloadToIngressUpstreamDisk(t *testing.T) {
	t.Run("version", requestProductPage)
}

func requestProductPage(t *testing.T) {
	// kubectl get pod -l app=sleep -n default -o jsonpath="{.items[0].metadata.name}"
	// hostname -I | awk '{print $1}'
	// curl -sSLk --cert /sleep-certs/sleep-svid.pem --key /sleep-certs/sleep-key.pem --cacert /sleep-certs/root-cert.pem https://$${HOST_IP}:8000/productpage

	cmd := exec.Command("istioctl", "version")

	buf := new(bytes.Buffer)
	cmd.Stdout = buf
	cmd.Stderr = os.Stderr

	cmd.Run()

	actual := buf.String()
	assert.Contains(t, actual, "client")
	fmt.Println(actual)
}
