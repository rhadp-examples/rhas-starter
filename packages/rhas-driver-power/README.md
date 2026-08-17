# RHAS Power Driver

`rhas-driver-power` is the RHAS fork of the jumpstarter power driver. It
provides the `PowerInterface`/`VirtualPowerInterface` contracts plus mock
implementations for local development and testing.

## Installation

```console
$ uv pip install "git+https://github.com/rhadp-examples/rhas-starter@main#subdirectory=packages/rhas-driver-power"
```

## Configuration

Example configuration:

```yaml
export:
  power:
    type: rhas_driver_power.driver.MockPower
    config: {}
```

## Drivers

- `RhasMockPower` (`rhas_driver_power.driver.MockPower`) — async mock power
  driver, useful for testing power on/off/read flows without real hardware.
- `SyncMockPower` (`rhas_driver_power.driver.SyncMockPower`) — synchronous
  variant of the mock power driver.

## Client API

```python
client.power.on()
client.power.off()
client.power.cycle(wait=2)

for reading in client.power.read():
    print(reading.voltage, reading.current)
```
