# Masq

Masq is a simple local dns server like [DNSMasq](http://www.thekelleys.org.uk/dnsmasq/doc.html). The first version was extracted from [Pow](https://github.com/basecamp/pow).

Please note: Masq is only worked on macOS right now.

[中文说明](/README_CN.md)

## Local DNS
As it is not possible to use wildcards in the `/etc/hosts` file, we cannot specify something like:
```
127.0.0.1 *.dev.
```

To get around this problem, we will install a DNS proxy, like DNSMasq. If you are a JavaScript Developer, you can give a try with Masq.

## Getting Started

Masq/Pow's `DnsServer` is designed to respond to DNS `A` queries with `127.0.0.1` for all subdomains of the specified top-level domain.
When used in conjunction with Mac OS X's [/etc/resolver system](https://www.manpagez.com/man/5/resolver/), there's no configuration needed to add and remove host names for local web development.

## Installation
```bash
$ npm install -g masq
```

## Usage

The user configuration file, `~/.masqconfig`, is evaluated on boot. You can configure options such as the top-level domain, listening ports.

```bash
export MASQ_DOMAINS=dev,test
```

Then you can run `masq --print-config`, it will output like this:

```bash
$ masq --print-config
MASQ_BIN='/path/to/masq/bin/masq'
MASQ_DNS_PORT='20560'
MASQ_DOMAINS='dev,test'
```

If all is ok, run `masq --install-system` to install DNS configuration files (need `sudo`):
```bash
$ sudo masq --install-system
```

Then simply start it:
```bash
masq
```

Now, if we try to ping some any address ending in `.dev`, it should return `127.0.0.1`:
```bash
$ ping example.dev
PING example.dev (127.0.0.1): 56 data bytes
```

## Run as daemon

Generate daemon configuration file:
```
$ masq --install-local
```

Then:
```
launchctl load ~/Library/LaunchAgents/cx.masq.masqd.plist
```

## Inspiration
- [Pow](https://github.com/basecamp/pow) - Zero-configuration Rack server for Mac OS X
- [Serving Apps Locally with Nginx and Pretty Domains
](https://zaiste.net/posts/serving_apps-locally-nginx-pretty-domains/)
- [Using Dnsmasq for local development on OS X](https://passingcuriosity.com/2013/dnsmasq-dev-osx/)

## License
[MIT](/LICENSE)
