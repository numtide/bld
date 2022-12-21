package nix

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"

	log "github.com/sirupsen/logrus"
)

func Build(rootDirectory, target string, showTrace bool, jsonOutput bool) (err error) {
	if err != nil {
		errorMessage := fmt.Sprintf(
			"Error looking for root directory %s", err.Error(),
		)

		return errors.New(errorMessage)
	}

	currentDirectory, err := os.Getwd()
	if err != nil {
		log.Println(err)
	}

	path, attr, err := TargetToAttr(rootDirectory, currentDirectory, target)
	if err != nil {
		errorMessage := fmt.Sprintf(
			"Error mapping target to directory %s", err.Error(),
		)

		return errors.New(errorMessage)
	}

	pathToBuild := strings.Trim(fmt.Sprintf("%s/%s", path, attr), "/")
	pathToBuild = strings.Replace(pathToBuild, "/", ".", -1)

	cacheDirectory := fmt.Sprintf("%s/.cache/bld", rootDirectory)

	output := "--print-out-paths"
	if jsonOutput {
		output = "--json"
	}

	args := []string{
		"--extra-experimental-features", "nix-command",
		"build",
		"--include", fmt.Sprintf("prj_root=%s", rootDirectory),
		output,
		"-L", "--out-link", fmt.Sprintf("%s/result-%s", cacheDirectory, attr),
		"--builders", "''",
		"-f", "<prj_root>",
		pathToBuild,
	}

	if showTrace {
		args = append(args, "--show-trace")
	}

	log.WithFields(log.Fields{"args": args}).Debug("Running nix build")

	cmd := exec.Command("nix", args...)

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err = cmd.Run()
	if err != nil {
		errorMessage := fmt.Sprintf(
			"Error while running `nix build ..`: %s", err.Error(),
		)

		return errors.New(errorMessage)
	}

	return nil
}
