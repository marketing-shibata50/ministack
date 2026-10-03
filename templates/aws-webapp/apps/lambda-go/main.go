package main

import (
	"context"
	"encoding/json"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handler(ctx context.Context, req events.APIGatewayV2HTTPRequest) (events.APIGatewayV2HTTPResponse, error) {
	body, _ := json.Marshal(map[string]string{
		"lang":          "go",
		"path":          req.RawPath,
		"db_host":       os.Getenv("DB_HOST"),
		"assets_bucket": os.Getenv("ASSETS_BUCKET"),
	})
	return events.APIGatewayV2HTTPResponse{
		StatusCode: 200,
		Headers:    map[string]string{"content-type": "application/json"},
		Body:       string(body),
	}, nil
}

func main() { lambda.Start(handler) }
