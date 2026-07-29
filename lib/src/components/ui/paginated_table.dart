import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:skrim/src/extensions/theme_extension.dart';
import 'package:skrim/theme/app_colors.dart';

class PaginatedTable<T> extends StatefulWidget {
  const PaginatedTable({
    super.key,
    required this.rows,
    required this.columns,
    required this.rowBuilder,
    this.rowsPerPage = 10,
    this.rowsPerPageOptions = const [10, 20, 30],
    this.sortColumnIndex,
    this.sortAscending = true,
    this.headingRowHeight = 48,
    this.dataRowMinHeight = 44,
    this.dataRowMaxHeight = 48,
  });

  final List<T> rows;
  final List<DataColumn> columns;
  final DataRow Function(T row) rowBuilder;
  final int rowsPerPage;
  final List<int> rowsPerPageOptions;
  final int? sortColumnIndex;
  final bool sortAscending;
  final double headingRowHeight;
  final double dataRowMinHeight;
  final double dataRowMaxHeight;

  @override
  State<PaginatedTable<T>> createState() => _PaginatedTableState<T>();
}

class _PaginatedTableState<T> extends State<PaginatedTable<T>> {
  var _page = 0;
  late var _rowsPerPage = widget.rowsPerPage;

  @override
  void didUpdateWidget(covariant PaginatedTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rowsPerPage != widget.rowsPerPage) {
      _rowsPerPage = widget.rowsPerPage;
      _page = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rowsPerPage = _rowsPerPage.clamp(1, 999);
    final total = widget.rows.length;
    final maxPage = total == 0
        ? 0
        : ((total - 1) / rowsPerPage).floor().clamp(0, 999);
    if (_page > maxPage) _page = maxPage;
    final start = total == 0 ? 0 : (_page * rowsPerPage) + 1;
    final end = total == 0 ? 0 : ((_page + 1) * rowsPerPage).clamp(0, total);
    final visibleRows = widget.rows
        .skip(_page * rowsPerPage)
        .take(rowsPerPage)
        .map(widget.rowBuilder)
        .toList();
    final pageSizeOptions = {
      ...widget.rowsPerPageOptions,
      widget.rowsPerPage,
      _rowsPerPage,
    }.where((value) => value > 0).toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: double.maxFinite,
          child: Material(
            type: MaterialType.transparency,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.sportForeground(
                  context,
                ).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.sportForeground(
                    context,
                  ).withValues(alpha: 0.10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 0,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: constraints.maxWidth,
                      ),
                      child: DataTable(
                        sortColumnIndex: widget.sortColumnIndex,
                        sortAscending: widget.sortAscending,
                        headingRowHeight: widget.headingRowHeight,
                        dataRowMinHeight: widget.dataRowMinHeight,
                        dataRowMaxHeight: widget.dataRowMaxHeight,
                        columns: widget.columns,
                        rows: visibleRows,
                      ),
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.sportForeground(
                      context,
                    ).withValues(alpha: 0.08),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                    child: _TablePager(
                      start: start,
                      end: end,
                      total: total,
                      rowsPerPage: rowsPerPage,
                      rowsPerPageOptions: pageSizeOptions,
                      onRowsPerPageChanged: (value) {
                        setState(() {
                          _rowsPerPage = value;
                          _page = 0;
                        });
                      },
                      onPrevious: _page == 0
                          ? null
                          : () => setState(() => _page--),
                      onNext: _page == maxPage
                          ? null
                          : () => setState(() => _page++),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TablePager extends StatelessWidget {
  const _TablePager({
    required this.start,
    required this.end,
    required this.total,
    required this.rowsPerPage,
    required this.rowsPerPageOptions,
    required this.onRowsPerPageChanged,
    required this.onPrevious,
    required this.onNext,
  });

  final int start;
  final int end;
  final int total;
  final int rowsPerPage;
  final List<int> rowsPerPageOptions;
  final ValueChanged<int> onRowsPerPageChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final textStyle = context.textTheme.bodySmall?.copyWith(
      color: AppColors.sportMutedForeground(context),
      fontWeight: FontWeight.w400,
    );

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        Text('$start-$end di $total', style: textStyle),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Text('Righe', style: textStyle),
            FPopoverMenu(
              menuAnchor: Alignment.topRight,
              childAnchor: Alignment.bottomRight,
              menuBuilder: (context, controller, menu) => [
                FItemGroup(
                  children: [
                    for (final option in rowsPerPageOptions)
                      FItem(
                        prefix: option == rowsPerPage
                            ? const Icon(FIcons.check)
                            : const SizedBox.square(dimension: 16),
                        title: Text('$option', style: context.textTheme.bodyMedium,),
                        onPress: () {
                          controller.hide();
                          onRowsPerPageChanged(option);
                        },
                      ),
                  ],
                ),
              ],
              builder: (context, controller, child) {
                return FButton(
                  variant: FButtonVariant.outline,
                  size: FButtonSizeVariant.xs,
                  mainAxisSize: MainAxisSize.min,
                  onPress: controller.toggle,
                  suffix: const Icon(FIcons.chevronDown),
                  child: Text('$rowsPerPage', style: context.textTheme.bodyMedium,),
                );
              },
            ),
            _PagerIconButton(icon: Icons.chevron_left, onPressed: onPrevious),
            _PagerIconButton(icon: Icons.chevron_right, onPressed: onNext),
          ],
        ),
      ],
    );
  }
}

class _PagerIconButton extends StatelessWidget {
  const _PagerIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 18,
      splashRadius: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 32, height: 32),
      color: AppColors.sportForeground(context),
      disabledColor: AppColors.sportMutedForeground(
        context,
      ).withValues(alpha: 0.45),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.sportForeground(
          context,
        ).withValues(alpha: 0.08),
        disabledBackgroundColor: AppColors.sportForeground(
          context,
        ).withValues(alpha: 0.04),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: AppColors.sportForeground(context).withValues(alpha: 0.12),
          ),
        ),
      ),
    );
  }
}
