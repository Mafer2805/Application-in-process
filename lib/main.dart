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

  String bpm = "--";
  String spo2 = "--";

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
                String bpmRecibido = partes[0];
                String spo2Recibido = partes[1];

                print("BPM: $bpmRecibido");
                print("SpO2: $spo2Recibido");

                setState(() {
                  bpm= bpmRecibido;
                  spo2 = spo2Recibido;

    
                  estado = "Datos recibidos correctamente";
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
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: const Text("Monitor BLE ESP32", 
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,  
        )
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF4F6BFF),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    body: Padding(

        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.bluetooth,
                  color: Color(0xFF4F6BFF),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    estado,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ),  
              ]
            ),
            ),
            const SizedBox(height: 20),


            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                  ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Icon(
                        Icons.favorite,
                        color:Color(0xFFFF4F6D),
                         size:30,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "BPM",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bpm,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF4F6D),
                        ),
                      ),
                      ]
                  ),

                  Container(
                    height: 70,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),

                  Column(
                    children: [
                      const Icon(
                        Icons.air,
                        color: Color(0xFF20C997),
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "SpO₂",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$spo2%",
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF20C997)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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