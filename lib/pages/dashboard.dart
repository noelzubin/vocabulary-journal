import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:get/get.dart';
import 'package:voc_journal/db/wordnet.dart';
import 'package:voc_journal/main.dart';

class DashboardPage extends StatelessWidget {
  final appController = Get.find<AppController>();

  DashboardPage({Key? key}) : super(key: key);

  Widget itemBuilder(context, String suggestion) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(suggestion),
    );
  }

  void onSuggestionsSelected(String suggestion) {
    appController.getWord(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    final inputTheme = Theme.of(context).inputDecorationTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 40, left: 40, right: 40),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24.0),
          child: TypeAheadField(
              textFieldConfiguration: TextFieldConfiguration(
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: inputTheme.contentPadding,
                    hintText: "Search",
                    prefixIcon: Icon(Icons.search),
                    enabledBorder: inputTheme.enabledBorder,
                    focusedBorder: inputTheme.focusedBorder,
                    filled: inputTheme.filled,
                    fillColor: inputTheme.fillColor,
                  )),
              suggestionsCallback: appController.getSuggestions,
              itemBuilder: itemBuilder,
              onSuggestionSelected: onSuggestionsSelected),
        ),
        Expanded(
            child: SingleChildScrollView(
          child: buildWord(),
        ))
      ]),
    );
  }

  Obx buildWord() {
    return Obx(() {
      if (appController.definition.value == null) {
        return Container();
      }

      return DefinitionView(appController.definition.value!);
    });
  }
}

class DefinitionView extends StatelessWidget {
  final AppController appController = Get.find<AppController>();
  final Definition definition;
  final bool showBookmark;

  DefinitionView(this.definition, {this.showBookmark = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                definition.word,
                style: Theme.of(context).textTheme.headline1,
              ),
            ),
            if (showBookmark)
              IconButton(
                  onPressed: () =>
                      appController.toggleBookmark(definition.word),
                  icon: Obx(() {
                    var bookmarked = appController.bookmarks
                        .any((bm) => bm.word == definition.word);
                    return BookmarkButton(bookmarked);
                  })),
          ],
        ),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: definition.definitions
                .map<Widget>((def) => SubDef(def))
                .toList())
      ],
    );
  }
}

class BookmarkButton extends StatelessWidget {
  final bool active;

  BookmarkButton(this.active);

  @override
  Widget build(BuildContext context) {
    if (active)
      return Icon(
        Icons.star_rounded,
        color: Colors.yellow,
        size: 28,
      );
    return Icon(
      Icons.star_outline_rounded,
      size: 28,
    );
  }
}

class SubDef extends GetView<AppController> {
  final WordDefinition def;

  const SubDef(this.def);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(def.wordType.toShortString(),
              style: TextStyle(color: Colors.grey.shade700)),
          Text(def.definition),
          ...def.examples.map((ex) => Text(
                ex,
                style: TextStyle(
                    fontStyle: FontStyle.italic, color: Colors.grey.shade600),
              )),
          Wrap(
              alignment: WrapAlignment.start,
              children: def.synonyms
                  .map((syn) => GestureDetector(
                      onTap: () => controller.getWord(syn),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: Text(
                          syn,
                          style:
                              TextStyle(color: Theme.of(context).primaryColor),
                        ),
                      )))
                  .toList())
        ],
      ),
    );
  }
}
