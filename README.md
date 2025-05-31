# aws-terraform

このリポジトリには、donblanccoのWebサイトをホスティングするためのAWS基盤（S3 + CloudFront）をTerraformで構築するコードが含まれています。

## 構成概要
- **S3バケット**：静的ウェブサイトホスティング
- **CloudFront**：CDN、およびHTTPSリダイレクト設定
- **OAI (Origin Access Identity)**：CloudFront経由のみでS3にアクセスさせるためのセキュリティ制御
- **バケットポリシー**：公開読み取り権限を付与
- **パブリックアクセスブロック**：S3バケットへの直接アクセスを制限

## 前提条件
1. **Terraform** (v1.x 以上) がインストール済みであること
2. **AWS CLI** の設定が完了しており、デフォルトリージョンが `ap-northeast-1` に設定されていること
3. AWSアカウントに対して `terraform apply` 実行可能なアクセス権限を持つIAMユーザーまたはロールを使用していること
4. リポジトリをクローン済みであること（以下の手順を参照）

## 使用方法

### 1. リポジトリをクローン
```bash
git clone https://github.com/donblancco/aws-terraform.git
cd aws-terraform
```

### 2. Terraform の初期化
Terraform プロジェクトを初期化して、必要なプロバイダプラグインをダウンロードします。
```bash
terraform init
```

### 3. プランの確認
実際にAWSに適用される変更内容を確認します。
```bash
terraform plan
```

### 4. インフラの作成
プランを確認後、以下コマンドでインフラを作成します。
対話形式で `yes` と入力するとリソースが作成されます。
```bash
terraform apply
```

### 5. 出力されたサイトURLの確認
リソース作成後、下記コマンドでCloudFrontディストリビューションのドメイン名（サイトURL）を取得できます。
```bash
terraform output site_url
```

例:
```
d1234abcdef8.cloudfront.net
```

### 6. 静的コンテンツのデプロイ
静的サイトのコンテンツ（例: `index.html`, `error.html`, CSS/JSファイルなど）をローカルで用意し、以下コマンドでS3バケットに同期します。
```bash
aws s3 sync ./site-content s3://couple-sideproject-site
```
- `site-content` フォルダを作成して、静的ファイルを配置してください。
- S3バケット名（デフォルト: `couple-sideproject-site`）は必要に応じて `main.tf` 内で変更し、同時にコマンド内でも適切に置き換えてください。

### 7. 後片付け (リソース削除)
テスト目的や不要になった場合は、以下のコマンドで作成したAWSリソースをすべて削除できます。
```bash
terraform destroy
```
対話形式で `yes` と入力すると削除が完了します。

## カスタマイズ例
- バケット名やリージョンを変更したい場合は、`main.tf` 内の `bucket` パラメータや `provider "aws"` の `region` を編集してください。
- CloudFront のビヘイビア設定やキャッシュポリシーを変更する場合は、`aws_cloudfront_distribution` リソースブロックを調整します。

## 注意事項
- **バケット名の一意性**：S3バケット名はグローバルに一意である必要があります。他のAWSアカウントやリージョンで同じ名前が使われているとエラーになります。
- **リージョン設定**：このサンプルでは `ap-northeast-1` を使用していますが、必要に応じて変更可能です。
- **CloudFront 反映待ち**：CloudFront への変更適用には数分かかる場合があります。出力されたドメイン名がすぐに有効にならないことがありますのでご注意ください。

## リポジトリ構成
```
.
├── main.tf            # S3 + CloudFront 構成のTerraformコード
├── README.md          # このファイル
└── .gitignore         # Terraform の状態ファイルなどを除外設定
```

## 参考
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [Creating a Static Website Using a Custom Domain Name](https://docs.aws.amazon.com/AmazonS3/latest/userguide/WebsiteHosting.html)
- [Configuring a CloudFront Origin for Amazon S3](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/DownloadDistS3AndCustomOrigins.html)