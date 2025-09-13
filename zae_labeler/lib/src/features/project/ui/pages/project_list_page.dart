import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zae_labeler/l10n/app_localizations.dart';
import 'package:zae_labeler/common/i18n.dart';
import 'package:zae_labeler/common/common_widgets.dart';
import 'package:zae_labeler/src/features/locale/view_models/locale_view_model.dart';
import 'package:zae_labeler/src/features/project/view_models/project_view_model.dart';
import '../../../../core/services/user_preference_service.dart';
import '../../view_models/project_list_view_model.dart';
import '../../../../core/models/project/project_model.dart';
import 'configuration_page.dart';
import '../../../../views/dialogs/onboarding_dialog.dart';
import '../widgets/project_tile.dart';

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({super.key});

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();

    // 첫 진입: 리스트는 VM 쪽에서 이미 로드된다는 가정하에, 진행률 프리로드만 수행
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final listVM = context.read<ProjectListViewModel>();
      await listVM.preloadProgressForAll(force: true, concurrency: 4);
    });
  }

  Future<void> _checkOnboarding() async {
    final prefs = context.read<UserPreferenceService>();
    if (!prefs.hasSeenOnboarding && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOnboardingOverlay());
    }
  }

  Future<void> _showOnboardingOverlay() async {
    await showDialog(context: context, barrierDismissible: true, builder: (_) => const OnboardingDialog());

    final prefs = context.read<UserPreferenceService>();
    await prefs.setHasSeenOnboarding(true);
  }

  Future<void> _importProject(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result != null) {
        final file = result.files.single;
        final content = file.bytes != null ? utf8.decode(file.bytes!) : await io.File(file.path!).readAsString();

        final jsonData = jsonDecode(content);
        final project = Project.fromJson(jsonData);

        if (!mounted) return;
        final projectListVM = context.read<ProjectListViewModel>();
        await projectListVM.upsertProject(project);

        if (mounted) GlobalAlertManager.show(context, '${context.l10n.message_import_project_success}: ${project.name}', type: AlertType.success);

        // 가져온 직후 진행률 프리로드 한 번 더
        await projectListVM.preloadProgressForAll(force: true, concurrency: 4);
      }
    } catch (e) {
      if (mounted) GlobalAlertManager.show(context, '${context.l10n.message_import_project_failed}: $e', type: AlertType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Consumer2<ProjectListViewModel, LocaleViewModel>(
      builder: (context, projectListVM, localeVM, child) {
        final isPreloading = projectListVM.isPreloadingSummaries;
        final done = projectListVM.preloadDone;
        final total = projectListVM.preloadTotal;

        return Scaffold(
          appBar: AppBar(
            title: Text(isPreloading ? '${loc.projectList_title}  •  $done/$total' : loc.projectList_title),
            bottom: isPreloading ? const PreferredSize(preferredSize: Size.fromHeight(3), child: LinearProgressIndicator(minHeight: 3)) : null,
            actions: [
              // 온보딩 다시 보기
              IconButton(
                icon: const Icon(Icons.help),
                tooltip: context.l10n.appbar_onboarding,
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('hasSeenOnboarding', false);
                  _checkOnboarding();
                },
              ),

              // 진행률 프리로드 새로고침
              IconButton(
                tooltip: '진행률 새로고침',
                icon: const Icon(Icons.autorenew),
                onPressed: isPreloading ? null : () => context.read<ProjectListViewModel>().preloadProgressForAll(force: true, concurrency: 4),
              ),

              // 프로젝트 리스트 재로딩 (메타)
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: context.l10n.appbar_refresh,
                onPressed: () async {
                  await projectListVM.loadProjects();
                  // 메타 새로고침 후 진행률도 재계산(필요 시)
                  await projectListVM.preloadProgressForAll(force: true, concurrency: 4);
                },
              ),

              // 언어 변경
              PopupMenuButton<String>(
                onSelected: (value) => localeVM.changeLocale(value),
                itemBuilder: (context) => const [PopupMenuItem(value: 'en', child: Text('English')), PopupMenuItem(value: 'ko', child: Text('한국어'))],
                icon: const Icon(Icons.language),
                tooltip: context.l10n.appbar_language,
              ),

              // 새 프로젝트 생성
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: loc.appbar_project_create,
                onPressed: () {
                  final vm = projectListVM.createNewProjectVM();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider<ProjectViewModel>.value(value: vm, child: const ConfigureProjectPage()),
                    ),
                  );
                },
              ),

              // 프로젝트 가져오기(JSON)
              IconButton(icon: const Icon(Icons.file_upload), tooltip: context.l10n.appbar_project_import, onPressed: () => _importProject(context)),
            ],
          ),

          // 본문: 당겨서 진행률 프리로드 재시작
          body: projectListVM.projectVMList.isEmpty
              ? Center(child: Text(context.l10n.projectList_empty))
              : RefreshIndicator(
                  onRefresh: () => projectListVM.preloadProgressForAll(force: true, concurrency: 4),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: projectListVM.projectVMList.length,
                    itemBuilder: (context, index) {
                      final vm = projectListVM.projectVMList[index];
                      return ProjectTile(key: ValueKey(vm.project.id), vm: vm);
                    },
                  ),
                ),
        );
      },
    );
  }
}
