package spire

import (
	"errors"
	"fmt"
	"strings"

	"k8s.io/utils/exec"
)

func DeploySpire() error {
	command := fmt.Sprintf("install server mithril/spire-server")
	cmdArgs := strings.Fields(command)
	cmd := exec.New()
	spireInstall := cmd.Command("helm", cmdArgs[0:]...)
	out, err := spireInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
		return err
	}

	command = fmt.Sprintf("install agent mithril/spire-agent")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	spireInstall = cmd.Command("helm", cmdArgs[0:]...)
	out, err = spireInstall.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
		return err
	}

	command = fmt.Sprintf("rollout status daemonset -n spire spire-agent --timeout=120s")
	cmdArgs = strings.Fields(command)
	cmd = exec.New()
	spireInstall = cmd.Command("kubectl", cmdArgs[0:]...)
	_, err = spireInstall.CombinedOutput()
	if err != nil {
		return errors.New("unable to install SPIRE")
	}
	return nil
}
