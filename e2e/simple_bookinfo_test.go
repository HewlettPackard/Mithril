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
	t.Run("get_cluster", getCluster)
	t.Run("request_productpage_workload", requestProductpageWorkload)
}

func version(t *testing.T) {
	cmd := exec.Command("istioctl", "version")

	buf := new(bytes.Buffer)
	cmd.Stdout = buf
	cmd.Stderr = os.Stderr

	cmd.Run()

	actual := buf.String()
	assert.Contains(t, actual, istioctlVersion)
}

func getCluster(t *testing.T) {
	cmd := exec.Command("kind", "get clusters")

	buf := new(bytes.Buffer)
	cmd.Stdout = buf
	cmd.Stderr = os.Stderr

	cmd.Run()

	actual := buf.String()
	assert.Contains(t, actual, "kind")
}

func requestProductpageWorkload(t *testing.T) {
	resp, err := http.Get("http://localhost:8000/productpage")
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
}
