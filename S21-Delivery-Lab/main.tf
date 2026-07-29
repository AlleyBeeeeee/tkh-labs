provider "aws" {  
  region = "us-east-1"  
}  
  
resource "aws_ssm_parameter" "drone_check" {  
  name  = "/tkh/pipeline/status"  
  type  = "String"  
  value = "Deployment Drone Successful via OIDC"  
}  
