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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

import '../../app_config.dart';
import '../../db/db_version_migration.dart';
import '../../db/hive/db.dart';
import '../../notifications/show_flush_bar.dart';
import '../../providers/desktop/storage_crypto_handler_provider.dart';
import '../../providers/global/secure_store_provider.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/assets.dart';
import '../../utilities/constants.dart';
import '../../utilities/flutter_secure_storage_interface.dart';
import '../../utilities/logger.dart';
import '../../utilities/text_styles.dart';
import '../../utilities/util.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/custom_buttons/blue_text_button.dart';
import '../../widgets/desktop/desktop_scaffold.dart';
import '../../widgets/desktop/primary_button.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/rounded_container.dart';
import '../../widgets/stack_text_field.dart';
import '../desktop_home_view.dart';
import 'forgot_password_desktop_view.dart';

class DesktopLoginView extends ConsumerStatefulWidget {
  const DesktopLoginView({
    super.key,
    this.startupWalletId,
    this.load,
  });

  static const String routeName = "/desktopLogin";

  final String? startupWalletId;
  final Future<void> Function()? load;

  @override
  ConsumerState<DesktopLoginView> createState() => _DesktopLoginViewState();
}

class _DesktopLoginViewState extends ConsumerState<DesktopLoginView> {
  late final TextEditingController passwordController;

  late final FocusNode passwordFocusNode;

  bool hidePassword = true;
  bool _continueEnabled = false;

  Future<void> _checkDesktopMigrate() async {
    if (Util.isDesktop) {
      final int dbVersion = DB.instance.get<dynamic>(
            boxName: DB.boxNameDBInfo,
            key: "hive_data_version",
          ) as int? ??
          0;
      if (dbVersion < Constants.currentDataVersion) {
        try {
          await DbVersionMigrator().migrate(
            dbVersion,
            secureStore: ref.read(secureStoreProvider),
          );
        } catch (e, s) {
          Logging.instance.f(
            "Cannot migrate desktop database",
            error: e,
            stackTrace: s,
          );
        }
      }
    }
  }

  bool _loginLock = false;
  Future<void> login() async {
    if (_loginLock) {
      return;
    }
    _loginLock = true;

    try {
      unawaited(
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              LoadingIndicator(
                width: 200,
                height: 200,
              ),
            ],
          ),
        ),
      );

      await Future<void>.delayed(const Duration(seconds: 1));

      // init security context
      await ref
          .read(storageCryptoHandlerProvider)
          .initFromExisting(passwordController.text);

      // init desktop secure storage
      await (ref.read(secureStoreProvider).store as DesktopSecureStore).init();

      // check and migrate if needed
      await _checkDesktopMigrate();

      // load data
      await widget.load?.call();

      // if no errors passphrase is correct
      if (mounted) {
        // pop loading indicator
        Navigator.of(context).pop();

        unawaited(
          Navigator.of(context).pushNamedAndRemoveUntil(
            DesktopHomeView.routeName,
            (route) => false,
          ),
        );
      }
    } catch (e) {
      // pop loading indicator
      Navigator.of(context).pop();

      await Future<void>.delayed(const Duration(seconds: 1));

      if (mounted) {
        await showFloatingFlushBar(
          type: FlushBarType.warning,
          message: e.toString(),
          context: context,
        );
      }
    } finally {
      _loginLock = false;
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: check if we still need to do this with new theming
    // unawaited(Assets.precache(context));

    super.didChangeDependencies();
  }

  @override
  void initState() {
    passwordController = TextEditingController();
    passwordFocusNode = FocusNode();

    super.initState();
  }

  @override
  void dispose() {
    passwordController.dispose();
    passwordFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesktopScaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon(
                  width: 100,
                ),
                const SizedBox(
                  height: 42,
                ),
                Text(
                  AppConfig.appName,
                  style: STextStyles.desktopH1(context),
                ),
                const SizedBox(
                  height: 24,
                ),
                SizedBox(
                  width: 350,
                  child: Text(
                    AppConfig.shortDescriptionText,
                    textAlign: TextAlign.center,
                    style: STextStyles.desktopSubtitleH1(context),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                RoundedContainer(
                  padding: EdgeInsets.zero,
                  height: 74,
                  color: Theme.of(context)
                      .extension<StackColors>()!
                      .textFieldDefaultBG,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      Constants.size.circularBorderRadius,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: TextField(
                        key: const Key("desktopLoginPasswordFieldKey"),
                        focusNode: passwordFocusNode,
                        controller: passwordController,
                        style: STextStyles.desktopTextMedium(context),
                        obscureText: hidePassword,
                        enableSuggestions: false,
                        textAlignVertical: TextAlignVertical.bottom,
                        autocorrect: false,
                        autofocus: true,
                        onSubmitted: (_) {
                          if (_continueEnabled) {
                            login();
                          }
                        },
                        decoration: standardInputDecoration(
                          "Enter password",
                          passwordFocusNode,
                          context,
                        ).copyWith(
                          isDense: true,
                          fillColor: Colors.transparent,
                          focusColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.only(
                            top: 0,
                            left: 16,
                            right: 16,
                            bottom: 0,
                          ),
                          suffixIcon: UnconstrainedBox(
                            child: SizedBox(
                              height: 40,
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  GestureDetector(
                                    key: const Key(
                                      "restoreFromFilePasswordFieldShowPasswordButtonKey",
                                    ),
                                    onTap: () async {
                                      setState(() {
                                        hidePassword = !hidePassword;
                                      });
                                    },
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: SvgPicture.asset(
                                        hidePassword
                                            ? Assets.svg.eye
                                            : Assets.svg.eyeSlash,
                                        color: Theme.of(context)
                                            .extension<StackColors>()!
                                            .textDark3,
                                        width: 20,
                                        height: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        onChanged: (newValue) {
                          setState(() {
                            _continueEnabled =
                                passwordController.text.isNotEmpty;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
                PrimaryButton(
                  label: "Continue",
                  enabled: _continueEnabled,
                  onPressed: login,
                ),
                const SizedBox(
                  height: 60,
                ),
                CustomTextButton(
                  text: "Forgot password?",
                  textSize: 20,
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      ForgotPasswordDesktopView.routeName,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
