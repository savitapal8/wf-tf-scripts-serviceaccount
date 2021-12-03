provider "google" {
  user_project_override = true
  access_token          = var.access_token
  project               = "airline1-sabre-wolverine"
  region                = "us-central1"
}

data "google_compute_network" "network"{
  project = "airline1-sabre-wolverine"
  name = "te-dev-vpce-syst-testvpc"
}

resource "google_sql_database_instance" "postgres" {
  name             = "postgres-instance-demo1"
  database_version = "POSTGRES_11"

  settings {
    tier = "db-f1-micro"

    ip_configuration {
      ipv4_enabled    = false
      #private_network = data.google_compute_network.network.self_link
    }
  }
}

/**************************************************************
	Database Config
 **************************************************************/
resource "google_sql_database" "database" {
  project = "airline1-sabre-wolverine"
  name    = "postgre-demo1"
  instance = google_sql_database_instance.postgres.name
} 
