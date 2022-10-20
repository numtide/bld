package main

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"

	"github.com/alecthomas/kong"
	nix "github.com/numtide/bld/nix"
	log "github.com/sirupsen/logrus"
)

type Run struct {
	Target    string `arg:"" name:"target" help:"Target to run" type:"target" default:"."`
	ShowTrace bool   `name:"show-trace" help:"Show trace on error"`
}

func isExecutable(filename string) (bool, error) {
	fileInfo, err := os.Stat(filename)
	if err != nil {
		return false, err
	}

	mode := fileInfo.Mode()

	return mode&0o111 != 0, nil
}

func (r *Run) Run(_ *kong.Context) error {
	log.Debug("Running target in directory")

	rootDirectory, err := getPrjRoot()
	if err != nil {
		return err
	}

	err = nix.Build(rootDirectory, r.Target, r.ShowTrace, false)
	if err != nil {
		return err
	}

	result, err := nix.Instantiate(rootDirectory, r.Target, "_run")
	if err != nil {
		return err
	}

	if result == "" {
		errorMessage := fmt.Sprintf(
			"Unable to find executable for target `%s`", r.Target)

		return errors.New(errorMessage)
	}

	isExec, err := isExecutable(result)
	if err != nil {
		return err
	}

	if !isExec {
		errorMessage := fmt.Sprintf(
			"Found file in target %s but %s is not executable", r.Target, result)

		return errors.New(errorMessage)
	}

	log.WithFields(log.Fields{"command": result}).Debug("Running target")

	cmd := exec.Command(result)

	var stdout bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = os.Stderr

	err = cmd.Run()
	if err != nil {
		errorMessage := fmt.Sprintf(
			"Error while running `%s ..`: %s", result, err.Error(),
		)

		return errors.New(errorMessage)
	}

	return err
}
