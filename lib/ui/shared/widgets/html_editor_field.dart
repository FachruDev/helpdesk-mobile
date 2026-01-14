import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';

class HtmlEditorField extends StatefulWidget {
  final HtmlEditorController controller;
  final String? labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final double height;

  const HtmlEditorField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.validator,
    this.height = 300,
  });

  @override
  State<HtmlEditorField> createState() => HtmlEditorFieldState();
}

class HtmlEditorFieldState extends State<HtmlEditorField> {
  String? _errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Row(
            children: [
              Icon(Icons.message, size: 18, color: AppColors.textHint),
              const SizedBox(width: 8),
              Text(
                widget.labelText!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(
              color: _errorText != null ? AppColors.error : AppColors.border,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: HtmlEditor(
              controller: widget.controller,
              htmlEditorOptions: HtmlEditorOptions(
                hint: widget.hintText ?? 'Enter text...',
                shouldEnsureVisible: true,
                adjustHeightForKeyboard: true,
              ),
              htmlToolbarOptions: HtmlToolbarOptions(
                toolbarPosition: ToolbarPosition.aboveEditor,
                toolbarType: ToolbarType.nativeScrollable,
                defaultToolbarButtons: [
                  const StyleButtons(),
                  const FontSettingButtons(fontSizeUnit: false),
                  const FontButtons(clearAll: false),
                  const ColorButtons(),
                  const ListButtons(listStyles: false),
                  const ParagraphButtons(
                    textDirection: false,
                    lineHeight: false,
                    caseConverter: false,
                  ),
                  const InsertButtons(
                    video: false,
                    audio: false,
                    table: false,
                    hr: false,
                    otherFile: false,
                  ),
                ],
              ),
              otherOptions: const OtherOptions(
                height: 250,
              ),
            ),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _errorText!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<bool> validate() async {
    if (widget.validator == null) {
      setState(() => _errorText = null);
      return true;
    }

    final text = await widget.controller.getText();
    final error = widget.validator!(text);
    setState(() => _errorText = error);
    return error == null;
  }
}
