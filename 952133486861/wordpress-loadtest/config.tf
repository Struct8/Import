resource "aws_ssm_document" "Struct8Probe-Debug1" {
  name = "Struct8Probe-2zeRq_EaN5iT0PSAbe6RL"
  content = <<EOF
{
  "schemaVersion": "2.2",
  "description": "Struct8 network probe. The command text is fixed here; the caller supplies only a target and a port.",
  "parameters": {
    "target": {
      "type": "String",
      "description": "Hostname or IP address to probe.",
      "interpolationType": "ENV_VAR",
      "allowedPattern": "^[A-Za-z0-9._-]{1,253}$"
    },
    "port": {
      "type": "String",
      "description": "TCP port to test.",
      "default": "443",
      "interpolationType": "ENV_VAR",
      "allowedPattern": "^[0-9]{1,5}$"
    }
  },
  "mainSteps": [
    {
      "action": "aws:runShellScript",
      "name": "struct8Probe",
      "inputs": {
        "timeoutSeconds": "60",
        "runCommand": [
          "if [ -z \"$SSM_target\" ]; then export SSM_target=\"{{target}}\"; fi",
          "if [ -z \"$SSM_port\" ]; then export SSM_port=\"{{port}}\"; fi",
          "echo '--- resolve ---'",
          "getent hosts \"$SSM_target\" || echo \"no DNS answer\"",
          "echo '--- icmp ---'",
          "ping -c 3 -W 2 \"$SSM_target\" || echo \"no ICMP reply (often filtered, not conclusive)\"",
          "echo '--- tcp ---'",
          "if timeout 5 bash -c 'exec 3<>/dev/tcp/\"$1\"/\"$2\"' _ \"$SSM_target\" \"$SSM_port\" 2>/dev/null; then echo \"port $SSM_port open\"; else echo \"port $SSM_port closed or filtered\"; fi"
        ]
      }
    }
  ]
}
  EOF
  document_format = "JSON"
  document_type   = "Command"
}
