import 'package:acs_upb_mobile/generated/l10n.dart';
import 'package:acs_upb_mobile/pages/filter/model/filter.dart';
import 'package:acs_upb_mobile/pages/filter/service/filter_provider.dart';
import 'package:acs_upb_mobile/resources/locale_provider.dart';
import 'package:acs_upb_mobile/widgets/icon_text.dart';
import 'package:acs_upb_mobile/widgets/scaffold.dart';
import 'package:acs_upb_mobile/widgets/selectable.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FilterPage extends StatefulWidget {
  const FilterPage(
      {Key key,
      this.title,
      this.info,
      this.hint,
      this.buttonText,
      this.onSubmit})
      : super(key: key);

  static const String routeName = '/filter';

  /// By default, this is [S.of(context).navigationFilter]
  final String title;

  /// Helper text that should show at the top of the page
  final String info;

  /// Additional helper text
  final String hint;

  /// Text for the save button (by default, [S.of(context).buttonApply])
  final String buttonText;

  /// Callback after the user submits the page
  final void Function() onSubmit;

  @override
  State<StatefulWidget> createState() => FilterPageState();
}

class FilterPageState extends State<FilterPage> {
  Filter filter;
  Map<FilterNode, SelectableController> nodeControllers = {};

  void _onSelected(bool selection, FilterNode node) {
    if (selection != node.value) node.value = selection;
    if (node.children != null) {
      for (final child in node.children) {
        // Deselect all children
        _onSelected(false, child);
      }
    }
  }

  void _onSelectedExclusive(
      bool selection, FilterNode node, List<FilterNode> nodesOnLevel) {
    // Only one node on level can be selected
    if (selection) {
      for (final otherNode in nodesOnLevel.where((n) => n != node)) {
        _onSelected(false, otherNode);
      }
    }

    _onSelected(selection, node);
  }

  void _buildTree(
      {FilterNode node, Map<int, List<Widget>> optionsByLevel, int level = 0}) {
    if (node.children == null || node.children.isEmpty) {
      return;
    }

    optionsByLevel.putIfAbsent(level, () => <Widget>[]);

    // Add list of options
    final listItems = <Widget>[const SizedBox(width: 10)];

    for (final child in node.children) {
      // Add option
      nodeControllers.putIfAbsent(child, () => SelectableController());
      listItems.add(Selectable(
        label: child.localizedName(context),
        initiallySelected: child.value,
        controller: nodeControllers[child],
        onSelected: (selection) => level != 0
            ? _onSelected(selection, child)
            : _onSelectedExclusive(selection, child, node.children),
      ));
      child.addListener(() {
        if (child.value) {
          nodeControllers[child].select();
        } else {
          nodeControllers[child].deselect();
        }
        setState(() {});
      });

      // Add padding
      listItems.add(const SizedBox(width: 10));
    }

    optionsByLevel[level].add(
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: listItems,
          ),
        ),
      ),
    );

    for (final child in node.children) {
      // Display children if selected
      if (child.value == true) {
        _buildTree(
            node: child, optionsByLevel: optionsByLevel, level: level + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterProvider = Provider.of<FilterProvider>(context);

    return AppScaffold(
      title: widget.title ?? S.of(context).navigationFilter,
      actions: [
        AppScaffoldAction(
          text: widget.buttonText ?? S.of(context).buttonApply,
          onPressed: () {
            filterProvider
              ..enableFilter()
              ..updateFilter(filter);
            if (widget.onSubmit != null) {
              widget.onSubmit();
            }
            Navigator.of(context).pop();
          },
        )
      ],
      body: FutureBuilder<Filter>(
          future: Provider.of<FilterProvider>(context).fetchFilter(context),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              filter ??= snapshot.data;
              final widgets = <Widget>[const SizedBox(height: 10)];

              final optionsByLevel = <int, List<Widget>>{};
              _buildTree(node: filter.root, optionsByLevel: optionsByLevel);
              for (var i = 0; i < filter.localizedLevelNames.length; i++) {
                if (optionsByLevel[i] == null || optionsByLevel.isEmpty) {
                  break;
                }

                widgets
                  // Level name
                  ..add(Padding(
                    padding: const EdgeInsets.only(left: 10, bottom: 8),
                    child: Text(
                        filter.localizedLevelNames[i]
                            [LocaleProvider.localeString],
                        style: Theme.of(context).textTheme.headline6),
                  ))
                  // Level options
                  ..addAll(optionsByLevel[i]);
              }

              return ListView(
                  children: <Widget>[
                        if (widget.info != null)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10, right: 10, top: 10),
                            child: IconText(
                              icon: Icons.info,
                              text: widget.info,
                              style: Theme.of(context).textTheme.bodyText1,
                            ),
                          ),
                        if (widget.hint != null)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 10, right: 10, top: 5),
                            child: Text(
                              widget.hint,
                              style:
                                  TextStyle(color: Theme.of(context).hintColor),
                            ),
                          )
                      ] +
                      widgets);
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          }),
    );
  }
}
