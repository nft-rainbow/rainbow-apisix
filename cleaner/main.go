package main

import (
	"time"

	"github.com/nft-rainbow/conflux-gin-helper/logger"
	"github.com/nft-rainbow/rainbow-apisix/cleaner/config"
	"github.com/nft-rainbow/rainbow-apisix/cleaner/core"
	"github.com/sirupsen/logrus"
)

func init() {
	logger.Init(logger.LogConfig{
		Folder: "./.log",
		Level:  "info",
		Format: "json",
	}, "==== Cleaner ====")
}

func main() {
	logrus.Info("start clean...")
	expireDate := time.Now().Add(-1 * time.Duration(config.Get().DataRetentionDays) * time.Hour * 24)

	var cleaners []core.Cleaner

	if config.Get().MongoDb.Enabled {
		cleaners = append(cleaners, &core.MongodbCleaner{
			Uri:            config.Get().MongoDb.Uri,
			ExpireDate:     expireDate,
			DeleteOneBatch: config.Get().MongoDb.DeleteOneBatch,
		})
	}

	for _, logPath := range config.Get().LogCleanPaths {
		cleaners = append(cleaners, &core.LogCleaner{
			ExpireDate: expireDate,
			FolderPath: logPath,
		})
	}

	logrus.WithField("cleaners len: ", len(cleaners)).Info("gen cleaners")

	for _, c := range cleaners {
		logrus.WithField("cleaner", c.Name()).Info("start clean")
		err := c.Clean()
		logrus.WithField("cleaner", c.Name()).WithField("expire date", expireDate).WithError(err).Info("cleaned completed")
	}

	logrus.Info("clean done!")
}
