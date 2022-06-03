import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:collection/collection.dart';

const String myServiceUUID = "00005895-0000-1000-8000-00805f9b34fb";
class DeviceScreen extends StatelessWidget {
  const DeviceScreen({Key? key, required this.device}) : super(key: key);

  final BluetoothDevice device;

  Widget _buildCharacteristicTiles(List<BluetoothCharacteristic> characteristics) {
      return  Column(
        children: characteristics.asMap().entries
          .map((entry) => 
              StreamBuilder<List<int>>(
                stream: entry.value.value,
                initialData: entry.value.lastValue,
                builder: (c, snapshot) {
                  final value = snapshot.data;
                  print(value);
                  return ListTile(
                    title: Text(
                      'Kit ${entry.key + 1}'
                    ),
                    leading: Switch(
                      value: value != null && value.isNotEmpty && value[0] == 1 ? true : false,
                      activeColor: const Color(0xFF6200EE),
                      onChanged:  (bool value) async {
                        await entry.value.setNotifyValue(true);
                        entry.value.write([value ? 1 : 0]);
                      },
                    )
                  );
                }
              ),
            ).toList()
          );
  }

  Widget _buildServiceTiles(List<BluetoothService> services) {
    BluetoothService? myService = services.firstWhereOrNull(
      (service) => service.uuid.toString() == myServiceUUID);
      return Container(
        child: myService != null ? _buildCharacteristicTiles(myService.characteristics) : Container(),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(device.name),
        actions: <Widget>[
          StreamBuilder<BluetoothDeviceState>(
            stream: device.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => device.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => device.connect();
                  text = 'CONNECT';
                  break;
                default:
                  onPressed = null;
                  text = snapshot.data.toString().substring(21).toUpperCase();
                  break;
              }
              return TextButton(
                  onPressed: onPressed,
                  child: Text(
                    text,
                    style: Theme.of(context)
                        .primaryTextTheme
                        .button
                        ?.copyWith(color: Colors.white),
                  ));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothDeviceState>(
              stream: device.state,
              initialData: BluetoothDeviceState.connecting,
              builder: (c, snapshot) => ListTile(
                leading: (snapshot.data == BluetoothDeviceState.connected)
                    ? const Icon(Icons.bluetooth_connected)
                    : const Icon(Icons.bluetooth_disabled),
                title: Text('${snapshot.data.toString().split('.')[1]}.'),
                subtitle: Text('${device.id}'),
                trailing: StreamBuilder<bool>(
                  stream: device.isDiscoveringServices,
                  initialData: false,
                  builder: (c, snapshot) => IndexedStack(
                    index: snapshot.data! ? 1 : 0,
                    children: <Widget>[
                      //auto push button when connected to device
                      TextButton(
                        child: const Text("Show options"),
                        onPressed: () => device.discoverServices(),
                      ),
                      const IconButton(
                        icon: SizedBox(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.grey),
                          ),
                          width: 18.0,
                          height: 18.0,
                        ),
                        onPressed: null,
                      )
                    ],
                  ),
                ),
              ),
            ),
            StreamBuilder<List<BluetoothService>>(
              stream: device.services,
              builder: (c, snapshot) {
                return snapshot.data != null ? _buildServiceTiles(snapshot.data!) : Container();
              },
            ),
          ],
        ),
      ),
    );
  }
}
