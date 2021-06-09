import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voc_journal/db/wordnet.dart';
import 'package:voc_journal/pages/bookmarks.dart';
import 'package:voc_journal/pages/dashboard.dart';
import 'package:voc_journal/pages/practice.dart';

void main() {
  runApp(App());
}

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AppController());
  }
}

class AppController extends GetxController {
  RxInt pageIndex = RxInt(0);
  Rxn<Definition> definition = Rxn();
  RxList<Bookmark> bookmarks = RxList();
  Rx<SortMethod> sortMethod = SortMethod.alpha.obs;

  AppController() {
    init();
  }

  init() async {
    var bms = await DBProvider.db.getAllBookmarks(SortMethod.recent);
    bookmarks(bms);
  }

  Future<List<String>> getSuggestions(String word) {
    return DBProvider.db.searchWord(word);
  }

  getWord(String word) async {
    Definition def = await DBProvider.db.getWord(word);
    definition(def);
  }

  toggleBookmark(String word) async {
    if (bookmarks.any((bm) => bm.word == word)) {
      await DBProvider.db.deleteBookmark(word);
    } else {
      await DBProvider.db.addBookmark(word);
    }
    var bms = await DBProvider.db.getAllBookmarks(sortMethod.value);
    bookmarks(bms);
  }

  onPageChange(int ind) {
    pageIndex(ind);
  }

  toggleSortMethod() async {
    var nextSortMethod = sortMethod.value == SortMethod.recent
        ? SortMethod.alpha
        : SortMethod.recent;
    sortMethod(nextSortMethod);
    var bms = await DBProvider.db.getAllBookmarks(nextSortMethod);
    bookmarks(bms);
  }
}

class App extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      themeMode: ThemeMode.system,
      theme: MyTheme.lightTheme,
      darkTheme: MyTheme.darkTheme,
      initialBinding: AppBinding(),
      initialRoute: '/',
      getPages: [GetPage(name: '/', page: () => HomePage())],
    );
  }
}

class HomePage extends GetView<AppController> {
  final List<Widget> _pages = [
    DashboardPage(),
    BookmarksPage(),
    PracticePage(),
  ];

  HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: Obx(() => BottomNavigationBar(
              currentIndex: controller.pageIndex.value,
              fixedColor: Theme.of(context).primaryColor,
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.collections), label: 'collection'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.card_membership_outlined),
                    label: 'practice')
              ],
              onTap: controller.onPageChange,
            )),
        body: SafeArea(
            child: Obx(() => _pages.elementAt(controller.pageIndex.value))));
  }
}

// THEME

var primaryColor = Color(0xFF0B6DF7);

var headline1 = GoogleFonts.getFont(
  'Source Serif Pro',
  color: Color(0xFF404040),
  fontWeight: FontWeight.bold,
  fontSize: 36,
);

var bodyText1 = GoogleFonts.getFont(
  'Open Sans',
  color: Color(0xFF171717),
  fontSize: 16,
);

var bodyText2 =
    GoogleFonts.getFont('Open Sans', color: Color(0xFF4E4E4E), fontSize: 14);

class MyTheme {
  static final lightTheme = ThemeData.light().copyWith(
      scaffoldBackgroundColor: Colors.white,
      primaryColor: primaryColor,
      iconTheme: IconThemeData(size: 18, color: Colors.black26),
      textTheme: TextTheme(
          headline1: headline1, bodyText1: bodyText1, bodyText2: bodyText2),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: EdgeInsets.all(4),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.transparent,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.transparent,
            ),
            borderRadius: BorderRadius.all(Radius.circular(8))),
        filled: true,
        fillColor: Color(0xFFF9F9F9),
      ));
  static final darkTheme = ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black,
      primaryColor: primaryColor,
      iconTheme: IconThemeData(size: 18, color: Color(0xFF3c3c3c)),
      textTheme: TextTheme(
          headline1: headline1.copyWith(color: Color(0xFFE7E7E7)),
          bodyText1: bodyText1.copyWith(color: Color(0xFFC3C3C3)),
          bodyText2: bodyText2.copyWith(color: Color(0XFF929292))),
      inputDecorationTheme: InputDecorationTheme(
        contentPadding: EdgeInsets.all(4),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Colors.transparent,
          ),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Colors.transparent,
            ),
            borderRadius: BorderRadius.all(Radius.circular(8))),
        filled: true,
        fillColor: Color(0xFF3A3A3A),
      ));
}

class AppTheme {
  String primaryFontFamily = 'Source Serif Pro';
  String secondaryFontFamily = 'Roboto';

  static TextStyle get title1 => GoogleFonts.getFont(
        'Source Serif Pro',
        color: Color(0xFF404040),
        fontWeight: FontWeight.bold,
        fontSize: 36,
      );
  static TextStyle get title2 => GoogleFonts.getFont(
        'Open Sans',
        color: Color(0xFF303030),
        fontWeight: FontWeight.w500,
        fontSize: 22,
      );
  static TextStyle get sectionHeader => GoogleFonts.getFont(
        'Open Sans',
        color: Color(0xFF767676),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      );
  static TextStyle get paragraph => GoogleFonts.getFont(
        'Open Sans',
        color: Color(0xFF171717),
        fontSize: 16,
      );

  static TextStyle get noto => GoogleFonts.notoSans(
          textStyle: TextStyle(
        color: Color(0xFF0B6DF7),
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ));
}
