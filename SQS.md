# List all queues

aws sqs list-queues

# Get configuration for each queue

Replace <QUEUE-URL> with the actual queue URL from above.

aws sqs get-queue-attributes \
  --queue-url <QUEUE-URL> \
  --attribute-names All \
  > sqs-config-backup.json

# Automated Backup Script (Exports All Queues at Once)

#!/bin/bash

mkdir -p sqs-backups

for url in $(aws sqs list-queues --output text --query QueueUrls[]); do
    name=$(basename $url)
    echo "Backing up $name"
    aws sqs get-queue-attributes \
      --queue-url $url \
      --attribute-names All \
      > "sqs-backups/$name.json"
done

# Create SQS FIFO Queue

aws sqs create-queue \
  --queue-name sqs-prd-dl-bsn0030651-djc-deadletter-queue.fifo \
  --region eu-west-1 \
  --attributes "{
    \"FifoQueue\": \"true\",
    \"ContentBasedDeduplication\": \"false\",
    \"VisibilityTimeout\": \"30\",
    \"MaximumMessageSize\": \"1048576\",
    \"MessageRetentionPeriod\": \"345600\",
    \"DelaySeconds\": \"0\",
    \"ReceiveMessageWaitTimeSeconds\": \"0\",
    \"DeduplicationScope\": \"queue\",
    \"FifoThroughputLimit\": \"perQueue\",
    \"SqsManagedSseEnabled\": \"true\",
    \"Policy\": \"{ \\\"Version\\\": \\\"2012-10-17\\\", \\\"Id\\\": \\\"__default_policy_ID\\\", \\\"Statement\\\": [ { \\\"Sid\\\": \\\"__owner_statement\\\", \\\"Effect\\\": \\\"Allow\\\", \\\"Principal\\\": { \\\"AWS\\\": \\\"arn:aws:iam::<NEW-AWS-ACCOUNT-ID>:root\\\" }, \\\"Action\\\": \\\"SQS:*\\\", \\\"Resource\\\": \\\"arn:aws:sqs:eu-west-1:<NEW-AWS-ACCOUNT-ID>:sqs-prd-dl-bsn0030651-djc-deadletter-queue.fifo\\\" } ] }\" 
  }"


# Create SQS

aws sqs create-queue \
  --queue-name sqs-stg-dl-bsn0030651-djc.fifo \
  --region eu-west-1 \
  --attributes "{
    \"FifoQueue\": \"true\",
    \"ContentBasedDeduplication\": \"true\",
    \"VisibilityTimeout\": \"60\",
    \"MaximumMessageSize\": \"1048576\",
    \"MessageRetentionPeriod\": \"345600\",
    \"DelaySeconds\": \"0\",
    \"ReceiveMessageWaitTimeSeconds\": \"0\",
    \"DeduplicationScope\": \"messageGroup\",
    \"FifoThroughputLimit\": \"perMessageGroupId\",
    \"SqsManagedSseEnabled\": \"true\",
    \"RedrivePolicy\": \"{ \\\"deadLetterTargetArn\\\": \\\"arn:aws:sqs:eu-west-1:<NEW-AWS-ACCOUNT-ID>:sqs-stg-dl-bsn0030651-djc-deadletter-queue.fifo\\\", \\\"maxReceiveCount\\\": 10 }\",
    \"Policy\": \"{ \\\"Version\\\": \\\"2012-10-17\\\", \\\"Id\\\": \\\"__default_policy_ID\\\", \\\"Statement\\\": [ { \\\"Sid\\\": \\\"__owner_statement\\\", \\\"Effect\\\": \\\"Allow\\\", \\\"Principal\\\": { \\\"AWS\\\": \\\"arn:aws:iam::<NEW-AWS-ACCOUNT-ID>:root\\\" }, \\\"Action\\\": \\\"SQS:*\\\", \\\"Resource\\\": \\\"arn:aws:sqs:eu-west-1:<NEW-AWS-ACCOUNT-ID>:sqs-stg-dl-bsn0030651-djc.fifo\\\" } ] }\" 
  }"