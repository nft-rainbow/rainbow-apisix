package core

import (
	"context"
	"log"
	"strings"
	"time"

	"github.com/sirupsen/logrus"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/event"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type MongodbCleaner struct {
	Uri            string
	ExpireDate     time.Time
	DeleteOneBatch int64
}

var dbClient *mongo.Client

func (m *MongodbCleaner) GetDbClient() *mongo.Client {
	if dbClient != nil {
		return dbClient
	}

	if m.Uri == "" {
		log.Fatal("You must set 'mongoDbUri' in config file.")
	}

	cmdMonitor := &event.CommandMonitor{
		Started: func(_ context.Context, evt *event.CommandStartedEvent) {
			log.Print(evt.Command)
		},
	}

	client, err := mongo.Connect(context.TODO(), options.Client().ApplyURI(m.Uri).SetMonitor(cmdMonitor))
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

	// date := m.ExpireDate.Format(time.DateOnly)
	// filter := bson.M{
	// 	"$or": []bson.M{
	// 		{"req_date_str": bson.M{"$lt": date}},      // req_date_str 小于 date
	// 		{"req_date_str": bson.M{"$exists": false}}, // 不包含 req_date_str
	// 	},
	// }

	filter := bson.M{
		"_id": bson.M{"$lt": primitive.NewObjectIDFromTimestamp(m.ExpireDate)},
	}

	for _, coll := range colls {
		if !strings.HasPrefix(coll, "http_logs_") {
			continue
		}

		logrus.WithField("table", coll).Info("start clean table")

		for {
			result := db.Collection(coll).FindOne(context.Background(), filter, options.FindOne().SetSkip(int64(m.DeleteOneBatch)))

			var log HttpLog
			err := result.Decode(&log)
			if err == mongo.ErrNoDocuments {
				break
			} else if err != nil {
				logrus.WithField("table", coll).WithError(err).Info("failed to query table")
				break
			}

			// logrus.WithField("last log id", log.ID).Info("find one")
			// break

			_filter := bson.M{
				"_id": bson.M{"$lte": log.ID},
			}

			deleteResult, err := db.Collection(coll).DeleteMany(context.Background(), _filter)
			logrus.WithField("table", coll).WithField("count", deleteResult).WithField("max ID", log.ID).WithError(err).Info("cleand table one batch")
		}
		logrus.WithField("table", coll).WithError(err).Info("clean table done")

		if err != nil {
			return err
		}
	}
	return nil
}
