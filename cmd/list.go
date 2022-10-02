package main

import (
	"fmt"

	"github.com/alecthomas/kong"
	nix "github.com/numtide/bld/nix"
	log "github.com/sirupsen/logrus"
)

type List struct {
	Target string `arg:"" name:"target" help:"Target to build" type:"target" default:"."`
}

func (l *List) Run(_ *kong.Context) error {
	log.Debug("Listing target in directory")

	rootDirectory, err := getPrjRoot()
	if err != nil {
		return err
	}

	result, err := nix.Instantiate(rootDirectory, l.Target, "_list")
	if err != nil {
		return err
	}

	fmt.Println(result)

	return err
}
