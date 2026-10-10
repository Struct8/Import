terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/CovidDataLake/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

### CATEGORY: IAM ###

data "aws_iam_policy_document" "glue_crawler_covid-bronze-crawler_st_CovidDataLake_doc" {
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [aws_s3_bucket.covid-bronze.arn]
  }
  statement {
    sid       = "AllowObjectCRUD"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.covid-bronze.arn}/*"]
  }
}

resource "aws_iam_policy" "glue_crawler_covid-bronze-crawler_st_CovidDataLake" {
  name        = "glue_crawler_covid-bronze-crawler_st_CovidDataLake"
  description = "Access Policy for covid-bronze-crawler"
  policy      = data.aws_iam_policy_document.glue_crawler_covid-bronze-crawler_st_CovidDataLake_doc.json
}

data "aws_iam_policy_document" "glue_job_covid-csv-to-parquet_st_CovidDataLake_doc" {
  statement {
    sid       = "AllowBucketLevelActions"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [aws_s3_bucket.covid-bronze.arn]
  }
  statement {
    sid       = "AllowObjectCRUD"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.covid-bronze.arn}/*"]
  }
  statement {
    sid       = "AllowBucketLevelActions1"
    effect    = "Allow"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [aws_s3_bucket.covid-scripts.arn]
  }
  statement {
    sid       = "AllowObjectCRUD1"
    effect    = "Allow"
    actions   = ["s3:DeleteObject", "s3:GetObject", "s3:PutObject"]
    resources = ["${aws_s3_bucket.covid-scripts.arn}/*"]
  }
}

resource "aws_iam_policy" "glue_job_covid-csv-to-parquet_st_CovidDataLake" {
  name        = "glue_job_covid-csv-to-parquet_st_CovidDataLake"
  description = "Access Policy for covid-csv-to-parquet"
  policy      = data.aws_iam_policy_document.glue_job_covid-csv-to-parquet_st_CovidDataLake_doc.json
}

resource "aws_iam_role" "covid-bronze-crawler_role" {
  name = "covid-bronze-crawler_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "glue.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "covid-bronze-crawler_role"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "covid-csv-to-parquet_role" {
  name = "covid-csv-to-parquet_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "glue.amazonaws.com"
      }
    }
  ]
})
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
  tags = {
    Name           = "covid-csv-to-parquet_role"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_role" "covid-lake-settings_role" {
  name = "covid-lake-settings_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lakeformation.amazonaws.com"
      }
    }
  ]
})
  description           = "Administrador do Lake Formation: registra os locais e concede as permissoes."
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
}

resource "aws_iam_role" "covid-select-silver_role" {
  name = "covid-select-silver_role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Effect": "Allow",
      "Principal": {
        "Service": "lakeformation.amazonaws.com"
      }
    }
  ]
})
  description           = "Papel que consulta o data lake pelo Athena e pelo QuickSight, com acesso concedido pelo Lake Formation."
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
}

resource "aws_iam_role_policy_attachment" "glue_crawler_covid-bronze-crawler_st_CovidDataLake_attach" {
  policy_arn = aws_iam_policy.glue_crawler_covid-bronze-crawler_st_CovidDataLake.arn
  role       = aws_iam_role.covid-bronze-crawler_role.name
}

resource "aws_iam_role_policy_attachment" "glue_job_covid-csv-to-parquet_st_CovidDataLake_attach" {
  policy_arn = aws_iam_policy.glue_job_covid-csv-to-parquet_st_CovidDataLake.arn
  role       = aws_iam_role.covid-csv-to-parquet_role.name
}




### CATEGORY: STORAGE ###

resource "aws_s3_bucket" "covid-athena-results" {
  bucket              = "struct8-covid-athena-results-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "covid-athena-results"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket" "covid-bronze" {
  bucket              = "struct8-covid-bronze-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "covid-bronze"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket" "covid-scripts" {
  bucket              = "struct8-covid-scripts-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "covid-scripts"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket" "covid-silver" {
  bucket              = "struct8-covid-silver-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
  bucket_namespace    = "account-regional"
  force_destroy       = true
  object_lock_enabled = false
  tags = {
    Name           = "covid-silver"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_bucket_ownership_controls" "covid-athena-results_controls" {
  bucket = aws_s3_bucket.covid-athena-results.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "covid-bronze_controls" {
  bucket = aws_s3_bucket.covid-bronze.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "covid-scripts_controls" {
  bucket = aws_s3_bucket.covid-scripts.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_ownership_controls" "covid-silver_controls" {
  bucket = aws_s3_bucket.covid-silver.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "covid-athena-results_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.covid-athena-results.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "covid-bronze_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.covid-bronze.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "covid-scripts_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.covid-scripts.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "covid-silver_block" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.covid-silver.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "covid-athena-results_configuration" {
  bucket = aws_s3_bucket.covid-athena-results.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "covid-bronze_configuration" {
  bucket = aws_s3_bucket.covid-bronze.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "covid-scripts_configuration" {
  bucket = aws_s3_bucket.covid-scripts.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "covid-silver_configuration" {
  bucket = aws_s3_bucket.covid-silver.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "covid-athena-results_versioning" {
  bucket = aws_s3_bucket.covid-athena-results.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_bucket_versioning" "covid-bronze_versioning" {
  bucket = aws_s3_bucket.covid-bronze.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_bucket_versioning" "covid-scripts_versioning" {
  bucket = aws_s3_bucket.covid-scripts.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_bucket_versioning" "covid-silver_versioning" {
  bucket = aws_s3_bucket.covid-silver.id
  versioning_configuration {
    mfa_delete = "Disabled"
    status     = "Suspended"
  }
}

resource "aws_s3_object" "covid-confirmed-csv" {
  source       = "${path.module}/.external_modules/struct8-templates/templates/basic-analytics-lab/v1/covid19/time_series_covid19_confirmed_global.csv"
  bucket       = aws_s3_bucket.covid-bronze.bucket
  content_type = "text/csv"
  etag         = filemd5("${path.module}/.external_modules/struct8-templates/templates/basic-analytics-lab/v1/covid19/time_series_covid19_confirmed_global.csv")
  key          = "covid19/confirmed/time_series_covid19_confirmed_global.csv"
  tags = {
    Name           = "covid-confirmed-csv"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_object" "covid-deaths-csv" {
  source       = "${path.module}/.external_modules/struct8-templates/templates/basic-analytics-lab/v1/covid19/time_series_covid19_deaths_global.csv"
  bucket       = aws_s3_bucket.covid-bronze.bucket
  content_type = "text/csv"
  etag         = filemd5("${path.module}/.external_modules/struct8-templates/templates/basic-analytics-lab/v1/covid19/time_series_covid19_deaths_global.csv")
  key          = "covid19/deaths/time_series_covid19_deaths_global.csv"
  tags = {
    Name           = "covid-deaths-csv"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_s3_object" "covid-etl-script" {
  source       = "${path.module}/.external_modules/struct8-templates/templates/basic-analytics-lab/v1/covid19/covid_csv_to_parquet.py"
  bucket       = aws_s3_bucket.covid-scripts.bucket
  content_type = "text/x-python"
  etag         = filemd5("${path.module}/.external_modules/struct8-templates/templates/basic-analytics-lab/v1/covid19/covid_csv_to_parquet.py")
  key          = "glue/covid_csv_to_parquet.py"
  tags = {
    Name           = "covid-etl-script"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
}




### CATEGORY: ANALYTICS ###

resource "aws_glue_catalog_database" "covid_db" {
  name        = "covid_db"
  description = "Glue Data Catalog database for the COVID-19 lake. It holds the bronze tables the crawler registers and the silver table that Athena and QuickSight read."
  tags = {
    Name           = "covid_db"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_glue_catalog_table" "silver_covid_global" {
  database_name = aws_glue_catalog_database.covid_db.name
  name          = "silver_covid_global"
  description   = "Curated COVID-19 series with cumulative confirmed cases and deaths per country and date. Stored as Parquet in the silver bucket and partitioned by report_date. This is the table Athena and QuickSight read."
  retention     = 0
  table_type    = "EXTERNAL_TABLE"
  partition_keys {
    name    = "report_date"
    comment = "Report date, in YYYY-MM-DD format."
    type    = "string"
  }
  storage_descriptor {
    compressed                = false
    input_format              = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    location                  = "s3://struct8-covid-silver/covid19/"
    number_of_buckets         = 0
    output_format             = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"
    stored_as_sub_directories = false
    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }
  }
  view_definition {
    view_version_id = 0
    is_protected    = false
    refresh_seconds = 0
  }
}

resource "aws_glue_crawler" "covid-bronze-crawler" {
  database_name = aws_glue_catalog_database.covid_db.name
  name          = "covid-bronze-crawler"
  description   = "Scans the raw CSV files in the bronze bucket every day at 05:00 UTC and registers them in the Glue Data Catalog under the bronze_ table prefix. Its successful completion is what starts the ETL job."
  role          = aws_iam_role.covid-bronze-crawler_role.arn
  schedule      = "cron(0 5 * * ? *)"
  table_prefix  = "bronze_"
  lake_formation_configuration {
    use_lake_formation_credentials = false
  }
  s3_target {
    path = "s3://struct8-covid-bronze/covid19/"
  }
  tags = {
    Name           = "covid-bronze-crawler"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.glue_crawler_covid-bronze-crawler_st_CovidDataLake_attach]
}

resource "aws_glue_job" "covid-csv-to-parquet" {
  name                    = "covid-csv-to-parquet"
  description             = "PySpark job that reads the raw COVID-19 CSV files from the bronze bucket, turns the wide date columns into one row per date, and writes Parquet partitioned by report_date to the silver bucket. The two paths arrive as the --BRONZE_PATH and --SILVER_PATH job arguments."
  glue_version            = "5.0"
  job_mode                = "SCRIPT"
  job_run_queuing_enabled = false
  number_of_workers       = 2
  role_arn                = aws_iam_role.covid-csv-to-parquet_role.arn
  timeout                 = 60
  worker_type             = "G.1X"
  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://struct8-covid-scripts/glue/covid_csv_to_parquet.py"
  }
  default_arguments = {
    "--BRONZE_PATH"    = "s3://struct8-covid-bronze/covid19"
    "--SILVER_PATH"    = "s3://struct8-covid-silver/covid19"
    "--job-language"   = "python"
    "--enable-metrics" = true
  }
  tags = {
    Name           = "covid-csv-to-parquet"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
  depends_on = [aws_iam_role_policy_attachment.glue_job_covid-csv-to-parquet_st_CovidDataLake_attach]
}

resource "aws_glue_trigger" "covid-etl-trigger" {
  name = "covid-etl-trigger"
  actions {
    job_name = aws_glue_job.covid-csv-to-parquet.name
  }
  actions {
    crawler_name = aws_glue_crawler.covid-bronze-crawler.name
  }
  description       = "Starts the ETL job when the bronze crawler finishes successfully. It is a conditional trigger with no schedule of its own, so the pipeline advances whenever the crawler runs."
  start_on_creation = false
  type              = "CONDITIONAL"
  predicate {
    conditions {
      crawl_state      = "SUCCEEDED"
      logical_operator = "EQUALS"
      state            = "SUCCEEDED"
    }
  }
  tags = {
    Name           = "covid-etl-trigger"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_athena_named_query" "brazil-weekly-new-cases" {
  name        = "brazil-weekly-new-cases"
  database    = aws_glue_catalog_database.covid_db.name
  description = "Weekly new confirmed cases in Brazil. The source series is cumulative, so each week is reported as the difference between its highest and lowest total."
  query = <<EOF
SELECT date_trunc('week', date_parse(report_date, '%Y-%m-%d')) AS week,
       MAX(confirmed) - MIN(confirmed) AS new_cases
FROM silver_covid_global
WHERE country = 'Brazil'
GROUP BY 1
ORDER BY 1;
  EOF
  workgroup = aws_athena_workgroup.covid-workgroup.name
}

resource "aws_athena_named_query" "top-countries-by-deaths" {
  name        = "top-countries-by-deaths"
  database    = aws_glue_catalog_database.covid_db.name
  description = "The twenty countries with the highest cumulative death count on the most recent date in the series."
  query = <<EOF
SELECT country, MAX(deaths) AS cumulative_deaths
FROM silver_covid_global
WHERE report_date = (SELECT MAX(report_date) FROM silver_covid_global)
GROUP BY country
ORDER BY cumulative_deaths DESC
LIMIT 20;
  EOF
  workgroup = aws_athena_workgroup.covid-workgroup.name
}

resource "aws_athena_workgroup" "covid-workgroup" {
  name        = "covid-workgroup"
  description = "Athena workgroup for the COVID-19 lake. It caps each query at 10 GiB scanned, publishes query metrics to CloudWatch, and overrides client settings so every query writes to the results bucket configured here."
  configuration {
    bytes_scanned_cutoff_per_query          = 10737418240
    enable_minimum_encryption_configuration = false
    engine_version {
      selected_engine_version = "AUTO"
    }
    result_configuration {
      output_location = "s3://${aws_s3_bucket.covid-athena-results.id}"
      acl_configuration {
        s3_acl_option = "BUCKET_OWNER_FULL_CONTROL"
      }
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
  tags = {
    Name           = "covid-workgroup"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_lakeformation_data_lake_settings" "covid-lake-settings" {
  admins = [aws_iam_role.covid-lake-settings_role.arn]
}

resource "aws_lakeformation_permissions" "covid-select-silver" {
  principal   = aws_iam_role.covid-select-silver_role.arn
  permissions = ["SELECT", "DESCRIBE"]
  database {
    name = aws_glue_catalog_database.covid_db.name
  }
}

resource "aws_lakeformation_resource" "covid-silver-registered" {
  arn                     = aws_s3_bucket.covid-silver.arn
  use_service_linked_role = true
}

resource "aws_quicksight_data_set" "covid-silver-dataset" {
  data_set_id = "covid-silver-dataset"
  name        = "covid-silver-dataset"
  import_mode = "DIRECT_QUERY"
  data_set_usage_configuration {
    disable_use_as_direct_query_source = false
    disable_use_as_imported_source     = false
  }
  logical_table_map {
    source {
      physical_table_id = "silver-covid-global"
    }
    logical_table_map_id = "silver-covid-global"
    alias                = "COVID-19 by country and date"
  }
  physical_table_map {
    physical_table_map_id = "silver-covid-global"
    relational_table {
      name            = aws_glue_catalog_table.silver_covid_global.name
      data_source_arn = aws_quicksight_data_source.covid-athena-source.arn
      schema          = aws_glue_catalog_table.silver_covid_global.database_name
      input_columns {
        name = "country"
        type = "STRING"
      }
      input_columns {
        name = "province"
        type = "STRING"
      }
      input_columns {
        name = "lat"
        type = "DECIMAL"
      }
      input_columns {
        name = "lon"
        type = "DECIMAL"
      }
      input_columns {
        name = "report_date"
        type = "STRING"
      }
      input_columns {
        name = "confirmed"
        type = "INTEGER"
      }
      input_columns {
        name = "deaths"
        type = "INTEGER"
      }
    }
  }
  tags = {
    Name           = "covid-silver-dataset"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_quicksight_data_source" "covid-athena-source" {
  data_source_id = "covid-athena-source"
  name           = "covid-athena-source"
  type           = "ATHENA"
  parameters {
    athena {
      work_group = aws_athena_workgroup.covid-workgroup.name
    }
  }
  ssl_properties {
    disable_ssl = false
  }
  tags = {
    Name           = "covid-athena-source"
    State          = "CovidDataLake"
    Struct8Creator = "Contato Struct"
  }
}


