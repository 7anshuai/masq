# Masq


Masq 是一个简单的本地 DNS 服务器，类似于 [DNSMasq](http://www.thekelleys.org.uk/dnsmasq/doc.html)。第一个版本来自于 [Pow](https://github.com/basecamp/pow)。

请注意：Masq 目前仅适用于 macOS。

## 本地 DNS

因为不能在 /etc/hosts 文件中使用通配符，无法实现类似功能：
```
127.0.0.1 *.dev.
```
为了解决这个问题，需要安装一个类似于 DNSMasq 的 DNS 代理。如果你是一个 JavaScript 开发者，你可以尝试一下 Masq。

## 开始

Masq（或者 Pow）的 `DnsServer` 被设计为对指定的顶级域名（及其子域名）的 DNS `A` 查询响应 IP 地址 `127.0.0.1`。
当与 Mac OS X的 [/etc/resolver system](http://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man5/resolver.5.html) 结合使用时，不需要添加和删除本地Web开发的主机名等类似配置。

## 安装
```bash
$ npm install -g masq
```

## 使用

用户配置文件 `~/.masqconfig` 在服务启动时读取执行。 您可以配置顶级域，监听端口等选项。如：

```bash
export MASQ_DOMAINS=dev,test
```

然后你可以运行 `masq --print-config`，将会得到如下输出：

```bash
$ masq --print-config
MASQ_BIN='/path/to/masq/bin/masq'
MASQ_DNS_PORT='20560'
MASQ_DOMAINS='dev,test'
```

如果一切正常，运行 `masq --install-system` 来安装系统 DNS 配置文件（需要 root 权限）：
```bash
$ sudo masq --install-system
```

最后运行 DNS 服务器：
```bash
masq
```

现在，试着 ping 任何以 .dev 结尾的地址，应该返回的 IP 地址是 127.0.0.1：
```bash
$ ping example.dev
PING example.dev (127.0.0.1): 56 data bytes
```

## 运行守护进程

生产守护进程配置文件：
```
$ masq --install-local
```

然后：
```
launchctl load ~/Library/LaunchAgents/cx.masq.masqd.plist
```

## 参考链接
- [Pow](https://github.com/basecamp/pow) - Zero-configuration Rack server for Mac OS X
- [Serving Apps Locally with Nginx and Pretty Domains
](https://zaiste.net/posts/serving_apps_locally_with_nginx_and_pretty_domains/)
- [Using Dnsmasq for local development on OS X](https://passingcuriosity.com/2013/dnsmasq-dev-osx/)
- [通过 Nginx 给本地应用取个漂亮域名](http://7anshuai.js.org/blog/work/nginx-and-pretty-domains.html)

## License
[MIT](/LICENSE)
