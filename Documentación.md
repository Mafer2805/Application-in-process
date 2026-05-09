# Aplicación de monitoreo BPM y SpO2 mediante BLE

## Descripción general

Esta aplicación fue desarrollada en Flutter con el objetivo de establecer comunicación inalámbrica mediante Bluetooth Low Energy (BLE) entre un dispositivo móvil y un ESP32 conectado a un sensor MAX30102. La app permite buscar dispositivos BLE cercanos, identificar el ESP32 configurado, conectarse a él y recibir datos biomédicos en tiempo real, específicamente frecuencia cardíaca en BPM y saturación de oxígeno en sangre SpO2.

El proyecto integra funcionalidades de escaneo, conexión y recepción de datos BLE, utilizando las librerías `flutter_blue_plus` y `permission_handler`. La interfaz muestra el estado actual de la conexión, los dispositivos encontrados y los valores recibidos desde el sensor.

## Funcionalidades principales

- Escaneo de dispositivos Bluetooth Low Energy cercanos.
- Solicitud de permisos necesarios para Bluetooth y ubicación.
- Identificación del ESP32 mediante el nombre `MAX30102_ESP32`.
- Conexión al dispositivo BLE seleccionado.
- Búsqueda de servicio y característica BLE mediante UUID.
- Activación de notificaciones para recibir datos del sensor.
- Lectura de valores enviados por el ESP32 en formato `BPM,SpO2`.
- Visualización en pantalla de la frecuencia cardíaca y la saturación de oxígeno.

## Tecnologías utilizadas

- Flutter
- Dart
- Bluetooth Low Energy
- ESP32
- Sensor MAX30102
- Librería `flutter_blue_plus`
- Librería `permission_handler`
- Git y GitHub para control de versiones

## Estructura general del código

El archivo principal contiene la lógica base de la aplicación:

- `main()`: inicia la aplicación y carga el widget principal.
- `MyApp`: define la configuración general de la app Flutter.
- `BluetoothScanPage`: pantalla principal donde se realiza el escaneo BLE.
- `pedirPermisos()`: solicita los permisos necesarios para usar Bluetooth y ubicación.
- `buscarDispositivosBLE()`: inicia el escaneo de dispositivos BLE y actualiza la lista de dispositivos encontrados.
- `conectarDispositivo()`: conecta la app al ESP32, busca el servicio BLE correspondiente y activa la recepción de datos.
- `build()`: construye la interfaz visual de la aplicación.

## Trabajo en ramas

Durante el desarrollo del proyecto se trabajó con más de una rama en GitHub para organizar mejor las contribuciones del equipo. La rama `main` se mantuvo como la rama principal del repositorio, mientras que la rama `prueba_jaz` fue utilizada para integrar y probar cambios relacionados con la comunicación BLE, conexión con el ESP32 y recepción de datos del sensor.

El uso de ramas permitió que cada uno pudiera trabajar en diferentes partes del proyecto sin afectar directamente la versión principal. Posteriormente, los cambios pueden revisarse, compararse y fusionarse mediante GitHub para mantener un flujo de trabajo ordenado.



