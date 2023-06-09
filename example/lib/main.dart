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

  final ValueNotifier<String?> stringItem = ValueNotifier(null);

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
              ValueListenableBuilder(
                valueListenable: stringItem,
                builder: (context, value, child) => BoringDropdown<String>(
                  key: dropdownKey,
                  searchWithFuture: (searchValue) {
                    return Future.delayed(
                      const Duration(seconds: 1),
                      () => [
                        DropdownMenuItem(
                          value: '1000',
                          child: Text('1000'),
                        ),
                      ],
                    );
                  },
                  items: List.generate(
                    10,
                    (index) => DropdownMenuItem(
                      value: '$index',
                      child: Text(index.toString()),
                    ),
                  ),
                  leadingOnSearchField: IconButton(
                    onPressed: () {
                      stringItem.value = '1231423';
                      dropdownKey.currentState!.hideOverlay();
                    },
                    icon: Icon(Icons.add),
                  ),
                  convertItemToString: (element) => element.toString(),
                  onChanged: (selectedElement) =>
                      stringItem.value = selectedElement,
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
