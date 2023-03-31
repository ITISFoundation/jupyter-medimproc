#!/bin/python
""" Healthcheck script to run inside docker

Example of usage in a Dockerfile
```
    COPY --chown=scu:scu docker/run_health_check.py docker/run_health_check.py
    HEALTHCHECK --interval=30s \
                --timeout=30s \
                --start-period=1s \
                --retries=3 \
                CMD python3 docker/run_health_check.py http://localhost:8080/v0/
```

Q&A:
    1. why not to use curl instead of a python script?
        - SEE https://blog.sixeyed.com/docker-healthchecks-why-not-to-use-curl-or-iwr/
"""

import os
import sys
from urllib.request import urlopen

HEALTHY, UNHEALTHY = 0, 1

# Disabled if boots with debugger
ok = os.environ.get("SC_BOOT_MODE", "").lower() == "debug"

# Queries host
ok = (
    ok
    or urlopen("{host}".format(host=sys.argv[1])).getcode() == 200
)

sys.exit(HEALTHY if ok else UNHEALTHY)
