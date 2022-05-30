package istio

import (
	"fmt"
	"k8s.io/utils/exec"
	"strings"
)

func DeployIstio() {
	command := fmt.Sprintf("install -f /home/alexandre/Goland/fork/Mithril/POC/base-1.13.4/base/values.yaml base /home/alexandre/Goland/fork/Mithril/POC/base-1.13.4/base/")
	cmdArgs := strings.Fields(command)
	cmd := exec.New()
	spireInstall := cmd.Command("helm", cmdArgs[0:]...)
	_, err := spireInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\nerror deploying istio base err: %s", err)
	}

	command = fmt.Sprintf("install -f /home/alexandre/Goland/fork/Mithril/POC/istiod-1.13.4/istiod/values.yaml istiod /home/alexandre/Goland/fork/Mithril/POC/istiod-1.13.4/istiod/ -n istio-system --wait --timeout 120s")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	spireInstall = cmd.Command("helm", cmdArgs[0:]...)
	_, err = spireInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\nerror deploying istiod err: %s", err)
	}

	command = fmt.Sprintf("rollout status deployment -n istio-system istiod --timeout=300s")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	spireInstall = cmd.Command("kubectl", cmdArgs[0:]...)
	_, err = spireInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("%s", err)
	}

	command = fmt.Sprintf("install -f /home/alexandre/Goland/fork/Mithril/POC/gateway-1.13.4/gateway/values.yaml ingressgateway /home/alexandre/Goland/fork/Mithril/POC/gateway-1.13.4/gateway/ -n istio-system")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	spireInstall = cmd.Command("helm", cmdArgs[0:]...)
	_, err = spireInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\nerror deploying ingressgateway err: %s", err)
	}

	command = fmt.Sprintf("rollout status deployment -n istio-system ingressgateway --timeout=300s")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	spireInstall = cmd.Command("kubectl", cmdArgs[0:]...)
	_, err = spireInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("%s", err)
	}
}
