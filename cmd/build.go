package main

import (
	"github.com/alecthomas/kong"
	nix "github.com/numtide/bld/nix"
	log "github.com/sirupsen/logrus"
)

type Build struct {
	Target    string `arg:"" name:"target" help:"Target to build" type:"target"`
	ShowTrace bool   `name:"show-trace" help:"Show trace on error"`
}

func (b *Build) Run(_ *kong.Context) error {
	log.WithFields(log.Fields{
		"target": b.Target,
	}).Info("Building target")

	rootDirectory, err := getPrjRoot()
	if err != nil {
		return err
	}

	err = nix.Build(rootDirectory, b.Target, b.ShowTrace)
	if err != nil {
		return err
	}

	return nil
}
