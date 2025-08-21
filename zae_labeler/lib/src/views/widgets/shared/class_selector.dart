// 📁 src/views/widgets/shared/class_selector.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zae_labeler/src/features/label/view_models/sub_view_models/base_labeling_view_model.dart';
import '../../../../theme/theme.dart';

class ClassSelectorWidget extends StatelessWidget {
  final bool multiSelect;
  final void Function(String label) onLabelSelected;

  const ClassSelectorWidget({Key? key, required this.multiSelect, required this.onLabelSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LabelingViewModel>();

    // 현재 라벨 페이로드(없을 수 있음)
    final payload = vm.currentLabelVM?.labelModel.label;

    // 로딩 중이면 살짝 플레이스홀더
    if (vm.currentLabelVM == null) {
      return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    return Wrap(
      spacing: 8.0,
      children: vm.project.classes.map((label) {
        final bool isSelected = multiSelect ? (payload is Set<String> && payload.contains(label)) : payload == label;

        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onLabelSelected(label), // vm 쪽에서 toggle/update 처리
          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
          labelStyle: TextStyle(color: isSelected ? AppTheme.primaryColor : Colors.black),
        );
      }).toList(),
    );
  }
}
