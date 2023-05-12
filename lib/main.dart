import 'dart:convert';

import 'package:averquetalweb/reporte.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share_whatsapp/share_whatsapp.dart';
import 'package:url_launcher/url_launcher.dart';

const _kTextMessage =
    'Hola *ROBERTO!* Te recordamos que tienes una visita programada en nuestro taller _AUTROMOTRIZ MARTINEZ_ *MAÑANA* a las *11:30am* para *SERVICIO DE FRENOS*. ¡Esperamos verte pronto!';

void main() {
  runApp(
    const MaterialApp(
      home: MyApp(),
    ),
  );
  // runApp(const MaterialApp(
  //   home: HomePage(),
  // ));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _mapInstalled =
      WhatsApp.values.asMap().map<WhatsApp, String?>((key, value) {
    return MapEntry(value, null);
  });

  @override
  void initState() {
    super.initState();
    _checkInstalledWhatsApp();
  }

  Future<void> _checkInstalledWhatsApp() async {
    String whatsAppInstalled = await _check(WhatsApp.standard),
        whatsAppBusinessInstalled = await _check(WhatsApp.business);

    if (!mounted) return;

    setState(() {
      _mapInstalled[WhatsApp.standard] = whatsAppInstalled;
      _mapInstalled[WhatsApp.business] = whatsAppBusinessInstalled;
    });
  }

  Future<String> _check(WhatsApp type) async {
    try {
      return await shareWhatsapp.installed(type: type)
          ? 'INSTALLED'
          : 'NOT INSTALLED';
    } on PlatformException catch (e) {
      return e.message ?? 'Error';
    }
  }

  Future<Directory> getDirectory() async {
    return await getApplicationDocumentsDirectory();
  }

  void sendWhatsAppMessage() async {
    String phoneNumber =
        '+52 1 833 382 0929'; // Número de teléfono del destinatario
    String message = 'Hola, ¿cómo estás?'; // Mensaje a enviar

    var url = 'https://wa.me/$phoneNumber?text=HelloWorld';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'No se pudo abrir la URL: $url';
    }
  }

  String generateCode(String secretKey) {
    // Obtener el tiempo actual en segundos
    int time = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Concatenar la llave secreta y el tiempo actual
    String combined = secretKey + time.toString();

    // Calcular el hash criptográfico (SHA-256) del valor combinado
    List<int> bytes = utf8.encode(combined);
    Digest hash = sha256.convert(bytes);

    // Tomar solo los primeros 4 dígitos del valor hash y convertirlos a decimal
    int decimal = int.parse(hash.toString().substring(0, 8), radix: 16);

    // Asegurarse de que el código de acceso tenga exactamente 4 dígitos
    String code = decimal.toString().padLeft(8, '0');

    return code;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share WhatsApp Example'),
      ),
      body: ListView(
        children: ListTile.divideTiles(
          context: context,
          tiles: [
            ListTile(
              title: const Text('Genera código de 4 dígitos'),
              trailing: const Icon(Icons.share),
              onTap: () {
                String code = generateCode('taller');
                print(code);
              },
            ),
            ListTile(
              title: const Text('Enviar PDFs a número especifico'),
              trailing: const Icon(Icons.share),
              onTap: () async {
                final dir = (await getDirectory()).path;
                XFile file = XFile('$dir/algo3.pdf', name: 'example.pdf');

                await shareWhatsapp.share(
                  text: 'Hello World',
                  file: file,
                  phone: '+52 1 833 295 6072',
                );
              },
            ),
            ListTile(
              title: const Text('Enviar Mensaje de Cita'),
              trailing: const Icon(Icons.share),
              onTap: () => shareWhatsapp.share(
                text: _kTextMessage,
                // change with real whatsapp number
                phone: '+52 1 833 295 6072',
              ),
            ),
            ListTile(
              title: const Text('Generar Reporte'),
              trailing: const Icon(Icons.share),
              onTap: () async {
                final dir = (await getDirectory()).path;
                var pdf = await generateReporte(
                  PdfPageFormat.letter,
                  ticket: [
                    {
                      "tipo": "concepto",
                      "nombre": "Thermostato",
                      "seleccionado": 180.00,
                    },
                    {
                      "tipo": "concepto",
                      "nombre": "Reemplazo de Thermostato",
                      "seleccionado": 220.00,
                    },
                  ],
                  items: [
                    {
                      "tipo": "servicio",
                      "nombre": "Afinación Mayor Completa",
                    },
                    {
                      "tipo": "seccion",
                      "nombre": "Cambio de Bujias",
                    },
                    {
                      "tipo": "respuesta",
                      "nombre": "normal",
                      "seleccionado": "done",
                    },
                    {
                      "tipo": "respuesta",
                      "nombre": "Platino",
                      "seleccionado": "No aplica",
                    },
                    {
                      "tipo": "respuesta",
                      "nombre": "Iridium",
                      "seleccionado": "No aplica",
                    },
                  ],
                  domicilio: 'Buen Canada Linda Vista #320',
                  fecha:
                      DateFormat('d MMMM yyyy [h:mm a]').format(DateTime.now()),
                  tel: '(833) 321 22 44',
                  tipoMantenimiento: 'Diagóstico',
                  cliente: 'Lupe',
                  datosGenerales: 'Jetta 2015',
                );
                final file = File('$dir/algo3.pdf');
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Reporte Generado'),
                    content: Text('El reporte se ha generado correctamente'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Aceptar'))
                    ],
                  ),
                );
                await file.writeAsBytes(pdf).whenComplete(() {
                  Navigator.pop(context);
                });
              },
            ),
            ListTile(
              title: const Text('Ver PDF Generado'),
              trailing: const Icon(Icons.share),
              onTap: () async {
                final dir = (await getDirectory()).path;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(),
                      body: PDFView(
                        filePath: '$dir/algo3.pdf',
                        enableSwipe: true,
                        swipeHorizontal: true,
                        autoSpacing: false,
                        pageFling: false,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ).toList(),
      ),
    );
  }
}

// class HomePage extends StatefulWidget {
//   const HomePage({super.key});

//   @override
//   State<HomePage> createState() => _HomePageState();
// }

// class _HomePageState extends State<HomePage> {
//   Future<Directory> getDirectory() async {
//     return await getApplicationDocumentsDirectory();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("My App"),
//       ),
//       body: Center(
//         child: FutureBuilder(
//           future: getDirectory(),
//           builder: (BuildContext context, AsyncSnapshot<Directory> snapshot) {
//             String? dir = snapshot.data?.path.toString();
//             if (snapshot.hasData) {
//               return Column(
//                 children: [
//                   ElevatedButton(
//                     onPressed: () async {
//                       var pdf = await generateReporte(PdfPageFormat.letter);
//                       final file = File('$dir/example6.pdf');
//                       await file.writeAsBytes(pdf);
//                     },
//                     child: const Text("Click Me2"),
//                   ),
//                   Text('$dir/example5.pdf'),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => Scaffold(
//                             appBar: AppBar(),
//                             body: PDFView(
//                               filePath: '$dir/example6.pdf',
//                               enableSwipe: true,
//                               swipeHorizontal: true,
//                               autoSpacing: false,
//                               pageFling: false,
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                     child: const Text("pdf Me"),
//                   ),
//                 ],
//               );
//             } else {
//               return const CircularProgressIndicator();
//             }
//           },
//         ),
//       ),
//     );
//   }
// }
