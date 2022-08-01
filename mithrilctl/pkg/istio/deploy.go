package istio

import (
	"errors"
	"fmt"
	"strings"

	"k8s.io/utils/exec"
)

func DeployIstio() error {
	command := fmt.Sprintf("upgrade --install base mithril/base")
	cmdArgs := strings.Fields(command)
	cmd := exec.New()
	istioInstall := cmd.Command("helm", cmdArgs[0:]...)
	out, err := istioInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
		return err
	}

	command = fmt.Sprintf("upgrade --install istiod mithril/istiod -n istio-system")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	istioInstall = cmd.Command("helm", cmdArgs[0:]...)
	out, err = istioInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
		return err
	}

	command = fmt.Sprintf("rollout status deployment -n istio-system istiod --timeout=300s")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	istioInstall = cmd.Command("kubectl", cmdArgs[0:]...)
	_, err = istioInstall.CombinedOutput()
	if err != nil {
		return err
	}

	command = fmt.Sprintf("upgrade --install ingressgateway mithril/gateway -n istio-system")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	istioInstall = cmd.Command("helm", cmdArgs[0:]...)
	out, err = istioInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
		return err
	}

	command = fmt.Sprintf("rollout status deployment -n istio-system ingressgateway --timeout=300s")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	istioInstall = cmd.Command("kubectl", cmdArgs[0:]...)
	_, err = istioInstall.CombinedOutput()
	if err != nil {
		return errors.New("unable to install ingressgateway")
	}
	return nil
}
