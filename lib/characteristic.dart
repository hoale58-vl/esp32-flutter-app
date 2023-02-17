import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:synchronized/synchronized.dart';

class CharacteristicTileWidget extends StatefulWidget {
  final List<BluetoothCharacteristic> characteristics;
  
  const CharacteristicTileWidget({Key? key, required this.characteristics}) : super(key: key);

  @override
  _CharacteristicTileWidgetState createState() => _CharacteristicTileWidgetState();
}

class _CharacteristicTileWidgetState extends State<CharacteristicTileWidget> {
  final _lock = Lock();

  @override
  void initState() {
    super.initState();
    readState();
  }

  Future<void> readState() async {
    await _lock.synchronized(() async {
      for (var characteristic in widget.characteristics) {
        if (characteristic.properties.notify){
          await characteristic.setNotifyValue(true);
        }
        if (characteristic.properties.read){
          await characteristic.read();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: widget.characteristics.asMap().entries
          .map((entry) => 
              StreamBuilder<List<int>>(
                stream: entry.value.value,
                initialData: entry.value.lastValue,
                builder: (c, snapshot) => ListTile(
                  title: Text(
                    'Kit nổ ${entry.key + 1}',
                  ),
                  leading: Switch(
                    value: snapshot.data != null && snapshot.data!.isNotEmpty && snapshot.data![0] == 1 ? true : false,
                    activeColor: const Color(0xFF6200EE),
                    onChanged:  (bool value) async {
                      entry.value.write([value ? 1 : 0]);
                    },
                  )
                )
              ),
            ).toList()
          );
  }
}