# RHAS OpenDAL Driver

`rhas-driver-opendal` is the RHAS fork of the jumpstarter OpenDAL/flasher
adapter. It streams files to and from any storage backend supported by
[Apache OpenDAL](https://opendal.apache.org/), preferring presigned URLs when
the backend supports them and falling back to streaming through the
jumpstarter client/exporter connection otherwise.

## Installation

```console
$ uv pip install "git+https://github.com/rhadp-examples/rhas-starter@main#subdirectory=packages/rhas-driver-opendal"
```

## Usage

`RhasOpendal` (`rhas_driver_opendal.adapter.OpendalAdapter`) is registered as a
`jumpstarter.adapters` entry point and is used as a context manager around a
client call that expects a resource, e.g. a flasher's `flash`/`dump` methods:

```python
from opendal import Operator
from rhas_driver_opendal.adapter import OpendalAdapter

operator = Operator("s3", bucket="images", region="us-east-1")

with OpendalAdapter(client=client, operator=operator, path="root.qcow2", mode="rb") as resource:
    client.qemu.flash(resource)
```

Supported options:

- `mode`: `"rb"` (read) or `"wb"` (write).
- `compression`: optional compression algorithm applied to the stream.
- `original_url`: bypass OpenDAL presigning and stream directly from a given
  HTTP URL (read mode only, incompatible with `compression`).
