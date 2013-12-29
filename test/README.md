These are a series of tests and demo nodules.

### testadd.coffee

Tests that a nodule can be correctly added via the HTTP API. This test adds `touch_nodule` to the specified nodule server.

### touch_nodule

This is a Node.js nodule which creates a file in its root directory, namely test.txt, which contains the current date and time. After starting up, `touch_nodule` sleeps forever.
