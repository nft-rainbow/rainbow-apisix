package core

type Cleaner interface {
	Clean() error
	Name() string
}
