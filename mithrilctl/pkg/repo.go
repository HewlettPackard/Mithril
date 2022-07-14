package pkg

import (
	"errors"
	"fmt"
	"k8s.io/utils/exec"
	"strings"
)

func AddMithril() error {
	command := fmt.Sprintf("repo add mithril https://hewlettpackard.github.io/Mithril/mithrilctl/helm/mithril")
	cmdArgs := strings.Fields(command)
	cmd := exec.New()
	repoAdd := cmd.Command("helm", cmdArgs[0:]...)
	out, err := repoAdd.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
		return errors.New(string(out))
	}
	return nil
}

func UpdateMithril() error {
	command := fmt.Sprintf("repo update")
	cmdArgs := strings.Fields(command)
	cmd := exec.New()
	repoAdd := cmd.Command("helm", cmdArgs[0:]...)
	out, err := repoAdd.CombinedOutput()
	if err != nil {
		fmt.Printf("\n%s", out)
		return errors.New(string(out))
	}
	return nil
}
