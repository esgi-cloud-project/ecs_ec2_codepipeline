resource "aws_dynamodb_table" "basic-dynamodb-table" {
  name           = "Product"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "Id"
  range_key      = "Name"

  attribute {
    name = "Id"
    type = "S"
  }

  attribute {
    name = "Name"
    type = "S"
  }
}