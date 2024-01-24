package core

import (
	"context"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
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

type HttpLog struct {
	ID         primitive.ObjectID `bson:"_id,omitempty"`
	ReqDateStr string             `bson:"req_date_str,omitempty"`
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

		logrus.WithField("table", coll).Info("start clean table")

		const bundle = 1000

		for {
			result := db.Collection(coll).FindOne(context.Background(), filter, options.FindOne().SetSkip(bundle))

			var log HttpLog
			err := result.Decode(&log)
			if err == mongo.ErrNoDocuments {
				fmt.Println("Document not found")
				break
			} else if err != nil {
				logrus.WithField("table", coll).WithError(err).Info("failed to query table")
				break
			}

			_filter := bson.D{
				bson.E{
					Key: "_id",
					Value: bson.D{
						bson.E{
							Key:   "$lt",
							Value: log.ID,
						},
					}},
			}

			deleteResult, err := db.Collection(coll).DeleteMany(context.Background(), _filter, options.Delete())
			logrus.WithField("table", coll).WithField("count", deleteResult).WithError(err).Info("cleand table one bundle ")
		}
		logrus.WithField("table", coll).WithError(err).Info("clean table done")

		if err != nil {
			return err
		}
	}
	return nil
}
