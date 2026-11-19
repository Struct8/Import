resource "aws_glue_catalog_database" "cdn_analytics" {
  name = "cdn_analytics"
  tags = {
    Name           = "cdn_analytics"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_glue_catalog_table" "cdn_log" {
  database_name = aws_glue_catalog_database.cdn_analytics.name
  name          = "cdn_log"
  parameters = {
    "projection.enabled"        = "true"
    "projection.year.type"      = "integer"
    "projection.year.range"     = "2026,2036"
    "projection.month.type"     = "integer"
    "projection.month.range"    = "1,12"
    "projection.month.digits"   = "2"
    "projection.day.type"       = "integer"
    "projection.day.range"      = "1,31"
    "projection.day.digits"     = "2"
    "storage.location.template" = "s3://${aws_s3_bucket.cdnLogBucket.bucket}/cdn-log/year=$${year}/month=$${month}/day=$${day}/"
  }
  table_type = "EXTERNAL_TABLE"
  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }
  storage_descriptor {
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    location      = "s3://${aws_s3_bucket.cdnLogBucket.bucket}/cdn-log/"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"
    columns {
      name    = "ts"
      comment = "Time of the request, in seconds since 1970."
      type    = "double"
    }
    columns {
      name    = "status"
      comment = "HTTP status the CDN answered."
      type    = "int"
    }
    columns {
      name    = "bytes"
      comment = "Bytes the CDN sent."
      type    = "bigint"
    }
    columns {
      name    = "method"
      comment = "HTTP method."
      type    = "string"
    }
    columns {
      name    = "uri_stem"
      comment = "Path of the request, including the query string. Use split_part(uri_stem, '?', 1) for the path alone."
      type    = "string"
    }
    columns {
      name    = "time_taken"
      comment = "Seconds from the request to the last byte."
      type    = "double"
    }
    columns {
      name    = "user_agent"
      comment = "User-Agent header."
      type    = "string"
    }
    columns {
      name    = "referer"
      comment = "Referer header."
      type    = "string"
    }
    columns {
      name    = "uri_query"
      comment = "Query string."
      type    = "string"
    }
    columns {
      name    = "edge_result_type"
      comment = "Hit, Miss, RefreshHit, Error..."
      type    = "string"
    }
    columns {
      name    = "edge_detailed_result_type"
      comment = "Detailed result, such as a response from the WAF."
      type    = "string"
    }
    columns {
      name    = "country"
      comment = "Two-letter country of the visitor."
      type    = "string"
    }
    columns {
      name    = "behavior_path"
      comment = "Path pattern of the cache behavior that served the request."
      type    = "string"
    }
    ser_de_info {
      parameters = {
        "field.delim"          = "\t"
        "serialization.format" = "1"
      }
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
    }
  }
}

resource "aws_athena_named_query" "cacheAndErrors" {
  name        = "cacheAndErrors"
  database    = aws_glue_catalog_database.cdn_analytics.name
  description = "Result of each request (hit, miss, error) and the average time, per path pattern."
  query = <<EOF
SELECT behavior_path, edge_result_type, count(*) AS requests,
  round(avg(time_taken), 3) AS avg_seconds, sum(bytes) AS bytes
FROM cdn_log
WHERE concat(year, month, day) >= date_format(current_date - interval '1' day, '%Y%m%d')
GROUP BY 1, 2
ORDER BY requests DESC;
  EOF
  workgroup = aws_athena_workgroup.cdnAnalytics.name
}

resource "aws_athena_named_query" "shopFunnel" {
  name        = "shopFunnel"
  database    = aws_glue_catalog_database.cdn_analytics.name
  description = "Requests to each step of the purchase, per day."
  query = <<EOF
SELECT concat(year, '-', month, '-', day) AS day,
  count_if(split_part(uri_stem, '?', 1) LIKE '/product/%') AS product_views,
  count_if(split_part(uri_stem, '?', 1) = '/cart/') AS cart_views,
  count_if(split_part(uri_stem, '?', 1) LIKE '/checkout/%' AND method = 'GET') AS checkout_views,
  count_if(split_part(uri_stem, '?', 1) LIKE '/wp-json/wc/store/v1/checkout%' AND method = 'POST') AS orders_placed
FROM cdn_log
WHERE concat(year, month, day) >= date_format(current_date - interval '14' day, '%Y%m%d')
GROUP BY 1
ORDER BY 1 DESC;
  EOF
  workgroup = aws_athena_workgroup.cdnAnalytics.name
}

resource "aws_athena_named_query" "topPages" {
  name        = "topPages"
  database    = aws_glue_catalog_database.cdn_analytics.name
  description = "Most viewed pages in the last 7 days, bots included."
  query = <<EOF
SELECT split_part(uri_stem, '?', 1) AS page, count(*) AS requests
FROM cdn_log
WHERE concat(year, month, day) >= date_format(current_date - interval '7' day, '%Y%m%d')
  AND method = 'GET' AND status = 200 AND behavior_path = '*'
GROUP BY 1
ORDER BY requests DESC
LIMIT 50;
  EOF
  workgroup = aws_athena_workgroup.cdnAnalytics.name
}

resource "aws_athena_named_query" "visitsByCountry" {
  name        = "visitsByCountry"
  database    = aws_glue_catalog_database.cdn_analytics.name
  description = "Requests per country and day, last 7 days."
  query = <<EOF
SELECT concat(year, '-', month, '-', day) AS day, country, count(*) AS requests
FROM cdn_log
WHERE concat(year, month, day) >= date_format(current_date - interval '7' day, '%Y%m%d')
  AND behavior_path = '*'
GROUP BY 1, 2
ORDER BY 1 DESC, 3 DESC;
  EOF
  workgroup = aws_athena_workgroup.cdnAnalytics.name
}

resource "aws_athena_workgroup" "cdnAnalytics" {
  name          = "cdnAnalytics"
  force_destroy = true
  configuration {
    bytes_scanned_cutoff_per_query = 10737418240
    result_configuration {
      output_location = "s3://${aws_s3_bucket.cdnLogBucket.id}"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }
  tags = {
    Name           = "cdnAnalytics"
    State          = "wp-analytics"
    Struct8Creator = "Contato Struct"
  }
}
