package nix

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"

	log "github.com/sirupsen/logrus"
)

func Inspect(rootDirectory, target string) (err error) {
	if err != nil {
		errorMessage := fmt.Sprintf(
			"Error looking for root directory %s", err.Error(),
		)

		return errors.New(errorMessage)
	}

	currentDirectory, err := os.Getwd()
	if err != nil {
		return err
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

	log.WithFields(log.Fields{"pathToBuild": pathToBuild}).Debug("Running nix show-derivation")

	// Eval
	var drvPath string
	{
		args := []string{"--no-gc-warning", "--json"}
		if pathToBuild != "" {
			args = append(args, "-A", pathToBuild)
		}

		cmd := exec.Command("nix-instantiate", args...)
		cmd.Stderr = os.Stderr

		bs, err := cmd.Output()
		if err != nil {
			return fmt.Errorf("error while inspecting the target: %w", err)
		}

		drvPath = strings.TrimSpace(string(bs))
	}

	// Show derivation
	cmd := exec.Command("nix", "show-derivation", "--extra-experimental-features", "nix-command", drvPath)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	err = cmd.Run()
	if err != nil {
		return fmt.Errorf("error while inspect target: %w", err)
	}

	return nil
}
