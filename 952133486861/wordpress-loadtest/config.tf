resource "aws_ssm_document" "Struct8Diag-Debug1" {
  name = "Struct8Diag-2zeRq_EaN5iT0PSAbe6RL"
  content = <<EOF
{
  "schemaVersion": "2.2",
  "description": "Struct8 diagnostics: runs one command from a closed list. The list is fixed at apply time and cannot be widened by the caller.",
  "parameters": {
    "command": {
      "type": "String",
      "description": "Which diagnostic to run. Constrained by the document, not by the caller.",
      "allowedValues": [
        "ping",
        "dig",
        "nslookup",
        "traceroute",
        "ss",
        "netstat",
        "ip",
        "route",
        "hostname"
      ]
    },
    "args": {
      "type": "String",
      "description": "Arguments. Shell metacharacters are rejected by the pattern, and the operands that make a command write (add, del, set, flush, a new host name) are refused by the document before it runs.",
      "default": "",
      "allowedPattern": "^[A-Za-z0-9 ._:/=@,+-]{0,200}$"
    }
  },
  "mainSteps": [
    {
      "action": "aws:runShellScript",
      "name": "struct8Diagnostics",
      "inputs": {
        "runCommand": [
          "if [ -z \"$SSM_command\" ]; then export SSM_command=\"{{command}}\"; fi",
          "if [ -z \"$SSM_args\" ]; then export SSM_args=\"{{args}}\"; fi",
          "for tok in $SSM_args; do case \"$tok\" in add|del|delete|set|flush|change|replace|append|update|attach|up|down|exec|-b|-batch|-force) echo \"struct8: operand '$tok' writes; diagnostics is read-only\" >&2; exit 2;; esac; done",
          "if [ \"$SSM_command\" = \"hostname\" ]; then for tok in $SSM_args; do case \"$tok\" in -a|-A|-d|-f|-i|-I|-s|-y|--all-fqdns|--all-ip-addresses|--domain|--fqdn|--ip-address|--short|--long|--alias|--nis) ;; *) echo \"struct8: hostname takes no name here; diagnostics is read-only\" >&2; exit 2;; esac; done; fi",
          "timeout 20 \"$SSM_command\" $SSM_args"
        ]
      }
    }
  ]
}
  EOF
  document_format = "JSON"
  document_type   = "Command"
}

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
