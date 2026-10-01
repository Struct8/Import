terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }

  backend "s3" {
    bucket  = "struct8-import"
    key     = "952133486861/State1/main.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}

# --- Main Cloud Provider ---
provider "aws" {
  region = "us-west-2"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

### EXTERNAL REFERENCES ###

data "aws_internet_gateway" "k6-panel-lab-igw" {
  filter {
    name   = "tag:Name"
    values = ["k6-panel-lab-igw"]
  }
}

data "aws_route_table" "k6-panel-lab-rtb-public" {
  filter {
    name   = "tag:Name"
    values = ["k6-panel-lab-rtb-public"]
  }
}

data "aws_lambda_function" "Function" {
  function_name = "Function"
}

data "aws_s3_bucket" "my-bucket1" {
  bucket = "my-bucket1-${data.aws_caller_identity.current.account_id}-${data.aws_region.current.region}-an"
}

data "aws_vpc" "k6-panel-lab" {
  filter {
    name   = "tag:Name"
    values = ["k6-panel-lab"]
  }
}

data "aws_instance" "k6-panel-lab-hub" {
  filter {
    name   = "tag:Name"
    values = ["k6-panel-lab-hub"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instance" "k6-panel-lab-k6" {
  filter {
    name   = "tag:Name"
    values = ["k6-panel-lab-k6"]
  }
  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}




### CATEGORY: IAM ###

data "aws_iam_policy_document" "User_role_access_0_doc" {
  statement {
    effect    = "Allow"
    actions   = ["lambda:CreateAlias", "lambda:CreateFunctionUrlConfig", "lambda:DeleteAlias", "lambda:DeleteFunctionCodeSigningConfig", "lambda:DeleteFunctionConcurrency", "lambda:DeleteFunctionEventInvokeConfig", "lambda:DeleteFunctionUrlConfig", "lambda:GetAlias", "lambda:GetFunction", "lambda:GetFunctionCodeSigningConfig", "lambda:GetFunctionConcurrency", "lambda:GetFunctionConfiguration", "lambda:GetFunctionEventInvokeConfig", "lambda:GetFunctionRecursionConfig", "lambda:GetFunctionScalingConfig", "lambda:GetFunctionUrlConfig", "lambda:GetPolicy", "lambda:GetRuntimeManagementConfig", "lambda:InvokeAsync", "lambda:InvokeFunction", "lambda:InvokeFunctionUrl", "lambda:ListAliases", "lambda:ListDurableExecutionsByFunction", "lambda:ListFunctionEventInvokeConfigs", "lambda:ListFunctionUrlConfigs", "lambda:ListProvisionedConcurrencyConfigs", "lambda:ListTags", "lambda:ListVersionsByFunction", "lambda:PublishVersion", "lambda:PutFunctionConcurrency", "lambda:PutFunctionEventInvokeConfig", "lambda:PutFunctionRecursionConfig", "lambda:PutFunctionScalingConfig", "lambda:PutRuntimeManagementConfig", "lambda:UpdateAlias", "lambda:UpdateFunctionCode", "lambda:UpdateFunctionConfiguration", "lambda:UpdateFunctionEventInvokeConfig", "lambda:UpdateFunctionUrlConfig"]
    resources = [data.aws_lambda_function.Function.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["lambda:DeleteProvisionedConcurrencyConfig", "lambda:GetProvisionedConcurrencyConfig", "lambda:PutProvisionedConcurrencyConfig"]
    resources = ["${data.aws_lambda_function.Function.arn}:*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["lambda:CheckpointDurableExecution", "lambda:GetDurableExecution", "lambda:GetDurableExecutionHistory", "lambda:GetDurableExecutionState", "lambda:SendDurableExecutionCallbackFailure", "lambda:SendDurableExecutionCallbackHeartbeat", "lambda:SendDurableExecutionCallbackSuccess", "lambda:StopDurableExecution"]
    resources = ["${data.aws_lambda_function.Function.arn}:*/durable-execution/*/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:AllowVendedLogDeliveryForResource", "s3:CreateBucketMetadataTableConfiguration", "s3:DeleteBucketMetadataTableConfiguration", "s3:DeleteBucketWebsite", "s3:GetAccelerateConfiguration", "s3:GetAnalyticsConfiguration", "s3:GetBucketAbac", "s3:GetBucketAcl", "s3:GetBucketCORS", "s3:GetBucketLocation", "s3:GetBucketLogging", "s3:GetBucketMetadataTableConfiguration", "s3:GetBucketNotification", "s3:GetBucketObjectLockConfiguration", "s3:GetBucketOwnershipControls", "s3:GetBucketPolicy", "s3:GetBucketPolicyStatus", "s3:GetBucketPublicAccessBlock", "s3:GetBucketRequestPayment", "s3:GetBucketTagging", "s3:GetBucketVersioning", "s3:GetBucketWebsite", "s3:GetEncryptionConfiguration", "s3:GetIntelligentTieringConfiguration", "s3:GetInventoryConfiguration", "s3:GetLifecycleConfiguration", "s3:GetMetricsConfiguration", "s3:GetReplicationConfiguration", "s3:ListBucket", "s3:ListBucketMultipartUploads", "s3:ListBucketVersions", "s3:ListTagsForResource", "s3:PauseReplication", "s3:PutAccelerateConfiguration", "s3:PutAnalyticsConfiguration", "s3:PutBucketAbac", "s3:PutBucketCORS", "s3:PutBucketLogging", "s3:PutBucketNotification", "s3:PutBucketObjectLockConfiguration", "s3:PutBucketRequestPayment", "s3:PutBucketVersioning", "s3:PutBucketWebsite", "s3:PutEncryptionConfiguration", "s3:PutIntelligentTieringConfiguration", "s3:PutInventoryConfiguration", "s3:PutLifecycleConfiguration", "s3:PutMetricsConfiguration", "s3:PutReplicationConfiguration", "s3:UpdateBucketMetadataAnnotationTableConfiguration", "s3:UpdateBucketMetadataInventoryTableConfiguration", "s3:UpdateBucketMetadataJournalTableConfiguration"]
    resources = [data.aws_s3_bucket.my-bucket1.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:AbortMultipartUpload", "s3:DeleteObject", "s3:DeleteObjectAnnotation", "s3:DeleteObjectVersion", "s3:DeleteObjectVersionAnnotation", "s3:GetObject", "s3:GetObjectAcl", "s3:GetObjectAnnotation", "s3:GetObjectAttributes", "s3:GetObjectLegalHold", "s3:GetObjectRetention", "s3:GetObjectTagging", "s3:GetObjectTorrent", "s3:GetObjectVersion", "s3:GetObjectVersionAcl", "s3:GetObjectVersionAnnotation", "s3:GetObjectVersionAnnotationForReplication", "s3:GetObjectVersionAttributes", "s3:GetObjectVersionForReplication", "s3:GetObjectVersionTagging", "s3:GetObjectVersionTorrent", "s3:InitiateReplication", "s3:ListMultipartUploadParts", "s3:ListObjectAnnotations", "s3:ListObjectVersionAnnotations", "s3:PutObject", "s3:PutObjectAnnotation", "s3:PutObjectLegalHold", "s3:PutObjectRetention", "s3:PutObjectVersionAnnotation", "s3:ReplicateDelete", "s3:ReplicateObject", "s3:ReplicateObjectAnnotation", "s3:RestoreObject", "s3:UpdateObjectEncryption"]
    resources = ["${data.aws_s3_bucket.my-bucket1.arn}/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeVpcAttribute", "ec2:GetSecurityGroupsForVpc", "ec2:GetVpcResourcesBlockingEncryptionEnforcement"]
    resources = [data.aws_vpc.k6-panel-lab.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeInstanceAttribute", "ec2:GetConsoleOutput", "ec2:GetConsoleScreenshot", "ec2:GetInstanceTpmEkPub", "ec2:GetInstanceUefiData", "ec2:GetLaunchTemplateData", "ec2:GetPasswordData"]
    resources = [data.aws_instance.k6-panel-lab-hub.arn, data.aws_instance.k6-panel-lab-k6.arn]
  }
}

resource "aws_iam_policy" "User_role_access_0" {
  name   = "User_role-access-0"
  policy = data.aws_iam_policy_document.User_role_access_0_doc.json
}

data "aws_iam_policy_document" "User_role_access_1_doc" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:GetRouteServerPropagations"]
    resources = [data.aws_route_table.k6-panel-lab-rtb-public.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeAccountAttributes", "ec2:DescribeAddressTransfers", "ec2:DescribeAddresses", "ec2:DescribeAddressesAttribute", "ec2:DescribeAggregateIdFormat", "ec2:DescribeAvailabilityZones", "ec2:DescribeAwsNetworkPerformanceMetricSubscriptions", "ec2:DescribeBundleTasks", "ec2:DescribeByoipCidrs", "ec2:DescribeCapacityBlockExtensionHistory", "ec2:DescribeCapacityBlockOfferings", "ec2:DescribeCapacityBlockStatus", "ec2:DescribeCapacityBlocks", "ec2:DescribeCapacityManagerDataExports", "ec2:DescribeCapacityReservationBillingRequests", "ec2:DescribeCapacityReservationCancellationQuotes", "ec2:DescribeCapacityReservationFleets", "ec2:DescribeCapacityReservationTopology", "ec2:DescribeCapacityReservations", "ec2:DescribeCarrierGateways", "ec2:DescribeClassicLinkInstances", "ec2:DescribeClientVpnEndpoints", "ec2:DescribeCoipPools", "ec2:DescribeConversionTasks", "ec2:DescribeCustomerGateways", "ec2:DescribeDeclarativePoliciesReports", "ec2:DescribeDhcpOptions", "ec2:DescribeEgressOnlyInternetGateways", "ec2:DescribeElasticGpus", "ec2:DescribeExportImageTasks", "ec2:DescribeExportTasks", "ec2:DescribeFastLaunchImages", "ec2:DescribeFastSnapshotRestores", "ec2:DescribeFleets", "ec2:DescribeFlowLogs", "ec2:DescribeFpgaImages", "ec2:DescribeHostReservationOfferings", "ec2:DescribeHostReservations", "ec2:DescribeHosts", "ec2:DescribeIamInstanceProfileAssociations", "ec2:DescribeIdFormat", "ec2:DescribeIdentityIdFormat", "ec2:DescribeImageReferences", "ec2:DescribeImageUsageReportEntries", "ec2:DescribeImageUsageReports", "ec2:DescribeImages", "ec2:DescribeImportImageTasks", "ec2:DescribeImportSnapshotTasks", "ec2:DescribeInstanceConnectEndpoints", "ec2:DescribeInstanceCreditSpecifications", "ec2:DescribeInstanceEventNotificationAttributes", "ec2:DescribeInstanceEventWindows", "ec2:DescribeInstanceImageMetadata", "ec2:DescribeInstanceSqlHaHistoryStates", "ec2:DescribeInstanceSqlHaStates", "ec2:DescribeInstanceStatus", "ec2:DescribeInstanceTopology", "ec2:DescribeInstanceTypeOfferings", "ec2:DescribeInstanceTypes", "ec2:DescribeInstances", "ec2:DescribeInternetGateways", "ec2:DescribeIpamByoasn", "ec2:DescribeIpamExternalResourceVerificationTokens", "ec2:DescribeIpamPolicies", "ec2:DescribeIpamPoolAllocations", "ec2:DescribeIpamPools", "ec2:DescribeIpamPrefixListResolverTargets", "ec2:DescribeIpamPrefixListResolvers", "ec2:DescribeIpamResourceDiscoveries", "ec2:DescribeIpamResourceDiscoveryAssociations", "ec2:DescribeIpamScopes", "ec2:DescribeIpams", "ec2:DescribeIpv6Pools", "ec2:DescribeKeyPairs", "ec2:DescribeLaunchTemplateVersions", "ec2:DescribeLaunchTemplates", "ec2:DescribeLocalGatewayRouteTablePermissions", "ec2:DescribeLocalGatewayRouteTableVirtualInterfaceGroupAssociations", "ec2:DescribeLocalGatewayRouteTableVpcAssociations", "ec2:DescribeLocalGatewayRouteTables", "ec2:DescribeLocalGatewayVirtualInterfaceGroups", "ec2:DescribeLocalGatewayVirtualInterfaces", "ec2:DescribeLocalGateways", "ec2:DescribeLockedSnapshots", "ec2:DescribeMacHosts", "ec2:DescribeMacModificationTasks", "ec2:DescribeManagedPrefixLists", "ec2:DescribeMovingAddresses", "ec2:DescribeNatGateways", "ec2:DescribeNetworkAcls", "ec2:DescribeNetworkInsightsAccessScopeAnalyses", "ec2:DescribeNetworkInsightsAccessScopes", "ec2:DescribeNetworkInsightsAnalyses", "ec2:DescribeNetworkInsightsPaths", "ec2:DescribeNetworkInterfaceAttribute", "ec2:DescribeNetworkInterfacePermissions", "ec2:DescribeNetworkInterfaces", "ec2:DescribeOutpostLags", "ec2:DescribePlacementGroups", "ec2:DescribePrefixLists", "ec2:DescribePrincipalIdFormat", "ec2:DescribePublicIpv4Pools", "ec2:DescribeRegions", "ec2:DescribeReplaceRootVolumeTasks", "ec2:DescribeReservedInstances", "ec2:DescribeReservedInstancesListings", "ec2:DescribeReservedInstancesModifications", "ec2:DescribeReservedInstancesOfferings", "ec2:DescribeRouteServerEndpoints", "ec2:DescribeRouteServerPeers", "ec2:DescribeRouteServers", "ec2:DescribeRouteTables", "ec2:DescribeScheduledInstanceAvailability", "ec2:DescribeScheduledInstances", "ec2:DescribeSecondaryInterfaces", "ec2:DescribeSecondaryNetworks", "ec2:DescribeSecondarySubnets", "ec2:DescribeSecurityGroupRules", "ec2:DescribeSecurityGroupVpcAssociations", "ec2:DescribeSecurityGroups", "ec2:DescribeServiceLinkVirtualInterfaces", "ec2:DescribeSnapshotTierStatus", "ec2:DescribeSnapshots", "ec2:DescribeSpotDatafeedSubscription", "ec2:DescribeSpotFleetRequests", "ec2:DescribeSpotInstanceRequests", "ec2:DescribeSpotPriceHistory", "ec2:DescribeStaleSecurityGroups", "ec2:DescribeStoreImageTasks", "ec2:DescribeSubnets", "ec2:DescribeTags", "ec2:DescribeTrafficMirrorFilterRules", "ec2:DescribeTrafficMirrorFilters", "ec2:DescribeTrafficMirrorSessions", "ec2:DescribeTrafficMirrorTargets", "ec2:DescribeTransitGatewayAttachments", "ec2:DescribeTransitGatewayConnectPeers", "ec2:DescribeTransitGatewayConnects", "ec2:DescribeTransitGatewayMeteringPolicies", "ec2:DescribeTransitGatewayMulticastDomains", "ec2:DescribeTransitGatewayPeeringAttachments", "ec2:DescribeTransitGatewayPolicyTables", "ec2:DescribeTransitGatewayRouteTableAnnouncements", "ec2:DescribeTransitGatewayRouteTables", "ec2:DescribeTransitGatewayVpcAttachments", "ec2:DescribeTransitGateways", "ec2:DescribeTrunkInterfaceAssociations", "ec2:DescribeVerifiedAccessEndpoints", "ec2:DescribeVerifiedAccessGroups", "ec2:DescribeVerifiedAccessInstanceLoggingConfigurations", "ec2:DescribeVerifiedAccessInstanceWebAclAssociations", "ec2:DescribeVerifiedAccessInstances", "ec2:DescribeVerifiedAccessTrustProviders", "ec2:DescribeVolumeStatus", "ec2:DescribeVolumes", "ec2:DescribeVolumesModifications", "ec2:DescribeVpcBlockPublicAccessExclusions", "ec2:DescribeVpcBlockPublicAccessOptions", "ec2:DescribeVpcClassicLink", "ec2:DescribeVpcClassicLinkDnsSupport", "ec2:DescribeVpcEncryptionControls", "ec2:DescribeVpcEndpointAssociations", "ec2:DescribeVpcEndpointConnectionNotifications", "ec2:DescribeVpcEndpointConnections", "ec2:DescribeVpcEndpointServiceConfigurations"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "User_role_access_1" {
  name   = "User_role-access-1"
  policy = data.aws_iam_policy_document.User_role_access_1_doc.json
}

data "aws_iam_policy_document" "User_role_access_2_doc" {
  statement {
    effect    = "Allow"
    actions   = ["ec2:DescribeVpcEndpointServices", "ec2:DescribeVpcEndpoints", "ec2:DescribeVpcPeeringConnections", "ec2:DescribeVpcs", "ec2:DescribeVpnConcentrators", "ec2:DescribeVpnConnections", "ec2:DescribeVpnGateways", "ec2:GetAllowedImagesSettings", "ec2:GetAwsNetworkPerformanceData", "ec2:GetCapacityManagerAttributes", "ec2:GetCapacityManagerMetricData", "ec2:GetCapacityManagerMetricDimensions", "ec2:GetCapacityManagerMonitoredTagKeys", "ec2:GetDefaultCreditSpecification", "ec2:GetEbsDefaultKmsKeyId", "ec2:GetEbsEncryptionByDefault", "ec2:GetEnabledIpamPolicy", "ec2:GetHostReservationPurchasePreview", "ec2:GetImageBlockPublicAccessState", "ec2:GetInstanceMetadataDefaults", "ec2:GetInstanceTypesFromInstanceRequirements", "ec2:GetManagedResourceVisibility", "ec2:GetSerialConsoleAccessStatus", "ec2:GetSnapshotBlockPublicAccessState", "ec2:GetSpotPlacementScores", "ec2:GetSubnetCidrReservations", "ec2:GetTransitGatewayAttachmentPropagations", "ec2:GetTransitGatewayPrefixListReferences", "ec2:GetTransitGatewayRouteTableAssociations", "ec2:GetTransitGatewayRouteTablePropagations", "ec2:GetVpnConnectionDeviceTypes", "ec2:ListImagesInRecycleBin", "ec2:ListSnapshotsInRecycleBin", "ec2:ListVolumesInRecycleBin", "ec2:StartDeclarativePoliciesReport", "lambda:GetAccountSettings", "lambda:ListCapacityProviders", "lambda:ListCodeSigningConfigs", "lambda:ListEventSourceMappings", "lambda:ListFunctions", "lambda:ListLayerVersions", "lambda:ListLayers", "lambda:ListManagedMicrovmImages", "lambda:ListMicrovmImages", "lambda:ListMicrovms", "lambda:ListNetworkConnectors", "s3:GetAccessPoint", "s3:GetAccountPublicAccessBlock", "s3:ListAccessGrantsInstances", "s3:ListAccessPoints", "s3:ListAccessPointsForObjectLambda", "s3:ListAllMyBuckets", "s3:ListJobs", "s3:ListMultiRegionAccessPoints", "s3:ListStorageLensConfigurations", "s3:ListStorageLensGroups"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "User_role_access_2" {
  name   = "User_role-access-2"
  policy = data.aws_iam_policy_document.User_role_access_2_doc.json
}

data "aws_iam_policy_document" "User_role_trust" {
  statement {
    effect = "Allow"
    principals {
      identifiers = [aws_iam_user.User.arn]
      type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "User_role" {
  name                  = "User_role"
  assume_role_policy    = data.aws_iam_policy_document.User_role_trust.json
  force_detach_policies = false
  max_session_duration  = 3600
  path                  = "/"
}

resource "aws_iam_role_policy_attachment" "User_role_access_0_attach" {
  policy_arn = aws_iam_policy.User_role_access_0.arn
  role       = aws_iam_role.User_role.name
}

resource "aws_iam_role_policy_attachment" "User_role_access_1_attach" {
  policy_arn = aws_iam_policy.User_role_access_1.arn
  role       = aws_iam_role.User_role.name
}

resource "aws_iam_role_policy_attachment" "User_role_access_2_attach" {
  policy_arn = aws_iam_policy.User_role_access_2.arn
  role       = aws_iam_role.User_role.name
}

resource "aws_iam_user" "User" {
  name          = "User"
  force_destroy = true
  tags = {
    Name           = "User"
    State          = "State1"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_iam_user_login_profile" "login_User" {
  password_length         = 20
  password_reset_required = true
  user                    = aws_iam_user.User.name
}




### CATEGORY: NETWORK ###

resource "aws_route" "route_k6-panel-lab-rtb-public_to_k6-panel-lab-igw_ipv6" {
  gateway_id                  = data.aws_internet_gateway.k6-panel-lab-igw.id
  route_table_id              = data.aws_route_table.k6-panel-lab-rtb-public.id
  destination_ipv6_cidr_block = "::/0"
}


