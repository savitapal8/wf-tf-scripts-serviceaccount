provider "google" {
  user_project_override = true
  access_token          = var.access_token
  project               = "airline1-sabre-wolverine"
  region                = "us-central1"
}

provider "google-beta"{
  access_token          = var.access_token
}
