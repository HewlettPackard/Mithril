package istio

import (
	"fmt"
	"github.com/spf13/viper"
	"k8s.io/utils/exec"
	"strings"
)

func DeployIstio() {
	mithrilPath := viper.GetString("mithrilPath")
	command := fmt.Sprintf("install -f %s/POC/base-1.13.4/base/values.yaml base %s/POC/base-1.13.4/base/", mithrilPath, mithrilPath)
	cmdArgs := strings.Fields(command)
	cmd := exec.New()
	istioInstall := cmd.Command("helm", cmdArgs[0:]...)
	out, err := istioInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
	}

	command = fmt.Sprintf("install -f %s/POC/istiod-1.13.4/istiod/values.yaml istiod %s/POC/istiod-1.13.4/istiod/ -n istio-system --wait --timeout 120s", mithrilPath, mithrilPath)
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	istioInstall = cmd.Command("helm", cmdArgs[0:]...)
	out, err = istioInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
	}

	command = fmt.Sprintf("rollout status deployment -n istio-system istiod --timeout=300s")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	istioInstall = cmd.Command("kubectl", cmdArgs[0:]...)
	out, err = istioInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
	}

	command = fmt.Sprintf("install -f %s/POC/gateway-1.13.4/gateway/values.yaml ingressgateway %s/POC/gateway-1.13.4/gateway/ -n istio-system", mithrilPath, mithrilPath)
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	istioInstall = cmd.Command("helm", cmdArgs[0:]...)
	out, err = istioInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
	}

	command = fmt.Sprintf("rollout status deployment -n istio-system ingressgateway --timeout=300s")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	istioInstall = cmd.Command("kubectl", cmdArgs[0:]...)
	out, err = istioInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
	}
}
