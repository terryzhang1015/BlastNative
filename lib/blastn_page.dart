import 'dart:io';

import 'package:blast_native/widget/arg_checkbox.dart';
import 'package:blast_native/widget/arg_dropdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

const Map<String, String> blastnTasks = {
  'blastn': 'blastn',
  'blastn-short': 'blastn-short',
};

const Map<String, String> blastnOutfmts = {
  'Pairwise': '0',
  'BLAST XML': '5',
  'Tabular': '6',
  'CSV': '10',
  'Single-file BLAST JSON': '15',
  'Single-file BLAST XML2': '16',
};

// Shell shell = Shell(throwOnError: false);

class BlastnPage extends StatefulWidget {
  const BlastnPage({super.key, required this.blastDir});

  final String blastDir;

  @override
  State<BlastnPage> createState() => _BlastnPageState();
}

class _BlastnPageState extends State<BlastnPage> {
  PlatformFile? _makeIn;
  PlatformFile? _blastnQuery;
  bool _running = false;
  bool _isRunMake = true;
  bool _makeParseSeqids = true;
  bool _makeHashIndex = true;
  String _blastnTask = 'blastn';
  String _blastnOutfmt = '0';
  String? _blastnOutDir;
  dynamic _cmdMakeResult;
  dynamic _cmdBlastnResult;

  String _cmdMake = '';
  String _cmdBlastn = '';

  @override
  void deactivate() {
    print('asdf');
    super.deactivate();
  }

  void _updateCmdMake() => _cmdMake =
      '${widget.blastDir}\\makeblastdb.exe" -in "${_makeIn != null ? _makeIn!.path : ''}" ' +
          '-dbtype nucl ${(_makeParseSeqids ? '-parse_seqids ' : '')}' +
          '${(_makeHashIndex ? '-hash_index ' : '')}';
  void _updateCmdBlastn() =>
      _cmdBlastn = '${widget.blastDir}\\blastn.exe" -task $_blastnTask ' +
          '-db "${_makeIn != null ? _makeIn!.path : ''}" ' +
          '-query "${_blastnQuery != null ? _blastnQuery!.path : ''}" ' +
          '-out "${'$_blastnOutDir\\output.txt'}" -outfmt $_blastnOutfmt';

  Future<void> _pickMakeIn() async {
    final result =
        await FilePicker.platform.pickFiles(allowMultiple: false, lockParentWindow: true);
    if (result == null) return;
    setState(() {
      _makeIn = result.files.first;
      _updateCmdMake();
      _updateCmdBlastn();
    });
  }

  Future<void> _pickBlastnQuery() async {
    final result =
        await FilePicker.platform.pickFiles(allowMultiple: false, lockParentWindow: true);
    if (result == null) return;
    setState(() {
      _blastnQuery = result.files.first;
      _updateCmdBlastn();
    });
  }

  Future<void> _pickFolder() async {
    final String? result =
        await FilePicker.platform.getDirectoryPath(lockParentWindow: true);
    if (result == null) return;
    setState(() {
      _blastnOutDir = result;
      _updateCmdMake();
      _updateCmdBlastn();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),
              ElevatedButton(
                onPressed: _pickMakeIn,
                child: Text(
                  'Choose DB to Init${(_makeIn != null ? ': ${_makeIn!.name}' : '')}',
                ),
              ),
              const Spacer(flex: 1),
              ElevatedButton(
                onPressed: _pickBlastnQuery,
                child: Text(
                  'Choose Blast Query File${(_blastnQuery != null ? ': ${_blastnQuery!.name}' : '')}',
                ),
              ),
              const Spacer(flex: 1),
              ElevatedButton(
                onPressed: _pickFolder,
                child: Text(
                  'Choose Output Dir${_blastnOutDir != null ? ': $_blastnOutDir' : ''}',
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
          Row(children: [
            ArgCheckbox(
              value: _isRunMake,
              text: 'Run makeblastdb',
              onChanged: (v) => setState(() => _isRunMake = v!),
            ),
            if (_isRunMake)
              ArgCheckbox(
                value: _makeParseSeqids,
                text: '-parse_seqids',
                onChanged: (v) {
                  setState(() => _makeParseSeqids = v!);
                  _updateCmdMake();
                },
              ),
            if (_isRunMake)
              ArgCheckbox(
                value: _makeHashIndex,
                text: '-hash_index',
                onChanged: (v) {
                  setState(() => _makeHashIndex = v!);
                  _updateCmdMake();
                },
              ),
          ]),
          Row(
            children: [
              const Spacer(flex: 1),
              ArgDropdown(
                onChanged: (v) {
                  setState(() => _blastnTask = v);
                  _updateCmdBlastn();
                },
                value: _blastnTask,
                opts: blastnTasks,
              ),
              const Spacer(flex: 1),
              ArgDropdown(
                onChanged: (v) {
                  setState(() => _blastnOutfmt = v);
                  _updateCmdBlastn();
                },
                value: _blastnOutfmt,
                opts: blastnOutfmts,
              ),
              const Spacer(flex: 1),
            ],
          ),
          if (_isRunMake && _makeIn != null) Text(_cmdMake),
          if (_makeIn != null && _blastnOutDir != null) Text(_cmdBlastn),
          if (_makeIn != null && _blastnOutDir != null)
            ElevatedButton(
              onPressed: _runCmds,
              child: Text(_running ? 'Running...' : 'Run!'),
            ),
          // ElevatedButton(
          //   onPressed: () {},
          //   child: const Text('Kill Process'),
          // ),
          if (_cmdMakeResult != null)
            Text(
              _cmdMakeResult!.stderr.toString() != ''
                  ? 'makeblastdb ERROR:\n    -${_cmdMakeResult!}'
                  : 'makeblastdb No Error',
              style: TextStyle(
                color:
                    _cmdMakeResult!.stderr.toString() != '' ? Colors.red : Colors.black,
              ),
            ),
          if (_cmdBlastnResult != null)
            SizedBox(
              child: Text(
                _cmdBlastnResult!.stderr.toString() != ''
                    ? 'blastn ERROR:\n    -${_cmdBlastnResult!.toString()}'
                    : 'blastn No Error',
                style: TextStyle(
                  color: _cmdBlastnResult!.stderr.toString() != ''
                      ? Colors.red
                      : Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _runMake() {
    // final result = await shell.run(_cmdMake);
    final result = Process.runSync(
      '${widget.blastDir}\\makeblastdb.exe"',
      [
        '-in',
        _makeIn!.path!,
        '-dbtype',
        'nucl',
        if (_makeParseSeqids) '-parse_seqids',
        if (_makeHashIndex) '-hash_index',
      ],
    );
    setState(() => _cmdMakeResult = result);
    // print(result.stdout.toString());
    // print(result.stderr.toString());
    // stdout.addStream(result.stdout);
    // stderr.addStream(result.stderr);
    // setState(() => _cmdMakeResult = result.stderr);
  }

  void _runBlastn() {
    // final result = await shell.run(_cmdBlastn);
    // _cmdBlastn = '${widget.blastDir}\\blastn.exe" -task $_blastnTask ' +
    //     '-db "${_makeIn != null ? _makeIn!.path : ''}" ' +
    //     '-query "${_blastnQuery != null ? _blastnQuery!.path : ''}" ' +
    //     '-out "${'$_blastnOutDir\\output.txt'}" -outfmt $_blastnOutfmt';
    final result = Process.runSync(
      '${widget.blastDir}\\blastn.exe"',
      [
        '-task',
        _blastnTask,
        '-db',
        _makeIn!.path!,
        '-query',
        _blastnQuery!.path!,
        '-out',
        '$_blastnOutDir\\output.txt',
        '-outfmt',
        _blastnOutfmt,
      ],
    );
    setState(() => _cmdBlastnResult = result);
    // print(result.stdout.toString());
    // print(result.stderr.toString());
  }

  void _runCmds() {
    if (_running) return;
    _cmdMakeResult = _cmdBlastnResult = null;
    setState(() => _running = true);
    try {
      if (_isRunMake) _runMake();
      if (_cmdMakeResult != null && _cmdMakeResult!.stderr != '') {
        throw const FormatException('Invalid makeblastdb arguments');
      }
      _runBlastn();
      if (_cmdBlastnResult != null && _cmdBlastnResult!.stderr != '') {
        throw const FormatException('Invalid blastn arguments');
      }
      // shell.run('explorer "${'$_blastnOutDir'}"');
      Process.run('explorer', [_blastnOutDir!]);
    } catch (e) {
      String? wtf;
      stderr.write(wtf);
      print(wtf);
    } finally {
      setState(() => _running = false);
    }
  }
}
