resource "cloudflare_workers_route" "worker-gcp-route" {
  zone_id = "719dfb5768a225d400fc49e5e8a04f25"
  pattern = "worker.gcp.cloudman.pro/*"
  script  = cloudflare_workers_script.gcp-hello.script_name
}

resource "cloudflare_workers_script" "gcp-hello" {
  account_id         = "bf9638139fc9b9a92fa0334ae15ac3ac"
  script_name        = "gcp-hello"
  compatibility_date = "2026-11-13"
  content = <<EOF
export default {
  async fetch(request) {
    const url = new URL(request.url);
    return new Response('Hello from a Cloudflare Worker at ' + url.hostname + '\n', {
      headers: { 'content-type': 'text/plain; charset=utf-8' }
    });
  }
};
  EOF
  main_module = "worker.js"
  usage_model = "standard"
}

resource "cloudflare_workers_script_subdomain" "gcp-hello_subdomain" {
  account_id       = "bf9638139fc9b9a92fa0334ae15ac3ac"
  script_name      = cloudflare_workers_script.gcp-hello.script_name
  enabled          = false
  previews_enabled = true
}
