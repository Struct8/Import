resource "aws_bedrock_inference_profile" "bedrock_devstral" {
  name = "bedrock_devstral"
  model_source {
    copy_from = "arn:aws:bedrock:${data.aws_region.current.region}::foundation-model/mistral.devstral-2-123b"
  }
  tags = {
    Name           = "bedrock_devstral"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_bedrock_inference_profile" "bedrock_haiku" {
  name = "bedrock_haiku"
  model_source {
    copy_from = "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.anthropic.claude-haiku-5-5"
  }
  tags = {
    Name           = "bedrock_haiku"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_bedrock_inference_profile" "bedrock_nova_2_lite" {
  name = "bedrock_nova_2_lite"
  model_source {
    copy_from = "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.amazon.nova-2-lite-v1:0"
  }
  tags = {
    Name           = "bedrock_nova_2_lite"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}

resource "aws_bedrock_inference_profile" "bedrock_nova_micro" {
  name = "bedrock_nova_micro"
  model_source {
    copy_from = "arn:aws:bedrock:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:inference-profile/us.amazon.nova-micro-v1:0"
  }
  tags = {
    Name           = "bedrock_nova_micro"
    State          = "chat-aurora"
    Struct8Creator = "Contato Struct"
  }
}
