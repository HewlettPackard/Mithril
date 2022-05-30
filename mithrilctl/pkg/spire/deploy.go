package spire

import (
	"fmt"
	"k8s.io/utils/exec"
	"strings"
)

func DeploySpire() {
	command := fmt.Sprintf("install -f /home/alexandre/Goland/fork/Mithril/mithrilctl/helm/spire-server/values.yaml spire-server /home/alexandre/Goland/fork/Mithril/mithrilctl/helm/spire-server/ --wait --timeout 120s")
	cmdArgs := strings.Fields(command)
	cmd := exec.New()
	spireInstall := cmd.Command("helm", cmdArgs[0:]...)
	_, err := spireInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\nerror deploying SPIRE server err: %s", err)
	}

	command = fmt.Sprintf("install -f /home/alexandre/Goland/fork/Mithril/mithrilctl/helm/spire-agent/values.yaml spire-agent /home/alexandre/Goland/fork/Mithril/mithrilctl/helm/spire-agent/ --wait --wait-for-jobs --timeout 120s")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	spireInstall = cmd.Command("helm", cmdArgs[0:]...)
	_, err = spireInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\nerror deploying SPIRE agent err: %s", err)
	}
	//fmt.Printf("%s", out)

	command = fmt.Sprintf("rollout status daemonset -n spire spire-agent --timeout=120s")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	spireInstall = cmd.Command("kubectl", cmdArgs[0:]...)
	_, err = spireInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", err)
	}
}
