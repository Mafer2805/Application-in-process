import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

final Guid serviceUuid =
    Guid("12345678-1234-1234-1234-123456789abc");

final Guid characteristicUuid =
    Guid("abcd1234-5678-1234-5678-123456789abc");

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BluetoothScanPage(),
    );
  }
}

class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});

  @override
  State<BluetoothScanPage> createState() => _BluetoothScanPageState();
}

class _BluetoothScanPageState extends State<BluetoothScanPage> {
  String estado = "Presiona el botón para buscar el ESP32";
  List<ScanResult> dispositivosEncontrados = [];

  Future<void> pedirPermisos() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  Future<void> buscarDispositivosBLE() async {
    await pedirPermisos();

    setState(() {
      estado = "Buscando dispositivos BLE...";
      dispositivosEncontrados.clear();
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 6),
    );

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        dispositivosEncontrados = results;
      });

      for (ScanResult result in results) {
        String nombre = result.device.platformName;

        print("Dispositivo encontrado: $nombre");

        if (nombre == "MAX30102_ESP32") {
          setState(() {
            estado = "¡ESP32 encontrado!";
          });

          FlutterBluePlus.stopScan();
        }
      }
    });
  }

  Future<void> conectarDispositivo(BluetoothDevice device) async {
    setState(() {
      estado = "Conectando a ${device.platformName}...";
    });

    await FlutterBluePlus.stopScan();

    await device.connect();

    setState(() {
      estado = "Conectado. Buscando servicio...";
    });

    List<BluetoothService> services = await device.discoverServices();

    for (BluetoothService service in services) {
      if (service.uuid == serviceUuid) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.uuid == characteristicUuid) {
            await characteristic.setNotifyValue(true);

            setState(() {
              estado = "Recibiendo datos del sensor...";
            });

            characteristic.onValueReceived.listen((value) {
              String data = String.fromCharCodes(value);

              List<String> partes = data.split(",");

              if (partes.length == 2) {
                String bpm = partes[0];
                String spo2 = partes[1];

                print("BPM: $bpm");
                print("SpO2: $spo2");

                setState(() {
                  estado = "BPM: $bpm | SpO2: $spo2%";
                });
              }
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Escaneo BLE ESP32"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              estado,
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: buscarDispositivosBLE,
              child: const Text("Buscar ESP32"),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: dispositivosEncontrados.length,
                itemBuilder: (context, index) {
                  final result = dispositivosEncontrados[index];
                  final device = result.device;

                  final nombre = device.platformName.isNotEmpty
                      ? device.platformName
                      : "Dispositivo sin nombre";

                  return ListTile(
                    title: Text(nombre),
                    subtitle: Text(device.remoteId.toString()),
                    trailing: Text("${result.rssi} dBm"),
                    onTap: () {
                      conectarDispositivo(device);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}