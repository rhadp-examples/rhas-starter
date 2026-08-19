# rhas-starter
A starter project for building RHIVOS/AutoSD images with sample automotive applications.

## TLDR

Build a simple RHIVOS image and run it locally (Qemu):

```shell
# start the build
bin/caib image build-dev manifests/minimal.aib.yml \
  --target qemu --internal-registry \
  --arch arm64 \
  --mode image \
  --format qcow2 \
  -o ./images/minimal.qcow2

# unpack and start localy
gunzip images/minimal.qcow2.gz

./bin/air --nographics images/minimal.qcow2
```

Log in with **root** / **password**, then verify:

```shell
uname -r
uname -m
```
