import 'package:blast_native/blastn_page.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:process_run/shell.dart';

Directory dir = Directory('blast\\bin');
String blastDir = '"${dir.absolute.path.replaceAll('\\', '\\\\')}';

void main() {
  runApp(MaterialApp(home: BlastnPage(blastDir: blastDir)));
}
