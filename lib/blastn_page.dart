import 'dart:io';

import 'package:blast_native/widget/arg_checkbox.dart';
import 'package:blast_native/widget/arg_dropdown.dart';
import 'package:file_picker/file_picker.dart';
import 'package:process_run/shell.dart';
import 'package:flutter/material.dart';

const List<String> blastnTasks = ['blastn', 'blastn-short'];
Shell shell = Shell(throwOnError: false);

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
  int _blastnTask = 0;
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
      '${widget.blastDir}\\\\makeblastdb.exe" -in "${_makeIn != null ? _makeIn!.path!.replaceAll('\\', '\\\\') : ''}" -dbtype nucl ${(_makeParseSeqids ? '-parse_seqids ' : '')}${(_makeHashIndex ? '-hash_index ' : '')}';
  void _updateCmdBlastn() => _cmdBlastn =
      '${widget.blastDir}\\\\blastn.exe" -task ${blastnTasks[_blastnTask]} -db "${_makeIn != null ? _makeIn!.path!.replaceAll('\\', '\\\\') : ''}" -query "${_blastnQuery != null ? _blastnQuery!.path!.replaceAll('\\', '\\\\') : ''}" -out "${'$_blastnOutDir\\\\output.txt'}"';

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
      _blastnOutDir = result.replaceAll('\\', '\\\\');
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
              ArgDropdown(
                onChanged: (v) {
                  setState(() => _blastnTask = v);
                  _updateCmdBlastn();
                },
                value: _blastnTask,
                opts: blastnTasks,
              ),
              const Spacer(flex: 1),
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
      if (_cmdBlastnResult != null) {
        throw const FormatException('Invalid blastn arguments');
      }
    } catch (e) {
    } finally {
      setState(() => _running = false);
    }
  }
}
