import 'package:blast_native/blastn_page.dart';
import 'package:flutter/material.dart';
import 'dart:io';

Directory dir = Directory('blast\\bin');
String blastDir = '"${dir.absolute.path}';

void main() {
  runApp(MaterialApp(home: BlastnPage(blastDir: blastDir)));
}
