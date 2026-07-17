# Myurls

A small self-hosted URL shortener with an optional nip.io-style DNS service.

Myurls can run two services from the same Docker image:

- **Web:** shorten URLs and redirect short links.
- **xip DNS (optional):** resolve an IPv4 address embedded in a hostname.

```text
127.0.0.1.xip.example.com    -> 127.0.0.1
127-0-0-1.xip.example.com    -> 127.0.0.1
app.10-0-0-8.xip.example.com -> 10.0.0.8
```

## Requirements

- A Linux server with a public IPv4 address
- Docker Engine with the `docker compose` command
- A domain name pointed at the server
- Nginx or another reverse proxy for HTTPS
- TCP and UDP port 53 open if the optional xip DNS service is enabled

## Quick start: URL shortener only

Clone the repository and create the local configuration:

```bash
git clone https://github.com/fatjyc/myurls.git
cd myurls
cp .env.example .env
```

Review `.env` if you need to change the local bind address or port. Replace
`short.example.com` in the reverse-proxy examples with your real domain.

Build the image, create the database tables, and start the web service:

```bash
./init_db.sh
docker compose up -d myurls
```

The application is now available locally on the server at
`http://127.0.0.1:9292`.

Check its status:

```bash
docker compose ps
curl -I -H 'Host: short.example.com' http://127.0.0.1:9292/
```

## Reverse proxy and HTTPS

The container only binds the web service to localhost by default. Put Nginx,
Caddy, or another reverse proxy in front of it.

Minimal Nginx configuration:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name short.example.com;

    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://127.0.0.1:9292;
    }
}
```

After enabling the site, issue a certificate. For example, with Certbot:

```bash
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d short.example.com
```

## Enable xip DNS

The DNS service is optional and is placed behind the Compose `xip` profile.
Configure it in `.env`:

```dotenv
XIP_WEB_HOST=xip.example.com
DNS_ZONE=xip.example.com
DNS_DEFAULT_IP=203.0.113.10
DNS_NAMESERVER=short.example.com
```

- `DNS_ZONE` is the delegated hostname suffix.
- `DNS_DEFAULT_IP` is the server's public IPv4 address and is returned for the
  zone root, such as `xip.example.com`.
- `DNS_NAMESERVER` must resolve to the server running this DNS service.
- `XIP_WEB_HOST` makes the web application show the built-in xip documentation
  page when that hostname is opened in a browser.

Start both services:

```bash
docker compose --profile xip up -d --build
```

The DNS container listens on both TCP and UDP port 53. Ensure those ports are
open in the operating-system firewall and cloud-provider firewall.

### Delegate the DNS zone

At the DNS provider for `example.com`, add an NS record:

```text
Type:    NS
Name:    xip
Target:  short.example.com
```

Do not add a wildcard A record such as `*.xip.example.com`. A wildcard A record
would return one fixed address and prevent queries from reaching the dynamic
DNS service.

Once the delegation has propagated, verify both supported formats:

```bash
dig 127.0.0.1.xip.example.com A +short
dig 127-0-0-1.xip.example.com A +short
```

Both commands should return:

```text
127.0.0.1
```

To serve the xip documentation page, add `xip.example.com` to the reverse proxy
and point it to the same web container:

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name xip.example.com;

    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://127.0.0.1:9292;
    }
}
```

Then issue its HTTPS certificate:

```bash
sudo certbot --nginx -d xip.example.com
```

## Configuration

| Variable | Default | Description |
| --- | --- | --- |
| `MYURLS_BIND` | `127.0.0.1` | Host address used for the web port binding. |
| `MYURLS_PORT` | `9292` | Host port used for the web service. |
| `XIP_WEB_HOST` | `xip.1gb.xyz` | Hostname that renders the xip documentation page. |
| `DNS_BIND` | `0.0.0.0` | Address used for TCP/UDP port 53 bindings. |
| `DNS_PORT` | `8053` | DNS port inside the container. |
| `DNS_ZONE` | `xip.1gb.xyz` | Authoritative DNS suffix. |
| `DNS_DEFAULT_IP` | `127.0.0.1` | A record returned for the DNS zone root. |
| `DNS_NAMESERVER` | `localhost` | Nameserver hostname returned by the DNS service. |
| `DNS_TTL` | `300` | DNS response TTL in seconds. |

## Database and backups

Production data is stored in `db/production.sqlite3` and mounted into the web
container. `init_db.sh` runs migrations without deleting existing data.

Back up the database before upgrades:

```bash
cp db/production.sqlite3 "db/production.sqlite3.$(date +%Y%m%d-%H%M%S).bak"
```

Apply new migrations and restart:

```bash
./init_db.sh
docker compose up -d --build myurls
```

## Operations

```bash
# Follow web logs
docker compose logs -f myurls

# Follow DNS logs
docker compose --profile xip logs -f xip

# Restart the web service
docker compose restart myurls

# Stop everything, preserving the database
docker compose --profile xip down
```

### Run web and DNS in one container

The default Compose file keeps web and DNS as separate services so either can
be upgraded or restarted independently. On a small server they can share one
container through the included supervisor:

```yaml
services:
  myurls:
    command: bundle exec ruby bin/myurls-server
    environment:
      - APP_ENV=production
      - RACK_ENV=production
      - ENABLE_XIP_DNS=true
      - DNS_PORT=8053
      - DNS_ZONE=xip.example.com
      - DNS_DEFAULT_IP=203.0.113.10
      - DNS_NAMESERVER=short.example.com
    ports:
      - "127.0.0.1:9292:9292"
      - "53:8053/tcp"
      - "53:8053/udp"
```

The supervisor forwards termination signals and stops the container if either
Unicorn or the DNS process exits unexpectedly, allowing the restart policy to
recover both services.

## Tests

Run the test suite inside the production Ruby environment:

```bash
docker compose build myurls
docker compose run --rm -e APP_ENV=test -e RACK_ENV=test myurls bundle exec rake test
```

## Troubleshooting

### The website returns 502

Check that the container is running and port 9292 is listening:

```bash
docker compose ps
docker compose logs --tail=100 myurls
curl -I http://127.0.0.1:9292/
```

### DNS returns the server IP for every hostname

Remove any wildcard A record for the delegated xip zone. Only the NS delegation
should exist at the parent DNS provider.

### DNS works with `dig @SERVER_IP` but not normally

Confirm the NS delegation, TCP/UDP port 53 firewall rules, and public address:

```bash
dig xip.example.com NS
dig @203.0.113.10 127-0-0-1.xip.example.com A +short
```

### Queries return addresses in `198.18.0.0/15`

Some proxy applications use that range for fake-IP DNS. Add the xip zone to the
proxy's real-IP/bypass list and route the zone directly.

### Old Docker reports `can't create Thread: Operation not permitted`

Upgrade Docker and the host operating system. As a temporary workaround on a
trusted server, add the following to the affected service:

```yaml
security_opt:
  - seccomp:unconfined
```

This disables the container's seccomp filter, so upgrading Docker is the safer
long-term solution.
