import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../models/project_model.dart';
import '../../../view_models/labeling_view_model.dart';
import '../../widgets/labeling_mode_selector.dart';
import '../../widgets/navigator.dart';

abstract class BaseLabelingPage<T extends LabelingViewModel> extends StatefulWidget {
  const BaseLabelingPage({Key? key}) : super(key: key);

  @override
  BaseLabelingPageState<T> createState();
}

abstract class BaseLabelingPageState<T extends LabelingViewModel> extends State<BaseLabelingPage<T>> {
  late FocusNode _focusNode;
  late Project project;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) => FocusScope.of(context).requestFocus(_focusNode));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    project = ModalRoute.of(context)!.settings.arguments as Project;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event, T labelingVM) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        labelingVM.movePrevious();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        labelingVM.moveNext();
      }
    }
  }

  Widget buildBody(T labelingVM);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => createViewModel(),
      child: Consumer<T>(
        builder: (context, labelingVM, child) {
          return (!labelingVM.isInitialized)
              ? const Center(child: CircularProgressIndicator())
              : Scaffold(
                  appBar: AppBar(
                    title: Text('${project.name} 라벨링'),
                  ),
                  body: KeyboardListener(
                    focusNode: _focusNode,
                    autofocus: true,
                    onKeyEvent: (event) => _handleKeyEvent(event, labelingVM),
                    child: Column(
                      children: [
                        LabelingModeSelector.button(
                          selectedMode: project.mode,
                          onModeChanged: (newMode) {},
                        ),
                        const Divider(),
                        Expanded(child: buildBody(labelingVM)),
                        NavigationButtons(onPrevious: labelingVM.movePrevious, onNext: labelingVM.moveNext),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }

  T createViewModel();
}
