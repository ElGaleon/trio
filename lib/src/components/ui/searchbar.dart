import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:skrim/src/extensions/theme_extension.dart';
import 'package:skrim/theme/app_colors.dart';

class Searchbar extends ConsumerStatefulWidget {
  final String label;
  final String? hint;
  final Function(String) onChange;
  final String? initialValue;

  const Searchbar({
    super.key,
    required this.label,
    required this.onChange,
    this.initialValue,
    this.hint,
  });

  @override
  ConsumerState<Searchbar> createState() => _SearchbarState();
}

class _SearchbarState extends ConsumerState<Searchbar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = context.textTheme.bodyMedium;
    return FTextFormField(
      control: FTextFieldControl.managed(
        controller: _searchController,
        onChange: (value) => widget.onChange(value.text),
      ),
      style: FTextFieldStyleDelta.delta(
        contentTextStyle: FVariantsDelta.delta([
          FVariantOperation.all(
            TextStyleDelta.delta(
              color: AppColors.sportForeground(context),
              fontFamily: textStyle?.fontFamily,
              fontFamilyFallback: textStyle?.fontFamilyFallback,
              fontWeight: FontWeight.w400,
            ),
          ),
        ]),
        hintTextStyle: FVariantsDelta.delta([
          FVariantOperation.all(
            TextStyleDelta.delta(
              color: AppColors.sportMutedText,
              fontFamily: textStyle?.fontFamily,
              fontFamilyFallback: textStyle?.fontFamilyFallback,
              fontWeight: FontWeight.w400,
            ),
          ),
        ]),
      ),
      prefixBuilder: (context, style, states) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Icon(FIcons.search, size: 16),
      ),
      hint: widget.hint,
    );
  }
}
