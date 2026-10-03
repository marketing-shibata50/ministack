# aws-webapp（MK2 用 AWS Web サービス雛形）

会社の AWS に出す Web サービスを、**MK2（Ubuntu）上の MiniStack で先に組んで動かす**ための雛形。
同じ Terraform を `ENV=local`（MiniStack）→ `ENV=prod`（会社 AWS）で切り替えるだけ。

```
              ┌──────────── app_stack（local / prod 共通）────────────┐
 API Gateway ─┤ Lambda (python | node | go)                           │
 ALB ─────────┤ ECS Fargate (Dockerfile なら言語自由) ← ECR           │
              │ RDS PostgreSQL + Secrets Manager / S3 / VPC          │
              └──────────────────────────────────────────────────────┘
```

## 必要なもの（MK2）
`docker` / `docker compose` / `terraform >= 1.6` / `jq` / `aws` CLI / （Go を使う時だけ）`go`

## 最短手順
```bash
make up                    # MiniStack 起動（127.0.0.1:4566、外部非公開）
make apply                 # 全部作る（Lambda は Python）
make smoke                 # API→Lambda / ALB→ECS 疎通
make db-check              # RDS(PostgreSQL) 接続確認
make destroy               # 片付け
```
Lambda の言語切替: `make apply LANG_=node` / `make apply LANG_=go`
片方だけ使う: `terraform -chdir=infra/envs/local apply -var enable_container=false`

## 自分のアプリに差し替える
| 置き場所 | 条件 |
|---|---|
| `apps/lambda-python/` `apps/lambda-node/` `apps/lambda-go/` | API Gateway HTTP API (payload v2) のイベントを受けて返す |
| `apps/container/` | `Dockerfile` があること・`PORT`(8080) で待受・`/health` が 200 |

アプリには環境変数 `DB_SECRET_ARN` `DB_HOST` `DB_PORT` `DB_NAME` `ASSETS_BUCKET` が渡る。
DB のユーザー/パスワードは Secrets Manager（`<name>/db`）から取得する。

## 会社の AWS へ
```bash
# ~/.aws/config に profile "company" を用意しておく
make apply ENV=prod        # ECR 作成 → イメージ build & push → 全構成作成
```
- チーム運用なら `infra/envs/prod/main.tf` の `backend "s3"` を有効化して state を S3 に置く
- 本番で追加検討: HTTPS（ACM + ALB 443）、独自ドメイン（Route53）、Lambda の VPC 接続、RDS の Multi-AZ・バックアップ

## MiniStack で確認できる範囲
| 項目 | local | prod で要確認 |
|---|---|---|
| Terraform 定義・依存関係 | ✅ | |
| API→Lambda / ALB→ECS / RDS 接続 | ✅（実コンテナで動く） | |
| IAM 権限の過不足 | △（`AUTH=true` で強制可） | ✅ |
| ドメイン・HTTPS・性能・料金 | ❌ | ✅ |

## 補足
- 署名なしの curl は `MINISTACK_REGION`（compose で `ap-northeast-1`）のリソースを見る
- local のデータ・DB は `docker compose down -v` で全消去
