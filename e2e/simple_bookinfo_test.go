package e2e

import (
	"bytes"
	"net/http"
	"os"
	"os/exec"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSimpleBookinfo(t *testing.T) {
	t.Run("version", version)
	t.Run("create_kind_cluster", createKindCluster)
	// t.Run("deploy_poc", deployPOC)
	t.Run("request_productpage_workload", requestProductpageWorkload)
}

func version(t *testing.T) {
	cmd := exec.Command("istioctl", "version")

	buf := new(bytes.Buffer)
	cmd.Stdout = buf
	cmd.Stderr = os.Stderr

	cmd.Run()

	actual := buf.String()
	assert.Contains(t, actual, "1.10.1")
}

func createKindCluster(t *testing.T) {
	cmd := exec.Command("kind", "get clusters")

	buf := new(bytes.Buffer)
	cmd.Stdout = buf
	cmd.Stderr = os.Stderr

	cmd.Run()

	actual := buf.String()
	assert.Contains(t, actual, "kind")
}

func requestProductpageWorkload(t *testing.T) {
	resp, err := http.Get("http:localhost:8080/productpage")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
}
