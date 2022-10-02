package nix

import (
	"errors"
	"fmt"
	"path/filepath"
	"strings"

	log "github.com/sirupsen/logrus"
	afero "github.com/spf13/afero"
)

//nolint:gochecknoglobals
var (
	FS    afero.Fs     = afero.NewOsFs()
	AppFS *afero.Afero = &afero.Afero{Fs: FS}
)

func TargetToPath(rootDirectory string, currentDirectory string, target string) (path string, err error) {
	log.WithFields(log.Fields{"target": target}).Debug("targetToPath")

	if target == "..." {
		return rootDirectory, nil
	}

	if strings.HasPrefix(target, "/") {
		currentDirectory = rootDirectory
	}

	path, err = filepath.Abs(filepath.Join(currentDirectory, target))
	if err != nil {
		errorMessage := fmt.Sprintf(
			"Error looking for current absolute path %s", err.Error(),
		)

		return "", errors.New(errorMessage)
	}

	log.WithFields(log.Fields{"target": target, "path": path}).Debug("targetToPath other")

	return path, nil
}

func pathExists(path string) bool {
	_, err := AppFS.Stat(path)

	return err == nil
}

func TargetToAttr(rootDirectory string, currentDirectory string, target string) (path string, attr string, err error) {
	pathAndTarget := strings.Split(target, ":")
	switch len(pathAndTarget) {
	case 1:
		switch target = pathAndTarget[0]; {
		case target == "...":
			path = target
		case pathExists(target):
			{
				path = target
			}
		case pathExists(filepath.Dir(target)):
			{
				path, attr = filepath.Split(target)
			}
		default:
			attr = target
		}
	case 2:
		path = pathAndTarget[0]
		attr = pathAndTarget[1]
	default:
		return "", "", errors.New("unable to parse target")
	}

	log.WithFields(log.Fields{"target": target}).Debug("targetToAttr")

	path, err = TargetToPath(rootDirectory, currentDirectory, path)
	if err != nil {
		return "", "", err
	}

	pathRelativeToRoot := strings.Replace(path, rootDirectory, "", -1)

	log.WithFields(log.Fields{"relativePathToRoot": pathRelativeToRoot, "attr": attr}).Debug("targetToAttr")

	return pathRelativeToRoot, attr, nil
}
