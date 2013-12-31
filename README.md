# Abstract

Nodules should provide a simple mechanism for deploying multiple isolated web applications on one host machine. It needs to support process management and a mechanism for relaunching crashed processes. It must provide a unified HTTP and HTTPS proxy with full support for WebSockets. This proxy will allow routing to local ports (inherently belonging to running nodules), and must support SNI for the use of multiple SSL certificates.

# Progress

I have created a process manager and a persistent datastore mechanism for nodules.  Nodules can be added, listed, started, stopped, and changed voa a web API or through the helper commands in `control/`.

I am now working on implementing and testing the proxy. I have yet to create command-line tools for managing the proxy, but I have tested it with HTTP and websockets. I have yet to test it with an SSL certificate, but I will do so soon.

My next step after this will be to generally reorganize this to be suitable for `npm`. I want to add a Cakefile and make an easy-to-use unified control command and a control Node API.

# Internal Implementation

Nodule Database Entry

* Base path
* Identifier (specified ID)
* Arguments
* Environment variables
* Local port
* URLs to serve
* Launch automatically (flag)
* Relaunch on exit

Web Proxy

* Enable WebSockets
* Enable HTTPS
* Port for HTTP and HTTPS
* SSL certificates for HTTPS
* Option to use certificates for different hosts
* Configuration API
  * /proxy/setflag
    * flags = [ws, https, http_port, https_port]
    * value = number or "true"/"false"
  * /proxy/stop
  * /proxy/start
  * /proxy/status

Module Manager

* Nodule object
  * Is running
  * Database entry
  * Start/stop
* Nodule Management API
  * /nodule/add
  * /nodule/remove
  * /nodule/list
  * /nodule/edit
  * /nodule/start
  * /nodule/stop

# Web Interface

Nodules

* View list of nodules
* Add nodule
* Edit nodule information
* Start/stop nodule process

Proxy

* Proxy check boxes for flags
* Proxy port configuration
* Start/stop button
* HTTPS certificates
  * No certificates
  * Single certificate file
  * Multiple keys with SNI & fallback
