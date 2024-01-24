package core

import (
	"context"
	"log"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type MongodbCleaner struct {
	Uri        string
	ExpireDate time.Time
}

var dbClient *mongo.Client

func (m *MongodbCleaner) GetDbClient() *mongo.Client {
	if dbClient != nil {
		return dbClient
	}

	if m.Uri == "" {
		log.Fatal("You must set 'mongoDbUri' in config file.")
	}

	client, err := mongo.Connect(context.TODO(), options.Client().ApplyURI(m.Uri))
	logrus.WithError(err).Info("connect to MongoDB")
	if err != nil {
		panic(err)
	}

	dbClient = client
	return dbClient
}

func (m *MongodbCleaner) Name() string {
	return "mongodb-cleaner"
}

func (m *MongodbCleaner) Clean() error {
	client := m.GetDbClient()
	db := client.Database("rainbow_services")

	colls, err := db.ListCollectionNames(context.Background(), bson.D{})
	if err != nil {
		return err
	}

	date := m.ExpireDate.Format(time.DateOnly)
	filter := bson.D{{"req_date_str", bson.D{{"$lt", date}}}}
	for _, coll := range colls {
		if !strings.HasPrefix(coll, "http_logs_") {
			continue
		}

		logrus.WithField("table", coll).WithError(err).Info("start clean table")
		result, err := db.Collection(coll).DeleteMany(context.Background(), filter)
		logrus.WithField("table", coll).WithField("count", result).WithError(err).Info("clean table done")
		if err != nil {
			return err
		}
	}
	return nil
}
