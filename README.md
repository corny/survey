# TLS Policy Map

This project contains a [SocketMap](http://www.postfix.org/socketmap_table.5.html) daemon for the TLS policy database.


## Requirements

You need python2.7 a up-to-date list of trusted root certificates (`ca-certificates` package on Debian and derivates).


## Installation

### Postfix

These instructions have been tested on Ubuntu 14.04.
We assume that postfix is running in a chroot environment and TLS is enabled for outgoing connections.

Download the TLS policy daemon and make it executable:

    curl https://raw.githubusercontent.com/corny/tlspolicy/socketmap/tlspolicy.py > /usr/bin/tlspolicy
    chmod +x /usr/bin/tlspolicy

Create a directory for the unix socket file:

    mkdir -p /var/spool/postfix/run
    chown postfix /var/spool/postfix/run

Create the [Upstart](http://upstart.ubuntu.com/) configuration and start the service:

    curl https://raw.githubusercontent.com/corny/tlspolicy/socketmap/upstart.conf > /etc/init/tlspolicy.conf
    service tlspolicy start

Check if its working:

    postmap -q "mailbox.org" socketmap:unix:/var/spool/postfix/run/tlspolicy.sock:tlspolicy

Enable the policy map in Postfix by extending the `/etc/postfix/main.cf`:

    smtp_tls_policy_maps = socketmap:unix:/run/tlspolicy.sock:tlspolicy

Apply changes with `postfix reload`.


## Copyright

The classes `MapError` and `Handler` are taken from [Python SocketMap](http://pydoc.net/Python/pysrs/0.30.11/SocketMap/).
Copyright by 2004 Shevek and 2004-2010 Business Management Systems.
Licensed under [SF-2.4](https://www.python.org/download/releases/2.4.2/license/).

All remaining code is Public domain.
