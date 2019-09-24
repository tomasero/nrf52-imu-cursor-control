# Example of low level interaction with a BLE UART device that has an RX and TX
# characteristic for receiving and sending data.  This doesn't use any service
# implementation and instead just manipulates the services and characteristics
# on a device.  See the uart_service.py example for a simpler UART service
# example that uses a high level service implementation.
# Author: Tony DiCola
import logging
import time
import uuid
import socket

import Adafruit_BluefruitLE
import socket
import sys
import atexit

# Enable debug output.
#logging.basicConfig(level=logging.DEBUG)

# Define service and characteristic UUIDs used by the UART service.
UART_SERVICE_UUID = uuid.UUID('6E400001-B5A3-F393-E0A9-E50E24DCCA9E')
TX_CHAR_UUID      = uuid.UUID('6E400002-B5A3-F393-E0A9-E50E24DCCA9E')
RX_CHAR_UUID      = uuid.UUID('6E400003-B5A3-F393-E0A9-E50E24DCCA9E')

# Get the BLE provider for the current platform.
ble = Adafruit_BluefruitLE.get_provider()

# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
#
## Connect the socket to the port where the server is listening
server_address = ('localhost', 33336)
print('connecting to %s port %s' % server_address)
#
def sendData(data):
    sock.sendto(data, server_address)
def closeSocket():
    sock.close()
# Main function implements the program logic so it can run in a background
# thread.  Most platforms require the main thread to handle GUI events and other
# asyncronous events like BLE actions.  All of the threading logic is taken care
# of automatically though and you just need to provide a main function that uses
# the BLE provider.
num_devices = 3
conn_devices = 0
rxs = []
def main():
    # Clear any cached data because both bluez and CoreBluetooth have issues with
    # caching data and it going stale.
    ble.clear_cached_data()

    # Get the first available BLE network adapter and make sure it's powered on.
    adapter = ble.get_default_adapter()
    adapter.power_on()
    print('Using adapter: {0}'.format(adapter.name))

    # Disconnect any currently connected UART devices.  Good for cleaning up and
    # starting from a fresh state.
    print('Disconnecting any connected UART devices...')
    ble.disconnect_devices([UART_SERVICE_UUID])

    # Scan for UART devices.
    print('Searching for UART device...')
     
    try:
        adapter.start_scan()
        # Search for the first UART device found (will time out after 60 seconds
        # but you can specify an optional timeout_sec parameter to change it).
        devices = ble.find_devicess(service_uuids=[UART_SERVICE_UUID])
        print(devices)
        if len(devices) == 0:
            raise RuntimeError('Failed to find UART device!')
        for device in devices:
            if device is None:
                raise RuntimeError('Failed to find UART device!')
    finally:
        # Make sure scanning is stopped before exiting.
        adapter.stop_scan()
        #atexit.register(adapter.stop_scan)

    print('Connecting to device...')
    for device in devices:
        device.connect()  # Will time out after 60 seconds, specify timeout_sec parameter
                      # to change the timeout.

    # Once connected do everything else in a try/finally to make sure the device
    # is disconnected when done.
    try:
        # Wait for service discovery to complete for at least the specified
        # service and characteristic UUID lists.  Will time out after 60 seconds
        # (specify timeout_sec parameter to override).
        print('Discovering services...')
        for device in devices:
            device.connect()  # Will time out after 60 seconds, specify timeout_sec parameter
            device.discover([UART_SERVICE_UUID], [TX_CHAR_UUID, RX_CHAR_UUID])
            # Find the UART service and its characteristics.
            uart = device.find_service(UART_SERVICE_UUID)
            rx = uart.find_characteristic(RX_CHAR_UUID)
            rxs.append(rx)
        tx = uart.find_characteristic(TX_CHAR_UUID)

        # Write a string to the TX characteristic.
        #print('Sending message to device...')
        #tx.write_value('Hello world!\r\n')

        # Function to receive RX characteristic changes.  Note that this will
        # be called on a different thread so be careful to make sure state that
        # the function changes is thread safe.  Use queue or other thread-safe
        # primitives to send data to other threads.
        def received(data):
            print('Received: {0}'.format(data))
            sendData(data)
            parsed = data.decode("utf-8").split(',')
            cmd = parsed[0]
            if (cmd == 'I'):
                print('IMU') 
                x = parsed[1]
                y = parsed[1]
                z = parsed[1]
            elif (cmd == 'G'):
                print('TAP')
            else:
                print("Unknown Command")
            #accX = data[0]+(data[1]<<8)+(data[2]<<16)+(data[3]<<24)
            #accY = data[4]+(data[5]<<8)+(data[6]<<16)+(data[7]<<24)
            #accZ = data[8]+(data[9]<<8)+(data[10]<<16)+(data[11]<<24)
            #gyrX = data[12]+(data[13]<<8)+(data[14]<<16)+(data[15]<<24)
            #gyrY = data[16]+(data[17]<<8)+(data[18]<<16)+(data[19]<<24)
            #gyrZ = data[20]+(data[21]<<8)+(data[22]<<16)+(data[23]<<24)
            #if data[1] >= 128:
            #    accX = accX - 65536 
            #if data[5] >= 128:
            #    accY = accY- 65536 
            #if data[9] >= 128:
            #    accZ = accZ - 65536 
            #if data[13] >= 128:
            #    gyrX = gyrX - 65536 
            #if data[17] >= 128:
            #    gyrY = gyrY - 65536 
            #if data[21] >= 128:
            #    gyrZ = gyrZ - 65536
            #s = str(accX) + ", " + str(accY) + ", " + str(accZ) + ", " + str(gyrX) + ", " + str(gyrY) + ", " + str(gyrZ)
            #print(s)              
        # Turn on notification of RX characteristics using the callback above.
        print('Subscribing to RX characteristic changes...')
        for rx in rxs:
            rx.start_notify(received)

        # Now just wait for 30 seconds to receive data.
        print('Waiting 60 seconds to receive data from the device...')
        time.sleep(100)
    finally:
        # Make sure device is disconnected on exit.
        adapter.stop_scan()
        device.disconnect()
        closeSocket()        


# Initialize the BLE system.  MUST be called before other BLE calls!
ble.initialize()

# Start the mainloop to process BLE events, and run the provided function in
# a background thread.  When the provided main function stops running, returns
# an integer status code, or throws an error the program will exit.
ble.run_mainloop_with(main)
