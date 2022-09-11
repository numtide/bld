package nix

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	log "github.com/sirupsen/logrus"
)

func Instantiate(rootDirectory string, target string, attr string) (result string, err error) {
	if err != nil {
		errorMessage := fmt.Sprintf(
			"Error looking for root directory %s", err.Error(),
		)

		return "", errors.New(errorMessage)
	}

	currentDirectory, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}

	path, err := TargetToPath(rootDirectory, currentDirectory, target)
	if err != nil {
		errorMessage := fmt.Sprintf(
			"Error mapping target to directory %s", err.Error(),
		)

		return "", errors.New(errorMessage)
	}

	pathToBuild := path

	// required for running targets
	if !pathExists(path) && pathExists(filepath.Dir(path)) {
		path = strings.Replace(path, rootDirectory, "", -1)
		pathToBuild = strings.Trim(path, "/")
		pathToBuild = strings.Replace(pathToBuild, "/", ".", -1)
	}

	args := []string{
		"--eval",
		"--include", fmt.Sprintf("prj_root=%s", rootDirectory),
		"--expr", fmt.Sprintf("{ path }: (import <prj_root> {}).%s path", attr),
		"--argstr", "path", pathToBuild,
		"--json",
		//"--strict", // TODO: make it optional ?
	}

	log.WithFields(log.Fields{"args": args}).Debug("Running nix-instantiate")

	cmd := exec.Command("nix-instantiate", args...)

	var stdout bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = os.Stderr

	err = cmd.Run()
	if err != nil {
		errorMessage := fmt.Sprintf(
			"Error while running `nix-instantiate ..`: %s", err.Error(),
		)

		return "", errors.New(errorMessage)
	}

	err = json.Unmarshal(stdout.Bytes(), &result)
	if err != nil {
		return "", err
	}

	return result, nil
}
