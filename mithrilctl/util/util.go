package util

import (
	"fmt"
	"github.com/mitchellh/go-homedir"
	"os"
)

const mithrilConfigFolderPath = ".mithril"
const mithrilConfigPath = "config"

func GetHomeDir() string {
	home, err := homedir.Dir()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	return home
}
