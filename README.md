# bld

bld is an experimental build tool for monorepos inspired by Bazel, and 
implemented with Nix. This is meant to evolve and its current form is not the
final one.

This tool has two sides: a CLI and a Nix library, that are meant to be able to
work together.

## Principles

We steal the notion of "targets" from Bazel, making each folder open-ended.

It should be possible to type `bld` in any folder and get the build output of
the current folder (and below?).

It should be possible to build any targets using purely `nix-build`.

## Usage

`$ bld --help`
```
Usage: bld <command>

Flags:
  -h, --help     Show context-sensitive help.
      --debug

Commands:
  build [<target>]
    Build target

  list [<target>]
    List available targets

  run [<target>]
    Run executable target

  inspect [<target>]
    Show build information about target

Run "bld <command> --help" for more information on a command.
```

The following examples are from this repository.


<details>
<summary>To list all targets.</summary>

`$ bld list`
```A
bin
default
devShell
hello
```
</details>

<details>
<summary>To build a target.</summary>

`$ bld build hello`
```
INFO[0000] Building target                               target=hello
/nix/store/9a74wmrh6l9h012xza53ff58v0rx456d-hello
```
</details>

<details>
<summary>To run a target.</summary>

`$ bld run hello`
```
/nix/store/9a74wmrh6l9h012xza53ff58v0rx456d-hello
Hello, world!
```
</details>

<details>
<summary>To inspect a target.</summary>

`$ bld inspect hello`
```
{
  "/nix/store/bn6wpa9yqibcy83d2iabh1s5k49lcpb7-hello.drv": {
    "args": [
      "-e",
      "/nix/store/9krlzvny65gdc8s7kpb6lkx8cd02c25b-default-builder.sh"
    ],
    "builder": "/nix/store/1b9p07z77phvv2hf6gm9f28syp39f1ag-bash-5.1-p16/bin/bash",
    "env": {
      "allowSubstitutes": "",
      "buildCommand": "target=$out'/bin/hello'\nmkdir -p \"$(dirname \"$target\")\"\n\nif [ -e \"$textPath\" ]; then\n  mv \"$textPath\" \"$target\"\nelse\n  echo -n \"$text\" > \"$target\"\nfi\n\neval \"$checkPhase\"\n\n(test -n \"$executable\" && chmod +x \"$target\") || true\n",
      "buildInputs": "",
      "builder": "/nix/store/1b9p07z77phvv2hf6gm9f28syp39f1ag-bash-5.1-p16/bin/bash",
      "checkPhase": "/nix/store/1b9p07z77phvv2hf6gm9f28syp39f1ag-bash-5.1-p16/bin/bash -n -O extglob \"$target\"\n",
      "cmakeFlags": "",
      "configureFlags": "",
      "depsBuildBuild": "",
      "depsBuildBuildPropagated": "",
      "depsBuildTarget": "",
      "depsBuildTargetPropagated": "",
      "depsHostHost": "",
      "depsHostHostPropagated": "",
      "depsTargetTarget": "",
      "depsTargetTargetPropagated": "",
      "doCheck": "",
      "doInstallCheck": "",
      "enableParallelBuilding": "1",
      "enableParallelChecking": "1",
      "executable": "1",
      "mesonFlags": "",
      "name": "hello",
      "nativeBuildInputs": "",
      "out": "/nix/store/9a74wmrh6l9h012xza53ff58v0rx456d-hello",
      "outputs": "out",
      "passAsFile": "buildCommand text",
      "patches": "",
      "preferLocalBuild": "1",
      "propagatedBuildInputs": "",
      "propagatedNativeBuildInputs": "",
      "stdenv": "/nix/store/p93ivxvrf3c2w02la2c6nppmkgdh08y3-stdenv-linux",
      "strictDeps": "",
      "system": "x86_64-linux",
      "text": "#!/nix/store/1b9p07z77phvv2hf6gm9f28syp39f1ag-bash-5.1-p16/bin/bash\n/nix/store/y4mxrg8c6l09lb2szl69vwl4f6441i5k-hello-2.12.1/bin/hello\n\n"
    },
    "inputDrvs": {
      "/nix/store/6pj63b323pn53gpw3l5kdh1rly55aj15-bash-5.1-p16.drv": [
        "out"
      ],
      "/nix/store/g6qkwa2xaq6i40cwl9bpjxi19m7q8121-hello-2.12.1.drv": [
        "out"
      ],
      "/nix/store/zq638s1j77mxzc52ql21l9ncl3qsjb2h-stdenv-linux.drv": [
        "out"
      ]
    },
    "inputSrcs": [
      "/nix/store/9krlzvny65gdc8s7kpb6lkx8cd02c25b-default-builder.sh"
    ],
    "outputs": {
      "out": {
        "path": "/nix/store/9a74wmrh6l9h012xza53ff58v0rx456d-hello"
      }
    },
    "system": "x86_64-linux"
  }
}
```
</details>


## Future ideas

* Resolve the targets purely with Nix. It should be necessary to connect the
  BUILD.nix files manually like currently.
* Snapshot nixpkgs. In order to speed-up nixpkgs, we want to be able to
  snapshot the build outputs that we are going to use.
* Add nix evaluation caching to speed-up builds.
* Introduce incremental rebuild Nix libraries for various languages.
* Hook in pre-processing tools. It should be possible to update a third-party
  package hash automatically.
