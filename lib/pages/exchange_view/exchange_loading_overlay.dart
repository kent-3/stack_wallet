/* 
 * This file is part of Stack Wallet.
 * 
 * Copyright (c) 2023 Cypher Stack
 * All Rights Reserved.
 * The code is distributed under GPLv3 license, see LICENSE file for details.
 * Generated by Cypher Stack on 2023-05-26
 *
 */

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/exchange/changenow_initial_load_status.dart';
import '../../themes/stack_colors.dart';
import '../../utilities/text_styles.dart';
import '../../widgets/custom_loading_overlay.dart';
import '../../widgets/stack_dialog.dart';

class ExchangeLoadingOverlayView extends ConsumerStatefulWidget {
  const ExchangeLoadingOverlayView({
    super.key,
    required this.unawaitedLoad,
  });

  final VoidCallback unawaitedLoad;

  @override
  ConsumerState<ExchangeLoadingOverlayView> createState() =>
      _ExchangeLoadingOverlayViewState();
}

class _ExchangeLoadingOverlayViewState
    extends ConsumerState<ExchangeLoadingOverlayView> {
  late ChangeNowLoadStatus _statusEst;
  late ChangeNowLoadStatus _statusFixed;

  bool userReloaded = false;

  @override
  void initState() {
    _statusEst =
        ref.read(changeNowEstimatedInitialLoadStatusStateProvider.state).state;
    _statusFixed =
        ref.read(changeNowFixedInitialLoadStatusStateProvider.state).state;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("BUILD: $runtimeType");

    ref.listen(
        changeNowEstimatedInitialLoadStatusStateProvider
            .select((value) => value), (previous, next) {
      if (next is ChangeNowLoadStatus) {
        setState(() {
          _statusEst = next;
        });
      }
    });

    ref.listen(
        changeNowFixedInitialLoadStatusStateProvider.select((value) => value),
        (previous, next) {
      if (next is ChangeNowLoadStatus) {
        setState(() {
          _statusFixed = next;
        });
      }
    });

    return Stack(
      children: [
        if (_statusEst == ChangeNowLoadStatus.loading ||
            (_statusFixed == ChangeNowLoadStatus.loading && userReloaded))
          Container(
            color: Theme.of(context)
                .extension<StackColors>()!
                .overlay
                .withOpacity(0.7),
            child: const CustomLoadingOverlay(
              message: "Loading Exchange data",
              eventBus: null,
            ),
          ),
        if ((_statusEst == ChangeNowLoadStatus.failed ||
                _statusFixed == ChangeNowLoadStatus.failed) &&
            _statusEst != ChangeNowLoadStatus.loading &&
            _statusFixed != ChangeNowLoadStatus.loading)
          Container(
            color: Theme.of(context)
                .extension<StackColors>()!
                .overlay
                .withOpacity(0.7),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StackDialog(
                  title: "Failed to fetch Exchange data",
                  message:
                      "Exchange requires a working internet connection. Tap OK to try fetching again.",
                  rightButton: TextButton(
                    style: Theme.of(context)
                        .extension<StackColors>()!
                        .getSecondaryEnabledButtonStyle(context),
                    child: Text(
                      "OK",
                      style: STextStyles.button(context).copyWith(
                        color: Theme.of(context)
                            .extension<StackColors>()!
                            .buttonTextSecondary,
                      ),
                    ),
                    onPressed: () {
                      userReloaded = true;
                      widget.unawaitedLoad();
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
