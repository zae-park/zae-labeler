import 'dart:convert';
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zae_labeler/common/common_widgets.dart';
import 'package:zae_labeler/common/i18n.dart';
import 'package:zae_labeler/l10n/app_localizations.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/models/project/project_model.dart';
import '../../../../views/dialogs/onboarding_dialog.dart';
import '../../../locale/providers/locale_provider.dart';
import '../../providers/project_providers.dart';
import '../widgets/project_tile.dart';
import 'configuration_page.dart';

class ProjectListPage extends ConsumerStatefulWidget {
  const ProjectListPage({super.key});

  @override
  ConsumerState<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends ConsumerState<ProjectListPage> {
  @override
  void initState() {
    super.initState();
    if (!ref.read(userPreferenceServiceProvider).hasSeenOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showOnboarding());
    }
  }

  Future<void> _showOnboarding() async {
    if (!mounted) return;
    await showDialog(context: context, barrierDismissible: true, builder: (_) => const OnboardingDialog());
    await ref.read(userPreferenceServiceProvider).setHasSeenOnboarding(true);
  }

  Future<void> _importProject() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null) return;
      final file = result.files.single;
      final content = file.bytes != null ? utf8.decode(file.bytes!) : await io.File(file.path!).readAsString();
      final project = Project.fromJson(jsonDecode(content));

      await ref.read(projectListProvider.notifier).upsert(project);
      if (mounted) GlobalAlertManager.show(context, '${context.l10n.message_import_project_success}: ${project.name}', type: AlertType.success);
    } catch (e) {
      if (mounted) GlobalAlertManager.show(context, '${context.l10n.message_import_project_failed}: $e', type: AlertType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final projects = ref.watch(projectListProvider);

    return Scaffold(
      appBar: AppHeader(
        title: loc.projectList_title,
        actions: [
          IconButton(icon: const Icon(Icons.help), tooltip: context.l10n.appbar_onboarding, onPressed: _showOnboarding),
          IconButton(tooltip: '진행률 새로고침', icon: const Icon(Icons.refresh), onPressed: () => ref.invalidate(projectSummaryProvider)),
          IconButton(icon: const Icon(Icons.sync), tooltip: context.l10n.appbar_refresh, onPressed: () => ref.read(projectListProvider.notifier).reload()),
          PopupMenuButton<String>(
            onSelected: (value) => ref.read(localeProvider.notifier).changeLocale(value),
            itemBuilder: (context) => const [PopupMenuItem(value: 'en', child: Text('English')), PopupMenuItem(value: 'ko', child: Text('한국어'))],
            icon: const Icon(Icons.language),
            tooltip: context.l10n.appbar_language,
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: loc.appbar_project_create,
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConfigureProjectPage(project: null))),
          ),
          IconButton(icon: const Icon(Icons.file_upload), tooltip: context.l10n.appbar_project_import, onPressed: _importProject),
        ],
      ),
      body: projects.when(
        data: (list) => list.isEmpty
            ? Center(child: Text(context.l10n.projectList_empty))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) => ProjectTile(key: ValueKey(list[index].id), project: list[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('프로젝트를 불러오지 못했습니다: $e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => ref.read(projectListProvider.notifier).reload(), child: const Text('다시 시도')),
            ],
          ),
        ),
      ),
    );
  }
}
