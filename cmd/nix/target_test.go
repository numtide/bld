package nix_test

import (
	"testing"

	"github.com/numtide/bld/nix"
	afero "github.com/spf13/afero"
	"github.com/stretchr/testify/require"
)

func TestTargetToAttr(t *testing.T) {
	FS := afero.NewMemMapFs()
	nix.AppFS = &afero.Afero{Fs: FS}
	err := nix.AppFS.MkdirAll("folder1/folder2", 0o755)
	require.NoError(t, err)

	tests := []struct {
		rootDirectory    string
		currentDirectory string
		target           string
		expectedPath     string
		expectedAttr     string
	}{
		{
			rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj", target: "pkg1",
			expectedPath: "", expectedAttr: "pkg1",
		},
		{
			rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj", target: "folder1",
			expectedPath: "/folder1", expectedAttr: "",
		},
		{
			rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj/folder1", target: "pkg1",
			expectedPath: "/folder1", expectedAttr: "pkg1",
		},
		{
			rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj", target: "folder1:pkg1",
			expectedPath: "/folder1", expectedAttr: "pkg1",
		},
		{
			rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj/folder1", target: "..:pkg1",
			expectedPath: "", expectedAttr: "pkg1",
		},
		{
			rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj/folder1", target: "..",
			expectedPath: "", expectedAttr: "",
		},
		{
			rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj", target: "folder1/folder2/attr",
			expectedPath: "/folder1/folder2", expectedAttr: "attr",
		},
		{
			rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj/folder1/folder2", target: "../attr",
			expectedPath: "/folder1", expectedAttr: "attr",
		},
	}
	for _, tt := range tests {
		path, attr, err := nix.TargetToAttr(tt.rootDirectory, tt.currentDirectory, tt.target)
		require.NoError(t, err)
		require.Equal(t, tt.expectedPath, path)
		require.Equal(t, tt.expectedAttr, attr)
	}
}

func TestTargetToPathAbsolute(t *testing.T) {
	tests := []struct {
		rootDirectory    string
		currentDirectory string
		target           string
		expectedPath     string
	}{
		{
			rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj", target: "/folder1",
			expectedPath: "/tmp/prj/folder1",
		},
		{
			rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj/folder1", target: "/folder1",
			expectedPath: "/tmp/prj/folder1",
		},
		{
			rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj/folder1", target: "//folder1",
			expectedPath: "/tmp/prj/folder1",
		},
		{
			rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj/folder1", target: "/",
			expectedPath: "/tmp/prj",
		},
		{
			rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj/folder1", target: "//",
			expectedPath: "/tmp/prj",
		},
	}
	for _, tt := range tests {
		path, err := nix.TargetToPath(tt.rootDirectory, tt.currentDirectory, tt.target)
		require.NoError(t, err)
		require.Equal(t, tt.expectedPath, path)
	}
}

func TestTargetToPathRelative(t *testing.T) {
	tests := []struct {
		rootDirectory    string
		currentDirectory string
		target           string
		expectedPath     string
	}{
		{rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj", target: "folder1", expectedPath: "/tmp/prj/folder1"},
		{rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj/folder1", target: "..", expectedPath: "/tmp/prj"},
		{rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj/folder1", target: "", expectedPath: "/tmp/prj/folder1"},
		{rootDirectory: "/tmp/prj", currentDirectory: "/tmp/prj/folder1", target: "...", expectedPath: "/tmp/prj"},
	}
	for _, tt := range tests {
		path, err := nix.TargetToPath(tt.rootDirectory, tt.currentDirectory, tt.target)
		require.NoError(t, err)
		require.Equal(t, tt.expectedPath, path)
	}
}
