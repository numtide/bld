package main

import (
	"github.com/alecthomas/kong"
	nix "github.com/numtide/bld/nix"
	log "github.com/sirupsen/logrus"
)

type Inspect struct {
	Target string `arg:"" name:"target" help:"Target to inspect" type:"target" default:"."`
}

func (b *Inspect) Run(_ *kong.Context) error {
	log.WithFields(log.Fields{
		"target": b.Target,
	}).Debug("Inspect target")

	rootDirectory, err := getPrjRoot()
	if err != nil {
		return err
	}

	err = nix.Inspect(rootDirectory, b.Target)
	if err != nil {
		return err
	}

	return nil
}
