package main

import (
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

	log.WithFields(log.Fields{"command": result}).Debug("Running target")

	cmd := exec.Command(result)

	cmd.Stdout = os.Stdout
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
