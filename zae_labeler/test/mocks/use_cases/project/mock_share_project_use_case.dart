import 'package:zae_labeler/src/features/project/use_cases/share_project_use_case.dart';
import 'package:zae_labeler/src/features/project/models/project_model.dart';

class MockShareProjectUseCase extends ShareProjectUseCase {
  bool wasCalled = false;
  Project? sharedProject;

  MockShareProjectUseCase({required super.repository});

  @override
  Future<ShareProjectResult> call(Project project) async {
    wasCalled = true;
    sharedProject = project;
    // Return a dummy ShareProjectResult for testing purposes
    return ShareProjectResult.success();
  }
}
