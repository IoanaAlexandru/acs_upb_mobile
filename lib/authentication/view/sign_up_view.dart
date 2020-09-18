import 'package:acs_upb_mobile/authentication/service/auth_provider.dart';
import 'package:acs_upb_mobile/generated/l10n.dart';
import 'package:acs_upb_mobile/navigation/routes.dart';
import 'package:acs_upb_mobile/pages/filter/model/filter.dart';
import 'package:acs_upb_mobile/pages/filter/service/filter_provider.dart';
import 'package:acs_upb_mobile/resources/banner.dart';
import 'package:acs_upb_mobile/resources/locale_provider.dart';
import 'package:acs_upb_mobile/resources/utils.dart';
import 'package:acs_upb_mobile/resources/validator.dart';
import 'package:acs_upb_mobile/widgets/button.dart';
import 'package:acs_upb_mobile/widgets/form/form.dart';
import 'package:acs_upb_mobile/widgets/toast.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';

class SignUpView extends StatefulWidget {
  static const String routeName = '/signup';

  SignUpView();

  @override
  _SignUpViewState createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  List<FormItem> formItems;
  Filter filter;
  List<FilterNode> nodes;
  FilterProvider filterProvider;
  bool agreedToPolicy = false;

  TextEditingController passwordController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  void _fetchFilter() async {
    // Fetch filter for dropdown buttons
    filterProvider = Provider.of<FilterProvider>(context, listen: false);
    filter = await filterProvider.fetchFilter(context);

    // Add the first selected node and refresh
    nodes = [filter.root];
    setState(() {});
  }

  initState() {
    super.initState();
    _fetchFilter();
  }

  /// Attempt to guess the user's first and last name from the email, since university e-mail addresses are standardized.
  ///
  /// Special characters such as ".", "_" are used to separate the names, numbers are removed and names are capitalized.
  /// *Format example:* firstnameone_firstnametwo.lastname123@stud.acs.pub.ro
  void parseNameFromEmail(TextEditingController email,
      TextEditingController firstName, TextEditingController lastName) {
    String emailWithoutNumbers = email.text.replaceAll(RegExp('[^a-zA-Z._]'), '');
    List<String> names = emailWithoutNumbers.split('.');

    if (!names[0].contains('_')) {
      firstName.text = names[0].titleCase;
    } else {
      List<String> firstNames = names[0].split('_');
      firstName.text = firstNames[0].titleCase + ' ' + firstNames[1].titleCase;
    }
    lastName.text = names[1].titleCase;
  }

  List<FormItem> _buildFormItems() {
    // Only build them once to avoid the cursor staying everywhere
    if (formItems != null) {
      return formItems;
    }
    String emailDomain = S.of(context).stringEmailDomain;
    AuthProvider authProvider = Provider.of<AuthProvider>(context);

    formItems = <FormItem>[
      FormItem(
        label: S.of(context).labelEmail,
        hint: S.of(context).hintEmail,
        controller: emailController,
        suffix: emailDomain,
        autocorrect: false,
        autofillHints: [AutofillHints.newUsername],
        check: (email, {BuildContext context}) => authProvider
            .canSignUpWithEmail(email: email + emailDomain, context: context),
        onChanged: (_) => parseNameFromEmail(
            emailController, firstNameController, lastNameController),
      ),
      FormItem(
        label: S.of(context).labelPassword,
        hint: S.of(context).hintPassword,
        additionalHint: S.of(context).infoPassword,
        controller: passwordController,
        obscureText: true,
        autofillHints: [AutofillHints.newPassword],
        check: (password, {BuildContext context}) =>
            AppValidator.isStrongPassword(password: password, context: context),
      ),
      FormItem(
        label: S.of(context).labelConfirmPassword,
        hint: S.of(context).hintPassword,
        obscureText: true,
        check: (password, {BuildContext context}) async {
          bool ok = password == passwordController.text;
          if (!ok && context != null) {
            AppToast.show(S.of(context).errorPasswordsDiffer);
          }
          return ok;
        },
      ),
      FormItem(
          label: S.of(context).labelFirstName,
          hint: S.of(context).hintFirstName,
          controller: firstNameController,
          autofillHints: [AutofillHints.givenName]),
      FormItem(
          label: S.of(context).labelLastName,
          hint: S.of(context).hintLastName,
          controller: lastNameController,
          autofillHints: [AutofillHints.familyName]),
    ];
    return formItems;
  }

  List<Widget> _dropdownTree(BuildContext context) {
    List<Widget> items = [SizedBox(height: 8)];

    if (filter == null) {
      items.add(Padding(
        padding: const EdgeInsets.all(10.0),
        child: Center(child: CircularProgressIndicator()),
      ));
    } else {
      for (var i = 0; i < nodes.length; i++) {
        if (nodes[i] != null && nodes[i].children.isNotEmpty) {
          items.add(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                    filter.localizedLevelNames[i][LocaleProvider.localeString],
                    style: Theme.of(context)
                        .textTheme
                        .subtitle1
                        .apply(fontSizeFactor: 1.1)),
              ),
              DropdownButtonFormField<FilterNode>(
                value: nodes.length > i + 1 ? nodes[i + 1] : null,
                items: nodes[i]
                    .children
                    .map((node) => DropdownMenuItem(
                          value: node,
                          child: Text(node.name),
                        ))
                    .toList(),
                onChanged: (selected) => setState(
                  () {
                    nodes.removeRange(i + 1, nodes.length);
                    nodes.add(selected);
                  },
                ),
              ),
            ],
          ));
        }
      }
    }
    return items;
  }

  Widget _privacyPolicy() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Checkbox(
            value: agreedToPolicy,
            visualDensity: VisualDensity.compact,
            onChanged: (value) => setState(() => agreedToPolicy = value),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                  style: Theme.of(context).textTheme.subtitle1,
                  children: [
                    TextSpan(text: S.of(context).messageIAgreeToThe),
                    TextSpan(
                        text: S.of(context).labelPrivacyPolicy,
                        style: Theme.of(context)
                            .accentTextTheme
                            .subtitle1
                            .apply(fontWeightDelta: 2),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Utils.launchURL(
                              'https://www.websitepolicies.com/policies/view/IIUFv381',
                              context: context)),
                    TextSpan(text: '.'),
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  AppForm _buildForm(BuildContext context) {
    AuthProvider authProvider = Provider.of(context);

    return AppForm(
      title: S.of(context).actionSignUp,
      items: _buildFormItems(),
      trailing: _dropdownTree(context) + [_privacyPolicy()],
      submitOnEnter: false,
      onSubmitted: (Map<String, String> fields) async {
        if (!agreedToPolicy) {
          AppToast.show(S.of(context).warningAgreeTo +
              S.of(context).labelPrivacyPolicy +
              '.');
          return;
        }

        fields[S.of(context).labelEmail] += S.of(context).stringEmailDomain;
        nodes.asMap().forEach((i, node) {
          if (i > 0) {
            fields[filter.localizedLevelNames[i - 1]
                [LocaleProvider.localeString]] = node.name;
          }
        });

        var result = await authProvider.signUp(
          info: fields,
          context: context,
        );

        if (result) {
          // Remove all routes below and push home page
          Navigator.pushNamedAndRemoveUntil(
              context, Routes.home, (route) => false);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    AppForm signUpForm = _buildForm(context);

    return GestureDetector(
      onTap: () {
        // Remove current focus on tap
        FocusScopeNode currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus) {
          currentFocus.unfocus();
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Align(
              alignment: FractionalOffset.topRight,
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Container(
                    height: MediaQuery.of(context).size.height / 3 - 20,
                    child: Image.asset(
                        "assets/illustrations/undraw_personal_information.png")),
              ),
            ),
            SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(left: 28.0, right: 28.0, bottom: 8.0),
                child: IntrinsicHeight(
                  child: Column(
                    children: <Widget>[
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 3,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            UniBanner(),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(child: signUpForm),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Expanded(
                            child: AppButton(
                              key: ValueKey('cancel_button'),
                              text: S.of(context).buttonCancel,
                              onTap: () async {
                                return Navigator.pop(context);
                              },
                            ),
                          ),
                          SizedBox(width: 20),
                          Expanded(
                            child: AppButton(
                              key: ValueKey('sign_up_button'),
                              color: Theme.of(context).accentColor,
                              text: S.of(context).actionSignUp,
                              onTap: () => signUpForm.submit(),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Reset filter so it can be reloaded after user signs in
    filterProvider?.resetFilter();

    super.dispose();
  }
}
