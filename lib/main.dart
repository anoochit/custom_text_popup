import 'dart:developer';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String sampleText =
      'A macro, close-up view of the [orange blue and green petals, the pink yellow and purple petals, the red white and black petals, the yellow orange and red petals, the blue purple and white petals] of a [dahlia flower,hydrangea,rose,sunflower] in bright, saturated colors in a Mexican mural art painting style.';

  void updateText(String newText) {
    setState(() {
      sampleText = newText;

      log(newText);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Popup prompt'),
        ),
        body: Column(
          children: [
            CustomTextPopup(
              text: sampleText,
              onChanged: (String resultText) {
                log(resultText);
                // You can use the resultText to update your state or perform any other actions
              },
            )
          ],
        ),
      ),
    );
  }
}

class CustomTextPopup extends StatefulWidget {
  final String text;
  final Function(String)? onChanged;

  const CustomTextPopup({
    super.key,
    required this.text,
    this.onChanged,
  });

  @override
  State<CustomTextPopup> createState() => _CustomTextPopupState();
}

class _CustomTextPopupState extends State<CustomTextPopup> {
  final RegExp _customFieldRegex = RegExp(r'\[([^\]]+)\]');
  late Map<String, String> _selectedOptions;

  @override
  void initState() {
    super.initState();
    _selectedOptions = {};
    _initializeSelectedOptions();
  }

  void _initializeSelectedOptions() {
    for (Match match in _customFieldRegex.allMatches(widget.text)) {
      String field = match.group(1)!;
      List<String> options = _getOptions(field);
      _selectedOptions[field] = options.first;
    }
  }

  List<String> _getOptions(String field) {
    return field.split(',').map((e) => e.trim()).toList();
  }

  String _generateResultText() {
    String result = widget.text;
    _selectedOptions.forEach((field, selection) {
      result = result.replaceFirst('[$field]', selection);
    });
    return result;
  }

  Widget _buildPopupMenu(String field) {
    List<String> options = _getOptions(field);

    return PopupMenuButton<String>(
      initialValue: _selectedOptions[field],
      onSelected: (String newValue) {
        setState(() {
          _selectedOptions[field] = newValue;
          String resultText = _generateResultText();
          widget.onChanged?.call(resultText);
        });
      },
      itemBuilder: (BuildContext context) {
        return options.map((String option) {
          return PopupMenuItem<String>(
            value: option,
            child: Text(option),
          );
        }).toList();
      },
      child: Text(
        _selectedOptions[field]!,
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<InlineSpan> textSpans = [];
    int lastMatchEnd = 0;

    for (Match match in _customFieldRegex.allMatches(widget.text)) {
      if (match.start > lastMatchEnd) {
        textSpans.add(
            TextSpan(text: widget.text.substring(lastMatchEnd, match.start)));
      }
      String field = match.group(1)!;
      textSpans.add(WidgetSpan(child: _buildPopupMenu(field)));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < widget.text.length) {
      textSpans.add(TextSpan(text: widget.text.substring(lastMatchEnd)));
    }

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: textSpans,
      ),
    );
  }
}

class CustomTextEdit extends StatefulWidget {
  final String text;
  final Function(String) onTextChanged;

  const CustomTextEdit(
      {super.key, required this.text, required this.onTextChanged});

  @override
  State<CustomTextEdit> createState() => _CustomTextEditState();
}

class _CustomTextEditState extends State<CustomTextEdit> {
  late List<InlineSpan> textSpans;

  @override
  void initState() {
    super.initState();
    textSpans = _buildTextSpans();
  }

  List<InlineSpan> _buildTextSpans() {
    List<InlineSpan> spans = [];
    RegExp exp = RegExp(r'\[([^\]]+)\]');
    int lastMatchEnd = 0;

    for (Match match in exp.allMatches(widget.text)) {
      if (match.start > lastMatchEnd) {
        spans.add(
            TextSpan(text: widget.text.substring(lastMatchEnd, match.start)));
      }

      spans.add(
        WidgetSpan(
          child: IntrinsicWidth(
            child: TextField(
              controller: TextEditingController(text: match.group(1)),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.blue),
              onChanged: (value) {
                String newText = widget.text
                    .replaceRange(match.start, match.end, '[$value]');
                widget.onTextChanged(newText);
              },
            ),
          ),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(lastMatchEnd)));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: textSpans,
      ),
    );
  }
}
