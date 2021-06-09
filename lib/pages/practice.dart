import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:voc_journal/db/wordnet.dart';
import 'package:voc_journal/pages/dashboard.dart';
import 'package:voc_journal/sm2.dart';

class PracticePageController extends GetxController {
  Rxn<List<Bookmark>> revisionWords = Rxn();
  Rxn<Definition> def = Rxn();

  initPractice() async {
    var words = await DBProvider.db.getRevisableWords();
    revisionWords(words);
  }

  onRevise(int quality) async {
    var bookmark = revisionWords.value![0];
    var resp = Sm().calc(
        quality, bookmark.repetition, bookmark.interval, bookmark.easeFactor);
    DBProvider.db.reviseBookmark(bookmark.id!, resp);
    revisionWords(revisionWords.value!.sublist(1));
  }

  fetchDefinition(String word) async {
    var wordDef = await DBProvider.db.getWord(word);
    def(wordDef);
  }
}

class PracticePage extends StatefulWidget {
  final controller = Get.put(PracticePageController());

  @override
  _PracticePageState createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  @override
  initState() {
    widget.controller.initPractice();
    super.initState();
  }

  Obx buildContent() {
    return Obx(() {
      var words = widget.controller.revisionWords.value;

      if (words == null) {
        return Center(child: Text("loading cards...."));
      }

      if (words.length == 0) {
        return Center(child: Text("No more cards to revise today"));
      }

      // // first word is always shows in the card
      var word = words[0];
      return FlipCardComp(word);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [Text("Practice"), Expanded(child: buildContent())],
      ),
    );
  }
}

class FlipCardComp extends StatelessWidget {
  final Bookmark word;
  final GlobalKey<FlipCardState> cardKey = GlobalKey<FlipCardState>();

  final controller = Get.put(PracticePageController());

  FlipCardComp(this.word) {
    controller.fetchDefinition(word.word);
  }

  void toggleCard() {
    cardKey.currentState?.toggleCard();
  }

  @override
  Widget build(BuildContext context) {
    return FlipCard(
      key: cardKey,
      flipOnTouch: false,
      direction: FlipDirection.HORIZONTAL,
      front: CardFront(word.word, toggleCard),
      back: CardBack(word),
    );
  }
}

class CardFront extends StatelessWidget {
  final String word;
  final void Function() showAnswer;

  CardFront(this.word, this.showAnswer, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var isDark = Theme.of(context).brightness == Brightness.dark;

    return FlashCard(Column(
      children: [
        Expanded(
            child: Container(
          child: Center(
            child: Text(word, style: Theme.of(context).textTheme.headline1),
          ),
        )),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: showAnswer,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade300))),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text("SHOW ANSWER")]),
          ),
        )
      ],
    ));
  }
}

class CardBack extends GetView<PracticePageController> {
  final Bookmark word;
  const CardBack(this.word, {Key? key}) : super(key: key);

  Obx buildContent() {
    return Obx(() {
      if (controller.def.value == null) {
        return Container();
      }

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: DefinitionView(
          controller.def.value!,
          showBookmark: false,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    var isDark = Theme.of(context).brightness == Brightness.dark;
    return FlashCard(Column(
      children: [
        Expanded(
          child: SingleChildScrollView(child: buildContent()),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(
                top: BorderSide(
                    color:
                        isDark ? Colors.grey.shade900 : Colors.grey.shade300)),
          ),
          height: 60,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            ResponseBtn(
                Icon(
                  Icons.sentiment_very_dissatisfied,
                  size: 24,
                  color: Colors.red,
                ),
                0),
            ResponseBtn(
                Icon(
                  Icons.sentiment_neutral,
                  size: 24,
                  color: Colors.yellow,
                ),
                3),
            ResponseBtn(
                Icon(Icons.sentiment_very_satisfied,
                    size: 24, color: Colors.green),
                5),
          ]),
        )
      ],
    ));
  }
}

class ResponseBtn extends GetView<PracticePageController> {
  final Icon icon;
  final int value;
  const ResponseBtn(this.icon, this.value, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        child: Padding(padding: const EdgeInsets.all(16.0), child: icon),
        onTap: () => controller.onRevise(controller.onRevise(value)));
  }
}

class FlashCard extends StatelessWidget {
  final Widget child;
  const FlashCard(this.child, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.95,
        heightFactor: 0.8,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            color: isDark ? Color(0XFF131313) : Color(0XFFFFF9CB),
          ),
          child: child,
        ),
      ),
    );
  }
}
