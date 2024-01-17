package core

import (
	"os"
	"path/filepath"
	"time"

	"github.com/sirupsen/logrus"
)

type LogCleaner struct {
	FolderPath string
	ExpireDate time.Time
}

func (l *LogCleaner) Name() string {
	return l.FolderPath
}

// clean log
func (l *LogCleaner) Clean() error {
	return filepath.Walk(l.FolderPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() {
			return nil
		}
		if info.ModTime().Before(l.ExpireDate) {
			err := os.Remove(path)
			logrus.WithField("file", info.Name()).WithError(err).Info("remove file")
		}
		return nil
	})
}
