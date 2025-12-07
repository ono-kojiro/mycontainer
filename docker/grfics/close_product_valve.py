#!/usr/bin/env python3

import time

#from pymodbus.client.sync import ModbusTcpClient
from pymodbus.client import ModbusTcpClient

host = '192.168.95.13'
port = 502

# Synchronous example
client = ModbusTcpClient(host, port=port)

client.connect()

print("Write to a coil and read back")
client.write_coil(1, True)
response = client.read_coils(1, count=1, device_id=1)

print(response.bits[0])

while True:
  #print("Write to a holding register and read back")
  client.write_registers(address=1, values=[0])

  response = client.read_holding_registers(1, count=1)
  #print(response.registers[0])
  time.sleep(0.02)

client.close()

