package config

import (
	cfg "github.com/nft-rainbow/rainbow-settle/common/config"
)

type Config struct {
	DataRetentionDays int `yaml:"dataRetentionDays"`
	MongoDb           struct {
		Enabled bool   `yaml:"enabled"`
		Uri     string `yaml:"uri"`
	} `yaml:"mongoDb"`
	LogCleanPaths []string `yaml:"logCleanPaths"`
}

var (
	_config Config
)

func init() {
	InitByFile("./config.yaml")
}

func InitByFile(file string) {
	_config = *cfg.InitByFile[Config](file)
}

func Get() *Config {
	return &_config
}
