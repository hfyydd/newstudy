import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/pages/note_creation/note_creation_controller.dart';
import 'package:newstudyapp/config/app_theme.dart';
import 'dart:io';

class NoteCreationPage extends StatelessWidget {
  const NoteCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NoteCreationController());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('创建笔记'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Obx(() {
          final isEditingTerms = controller.state.isEditingTerms.value;
          return isEditingTerms
              ? _buildTermsEditor(context, controller, isDark)
              : _buildNoteInput(context, controller, isDark);
        }),
      ),
    );
  }

  Widget _buildNoteInput(
      BuildContext context, NoteCreationController controller, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              '上传/粘贴你的笔记',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '我们会自动抽取你需要学习的词语，你可以在下一步编辑。',
              style: TextStyle(
                fontSize: 16,
                color: secondaryColor,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: controller.state.titleController,
              decoration: InputDecoration(
                labelText: '标题（可选）',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.attach_file, color: secondaryColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() {
                      final name = controller.state.selectedFileName.value;
                      return Text(
                        name ?? '未选择文件（支持 PDF / DOCX / 图片）',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: secondaryColor),
                      );
                    }),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: controller.pickFile,
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: borderColor),
                    ),
                    child: Text('选择文件', style: TextStyle(color: textColor)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 照片预览（如果选中的是图片）
            Obx(() {
              final path = controller.state.selectedFilePath.value;
              final name =
                  controller.state.selectedFileName.value?.toLowerCase() ?? '';
              if (path != null &&
                  (name.endsWith('.jpg') ||
                      name.endsWith('.jpeg') ||
                      name.endsWith('.png') ||
                      name.endsWith('.webp') ||
                      name.endsWith('.heic'))) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                    image: DecorationImage(
                      image: FileImage(File(path)),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }),
            const SizedBox(height: 0),
            SizedBox(
              width: double.infinity,
              child: Obx(() {
                final loading = controller.state.isLoading.value;
                final hasFile = controller.state.selectedFilePath.value != null;
                return ElevatedButton(
                  onPressed: (!hasFile || loading)
                      ? null
                      : controller.extractTermsFromSelectedFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '上传文件并解析',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                );
              }),
            ),
            const SizedBox(height: 24),
            Container(
              constraints: const BoxConstraints(minHeight: 200),
              child: TextField(
                controller: controller.state.noteTextController,
                maxLines: 10,
                textAlignVertical: TextAlignVertical.top,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: '笔记内容',
                  alignLabelWithHint: true,
                  hintText: '把你的笔记粘贴到这里（支持中英混合）…',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Obx(() {
                final loading = controller.state.isLoading.value;
                return ElevatedButton(
                  onPressed: loading ? null : controller.extractTerms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '解析并抽取词语',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                );
              }),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsEditor(
      BuildContext context, NoteCreationController controller, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black;
    final secondaryColor = isDark ? Colors.grey[500] : Colors.grey[600];
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              '编辑待学习词表',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '删除不需要的词，改成你更习惯的写法，或手动添加新词。',
              style: TextStyle(
                fontSize: 16,
                color: secondaryColor,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
            _AddTermRow(
                controller: controller,
                isDark: isDark,
                textColor: textColor,
                borderColor: borderColor),
            const SizedBox(height: 16),
            Obx(() {
              final terms = controller.state.terms;
              if (terms.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Text(
                      '当前词表为空，你可以先添加几个词语。',
                      style: TextStyle(color: secondaryColor),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  ...terms.asMap().entries.map((entry) {
                    final index = entry.key;
                    final term = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: index < terms.length - 1 ? 12 : 12),
                      child: _EditableTermTile(
                        initialValue: term,
                        onChanged: (value) =>
                            controller.updateTerm(index, value),
                        onRemove: () => controller.removeTerm(index),
                        isDark: isDark,
                        cardColor: cardColor,
                        borderColor: borderColor,
                        textColor: textColor,
                      ),
                    );
                  }),
                ],
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: Obx(() {
                final isSaving = controller.state.isSaving.value;
                return ElevatedButton.icon(
                  onPressed: isSaving ? null : controller.saveAndExit,
                  icon: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    isSaving ? '保存中...' : '提交并保存',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                );
              }),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _EditableTermTile extends StatefulWidget {
  const _EditableTermTile({
    required this.initialValue,
    required this.onChanged,
    required this.onRemove,
    required this.isDark,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;
  final bool isDark;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;

  @override
  State<_EditableTermTile> createState() => _EditableTermTileState();
}

class _EditableTermTileState extends State<_EditableTermTile> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.borderColor, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: TextStyle(color: widget.textColor),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: widget.onChanged,
            ),
          ),
          IconButton(
            onPressed: widget.onRemove,
            icon: const Icon(Icons.close, color: Colors.redAccent),
            tooltip: '删除',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _AddTermRow extends StatefulWidget {
  const _AddTermRow({
    required this.controller,
    required this.isDark,
    required this.textColor,
    required this.borderColor,
  });

  final NoteCreationController controller;
  final bool isDark;
  final Color textColor;
  final Color borderColor;

  @override
  State<_AddTermRow> createState() => _AddTermRowState();
}

class _AddTermRowState extends State<_AddTermRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    widget.controller.addTerm(_controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            style: TextStyle(color: widget.textColor),
            decoration: InputDecoration(
              hintText: '手动添加词语…',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.darkPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child:
              const Text('添加', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
