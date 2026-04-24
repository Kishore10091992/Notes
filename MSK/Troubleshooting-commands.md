# List clusters

aws kafka list-clusters

# List MSK Serverless Clusters

aws kafka list-clusters-v2 \
  --cluster-type-filter SERVERLESS

# Filter by ClusterName

aws kafka list-clusters \
  --query "ClusterInfoList[?ClusterName=='YOUR_CLUSTER_NAME']"

aws kafka list-clusters-v2 \
  --query "ClusterInfoList[?ClusterName=='YOUR_CLUSTER_NAME']"


# Backup Cluster Details (Basic Metadata)

aws kafka describe-cluster \
  --cluster-arn <CLUSTER_ARN>

aws kafka describe-cluster-v2 \
  --cluster-arn <CLUSTER_ARN>

# Full VPC Configuration (Recommended)

aws kafka describe-cluster-v2 \
   --cluster-arn <CLUSTER_ARN> \
   --query "ClusterInfo.Serverless.VpcConfigs"

# Get Bootstrap Brokers

aws kafka get-bootstrap-brokers \
  --cluster-arn <NEW_CLUSTER_ARN>

