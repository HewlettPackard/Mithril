package e2e

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestSimpleBookinfo(t *testing.T) {
	t.Run("version", Version)
	// t.Run("create_kind_cluster", createKindCluster)
	// t.Run("deploy_poc", deployPOC)
	t.Run("request_productpage_workload", requestProductpageWorkload)
}

func Version(t *testing.T) {

	cmd := exec.Command("istioctl", "version")

	buf := new(bytes.Buffer)
	cmd.Stdout = buf
	cmd.Stderr = os.Stderr

	cmd.Run()

	actual := buf.String()
	assert.Contains(t, actual, "client")
	fmt.Println(actual)
}

func requestProductpageWorkload(t *testing.T) {

	cmd := exec.Command("curl", "localhost:8000/productpage")

	buf := new(bytes.Buffer)
	cmd.Stdout = buf
	cmd.Stderr = os.Stderr

	cmd.Run()

	actual := buf.String()
	assert.Contains(t, actual, "client")
	fmt.Println(actual)
}
