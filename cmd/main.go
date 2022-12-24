package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/alecthomas/kong"
	log "github.com/sirupsen/logrus"
)

//nolint:gochecknoglobals
var cli struct {
	Debug   bool
	Build   Build   `kong:"cmd,name='build',help='Build target',default='withargs'"`
	List    List    `kong:"cmd,name='list',help='List available targets'"`
	Run     Run     `kong:"cmd,name='run',help='Run executable target'"`
	Inspect Inspect `kong:"cmd,name='inspect',help='Show build information about target'"`
}

func getPrjRoot() (string, error) {
	if prjRoot := os.Getenv("PRJ_ROOT"); prjRoot != "" {
		return prjRoot, nil
	}

	cmdOut, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		errorMessage := fmt.Sprintf(
			"Error looking project root directory %s", err.Error(),
		)

		return "", errors.New(errorMessage)
	}

	return strings.TrimSpace(string(cmdOut)), nil
}

func die(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
}

func main() {
	parser, err := kong.New(&cli)
	if err != nil {
		die(err)
	}

	ctx, err := parser.Parse(os.Args[1:])
	if err != nil {
		die(err)
	}

	if cli.Debug {
		log.SetLevel(log.DebugLevel)
	}

	// Call the Run() method of the selected parsed command.
	err = ctx.Run()

	ctx.FatalIfErrorf(err)
}
