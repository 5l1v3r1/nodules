# Nodule

Nodule (formerly "nodules") provides a simple mechanism for deploying multiple isolated web applications on one host machine. It supports process management and has a built-in mechanism for relaunching crashed or terminated processes. It provides a unified HTTP and HTTPS proxy with full support for WebSockets. The proxy allows routing to local and remote ports (inherently belonging to running nodules), and supports SNI for the use of multiple SSL certificates.

# Setup

Install nodule as follows:

    npm install -g nodule

Then, create your default configuration file and save it as `config.json`:

    {
      "proxy": {
        "ws": true,
        "https": false,
        "http": true,
        "ssl": {
          "default_key": "",
          "default_cert": "",
          "sni": {}
        },
        "ports": {
          "http": 80,
          "https": 443
        }
      },
      "password": "5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8",
      "nodules": []
    }

Note that the `password` field here is a SHA1 hash and can be changed later. The HTTP and HTTPS ports are the ports on which the server listens for incoming connections.

Finally, run the nodule server in a detatch-able screen session:

    nodule-server 8000 ./config.json

Now, you can add nodules using the `nodule` command:

    nodule.coffee add password 8000 /path/to/nodule \
        noduleIdentifier 1337 --PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin \
        --NODE_PATH=/usr/local/lib/node_modules --autolaunch \
        --url http://aqnichol.com/myprogram \
        --url http://www.aqnichol.com/myprogram
        --url ws://aqnichol.com/myprogram \
        --url ws://www.aqnichol.com/myprogram \
        --args node main.js 1337

This will add and launch a new nodule by the identifier `noduleIdentifier` which does the following when run:

* `cd /path/to/nodule`
* set PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
* set NODE_PATH=/usr/local/lib/node_modules
* node main.js 1337

When `nodule` is running on the VPS which hosts `aqnichol.com`, the path `/myprogram` will now be proxied automatically to the local server running on port `1337`. This proxying will include WebSockets traffic.

# Managing nodules

You can start or stop a nodule like this:

	nodule start password 8000 <nodule id>
	nodule stop password 8000 <nodule id>

You can delete a nodule like this:

	nodule delete password 8000 <nodule id>

I recommend editing `config.json` to modify an existing nodule, it's just easier. Once you modify the configuration file, you must re-run `nodule-server` to have the changes take effect.

**NOTE:** if you use the `nodule` command whle you have unapplied changes in `config.json`, these changes may be lost. I recommend restarting `nodule-server` right away after editing `config.json`.

# Managing the proxy

Start or stop the proxy like this:

	nodule proxy-start password 8000
	nodule proxy-stop password 8000

Set a flag on the proxy using `nodule proxy-flag`. Edit the certificates configuration using `nodule proxy-setcert`.

# Security

If you are running `nodule` as root, and you probably are, you should be VERY conscious of security. The nodule server essentially becomes a networked `sudo`. I recommend sealing off port `8000` using a firewall. Additionally, you *should definitely* change your nodule password using `nodule passwd`.

Nodule executes all its nodules as children of the `nodule-server` process. If you want a nodule to run as a different user, you should supply `sudo` as your executable and use the `-u` argument to provider a different user. Note that sudo prompts for a password unless it's run by root, so this only works if `nodule-server` is running as root.

# Logging

Nodule automatically saves the stdout and stderr of running nodules. These logs are saved to a `log/` subdirectory of every nodule. Note that logs are only created if the nodule actually *outputs* something. Since all logs are saved indefinitely, it is recommended that the nodules you provide only output to the console when an error occurs.

# Using with Apache

Nodule is nice. Really nice. But what if you already have a web server configured? Well, you can create a new nodule! Checkout my [command nodule](https://gist.github.com/unixpickle/8202073). This nodule can be configured to start and stop Apache like this:

    nodule.coffee add password 8000 /a/path/containing/script \
        apache2 8080 --PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin \
        --NODE_PATH=/usr/local/lib/node_modules --autolaunch \
        --url http://aqnichol.com \
        --url http://www.aqnichol.com
        --url ws://aqnichol.com \
        --url ws://www.aqnichol.com \
        --args coffee main.coffee "/etc/init.d/apache2 start" \
        "/etc/init.d/apache2 stop"

Now, just setup Apache to listen on port 8080, and nodule will forward it for you!

# TODO

* Add nodule command to reload configuration
* Add nodule pipe websocket to pipe input/output from a nodule.
* Add *log* flag to enable or disable logging for stderr and stdout
