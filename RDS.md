# Create trust policy file

cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "monitoring.rds.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the IAM role

aws iam create-role \
  --role-name rds-monitoring-role \
  --assume-role-policy-document file://trust-policy.json

# Attach required policy

aws iam attach-role-policy \
  --role-name rds-monitoring-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole

# Create DB Cluster

aws rds create-db-cluster \
  --db-cluster-identifier dl-bsn0030651-prod-cluster \
  --engine aurora-mysql \
  --engine-version "8.0.mysql_aurora.3.06.0" \
  --db-subnet-group-name my-db-subnet-group \
  --vpc-security-group-ids sg-1234567890abcdef0 \
  --storage-type aurora-iopt \
  --backup-retention-period 7 \
  --deletion-protection \
  --enable-cloudwatch-logs-exports error general slowquery \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --enable-iam-database-authentication \
  --database-name dl \
  --manage-master-user-password \
  --master-user-secret-kms-key-id <secret-manager-arn> \
  --backtrack-window 86400 \
  --region eu-west-1

# Create the DB Instance

aws rds create-db-instance \
  --db-instance-identifier dl-bsn0030651-prod-instance-1 \
  --db-cluster-identifier dl-bsn0030651-prod-cluster \
  --db-instance-class db.r7g.2xlarge \
  --engine aurora-mysql \
  --publicly-accessible false \
  --monitoring-interval 60 \
  --monitoring-role-arn arn:aws:iam::<ACCOUNT_ID>:role/rds-monitoring-role \
  --region eu-west-1

# Create reader instance (Multi-AZ)

aws rds create-db-instance \
  --db-instance-identifier dl-bsn0030651-prod-reader-1 \
  --db-cluster-identifier dl-bsn0030651-prod-cluster \
  --db-instance-class db.r7g.2xlarge \
  --engine aurora-mysql \
  --publicly-accessible false \
  --availability-zone eu-west-1b \
  --monitoring-interval 60 \
  --monitoring-role-arn arn:aws:iam::<ACCOUNT_ID>:role/rds-monitoring-role \
  --region eu-west-1