import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zae_labeler/l10n/app_localizations.dart';
import 'package:zae_labeler/common/i18n.dart';
import 'package:zae_labeler/common/common_widgets.dart';
import '../../../core/services/user_preference_service.dart';
import '../../../core/use_cases/app_use_cases.dart';
import '../view_models/project_list_view_model.dart';
import '../../../view_models/locale_view_model.dart';
import '../../../view_models/configuration_view_model.dart';
import '../../../core/models/project_model.dart';
import '../../../views/pages/configuration_page.dart';
import '../../../views/dialogs/onboarding_dialog.dart';
import '../widgets/project_tile.dart';

class ProjectListPage extends StatefulWidget {
  const ProjectListPage({Key? key}) : super(key: key);

  @override
  State<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends State<ProjectListPage> {
  @override
  void initState() {
    super.initState();
    _checkOnboarding();
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        final file = result.files.single;
        final content = file.bytes != null ? utf8.decode(file.bytes!) : await io.File(file.path!).readAsString();
        final jsonData = jsonDecode(content);
        final project = Project.fromJson(jsonData);

        if (!mounted) return;
        final projectListVM = Provider.of<ProjectListViewModel>(context, listen: false);
        await projectListVM.upsertProject(project);

        if (mounted) {
          GlobalAlertManager.show(context, '${context.l10n.message_import_project_success}: ${project.name}', type: AlertType.success);
        }
      }
    } catch (e) {
      if (mounted) {
        GlobalAlertManager.show(context, '${context.l10n.message_import_project_failed}: $e', type: AlertType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appUseCases = context.read<AppUseCases>();
    final loc = AppLocalizations.of(context)!;

    return Consumer2<ProjectListViewModel, LocaleViewModel>(
      builder: (context, projectListVM, localeVM, child) {
        return Scaffold(
          appBar: AppHeader(
            title: loc.projectList_title,
            actions: [
              IconButton(
                icon: const Icon(Icons.help),
                tooltip: context.l10n.appbar_onboarding,
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('hasSeenOnboarding', false);
                  _checkOnboarding();
                },
              ),
              IconButton(icon: const Icon(Icons.refresh), tooltip: context.l10n.appbar_refresh, onPressed: () => projectListVM.loadProjects()),
              PopupMenuButton<String>(
                onSelected: (value) => localeVM.changeLocale(value),
                itemBuilder: (context) => const [PopupMenuItem(value: 'en', child: Text('English')), PopupMenuItem(value: 'ko', child: Text('한국어'))],
                icon: const Icon(Icons.language),
                tooltip: context.l10n.appbar_language,
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: loc.appbar_project_create,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          ChangeNotifierProvider(create: (_) => ConfigurationViewModel(appUseCases: appUseCases), child: const ConfigureProjectPage())),
                ),
              ),
              IconButton(icon: const Icon(Icons.file_upload), tooltip: context.l10n.appbar_project_import, onPressed: () => _importProject(context)),
            ],
          ),
          body: projectListVM.projectVMList.isEmpty
              ? Center(child: Text(context.l10n.projectList_empty))
              : ListView.builder(
                  itemCount: projectListVM.projectVMList.length,
                  itemBuilder: (context, index) {
                    final vm = projectListVM.projectVMList[index];
                    return ProjectTile(key: ValueKey(vm.project.id), vm: vm);
                  },
                ),
        );
      },
    );
  }
}
