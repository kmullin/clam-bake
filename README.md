# Clam Bake

### Description

A simple HTTP API for `libclamav` to scan files from URLs.

All output is in JSON format for easy portability.

### Synopsis

```
GET /              Simple test website for manually scanning URLs
GET /info          Returns: Output # of virus signatures in loaded database
POST /scan         Takes: url param (must begin with http(s)?)
                   Returns: virus = false if no virus, null if wasnt scanned, and virus name if has virus
PUT /reload        Returns: true or false if reload database from disk
GET /virus_test    Returns: a file with Eicar-Test-Signature for testing
```
