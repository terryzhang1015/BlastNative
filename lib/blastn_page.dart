import 'dart:io';

import 'package:blast_native/widget/arg_checkbox.dart';
import 'package:blast_native/widget/arg_dropdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:process_run/shell.dart';
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

Shell shell = Shell(throwOnError: false, includeParentEnvironment: false);

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
  ProcessResult? _cmdMakeResult;
  ProcessResult? _cmdBlastnResult;

  String _cmdMake = '';
  String _cmdBlastn = '';

  @override
  void dispose() {
    shell.kill();
    super.dispose();
  }

  void _updateCmdMake() => _cmdMake =
      '${widget.blastDir}\\makeblastdb.exe" -in "${_makeIn != null ? _makeIn!.path : ''}" -dbtype nucl ${(_makeParseSeqids ? '-parse_seqids ' : '')}${(_makeHashIndex ? '-hash_index ' : '')}';
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
    final String? result = await FilePicker.platform.getDirectoryPath();
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
          ElevatedButton(
            onPressed: shell.kill,
            child: const Text('Kill Process'),
          ),
          if (_cmdMakeResult != null)
            Text(
              _cmdMakeResult!.stderr != ''
                  ? 'makeblastdb ERROR:\n    -${_cmdMakeResult!.stderr.toString()}'
                  : 'makeblastdb No Error',
              style: TextStyle(
                color: _cmdMakeResult!.stderr != '' ? Colors.red : Colors.black,
              ),
            ),
          if (_cmdBlastnResult != null)
            SizedBox(
              child: Text(
                _cmdBlastnResult!.stderr != ''
                    ? 'blastn ERROR:\n    -${_cmdBlastnResult!.stderr.toString()}'
                    : 'blastn No Error',
                style: TextStyle(
                  color: _cmdBlastnResult!.stderr != '' ? Colors.red : Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _runMake() async {
    final result = await shell.run(_cmdMake);
    setState(() => _cmdMakeResult = result.first);
  }

  Future<void> _runBlastn() async {
    final result = await shell.run(_cmdBlastn);
    setState(() => _cmdBlastnResult = result.first);
  }

  Future<void> _runCmds() async {
    if (_running) return;
    _cmdMakeResult = _cmdBlastnResult = null;
    setState(() => _running = true);
    try {
      if (_isRunMake) await _runMake();
      if (_cmdMakeResult != null && _cmdMakeResult!.stderr != '') {
        throw const FormatException('Invalid makeblastdb arguments');
      }
      await _runBlastn();
      if (_cmdBlastnResult != null && _cmdBlastnResult!.stderr != '') {
        throw const FormatException('Invalid blastn arguments');
      }
      shell.run('explorer "${'$_blastnOutDir'}"');
      setState(() => _running = false);
    } catch (e) {
      print(_cmdBlastnResult!.stderr);
    } finally {
      setState(() => _running = false);
    }
  }
}
