data "google_storage_project_service_account" "gcss_sa" {
   project =  "airline1-sabre-wolverine"
 }


resource "google_kms_crypto_key" "secrets" {
 name     = "my-dev-appid-str-demo-key"
 key_ring = "projects/airline1-sabre-wolverine/locations/us/keyRings/savita-keyring-us"
 labels = {
    owner = "hybridenv"
    application_division = "pci"
    application_name = "app1"
    application_role = "auth"
    au = "0223092"
    gcp_region = "us" 
    environment = "dev" 
    created = "20211124" 
  }
}

resource "google_service_account" "dataproc_sa" {
 account_id   = "my-dev-appid-sa-demo-dataproc"
 display_name = "DataProc Service Account"
 project      = data.google_project.project.project_id
}

resource "google_project_iam_member" "dataproc_workers" {
 project = data.google_project.project.id
 role    = "roles/dataproc.worker"
 member  = "serviceAccount:${google_service_account.dataproc_sa.email}"
}

resource "google_project_iam_member" "dataproc_workers1" {
 project = data.google_project.project.id
 role    = "roles/logging.logWriter"
 member  = "serviceAccount:${google_service_account.dataproc_sa.email}"
}

resource "google_kms_crypto_key_iam_member" "dataproc_gce_encryption" {
 crypto_key_id = google_kms_crypto_key.secrets.id
 role   = "roles/cloudkms.cryptoKeyEncrypter"
 member = "serviceAccount:service-${data.google_project.project.number}@compute-system.iam.gserviceaccount.com"
}

resource "google_kms_crypto_key_iam_member" "dataproc_gce_encryption1" {
 crypto_key_id = google_kms_crypto_key.secrets.id
 role   = "roles/cloudkms.cryptoKeyEncrypter"
 member = "serviceAccount:${google_service_account.dataproc_sa.email}"
}  

resource "google_project_iam_binding" "dataproc" {
 project = "shared-sabre-wolverine"  # Shared VPC project 
 role    = "roles/compute.networkUser"
 members = [
     "serviceAccount:${google_service_account.dataproc_sa.email}",
     "serviceAccount:service-${data.google_project.project.number}@dataproc-accounts.iam.gserviceaccount.com"
 ]
}
/*
resource "google_storage_bucket" "dataproc_staging" { 
 name                        = "my-dev-appid-strg-stagedemo-gcsbucket"
 project                     = "airline1-sabre-wolverine"
 location                    = "us"
 # Enable CMEK
 encryption {
     default_kms_key_name = google_kms_crypto_key.secrets.name
 }
}

resource "google_storage_bucket" "dataproc_temp" {
 name                        = "my-dev-appid-strg-tempdemo-gcsbucket"
 project                     = "airline1-sabre-wolverine"
 location                    = "us"
 # Enable CMEK
 encryption {
     default_kms_key_name = google_kms_crypto_key.secrets.name
 }
}
*/
resource "google_kms_crypto_key_iam_member" "dataproc_gcs_encryption" {
 crypto_key_id = google_kms_crypto_key.secrets.id
 role   = "roles/cloudkms.cryptoKeyEncrypter"
 member = "serviceAccount:${data.google_storage_project_service_account.gcss_sa.email_address}"
}

resource "google_compute_firewall" "dataproc" {
 project     = "airline1-sabre-wolverine"
 name        = "allow-tcp-udp-icmp-dataprocdemo-fw"
 network     = "projects/airline1-sabre-wolverine/regions/us-central1/networks/us-dev-appid-syst-demo-vpc"
 description = "Enable Dataproc master and nodes connectivity"

 # VMs within that applies the firewall rule
 source_tags = ["dataproc-source"]
 target_tags = ["dataproc-target"]

 # Protocols/ports allowed
 allow {
   protocol  = "tcp"
 }
 allow {
   protocol  = "udp"
 }
 allow {
   protocol  = "icmp"
 }
}

resource "google_dataproc_cluster" "example" {
 provider = google-beta # Required to enforce HTTPS config
 project  = data.google_project.project.project_id
 name     = "my-dev-appid-strg-dlpdemo-dpcluster"
 region   = "us-central1"
 labels   = {
    owner = "hybridenv"
    application_division = "pci"
    application_name = "app1"
    application_role = "auth"
    au = "0223092"
    gcp_region = "us" 
    environment = "dev" 
    created = "20211124" 
  } 

 cluster_config {
   # Enable CMEK
   encryption_config {
     kms_key_name = google_kms_crypto_key.secrets.id
   }
  
   # Disable plain HTTP
   endpoint_config {
     enable_http_port_access = false
   }

   # Use user-managed Service Account
   gce_cluster_config {
     tags                   = ["dataproc-tag"]
     subnetwork             = "projects/airline1-sabre-wolverine/regions/us-central1/subnetworks/us-dev-appid-syst-demo-subnet"
     internal_ip_only       = true
     service_account        = google_service_account.dataproc_sa.email
     #service_account        = "dataproc-sa-compute@developer.gserviceaccount.com"
     service_account_scopes = [
       "cloud-platform"
     ]
   }

   # Use CMEK encrypted buckets
   #staging_bucket  = google_storage_bucket.dataproc_staging.id
   #temp_bucket     = google_storage_bucket.dataproc_temp.id
 }
  
 depends_on = [
      google_service_account.dataproc_sa, google_project_iam_member.dataproc_workers
]
}

