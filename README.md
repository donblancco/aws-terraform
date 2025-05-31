# aws-terraform

このリポジトリには、don-blanc-co.com ドメインを使ってWebサイトをホスティングするためのAWS基盤（S3 + CloudFront + ACM + Route 53）をTerraformで構築するコードが含まれています。

## 構成概要
- **S3バケット**：Reactアプリ（build ディレクトリ）の静的ホスティング、およびポートフォリオ用静的サイトのホスティング
- **CloudFront**：CDN（コンテンツ配信）＋HTTPS化(ACM証明書)＋OAIによるアクセス制御
- **ACM (AWS Certificate Manager)**：don-blanc-co.com および www.don-blanc-co.com で使用するSSL/TLS証明書の取得（DNS検証）
- **Route 53**：ドメインのホストゾーン管理およびCloudFrontへのAliasレコード登録
- **バケットポリシー**：CloudFront OAIからのみS3コンテンツを取得できるように制限
- **パブリックアクセスブロック**：S3バケットへの直接アクセスを最小限にする制御

## 前提条件
1. **Terraform** (v1.x 以上) がインストール済みであること
2. **AWS CLI** の設定が完了しており、デフォルトリージョンが `ap-northeast-1` に設定されていること
3. Terraform 用 IAM ユーザー(`terraform-user`)に適切な権限が付与されていること
4. ドメイン を取得済みであること

## ディレクトリ構成
```
.
├── main.tf                 # S3 + CloudFront + OAI + バケットポリシー のTerraformコード
├── acm_route53.tf          # ACM証明書取得（DNS検証）および Route53 Alias レコード のTerraformコード
├── variables.tf            # 変数定義
├── terraform.tfvars        # 変数に値を設定（環境ごとに上書き可能）
├── .gitignore              # Terraform状態ファイルなどを除外設定
└── README.md               # このファイル
```

## 使用方法

### 1. リポジトリをクローン
```bash
git clone https://github.com/donblancco/aws-terraform.git
cd aws-terraform
```

### 1.5. 変数の設定
`terraform.tfvars` ファイルに環境ごとの変数値を設定してください。例:
```
aws_region                        = "ap-northeast-1"
bucket_name                       = "ソースコードを配置したバケット名"
domain_name                       = "don-blanc-co.com"
alternate_domain_name             = "www.don-blanc-co.com"
certificate_subject_alternative_names = ["www.don-blanc-co.com"]
```

### 2. Terraform の初期化
Terraform プロジェクトを初期化して、必要なプロバイダプラグインをダウンロードします。
```bash
terraform init
```
変数は `variables.tf` と `terraform.tfvars` を使って管理されています。


### 3. Terraform の実行
以下を実行して AWS インフラを一気に構築します。

```bash
terraform apply
```
Terraform は以下を順に実行します：
1. **S3バケット作成**
2. **Public Access Block + バケットポリシー設定**
3. **CloudFront OAI 作成**
4. **ACM証明書リクエスト（DNS検証用CNAMEレコード自動登録）**
5. **DNS検証完了後に ACM 証明書発行**
6. **CloudFrontデフォルトディストリビューションにACM証明書とAliasを設定**
7. **Route 53 に Aレコード（Alias）で CloudFront を向ける**

以上が完了すると、`don-blanc-co.com` および `www.don-blanc-co.com` で HTTPS 接続が有効なWebサイトが公開されます。


### 4. 出力されたサイトURLの確認
Terraform 実行後、以下コマンドで CloudFront のドメイン名を確認できます。

```bash
terraform output site_url
```
例:
```
dkz59juhsa6rl.cloudfront.net
```
しばらく待つと、`https://don-blanc-co.com/` が 配信するようになります。

### 5. 後片付け (リソース削除)
テスト目的や不要になった場合は、以下のコマンドで作成した AWS リソースをすべて削除できます。

```bash
terraform destroy
```
対話形式で `yes` と入力すると削除が完了します。

## カスタマイズ例
- バケット名やリージョンを変更したい場合は、`main.tf` 内の `bucket` パラメータや `provider "aws"` の `region` を編集してください。
- CloudFront のビヘイビア設定やキャッシュポリシーを変更する場合は、`aws_cloudfront_distribution` リソースブロックを調整。
- React とポートフォリオの両方を同一バケット内でホスティングする場合は、CloudFront の `ordered_cache_behavior` でパスごとにオリジンを切り替えできます（詳細は README の該当セクション参照）。

## 注意事項
- **バケット名の一意性**：S3 バケット名はグローバルに一意である必要があります。他の AWS アカウントやリージョンで同じ名前が使われているとエラーになります。
- **ネームサーバ変更の反映**：レジストラでのネームサーバ更新は DNS TTL によって最大数時間かかることがあります。変更後は `dig NS don-blanc-co.com` などで確認してください。
- **CloudFront 反映待ち**：CloudFront 設定変更の反映には数分かかる場合があります。すぐに独自ドメインでサイトが表示されなくても慌てず待機してください。
- **IAM 権限**：Terraform 用ユーザーには S3, CloudFront, ACM, Route53 の操作に必要な権限が付与されていることを確認してください。
- **Terraform Lock ファイル**：このリポジトリには `.terraform.lock.hcl` を含めているため、プロバイダバージョンが固定され、環境間の再現性が確保されます。

## 参考
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [AWS Certificate Manager – ACM](https://docs.aws.amazon.com/acm/latest/userguide/ca-overview.html)
- [Create a Distribution by Using the CloudFront Console](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-creating-console.html)
- [How do I configure Amazon S3 static website hosting with CloudFront?](https://aws.amazon.com/premiumsupport/knowledge-center/cloudfront-serve-static-website/)
- [Hosting a Single-Page App (SPA) on Amazon S3 and CloudFront](https://aws.amazon.com/jp/blogs/compute/serving-a-single-page-application-with-amazon-s3-and-amazon-cloudfront/)