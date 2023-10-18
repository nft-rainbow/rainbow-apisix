package resphandler

import (
	"bytes"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"github.com/apache/apisix-go-plugin-runner/cmd/go-runner/plugins/count"
	pkgHTTP "github.com/apache/apisix-go-plugin-runner/pkg/http"
	"github.com/apache/apisix-go-plugin-runner/pkg/log"
	"github.com/apache/apisix-go-plugin-runner/pkg/plugin"
	"github.com/nft-rainbow/rainbow-settle/common/constants"
	"github.com/nft-rainbow/rainbow-settle/common/redis"
	"github.com/openweb3/go-rpc-provider"
	"github.com/samber/lo"
)

func init() {
	err := plugin.RegisterPlugin(&RpcRespHandler{})
	if err != nil {
		log.Fatalf("failed to register plugin rpc-resp-handler: %s", err)
	}
}

// RpcRespHandler is a demo to show how to return data directly instead of proxying
// it to the upstream.
type RpcRespHandler struct {
	// Embed the default plugin here,
	// so that we don't need to reimplement all the methods.
	plugin.DefaultPlugin
}

type RpcRespHandlerConf struct {
}

func (p *RpcRespHandler) Name() string {
	return "rpc-resp-handler"
}

func (p *RpcRespHandler) ParseConf(in []byte) (interface{}, error) {
	conf := RpcRespHandlerConf{}
	err := json.Unmarshal(in, &conf)
	return conf, err
}

// TODO: 由于apisix在ResponseFilter中会丢失Content-Encoding Header，目前 Content-Encoding 为 gzip 时仅通过解压缩的方式正常返回，
// 正确的做法是用lua插件补上apisix丢失的该Header，或使用lua插件完成 ResponseFilter 的全部功能（最佳）。
func (c *RpcRespHandler) ResponseFilter(conf interface{}, w pkgHTTP.Response) {

	// NOTE: 这里置count是由于 1.apisix ext-plugin-post-resp 不支持多个 2.status ok，而rpc返回错误的不扣费
	c.determineCount(w)

	body, err := readDecompressedBody(w)
	if err != nil {
		log.Errorf("failed to read decompressed resp body: %v", err)
		return
	}

	log.Infof("in rpc-resp-handler response filter, status code: %d", w.StatusCode())
	if w.StatusCode() < http.StatusBadRequest {
		log.Infof("apisix response header: %v\n", w.Header())
		if _, err := w.Write(body); err != nil {
			log.Infof("failed to write response body: %v", err)
		}
		return
	}
	// log.Infof("aaa")
	reqId := w.Header().Get(constants.RAINBOW_REQUEST_ID_HEADER_KEY)
	rpcIdsInfo, err := redis.GetRpcIdsInfo(reqId)
	if err != nil {
		log.Errorf("failed to get rpc ids from redis: %v", err)
		return
	}
	// log.Infof("bbb")

	rpcResps := lo.Map(rpcIdsInfo.Items, func(item *redis.RpcInfoItem, index int) rpc.JsonRpcMessage {
		return rpc.JsonRpcMessage{
			Version: item.RpcVersion,
			ID:      json.RawMessage(item.RpcId),
			Error: &rpc.JsonError{
				Code:    -32001,
				Message: string(body),
			},
		}
	})

	w.WriteHeader(http.StatusOK)
	if rpcIdsInfo.IsBatchRpc {
		newResp, _ := json.Marshal(rpcResps)
		w.Write(newResp)
		return
	} else {
		newResp, _ := json.Marshal(rpcResps[0])
		w.Write(newResp)
	}
	// log.Infof("ddd")
}

func (c *RpcRespHandler) determineCount(w pkgHTTP.Response) {
	count.DeterminCount(w, func(w pkgHTTP.Response) int {
		if w.StatusCode() != http.StatusOK {
			return 0
		}

		body, err := readDecompressedBody(w)
		if err != nil {
			log.Errorf("failed to read decompressed body: %v", err)
			return 0
		}

		var successCount int
		var resps []*rpc.JsonRpcMessage
		if err := json.Unmarshal(body, &resps); err == nil {
			successCount = len(lo.Filter(resps, func(item *rpc.JsonRpcMessage, index int) bool {
				return item.Error == nil
			}))
			return successCount
		}

		var resp rpc.JsonRpcMessage
		if err = json.Unmarshal(body, &resp); err != nil {
			log.Infof("failed unmarshal rpc response: %v", err)
			return 0
		}
		if resp.Error != nil {
			return 0
		}
		return 1
	})
}

func readDecompressedBody(w pkgHTTP.Response) ([]byte, error) {
	rawBody, err := w.ReadBody()
	if err != nil {
		return nil, fmt.Errorf("failed to read body: %v", err)
	}
	// var body []byte
	var reader io.Reader = bytes.NewReader(rawBody)
	encoding := w.Header().Get("Content-Encoding")
	if encoding == "gzip" {
		reader, err = gzip.NewReader(reader)
		if err != nil {
			return nil, fmt.Errorf("failed to new gzip reader: %v", err)
		}
	}
	// log.Infof("ccc")
	body, err := io.ReadAll(reader)
	if err != nil {
		return nil, fmt.Errorf("failed to read body: %v", err)
	}
	return body, nil
}
