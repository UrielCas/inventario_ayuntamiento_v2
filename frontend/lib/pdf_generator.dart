// Autor: URIEL GUTIÉRREZ CASTILLO
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfGenerator {
  // Función para generar el PDF de Entrada (Recepción - Formato Tabular)
  static Future<Uint8List> generarPdfRecepcion({
    required String folio,
    required String departamento,
    required String tipoEquipo,
    required String marca,
    required String modelo,
    required String diagnostico,
    required String accesorios,
    required String estadoFisico,
    required String quienEntrega,
    required String quienRecibe,
    String telefono = '', // Agregado para que no marque error con tu pantalla
  }) async {
    
    // Carga del logo superior
    final bytesLogo = await rootBundle.load('assets/logo_ayuntamiento.jpeg');
    final imagenLogo = pw.MemoryImage(bytesLogo.buffer.asUint8List());

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter.copyWith(
          marginBottom: 30, marginLeft: 30, marginRight: 30, marginTop: 30
        ),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ================= ENCABEZADO =================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(imagenLogo, width: 150),
                pw.Text('Gobierno Digital e\nInnovación Tecnológica', 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                  textAlign: pw.TextAlign.right,
                ),
              ],
            ),
            pw.SizedBox(height: 15),

            // ================= TABLA PRINCIPAL (Basada en formato físico) =================
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
              child: pw.Column(
                children: [
                  pw.Row(children: [ _celda('N° DE ORDEN INGRESO', flex: 3), _celda('', flex: 3), _celda('FECHA: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', flex: 3), _celda('HORA:', flex: 2)]),
                  pw.Row(children: [ _celda('FECHA DE ENTRADA', flex: 3), _celda('${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', flex: 3), _celda('FECHA DE SALIDA', flex: 3), _celda('', flex: 2)]),
                  pw.Row(children: [ _celda('NOMBRE QUIEN ENTREGA:', flex: 3), _celda(quienEntrega, flex: 8)]),
                  pw.Row(children: [ _celda('NOMBRE DE QUIEN RECIBE:', flex: 3), _celda(quienRecibe, flex: 8)]),
                  pw.Row(children: [ _celda('TELEFONO', flex: 2), _celda(telefono, flex: 3), _celda('EXT', flex: 1), _celda('', flex: 1), _celda('TEL CEL', flex: 2), _celda('', flex: 2)]),
                  pw.Row(children: [ _celda('DEPARTAMENTO', flex: 2), _celda(departamento, flex: 5), _celda('AREA:', flex: 2), _celda('', flex: 2)]),
                  
                  // DATOS DEL EQUIPO
                  pw.Row(children: [ _celda('DATOS DEL EQUIPO', gris: true, flex: 1, alineacion: pw.TextAlign.center) ]),
                  pw.Row(children: [ _celda('TIPO DE EQUIPO:', flex: 2), _celda(tipoEquipo, flex: 9)]),
                  pw.Row(children: [ _celda('MARCA', flex: 2), _celda(marca, flex: 4), _celda('MODELO', flex: 2), _celda(modelo, flex: 3)]),
                  pw.Row(children: [ _celda('N° DE INVENTARIO', flex: 2), _celda(folio, flex: 4), _celda('N° IP', flex: 2), _celda('', flex: 3)]),
                  
                  // DIAGNÓSTICO INICIAL
                  pw.Row(children: [ _celda('DIAGNOSTICO INICIAL', gris: true, flex: 1, alineacion: pw.TextAlign.center) ]),
                  pw.Row(children: [ _celda(diagnostico, flex: 1, altura: 50) ]),

                  // ACCESORIOS ENTREGADOS
                  pw.Row(children: [ _celda('ACCESORIOS ENTREGADOS :', gris: true, flex: 1, alineacion: pw.TextAlign.center) ]),
                ],
              )
            ),

            // TABLITA INTERNA DE ACCESORIOS
            pw.TableHelper.fromTextArray(
              border: pw.TableBorder.all(width: 1),
              cellStyle: const pw.TextStyle(fontSize: 8),
              headers: ['ACCESORIO', 'CANTIDAD', 'INVENTARIO', 'MARCA', 'COLOR', 'OBS.'],
              data: [
                [accesorios.isNotEmpty ? accesorios : 'N/A', '1', folio, marca, '', ''],
                ['', '', '', '', '', ''],
              ]
            ),

            // CONTINUACIÓN DEL FORMATO
            pw.Container(
              decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 1), right: pw.BorderSide(width: 1), bottom: pw.BorderSide(width: 1))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Row(children: [ _celda('ESTADO FISICO DE LA MAQUINA', gris: true, flex: 1, alineacion: pw.TextAlign.center) ]),
                  pw.Row(children: [ _celda(estadoFisico, flex: 1, altura: 30) ]),
                  
                  // FIRMA DE QUIEN ENTREGA (Centro de la hoja)
                  pw.Container(
                    padding: const pw.EdgeInsets.only(top: 25, bottom: 10, left: 20),
                    child: pw.Text('FIRMA DE QUIEN ENTREGA: _________________________________________', style: const pw.TextStyle(fontSize: 9))
                  ),

                  pw.Row(children: [ _celda('EJECUCION DEL SERVICIO', gris: true, flex: 1, alineacion: pw.TextAlign.center) ]),
                  pw.Row(children: [ _celda('', flex: 1, altura: 50) ]), // Espacio en blanco para que el técnico escriba a mano

                  pw.Row(children: [ _celda('REQUERIMIENTO DE REFACCION', gris: true, flex: 1, alineacion: pw.TextAlign.center) ]),
                  pw.Row(children: [ _celda('', flex: 1, altura: 40) ]), // Espacio en blanco para refacciones
                  
                  // ================= BLOQUE DE 3 FIRMAS INFERIORES =================
                  pw.Container(
                    padding: const pw.EdgeInsets.only(top: 40, bottom: 10),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        // Firma Técnico
                        pw.Column(
                          children: [
                            pw.Container(width: 120, height: 1, color: PdfColors.black),
                            pw.SizedBox(height: 5),
                            pw.Text('FIRMA DEL TECNICO', style: const pw.TextStyle(fontSize: 9)),
                          ]
                        ),
                        // Firma Ing. Lechuga
                      pw.Column(
                          children: [
                            pw.Container(width: 120, height: 1, color: PdfColors.black), // <-- LÍNEA AGREGADA
                            pw.SizedBox(height: 5), // <-- ESPACIO
                            pw.Text('ING. LUIS IVAN ORTIZ\nLECHUGA', 
                              textAlign: pw.TextAlign.center, 
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)
                            ),
                          ]
                        ),
                        // Firma Quien Recibe
                        pw.Column(
                          children: [
                            pw.Container(width: 120, height: 1, color: PdfColors.black),
                            pw.SizedBox(height: 5),
                            pw.Text('FIRMA DE QUIEN RECIBE', style: const pw.TextStyle(fontSize: 9)),
                          ]
                        ),
                      ]
                    )
                  )
                ]
              )
            )
          ],
        ),
      ),
    );

    final Uint8List bytes = await pdf.save();
    
    // Comando para abrir la vista previa del PDF en el navegador
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'Recepcion_Oficial_$folio.pdf',
    );

    return bytes;
  }






  // ==========================================
  // FUNCIÓN AUXILIAR PARA DIBUJAR LAS CELDAS EXACTAS
  // ==========================================
  static pw.Widget _celda(String texto, {int flex = 1, bool gris = false, double altura = 15, pw.TextAlign alineacion = pw.TextAlign.left}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        // --- AQUÍ ESTÁ LA CORRECCIÓN ---
        constraints: pw.BoxConstraints(minHeight: altura), 
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5),
          color: gris ? PdfColor.fromHex('#e0e0e0') : PdfColors.white,
        ),
        child: pw.Text(
          texto, 
          textAlign: alineacion, 
          style: pw.TextStyle(fontSize: 9, fontWeight: gris ? pw.FontWeight.bold : pw.FontWeight.normal)
        ),
      ),
    );
  }








  // ==========================================
  // GENERADOR DE ETIQUETA QR
  // ==========================================
  static Future<Uint8List> generarEtiquetaQR(String folio, String tipo) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) => pw.Center(
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('AYUNTAMIENTO POZA RICA', style: const pw.TextStyle(fontSize: 8)),
              pw.SizedBox(height: 5),
              pw.BarcodeWidget(
                data: folio,
                barcode: pw.Barcode.qrCode(),
                width: 60,
                height: 60,
              ),
              pw.SizedBox(height: 5),
              pw.Text('Folio: $folio', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text(tipo, style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
      ),
    );
    
    final Uint8List bytes = await pdf.save();
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => bytes,
      name: 'QR_$folio.pdf',
    );

    return bytes;
  }




// ==========================================
  // GENERADOR DE PDF DE SALIDA (ENTREGA DE EQUIPO REPARADO)
  // ==========================================
  static Future<Uint8List> generarPdfSalida({
    required String folio,
    required String departamento,
    required String tipoEquipo,
    required String marca,
    required String modelo,
    required String diagnostico,
    required String ejecucionServicio,
    required String refacciones,
    required String quienEntrega,
    required String quienRecibe,
  }) async {
    
    final bytesLogo = await rootBundle.load('assets/logo_ayuntamiento.jpeg');
    final imagenLogo = pw.MemoryImage(bytesLogo.buffer.asUint8List());

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.letter.copyWith(
          marginBottom: 30, marginLeft: 30, marginRight: 30, marginTop: 30
        ),
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ================= ENCABEZADO =================
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Image(imagenLogo, width: 150),
                pw.Text('Gobierno Digital e\nInnovación Tecnológica', 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                  textAlign: pw.TextAlign.right,
                ),
              ],
            ),
            pw.SizedBox(height: 15),
            
            // TÍTULO DEL DOCUMENTO
            pw.Center(child: pw.Text('ORDEN DE SALIDA / ENTREGA DE EQUIPO', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
            pw.SizedBox(height: 10),

            // ================= TABLA PRINCIPAL =================
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
              child: pw.Column(
                children: [
                  pw.Row(children: [ _celda('N° DE ORDEN INGRESO', flex: 3), _celda('', flex: 3), _celda('FECHA DE SALIDA: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', flex: 5)]),
                  pw.Row(children: [ _celda('NOMBRE QUIEN ENTREGA (TALLER):', flex: 4), _celda(quienEntrega, flex: 7)]),
                  pw.Row(children: [ _celda('NOMBRE DE QUIEN RECIBE (USUARIO):', flex: 4), _celda(quienRecibe, flex: 7)]),
                  pw.Row(children: [ _celda('DEPARTAMENTO', flex: 2), _celda(departamento, flex: 9)]),
                  
                  pw.Row(children: [ _celda('DATOS DEL EQUIPO', gris: true, flex: 1, alineacion: pw.TextAlign.center) ]),
                  pw.Row(children: [ _celda('TIPO DE EQUIPO:', flex: 2), _celda(tipoEquipo, flex: 9)]),
                  pw.Row(children: [ _celda('MARCA', flex: 2), _celda(marca, flex: 4), _celda('MODELO', flex: 2), _celda(modelo, flex: 3)]),
                  pw.Row(children: [ _celda('N° DE INVENTARIO', flex: 2), _celda(folio, flex: 9)]),
                  
                  pw.Row(children: [ _celda('DIAGNOSTICO INICIAL REPORTADO', gris: true, flex: 1, alineacion: pw.TextAlign.center) ]),
                  pw.Row(children: [ _celda(diagnostico, flex: 1, altura: 30) ]),
                ],
              )
            ),

            pw.Container(
              decoration: const pw.BoxDecoration(border: pw.Border(left: pw.BorderSide(width: 1), right: pw.BorderSide(width: 1), bottom: pw.BorderSide(width: 1))),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // AQUÍ INSERTAMOS LO QUE HIZO EL TÉCNICO
                  pw.Row(children: [ _celda('EJECUCION DEL SERVICIO (TRABAJO REALIZADO)', gris: true, flex: 1, alineacion: pw.TextAlign.center) ]),
                  pw.Row(children: [ _celda(ejecucionServicio, flex: 1, altura: 50) ]), 

                  pw.Row(children: [ _celda('REQUERIMIENTO DE REFACCION / PIEZAS CAMBIADAS', gris: true, flex: 1, alineacion: pw.TextAlign.center) ]),
                  pw.Row(children: [ _celda(refacciones.isEmpty ? 'Ninguna' : refacciones, flex: 1, altura: 40) ]),
                  
                  // ================= BLOQUE DE FIRMAS INFERIORES =================
                  pw.Container(
                    padding: const pw.EdgeInsets.only(top: 40, bottom: 10),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Column(
                          children: [
                            pw.Container(width: 120, height: 1, color: PdfColors.black),
                            pw.SizedBox(height: 5),
                            pw.Text('ENTREGA (TALLER)', style: const pw.TextStyle(fontSize: 9)),
                          ]
                        ),
                        pw.Column(
                          children: [
                            pw.Container(width: 120, height: 1, color: PdfColors.black),
                            pw.SizedBox(height: 5),
                            pw.Text('ING. LUIS IVAN ORTIZ\nLECHUGA', 
                              textAlign: pw.TextAlign.center, 
                              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)
                            ),
                          ]
                        ),
                        pw.Column(
                          children: [
                            pw.Container(width: 120, height: 1, color: PdfColors.black),
                            pw.SizedBox(height: 5),
                            pw.Text('RECIBE (USUARIO)', style: const pw.TextStyle(fontSize: 9)),
                          ]
                        ),
                      ]
                    )
                  )
                ]
              )
            )
          ],
        ),
      ),
    );

    final Uint8List bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => bytes, name: 'Orden_Salida_$folio.pdf');
    return bytes;
  }






}



