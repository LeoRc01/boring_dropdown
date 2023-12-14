import 'package:boring_dropdown/boring_dropdown.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key? key}) : super(key: key);

  final ValueNotifier<List<String>?> stringItem = ValueNotifier(null);

  final BoringDropdownKey dropdownKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(),
              ValueListenableBuilder(
                valueListenable: stringItem,
                builder: (context, value, child) =>
                    BoringDropdown<String>.multichoice(
                  key: dropdownKey,
                  enabled: true,
                  // searchWithFuture: (searchValue) {
                  //   return Future.delayed(
                  //     const Duration(seconds: 1),
                  //     () => [
                  //       DropdownMenuItem(
                  //         value: '1000',
                  //         child: Text('1000'),
                  //       ),
                  //     ],
                  //   );
                  // },
                  items: [
                    '#PRODOTTO_GENERICO#',
                    'Prova prodotto',
                    'Test123',
                    'ciao prova'
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),

                  onAdd: (context) async {
                    await Future.delayed(const Duration(seconds: 3));
                    return DropdownMenuItem(value: 'ASD', child: Text('ASD'));
                  },
                  searchMatchFunction: (value, searchValue) {
                    return (value ?? "NONAME")
                        .toLowerCase()
                        .contains(searchValue.toLowerCase().trim());
                  },
                  convertItemToString: (element) => element.toString(),
                  onChanged: (selectedElement) {
                    print(selectedElement);
                    stringItem.value = selectedElement;
                    stringItem.notifyListeners();
                  },
                  value: value,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
