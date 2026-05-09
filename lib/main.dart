// Importa la librería principal de Flutter para crear interfaces gráficas
import 'package:flutter/material.dart';

// Importa la librería flutter_blue_plus para trabajar con Bluetooth Low Energy (BLE)
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

// Importa la librería para solicitar permisos en Android/iOS
import 'package:permission_handler/permission_handler.dart';

// Este identificador permite encontrar el servicio correcto dentro del dispositivo Bluetooth
final Guid serviceUuid =
    Guid("12345678-1234-1234-1234-123456789abc");

// Aquí llegan los valores de BPM y SpO2
final Guid characteristicUuid =
    Guid("abcd1234-5678-1234-5678-123456789abc");

// Función principal de Flutter
// Inicia la aplicación ejecutando el widget MyApp
void main() {
  runApp(const MyApp());
}

// Clase principal de la aplicación
// StatelessWidget porque no necesita cambiar estados internos
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    // MaterialApp configura la aplicación general
    return const MaterialApp(

      // Quita la etiqueta DEBUG de la esquina superior derecha
      debugShowCheckedModeBanner: false,

      // Pantalla principal de la app
      home: BluetoothScanPage(),
    );
  }
}

// Widget principal donde se realizará el escaneo BLE
// StatefulWidget porque los datos cambian constantemente
class BluetoothScanPage extends StatefulWidget {
  const BluetoothScanPage({super.key});

  @override
  State<BluetoothScanPage> createState() => _BluetoothScanPageState();
}

// Estado interno del widget BluetoothScanPage
class _BluetoothScanPageState extends State<BluetoothScanPage> {

  // Variable que muestra el estado actual de la conexión
  String estado = "Presiona el botón para buscar el ESP32";

  // Lista donde se almacenan los dispositivos BLE encontrados
  List<ScanResult> dispositivosEncontrados = [];

  // Variables para mostrar BPM y SpO2 en pantalla
  String bpm = "--";
  String spo2 = "--";

  // Función para solicitar permisos Bluetooth y ubicación
  // Android requiere permisos de ubicación para escaneo BLE
  Future<void> pedirPermisos() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();
  }

  // Función que realiza el escaneo de dispositivos BLE
  Future<void> buscarDispositivosBLE() async {

    // Primero pide permisos
    await pedirPermisos();

    // Actualiza la interfaz indicando que comenzó el escaneo
    setState(() {
      estado = "Buscando dispositivos BLE...";
      dispositivosEncontrados.clear();
    });

    // Inicia el escaneo Bluetooth durante 6 segundos
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 6),
    );

    // Escucha continuamente los resultados encontrados
    FlutterBluePlus.scanResults.listen((results) {

      // Actualiza la lista de dispositivos encontrados
      setState(() {
        dispositivosEncontrados = results;
      });

      // Recorre cada dispositivo encontrado
      for (ScanResult result in results) {

        // Obtiene el nombre del dispositivo BLE
        String nombre = result.device.platformName;

        // Imprime el nombre en consola
        print("Dispositivo encontrado: $nombre");

        // Si el dispositivo encontrado es el ESP32 esperado
        if (nombre == "MAX30102_ESP32") {

          // Actualiza el estado de la interfaz
          setState(() {
            estado = "¡ESP32 encontrado!";
          });

          // Detiene el escaneo automáticamente
          FlutterBluePlus.stopScan();
        }
      }
    });
  }

  // Función para conectarse al dispositivo BLE seleccionado
  Future<void> conectarDispositivo(BluetoothDevice device) async {

    // Actualiza el estado indicando conexión
    setState(() {
      estado = "Conectando a ${device.platformName}...";
    });

    // Detiene el escaneo antes de conectar
    await FlutterBluePlus.stopScan();

    // Realiza la conexión Bluetooth con el dispositivo
    await device.connect();

    // Actualiza el estado después de conectarse
    setState(() {
      estado = "Conectado. Buscando servicio...";
    });

    // Descubre todos los servicios BLE disponibles en el dispositivo
    List<BluetoothService> services = await device.discoverServices();

    // Recorre cada servicio encontrado
    for (BluetoothService service in services) {

      // Verifica si el servicio coincide con el UUID esperado
      if (service.uuid == serviceUuid) {

        // Recorre las características del servicio
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {

          // Verifica si la característica coincide con el UUID esperado
          if (characteristic.uuid == characteristicUuid) {

            // Activa las notificaciones BLE para recibir datos en tiempo real
            await characteristic.setNotifyValue(true);

            // Actualiza el estado
            setState(() {
              estado = "Recibiendo datos del sensor...";
            });

            // Escucha los datos enviados desde el ESP32
            characteristic.onValueReceived.listen((value) {

              // Convierte los bytes recibidos en texto
              String data = String.fromCharCodes(value);

              // Divide la información usando la coma como separador
              // Ejemplo: "75,98"
              List<String> partes = data.split(",");

              // Verifica que se hayan recibido exactamente 2 datos
              if (partes.length == 2) {

                // Extrae BPM y SpO2
                String bpmRecibido = partes[0];
                String spo2Recibido = partes[1];

                // Imprime los datos en consola
                print("BPM: $bpmRecibido");
                print("SpO2: $spo2Recibido");

                // Actualiza los valores mostrados en pantalla
                setState(() {

                  // Actualiza BPM
                  bpm= bpmRecibido;

                  // Actualiza SpO2
                  spo2 = spo2Recibido;

                  // Cambia el mensaje de estado
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

    // Scaffold crea la estructura principal de la pantalla
    return Scaffold(

      // Color de fondo de toda la app
      backgroundColor: const Color(0xFFF4F7FB),

      // Barra superior de la aplicación
      appBar: AppBar(

        // Título mostrado arriba
        title: const Text("Monitor BLE ESP32", 
        
        // Estilo del texto del título
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,  
        )
      ),

      // Centra el título
      centerTitle: true,

      // Color de fondo de la barra superior
      backgroundColor: const Color(0xFF4F6BFF),

      // Color del texto e iconos del AppBar
      foregroundColor: Colors.white,

      // Elimina sombra inferior del AppBar
      elevation: 0,
    ),

    // Padding agrega espacio alrededor del contenido
    body: Padding(

        padding: const EdgeInsets.all(20),

        // Column organiza widgets verticalmente
        child: Column(
          children: [

            // Caja superior donde se muestra el estado Bluetooth
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),

              // Decoración visual del contenedor
              decoration: BoxDecoration(
                color: const Color(0xFFEAF0FF),
                borderRadius: BorderRadius.circular(20),
            ),

            // Row organiza widgets horizontalmente
            child: Row(
              children: [

                // Icono Bluetooth
                const Icon(
                  Icons.bluetooth,
                  color: Color(0xFF4F6BFF),
                  size: 28,
                ),

                // Espacio horizontal
                const SizedBox(width: 12),

                // Expanded hace que el texto ocupe el espacio restante
                Expanded(
                  child: Text(

                    // Muestra el estado actual
                    estado,

                    // Diseño del texto
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

            // Espacio vertical
            const SizedBox(height: 20),

            // Tarjeta principal donde se muestran BPM y SpO2
            Container(
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),

                // Sombra de la tarjeta
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                  ],
              ),

              // Distribuye BPM y SpO2 horizontalmente
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [

                  // Columna BPM
                  Column(
                    children: [

                      // Icono de corazón
                      const Icon(
                        Icons.favorite,
                        color:Color(0xFFFF4F6D),
                         size:30,
                      ),

                      const SizedBox(height: 8),

                      // Texto BPM
                      const Text(
                        "BPM",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Valor BPM recibido
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

                  // Línea divisoria vertical
                  Container(
                    height: 70,
                    width: 1,
                    color: Colors.grey.shade300,
                  ),

                  // Columna SpO2
                  Column(
                    children: [

                      // Icono de aire/oxígeno
                      const Icon(
                        Icons.air,
                        color: Color(0xFF20C997),
                        size: 30,
                      ),

                      const SizedBox(height: 8),

                      // Texto SpO2
                      const Text(
                        "SpO₂",
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Valor de saturación de oxígeno
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

            // Botón para iniciar búsqueda BLE
            ElevatedButton(

              // Ejecuta buscarDispositivosBLE al presionarlo
              onPressed: buscarDispositivosBLE,

              // Texto del botón
              child: const Text("Buscar ESP32"),
            ),

            const SizedBox(height: 20),

            // Expanded hace que la lista use el espacio restante
            Expanded(

              // Lista dinámica de dispositivos encontrados
              child: ListView.builder(

                // Cantidad de elementos de la lista
                itemCount: dispositivosEncontrados.length,

                // Construye cada elemento visualmente
                itemBuilder: (context, index) {

                  // Obtiene el resultado actual
                  final result = dispositivosEncontrados[index];

                  // Obtiene el dispositivo BLE
                  final device = result.device;

                  // Verifica si el dispositivo tiene nombre
                  final nombre = device.platformName.isNotEmpty
                      ? device.platformName
                      : "Dispositivo sin nombre";

                  // Elemento visual de cada dispositivo
                  return ListTile(

                    // Nombre del dispositivo
                    title: Text(nombre),

                    // ID Bluetooth del dispositivo
                    subtitle: Text(device.remoteId.toString()),

                    // Intensidad de señal Bluetooth
                    trailing: Text("${result.rssi} dBm"),

                    // Acción al tocar el dispositivo
                    onTap: () {

                      // Conecta el dispositivo seleccionado
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