// lib/src/pages/labeling_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/labeling_view_model.dart';
import '../models/project_model.dart';

class LabelingPage extends StatelessWidget {
  const LabelingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 전달된 프로젝트 객체 받기
    final Project project =
        ModalRoute.of(context)!.settings.arguments as Project;

    return ChangeNotifierProvider(
      create: (_) => LabelingViewModel(project: project),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${project.name} 라벨링'),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                Provider.of<LabelingViewModel>(context, listen: false)
                    .downloadLabels();
              },
              tooltip: '다운로드',
            ),
          ],
        ),
        body: Consumer<LabelingViewModel>(
          builder: (context, labelingVM, child) {
            return Column(
              children: [
                // 데이터 시각화 (예시로 텍스트 사용)
                Expanded(
                  child: Center(
                    child: Text(
                      labelingVM.currentData,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                // 라벨 입력 키패드
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(10, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ElevatedButton(
                          onPressed: () {
                            labelingVM.addOrUpdateLabel(
                                labelingVM.currentData, index.toString());
                          },
                          child: Text('$index'),
                        ),
                      );
                    }),
                  ),
                ),
                // 데이터 이동 버튼
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          labelingVM.movePrevious();
                        },
                        child: const Text('이전'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          labelingVM.moveNext();
                        },
                        child: const Text('다음'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
