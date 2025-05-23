/*
 * This file is part of Stack Wallet.
 *
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 * Generated by Cypher Stack on 2023-05-26
 *
 */

import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../app_config.dart';
import '../../../../providers/global/prefs_provider.dart';
import '../../../../themes/stack_colors.dart';
import '../../../../utilities/assets.dart';
import '../../../../utilities/logger.dart';
import '../../../../utilities/text_styles.dart';
import '../../../../widgets/desktop/desktop_dialog.dart';
import '../../../../widgets/desktop/desktop_dialog_close_button.dart';
import '../../../../widgets/desktop/primary_button.dart';
import '../../../../widgets/log_level_preference_widget.dart';
import '../../../../widgets/rounded_white_container.dart';
import '../../../../widgets/stack_dialog.dart';

class DesktopLoggingDialog extends ConsumerStatefulWidget {
  const DesktopLoggingDialog({super.key});

  @override
  ConsumerState<DesktopLoggingDialog> createState() => _DebugInfoDialog();
}

class _DebugInfoDialog extends ConsumerState<DesktopLoggingDialog> {
  late final TextEditingController fileLocationController;
  bool _lock = false;

  Future<void> _edit() async {
    final currentPath = ref.read(prefsChangeNotifierProvider).logsPath ??
        Logging.instance.logsDirPath;
    final newPath = await _pickDir(context, currentPath);

    // test if has permission to write
    if (newPath != null) {
      final file = File(
        "$newPath${Platform.pathSeparator}._test",
      );
      if (!file.existsSync()) {
        file.createSync();
        file.deleteSync();
      }
    }

    // success
    ref.read(prefsChangeNotifierProvider).logsPath = newPath;

    if (mounted) {
      setState(() {
        fileLocationController.text =
            ref.read(prefsChangeNotifierProvider).logsPath ??
                Logging.instance.logsDirPath;
      });
    }
  }

  Future<String?> _pickDir(BuildContext context, String currentPath) async {
    final String? chosenPath;
    if (Platform.isIOS) {
      chosenPath = currentPath;
    } else {
      final String path =
          Platform.isWindows ? currentPath.replaceAll("/", "\\") : currentPath;
      chosenPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: "Choose Log Save location",
        initialDirectory: path,
        lockParentWindow: true,
      );
    }
    return chosenPath;
  }

  @override
  void initState() {
    super.initState();
    fileLocationController = TextEditingController();
    fileLocationController.text =
        ref.read(prefsChangeNotifierProvider).logsPath ??
            Logging.instance.logsDirPath;
  }

  @override
  void dispose() {
    fileLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopDialog(
      maxHeight: double.infinity,
      maxWidth: 640,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "Logging",
                  style: STextStyles.desktopH3(context),
                  textAlign: TextAlign.center,
                ),
              ),
              const DesktopDialogCloseButton(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              children: [
                Text(
                  "Log files location",
                  style: STextStyles.desktopTextFieldLabel(context),
                  textAlign: TextAlign.left,
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: TextField(
              autocorrect: false,
              enableSuggestions: false,
              controller: fileLocationController,
              style: STextStyles.field(context),
              decoration: InputDecoration(
                hintText: "Save to...",
                hintStyle: STextStyles.fieldLabel(context),
                suffixIcon: UnconstrainedBox(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                      ),
                      SvgPicture.asset(
                        Assets.svg.folder,
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .textDark3,
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                    ],
                  ),
                ),
              ),
              key: const Key(
                "logsDirPathLocationControllerKey",
              ),
              readOnly: true,
              toolbarOptions: const ToolbarOptions(
                copy: true,
                cut: false,
                paste: false,
                selectAll: false,
              ),
              onChanged: (newValue) {},
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          const Padding(
            padding: EdgeInsets.all(32),
            child: LogLevelPreferenceWidget(),
          ),
          if (!Platform.isMacOS)
            const SizedBox(
              height: 8,
            ),
          if (!Platform.isMacOS)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  Expanded(
                    child: RoundedWhiteContainer(
                      borderColor: Theme.of(context)
                          .extension<StackColors>()!
                          .textSubtitle6,
                      child: Text(
                        "NOTE: ${AppConfig.appName} must be restarted in order"
                        " for changes to take effect.",
                        style: STextStyles.desktopTextExtraExtraSmall(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (!Platform.isMacOS)
            const SizedBox(
              height: 16,
            ),
          if (!Platform.isMacOS)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                children: [
                  const Spacer(),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: PrimaryButton(
                      label: "Select log save location",
                      onPressed: () async {
                        if (_lock) {
                          return;
                        }
                        _lock = true;
                        try {
                          await _edit();
                        } catch (e, s) {
                          Logging.instance.e(
                            "Failed to change logs path",
                            error: e,
                            stackTrace: s,
                          );
                          if (context.mounted) {
                            unawaited(
                              showDialog(
                                context: context,
                                builder: (context) => StackOkDialog(
                                  title: "Failed to change logs path",
                                  message: e.toString(),
                                ),
                              ),
                            );
                          }
                        } finally {
                          _lock = false;
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
