import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newstudyapp/pages/note_creation/note_creation_controller.dart';

class NoteCreationPage extends StatelessWidget {
  const NoteCreationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NoteCreationController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('创建笔记'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SafeArea(
        child: Obx(() {
          final isEditingTerms = controller.state.isEditingTerms.value;
          return isEditingTerms
              ? _buildTermsEditor(context, controller)
              : _buildNoteInput(context, controller);
        }),
      ),
    );
  }

  Widget _buildNoteInput(BuildContext context, NoteCreationController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '上传/粘贴你的笔记',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '我们会自动抽取你需要学习的词语，你可以在下一步编辑。',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.state.titleController,
            decoration: InputDecoration(
              labelText: '标题（可选）',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: Colors.black54),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() {
                    final name = controller.state.selectedFileName.value;
                    return Text(
                      name ?? '未选择文件（支持 PDF / DOCX / TXT）',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700]),
                    );
                  }),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: controller.pickFile,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('选择文件'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: Obx(() {
              final loading = controller.state.isLoading.value;
              final hasFile = controller.state.selectedFilePath.value != null;
              return ElevatedButton(
                onPressed: (!hasFile || loading) ? null : controller.extractTermsFromSelectedFile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('上传文件并解析'),
              );
            }),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TextField(
              controller: controller.state.noteTextController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                labelText: '笔记内容',
                alignLabelWithHint: true,
                hintText: '把你的笔记粘贴到这里（支持中英混合）…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Obx(() {
              final loading = controller.state.isLoading.value;
              return ElevatedButton(
                onPressed: loading ? null : controller.extractTerms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2ECC71),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '解析并抽取词语',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsEditor(BuildContext context, NoteCreationController controller) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '编辑待学习词表',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '删除不需要的词，改成你更习惯的写法，或手动添加新词。',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          _AddTermRow(controller: controller),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              final terms = controller.state.terms;
              if (terms.isEmpty) {
                return Center(
                  child: Text(
                    '当前词表为空，你可以先添加几个词语。',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                );
              }

              return ListView.separated(
                itemCount: terms.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final term = terms[index];
                  return _EditableTermTile(
                    initialValue: term,
                    onChanged: (value) => controller.updateTerm(index, value),
                    onRemove: () => controller.removeTerm(index),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: controller.startLearning,
              icon: const Icon(Icons.rocket_launch),
              label: const Text(
                '开始学习',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableTermTile extends StatefulWidget {
  const _EditableTermTile({
    required this.initialValue,
    required this.onChanged,
    required this.onRemove,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
              onChanged: widget.onChanged,
            ),
          ),
          IconButton(
            onPressed: widget.onRemove,
            icon: const Icon(Icons.close, color: Colors.redAccent),
            tooltip: '删除',
          ),
        ],
      ),
    );
  }
}

class _AddTermRow extends StatefulWidget {
  const _AddTermRow({required this.controller});

  final NoteCreationController controller;

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
            decoration: InputDecoration(
              hintText: '手动添加词语…',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('添加'),
          ),
        ),
      ],
    );
  }
}


