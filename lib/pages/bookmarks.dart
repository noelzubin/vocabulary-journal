import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:voc_journal/main.dart';

class BookmarksPage extends GetView<AppController> {
  const BookmarksPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Bookmarks",
                        style: Theme.of(context).textTheme.headline1),
                    SortIcon(),
                  ]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Obx(() => SingleChildScrollView(
                      child: Column(
                          children: controller.bookmarks
                              .map((bookmark) => GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      controller.getWord(bookmark.word);
                                      controller.onPageChange(0);
                                    },
                                    child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(bookmark.word),
                                          IconButton(
                                              onPressed: () =>
                                                  controller.toggleBookmark(
                                                      bookmark.word),
                                              icon: Icon(Icons.close))
                                        ]),
                                  ))
                              .toList()),
                    )),
              ),
            ),
          ],
        ));
  }
}

enum SortMethod {
  alpha,
  recent,
}

class SortIcon extends GetView<AppController> {
  const SortIcon({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => GestureDetector(
          onTap: controller.toggleSortMethod,
          child: Container(
            child: (controller.sortMethod.value == SortMethod.alpha)
                ? Icon(Icons.sort_by_alpha, color: Colors.grey.shade500)
                : Icon(Icons.sort),
          ),
        ));
  }
}
