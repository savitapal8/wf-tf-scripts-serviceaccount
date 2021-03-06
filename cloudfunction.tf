resource "google_vpc_access_connector" "vpc_conn_example" {
  name          = "my-dev-appid-vc-demo-function"
  ip_cidr_range = "10.8.0.0/28"
  network       = "us-dev-appid-syst-demo-vpc"
}

resource "google_service_account" "example" {
 account_id   = "my-dev-appid-sa-demo-function"
 display_name = "Function Example Service Account"
 project      = "airline1-sabre-wolverine"
}

resource "google_storage_bucket" "bucket" {
  name     = "my-dev-appid-system-demo-gcsbucke"
  location = "us"
}

resource "google_storage_bucket_object" "archive" {
  name   = "my-dev-appid-system-demo-gcsbucketobject"
  bucket = google_storage_bucket.bucket.name
  source = "./main.zip"
}

resource "google_cloudfunctions_function" "function" {
  name        = "my-dev-appid-system-demo-function"
  description = "My function"
  runtime     = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.archive.name
  trigger_http          = true
  timeout               = 60
  entry_point           = "hello_world"
  labels = {
    my-label = "my-label-value"
  }

  environment_variables = {
    MY_ENV_VAR = "my-env-var-value"
    GOOGLE_FUNCTION_SOURCE = "main.py"
  }
  
  ingress_settings = "ALLOW_INTERNAL_ONLY"
  #ingress_settings = "ALLOW_ALL"
  vpc_connector    = google_vpc_access_connector.vpc_conn_example.id
  vpc_connector_egress_settings = "ALL_TRAFFIC"
  #vpc_connector_egress_settings = "PRIVATE_RANGES_ONLY"
  service_account_email = google_service_account.example.email
  #service_account_email = "service-sa@appspot.gserviceaccount.com"
}

# IAM entry for a single user to invoke the function
resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions_function.function.project
  region         = google_cloudfunctions_function.function.region
  cloud_function = google_cloudfunctions_function.function.name

  role   = "roles/cloudfunctions.invoker"
  #member = "serviceAccount:demo-sentinel-sa@airline1-sabre-wolverine.iam.gserviceaccount.com"
  member = "serviceAccount:${google_service_account.example.email}"
  #member = "serviceAccount:service-sa@appspot.gserviceaccount.com"
}
