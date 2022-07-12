package istio

import (
	"errors"
	"fmt"
	"strings"

	"github.com/spf13/viper"
	"k8s.io/utils/exec"
)

func DeployIstio() error {
	mithrilPath := viper.GetString("mithrilPath")
	command := fmt.Sprintf("install -f %s/mithrilctl/helm/istio/base-1.14.1/base/values.yaml base %s/mithrilctl/helm/istio/base-1.14.1/base/", mithrilPath, mithrilPath)
	cmdArgs := strings.Fields(command)
	cmd := exec.New()
	istioInstall := cmd.Command("helm", cmdArgs[0:]...)
	out, err := istioInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
		return err
	}

	command = fmt.Sprintf("install -f %s/mithrilctl/helm/istio/istiod-1.14.1/istiod/values.yaml istiod %s/mithrilctl/helm/istio/istiod-1.14.1/istiod/ -n istio-system --wait --timeout 120s", mithrilPath, mithrilPath)
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

	command = fmt.Sprintf("install -f %s/mithrilctl/helm/istio/gateway-1.14.1/gateway/values.yaml ingressgateway %s/mithrilctl/helm/istio/gateway-1.14.1/gateway/ -n istio-system", mithrilPath, mithrilPath)
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
