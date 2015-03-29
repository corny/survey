# TLS Policy Map

This project contains a [SocketMap](http://www.postfix.org/socketmap_table.5.html) daemon for the TLS policy database.


## Installation


### Download and install the daemon

Download the TLS policy daemon:

    curl https://raw.githubusercontent.com/corny/tlspolicy/socketmap/tlspolicy.py > /etc/postfix/tls_policy

If you are using Upstart, create a upstart configuration:

    TODO


### Postfix

Add to the `/etc/postfix/main.cf`:

    smtp_tls_policy_maps = socketmap:unix:/var/run/tls_policy.sock:tls_policy

Apply changes with `postfix reload`.
The map can be tested with:

    postmap -q "mailbox.org" socketmap:unix:/var/run/tls_policy.sock:tls_policy


## Copyright

The classes `MapError` and `Handler` are taken from [Python SocketMap](http://pydoc.net/Python/pysrs/0.30.11/SocketMap/).
Copyright by 2004 Shevek and 2004-2010 Business Management Systems.
Licensed under [SF-2.4](https://www.python.org/download/releases/2.4.2/license/).

All remaining code is Public domain.
