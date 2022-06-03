package spire

import (
	"fmt"
	"github.com/spf13/viper"
	"k8s.io/utils/exec"
	"strings"
)

func DeploySpire() {
	mithrilPath := viper.GetString("mithrilPath")
	command := fmt.Sprintf("install -f %s/mithrilctl/helm/spire/spire-server/values.yaml spire-server %s/mithrilctl/helm/spire/spire-server/ --wait --timeout 120s", mithrilPath, mithrilPath)
	cmdArgs := strings.Fields(command)
	cmd := exec.New()
	spireInstall := cmd.Command("helm", cmdArgs[0:]...)
	out, err := spireInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
	}

	command = fmt.Sprintf("install -f %s/mithrilctl/helm/spire/spire-agent/values.yaml spire-agent %s/mithrilctl/helm/spire/spire-agent/ --wait --wait-for-jobs --timeout 120s", mithrilPath, mithrilPath)
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	spireInstall = cmd.Command("helm", cmdArgs[0:]...)
	_, err = spireInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
	}

	command = fmt.Sprintf("rollout status daemonset -n spire spire-agent --timeout=120s")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	spireInstall = cmd.Command("kubectl", cmdArgs[0:]...)
	out, err = spireInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
	}
}
