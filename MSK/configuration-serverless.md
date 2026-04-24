aws kafka create-cluster-v2 \
  --cluster-name <Cluster-name> \
  --serverless \
  --client-authentication '{
    "Sasl": {
      "Iam": {
        "Enabled": true
      }
    }
  }' \
  --vpc-configs '[
    {
      "SubnetIds": [
        "subnet-1-id",
        "subnet-2-id"
      ],
      "SecurityGroupIds": [
        "sg-id"
      ]
    }
  ]'