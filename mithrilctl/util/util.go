package util

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"github.com/mitchellh/go-homedir"
	"github.com/spf13/viper"
	"io/ioutil"
	"mithril/entity"
	"net/http"
	"os"
)

const mithrilConfigFolderPath = ".mithril"
const mithrilConfigPath = "config"

func GetScripts() {
	home := GetHomeDir()
	var response entity.Response
	client := &http.Client{}

	_ = os.Mkdir(fmt.Sprintf("%s/%s/%s", home, mithrilConfigFolderPath, "scripts"), 0777)

	request, _ := http.NewRequest("GET", "https://gitlab.engdb.com.br/api/v4/projects/3400/repository/files/mithril-clone.sh?ref=master", nil)
	request.Header.Set("PRIVATE-TOKEN", viper.GetString("gitlabToken"))
	resp, err := client.Do(request)
	if err != nil {
		fmt.Println("error getting response err: ", err.Error())
	}

	defer resp.Body.Close()
	respBody, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("error reading response body err: ", err.Error())
	}

	_ = json.Unmarshal(respBody, &response)
	content := response.Content
	cloneScript, _ := base64.StdEncoding.DecodeString(content)
	err = os.WriteFile(fmt.Sprintf("%s/%s/%s", home, mithrilConfigFolderPath, "scripts/mithril-clone.sh"), cloneScript, 0777)
	if err != nil {
		fmt.Println("error writing script file err: ", err.Error())
	}

	request, _ = http.NewRequest("GET", "https://gitlab.engdb.com.br/api/v4/projects/3400/repository/files/mithrilsub.sh?ref=master", nil)
	request.Header.Set("PRIVATE-TOKEN", viper.GetString("gitlabToken"))
	resp, err = client.Do(request)
	if err != nil {
		fmt.Println("error getting response err: ", err.Error())
	}

	defer resp.Body.Close()
	respBody, err = ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println("error reading response body err: ", err.Error())
	}

	_ = json.Unmarshal(respBody, &response)
	content = response.Content
	cloneScript, _ = base64.StdEncoding.DecodeString(content)
	err = os.WriteFile(fmt.Sprintf("%s/%s/%s", home, mithrilConfigFolderPath, "scripts/mithrilsub.sh"), cloneScript, 0777)
	if err != nil {
		fmt.Println("error writing script file err: ", err.Error())
	}
}

func GetHomeDir() string {
	home, err := homedir.Dir()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	return home
}
