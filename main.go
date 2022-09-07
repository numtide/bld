package main

import (
	"context"
	_ "embed"
	"fmt"
	"os"
	"runtime"
	"strings"
	"time"

	"mvdan.cc/sh/v3/expand"
	"mvdan.cc/sh/v3/interp"
	"mvdan.cc/sh/v3/syntax"
)

//go:embed bld.sh
var src string

// FIXME: add more goarch and goos
var goarch2ostype = map[string]string{
	"amd64": "x86_64",
}
var goos2hosttype = map[string]string{
	"linux": "linux-gnu",
}

func run(args []string) error {
	file, err := syntax.NewParser().Parse(strings.NewReader(src), "bld.sh")
	if err != nil {
		return err
	}

	exec := func(ctx context.Context, args []string) error {
		hc := interp.HandlerCtx(ctx)

		// Override show_help so it works
		if args[0] == "show_help" {
			fmt.Fprintln(hc.Stdout, strings.Split(src, "\n")[2])
			return nil
		}

		return interp.DefaultExecHandler(2000*time.Second)(ctx, args)
	}

	runner, err := interp.New(
		interp.ExecHandler(exec),
		interp.Env(expand.ListEnviron(append(
			os.Environ(),
			// TODO: port this to upstream
			"HOSTTYPE="+goos2hosttype[runtime.GOOS],
			"OSTYPE="+goarch2ostype[runtime.GOARCH],
		)...)),
		interp.Params(args...),
		interp.StdIO(os.Stdin, os.Stdout, os.Stdout),
	)
	if err != nil {
		return err
	}
	return runner.Run(context.Background(), file)
}

func main() {
	err := run(os.Args)
	if err != nil {
		fmt.Errorf("error: %w", err)
		os.Exit(1)
	}
}
