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
	// t.Run("version", Version)
	// t.Run("create_kind_cluster", createKindCluster)
	// t.Run("deploy_poc", deployPOC)
	t.Run("request_productpage_workload_from_sleep_pod", requestProductpageWorkloadFromSleepPod)
}

func requestProductpageWorkloadFromSleepPod(t *testing.T) {
	cmd := exec.Command("kubectl", "get pod -l app=sleep -n default -o jsonpath='{.items[0].metadata.name}'")

	buf := new(bytes.Buffer)
	cmd.Stdout = buf
	cmd.Stderr = os.Stderr

	cmd.Run()

	actual := buf.String()
	assert.Contains(t, actual, "client")
	fmt.Println(actual)

	exec.Command("hostname", "-I | awk '{print $1}'")
	actual = buf.String()
	assert.Contains(t, actual, "client")
	fmt.Println(actual)

	curlCommand := fmt.Sprintf("-sSLk --cert /sleep-certs/sleep-svid.pem --key /sleep-certs/sleep-key.pem --cacert /sleep-certs/root-cert.pem https://%s:8080/productpage", actual)

	exec.Command("curl", curlCommand)
	actual = buf.String()
	assert.Contains(t, actual, "client")
	fmt.Println(actual)
}
