import 'dart:async';
import 'package:flutter/material.dart';

class BoringDropdown<T> extends StatefulWidget {
  BoringDropdown({
    Key? key,
    required List<DropdownMenuItem<T>> items,
    required this.convertItemToString,
    required void Function(T selectedElement) this.onChanged,
    this.onSearchFeedback = const CircularProgressIndicator(),
    this.searchWithFuture,
    this.inputDecoration,
    this.searchInputDecoration,
    required T? this.value,
  })  : _items = ValueNotifier(items),
        _originalItems = items,
        _isMultiChoice = false,
        checkedIcon = null,
        unCheckedIcon = null,
        super(key: key);

  BoringDropdown.multichoice(
      {Key? key,
      required List<DropdownMenuItem<T>> items,
      required this.convertItemToString,
      required void Function(List<T> selectedElements) this.onChanged,
      this.onSearchFeedback = const CircularProgressIndicator(),
      this.searchWithFuture,
      this.inputDecoration,
      this.searchInputDecoration,
      required List<T>? this.value,
      this.checkedIcon,
      this.unCheckedIcon})
      : _items = ValueNotifier(items),
        _originalItems = items,
        _isMultiChoice = true,
        super(key: key);

  final ValueNotifier<List<DropdownMenuItem<T>>> _items;
  final List<DropdownMenuItem<T>> _originalItems;
  final InputDecoration? inputDecoration;
  final InputDecoration? searchInputDecoration;

  final String Function(T element) convertItemToString;
  final Future<List<DropdownMenuItem<T>>> Function(String searchValue)?
      searchWithFuture;
  final Icon? checkedIcon;
  final Icon? unCheckedIcon;
  final bool _isMultiChoice;
  final Widget onSearchFeedback;
  dynamic onChanged;
  dynamic value;

  @override
  State<BoringDropdown<T>> createState() => _BoringDropdownState<T>();
}

class _BoringDropdownState<T> extends State<BoringDropdown<T>> {
  final TextEditingController _mainTextFieldController =
      TextEditingController();

  final TextEditingController _searchTextFieldController =
      TextEditingController();

  OverlayEntry? entry;

  final FocusNode _mainTextFieldFocusNode = FocusNode();
  final FocusNode _searchTextFieldFocusNode = FocusNode();

  Timer? _timer;

  final ValueNotifier<bool> _isWriting = ValueNotifier(false);

  final layerLink = LayerLink();

  void showOverlay(BuildContext context) {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    widget._items.value = widget._originalItems;
    entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                hideOverlay();
              },
              child: Container(
                height: double.infinity,
                width: double.infinity,
                color: Colors.transparent,
              ),
            ),
            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: layerLink,
                showWhenUnlinked: false,
                offset: Offset(0, size.height),
                child: Material(
                  elevation: 10,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _searchWidget(context),
                        ),
                        _overlay(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => overlay.insert(entry!));
  }

  TextField _searchWidget(BuildContext context) => TextField(
        focusNode: _searchTextFieldFocusNode,
        decoration: widget.searchInputDecoration ?? const InputDecoration(),
        controller: _searchTextFieldController,
        onChanged: (value) {
          if (widget.searchWithFuture != null) {
            _searchWithFuture(value);
          } else {
            _searchLocally(value);
          }
        },
      );

  void hideOverlay() {
    _searchTextFieldController.text = '';
    entry?.remove();
    entry = null;
  }

  Future<void> _searchWithFuture(String searchValue) async {
    _isWriting.value = true;
    if (searchValue.isEmpty) {
      _timer!.cancel();
      _timer = null;
      widget._items.value = widget._originalItems;
      _isWriting.value = false;
      return;
    }
    //quando ribatto
    if (_timer != null) {
      _timer!.cancel();
    }
    _timer = Timer(
      const Duration(milliseconds: 300),
      () async {
        // non togliere anche se sembra inutile, non lo e'

        widget._items.value = await widget.searchWithFuture!.call(searchValue);
        if (_searchTextFieldController.text.isEmpty) {
          widget._items.value = widget._originalItems;
        }
        _isWriting.value = false;
      },
    );
  }

  void _searchLocally(String searchValue) {
    if (searchValue.isEmpty) {
      widget._items.value = widget._originalItems;
      return;
    }
    widget._items.value = widget._items.value
        .where((element) =>
            _defaultSearchMatchFunction(element.value as T, searchValue))
        .toList();
  }

  bool _defaultSearchMatchFunction(T value, String searchValue) =>
      value.toString().contains(searchValue);

  Widget _overlay(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _isWriting,
      builder: (context, isWriting, child) => isWriting
          ? Padding(
              padding: const EdgeInsets.all(15.0),
              child: widget.onSearchFeedback,
            )
          : ValueListenableBuilder(
              valueListenable: widget._items,
              builder: (context, dropdownItems, child) {
                return ListView.builder(
                  itemCount: dropdownItems.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    T val = dropdownItems[index].value as T;
                    final isContained = widget._isMultiChoice
                        ? (widget.value as List<T>?)?.contains(val) ?? false
                        : false;

                    ValueNotifier<bool> isSelected = ValueNotifier(isContained);

                    return ValueListenableBuilder(
                      valueListenable: isSelected,
                      builder: (context, selected, child) => ListTile(
                        title: dropdownItems[index].child,
                        leading: widget._isMultiChoice
                            ? selected
                                ? widget.checkedIcon ??
                                    const Icon(Icons.check_box)
                                : widget.unCheckedIcon ??
                                    const Icon(Icons.check_box_outline_blank)
                            : null,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 10),
                        onTap: () {
                          if (widget._isMultiChoice) {
                            List<T>? selectedItems = widget.value;

                            if (selectedItems == null) {
                              selectedItems = [val];
                              isSelected.value = true;
                            } else {
                              if (selectedItems.contains(val)) {
                                selectedItems.remove(val);
                                isSelected.value = false;
                              } else {
                                selectedItems.add(val);
                                isSelected.value = true;
                              }
                            }
                            widget.onChanged(selectedItems);
                          } else {
                            widget.onChanged(val);
                            hideOverlay();
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _getMultichoiceStringValue(List<T> items) =>
      items.map((e) => widget.convertItemToString(e)).toList().join(", ");

  @override
  void didUpdateWidget(covariant BoringDropdown<T> oldWidget) {
    if (widget.value != null) {
      if (widget._isMultiChoice) {
        _mainTextFieldController.text =
            _getMultichoiceStringValue(widget.value as List<T>);
      } else {
        _mainTextFieldController.text =
            widget.convertItemToString(widget.value as T);
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: layerLink,
      child: TextField(
        onTap: () {
          showOverlay(context);
        },
        decoration: widget.inputDecoration ?? const InputDecoration(),
        focusNode: _mainTextFieldFocusNode,
        controller: _mainTextFieldController,
        readOnly: true,
      ),
    );
  }
}
