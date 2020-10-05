import 'package:acs_upb_mobile/authentication/model/user.dart';
import 'package:acs_upb_mobile/authentication/service/auth_provider.dart';
import 'package:acs_upb_mobile/generated/l10n.dart';
import 'package:acs_upb_mobile/pages/filter/model/filter.dart';
import 'package:acs_upb_mobile/pages/filter/service/filter_provider.dart';
import 'package:acs_upb_mobile/pages/filter/view/filter_page.dart';
import 'package:acs_upb_mobile/resources/custom_icons.dart';
import 'package:acs_upb_mobile/widgets/selectable.dart';
import 'package:acs_upb_mobile/widgets/toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RelevanceController {
  _RelevancePickerState _state;

  String get degree =>
      _state?._filterApplied == true ? _state?._filter?.baseNode : null;

  bool get private =>
      _state?._onlyMeController?.isSelected ??
      _state?.widget?.defaultPrivate ??
      true;

  bool get anyone =>
      _state?._anyoneController?.isSelected ??
      _state?.widget != null && _state.widget.defaultRelevance == null;

  List<String> get customRelevance {
    final relevance = <String>[];
    if (_state?._customControllers != null) {
      _state._customControllers.forEach((node, controller) {
        if (controller.isSelected) {
          relevance.add(node);
        }
      });
    }

    return relevance.isEmpty ? null : relevance;
  }
}

class RelevancePicker extends StatefulWidget {
  const RelevancePicker(
      {@required this.filterProvider,
      this.defaultPrivate = true,
      this.defaultRelevance,
      this.controller});

  final FilterProvider filterProvider;

  /// Whether the 'Only me' option should be enabled by default
  final bool defaultPrivate;

  /// This is only used if [defaultPrivate] is `false`
  final List<String> defaultRelevance;

  final RelevanceController controller;

  @override
  _RelevancePickerState createState() => _RelevancePickerState();
}

class _RelevancePickerState extends State<RelevancePicker> {
  // The three relevance options ("Only me", "Anyone" or an arbitrary list of nodes) are mutually exclusive
  final _onlyMeController = SelectableController();
  final _anyoneController = SelectableController();
  Map<String, SelectableController> _customControllers = {};

  User _user;
  Filter _filter;

  bool _filterApplied = false;

  Future<void> _fetchUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _user = await authProvider.currentUser;
    setState(() {});
  }

  Future<void> _fetchFilter() async {
    _filter = await widget.filterProvider.fetchFilter(context);
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _fetchUser();
    _fetchFilter();
  }

  Widget _customRelevanceButton() {
    final buttonColor = _user?.canAddPublicWebsite ?? false
        ? Theme.of(context).accentColor
        : Theme.of(context).hintColor;

    return IntrinsicWidth(
      child: GestureDetector(
        onTap: () {
          if (_user?.canAddPublicWebsite ?? false) {
            Navigator.of(context)
                .push(MaterialPageRoute<ChangeNotifierProvider>(
              builder: (_) => ChangeNotifierProvider.value(
                value: widget.filterProvider,
                child: FilterPage(
                  title: S.of(context).labelRelevance,
                  buttonText: S.of(context).buttonSet,
                  info:
                      '${S.of(context).infoRelevanceNothingSelected} ${S.of(context).infoRelevance}',
                  hint: S.of(context).infoRelevanceExample,
                  onSubmit: () async {
                    // Deselect all options
                    _onlyMeController.deselect();
                    _anyoneController.deselect();

                    // Select the new options
                    await _fetchFilter();
                    setState(() => _filterApplied = true);
                    if (_filter.relevantLeaves.contains('All')) {
                      _anyoneController.select();
                    }
                  },
                ),
              ),
            ));
          } else {
            AppToast.show(S.of(context).warningNoPermissionToAddPublicWebsite);
          }
        },
        child: Row(
          children: <Widget>[
            Text(
              S.of(context).labelCustom,
              style: Theme.of(context)
                  .accentTextTheme
                  .subtitle2
                  .copyWith(color: buttonColor),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: buttonColor,
              size: Theme.of(context).textTheme.subtitle2.fontSize,
            )
          ],
        ),
      ),
    );
  }

  void _onCustomSelected(bool selected) => setState(() {
        if (_user?.canAddPublicWebsite ?? false) {
          if (selected) {
            _onlyMeController.deselect();
            _anyoneController.deselect();
          }
        } else {
          AppToast.show(S.of(context).warningNoPermissionToAddPublicWebsite);
        }
      });

  Widget _customRelevanceSelectables() {
    final widgets = <Widget>[];
    _customControllers = {};

    if (_filterApplied || widget.defaultPrivate) {
      // Add strings from the filter options
      for (final node in _filter?.relevantLocalizedLeaves(context) ?? []) {
        if (node != 'All') {
          // The "All" case (when nothing is selected in the filter) is handled
          // separately using [_anyoneController]
          final controller = SelectableController();
          _customControllers[node] = controller;

          widgets
            ..add(const SizedBox(width: 8))
            ..add(Selectable(
              label: node,
              controller: controller,
              initiallySelected: _filterApplied,
              onSelected: (selected) => setState(() {
                if (_user?.canAddPublicWebsite ?? false) {
                  if (selected) {
                    _onlyMeController.deselect();
                    _anyoneController.deselect();
                  }
                } else {
                  AppToast.show(
                      S.of(context).warningNoPermissionToAddPublicWebsite);
                }
              }),
              disabled: !(_user?.canAddPublicWebsite ?? false),
            ));
        }
      }
    } else {
      // Add the provided website relevance strings, if applicable
      // These are selected by default
      for (final node in widget.defaultRelevance ?? []) {
        if (!_customControllers.containsKey(node)) {
          final controller = SelectableController();
          _customControllers[node] = controller;

          widgets
            ..add(const SizedBox(width: 8))
            ..add(Selectable(
              label: node,
              controller: controller,
              initiallySelected: true,
              onSelected: _onCustomSelected,
              disabled: !(_user?.canAddPublicWebsite ?? false),
            ));
        }
      }
    }

    return Row(children: widgets);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller != null) {
      widget.controller._state = this;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 12),
      child: Row(
        children: <Widget>[
          Icon(CustomIcons.filter,
              color: CustomIcons.formIconColor(Theme.of(context))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            S.of(context).labelRelevance,
                            style: Theme.of(context)
                                .textTheme
                                .caption
                                .apply(color: Theme.of(context).hintColor),
                          ),
                        ),
                        _customRelevanceButton(),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Container(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: <Widget>[
                                Selectable(
                                  label: S.of(context).relevanceOnlyMe,
                                  initiallySelected:
                                      widget.defaultPrivate ?? true,
                                  onSelected: (selected) => setState(() {
                                    if (_user?.canAddPublicWebsite ?? false) {
                                      if (selected) {
                                        _anyoneController.deselect();
                                        for (final controller
                                            in _customControllers.values) {
                                          controller.deselect();
                                        }
                                      } else {
                                        _anyoneController.select();
                                      }
                                    } else {
                                      _onlyMeController.select();
                                    }
                                  }),
                                  controller: _onlyMeController,
                                ),
                                const SizedBox(width: 8),
                                Selectable(
                                  label: S.of(context).relevanceAnyone,
                                  initiallySelected: !widget.defaultPrivate &&
                                      widget.defaultRelevance == null,
                                  onSelected: (selected) => setState(() {
                                    if (_user?.canAddPublicWebsite ?? false) {
                                      if (selected) {
                                        // Deselect all controllers
                                        _onlyMeController.deselect();
                                        for (final controller
                                            in _customControllers.values) {
                                          controller.deselect();
                                        }
                                      } else {
                                        _onlyMeController.select();
                                      }
                                    } else {
                                      AppToast.show(S
                                          .of(context)
                                          .warningNoPermissionToAddPublicWebsite);
                                    }
                                  }),
                                  controller: _anyoneController,
                                  disabled:
                                      !(_user?.canAddPublicWebsite ?? false),
                                ),
                                _customRelevanceSelectables(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
