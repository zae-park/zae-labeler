import 'package:flutter/material.dart';
import 'package:zae_labeler/src/features/project/use_cases/share_project_use_case.dart';
import 'package:zae_labeler/src/core/models/project_model.dart';

class MockShareProjectUseCase extends ShareProjectUseCase {
  bool wasCalled = false;
  Project? sharedProject;

  MockShareProjectUseCase({required super.repository});

  @override
  Future<void> call(BuildContext context, Project project) async {
    wasCalled = true;
    sharedProject = project;
  }
}
