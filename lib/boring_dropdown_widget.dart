import 'dart:async';

import 'package:flutter/material.dart';

typedef BoringDropdownKey = GlobalKey<_BoringDropdownState>;

class BoringDropdown<T> extends StatefulWidget {
  BoringDropdown({
    Key? key,
    required List<DropdownMenuItem<T>> items,
    required this.convertItemToString,
    required void Function(T selectedElement) this.onChanged,
    this.isLoading = false,
    this.onSearchFeedback = const CircularProgressIndicator(),
    this.searchWithFuture,
    this.inputDecoration,
    this.searchInputDecoration,
    this.enabled = true,
    this.validator,
    this.autovalidateMode,
    TextEditingController? searchController,
    this.searchMatchFunction,
    this.onAdd,
    this.onAddIcon = const Icon(Icons.add),
    required T? this.value,
  })  : _items = ValueNotifier(items),
        _originalItems = items,
        _isMultiChoice = false,
        checkedIcon = null,
        unCheckedIcon = null,
        searchController = searchController ?? TextEditingController(),
        super(key: key);

  BoringDropdown.multichoice(
      {Key? key,
      required List<DropdownMenuItem<T>> items,
      required this.convertItemToString,
      required void Function(List<T> selectedElements) this.onChanged,
      required List<T>? this.value,
      this.isLoading = false,
      this.onSearchFeedback = const CircularProgressIndicator(),
      this.searchWithFuture,
      this.inputDecoration,
      this.enabled = true,
      this.validator,
      this.autovalidateMode,
      this.searchInputDecoration,
      this.searchMatchFunction,
      TextEditingController? searchController,
      this.onAdd,
      this.checkedIcon,
      this.onAddIcon = const Icon(Icons.add),
      this.unCheckedIcon})
      : _items = ValueNotifier(items),
        _originalItems = items,
        _isMultiChoice = true,
        searchController = searchController ?? TextEditingController(),
        super(key: key);

  final ValueNotifier<List<DropdownMenuItem<T>>> _items;
  final List<DropdownMenuItem<T>> _originalItems;
  final InputDecoration? inputDecoration;
  final InputDecoration? searchInputDecoration;
  final bool enabled;
  final String Function(T element) convertItemToString;
  final Future<List<DropdownMenuItem<T>>> Function(String searchValue)?
      searchWithFuture;
  final bool Function(T value, String searchValue)? searchMatchFunction;
  final Icon? checkedIcon;
  final Icon? unCheckedIcon;
  final bool _isMultiChoice;
  final Widget onSearchFeedback;
  final Future<DropdownMenuItem<T>?> Function(BuildContext context)? onAdd;
  final TextEditingController searchController;
  final String? Function(String?)? validator;
  final AutovalidateMode? autovalidateMode;
  final Widget onAddIcon;
  final bool isLoading;

  dynamic onChanged;
  dynamic value;

  @override
  State<BoringDropdown<T>> createState() => _BoringDropdownState<T>();
}

class _BoringDropdownState<T> extends State<BoringDropdown<T>> {
  final TextEditingController _mainTextFieldController =
      TextEditingController();

  OverlayEntry? entry;

  final FocusNode _mainTextFieldFocusNode = FocusNode();
  final FocusNode _searchTextFieldFocusNode = FocusNode();

  Timer? _timer;

  late ValueNotifier<bool> _isWriting;
  bool get _isOverlayOpened => entry != null;
  bool _isMouseHoverOverylay = false;
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
                    child: MouseRegion(
                      onEnter: (event) {
                        _isMouseHoverOverylay = true;
                      },
                      onExit: (event) {
                        _isMouseHoverOverylay = false;
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                widget.onAdd != null
                                    ? Row(
                                        children: [
                                          _onAddWidget(context),
                                          const SizedBox(width: 10),
                                        ],
                                      )
                                    : Container(),
                                Expanded(child: _searchWidget(context)),
                              ],
                            ),
                          ),
                          _overlay(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      overlay.insert(entry!);
    });
  }

  Widget _onAddWidget(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(useMaterial3: true),
        child: IconButton(
          onPressed: () {
            _onAdd(context);
          },
          icon: widget.onAddIcon,
        ),
      );

  _onAdd(BuildContext context) async {
    final newList = widget._items.value;
    final item = await widget.onAdd!.call(context);

    if (item != null) {
      newList.add(item);
      widget._items.value = newList;

      if (widget._isMultiChoice) {
        widget.value as List;
        widget.value ??= [];
        widget.value.insert(0, item.value);
      } else {
        widget.value = item.value;
      }
      setVisualValue();
      (widget.key as BoringDropdownKey).currentState!.hideOverlay();
    }
  }

  void hideOverlay() {
    widget.searchController.text = '';
    entry?.remove();
    entry = null;
  }

  TextField _searchWidget(BuildContext context) => TextField(
        focusNode: _searchTextFieldFocusNode,
        decoration: widget.searchInputDecoration ?? const InputDecoration(),
        controller: widget.searchController,
        onChanged: (value) {
          if (widget.searchWithFuture != null) {
            _searchWithFuture(value);
          } else {
            _searchLocally(value);
          }
        },
      );

  Future<void> _searchWithFuture(String searchValue) async {
    _isWriting.value = true;
    _searchLocally(searchValue);
    if (widget._items.value.isNotEmpty) {
      _isWriting.value = false;
      return;
    }
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
        widget._items.value = await widget.searchWithFuture!.call(searchValue);
        if (widget.searchController.text.isEmpty) {
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
    widget._items.value = widget._originalItems
        .where((element) =>
            widget.searchMatchFunction?.call(element.value as T, searchValue) ??
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
                return Flexible(
                  child: ListView.builder(
                    itemCount: dropdownItems.length,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      T val = dropdownItems[index].value as T;
                      final isContained = widget._isMultiChoice
                          ? (widget.value as List<T>?)?.contains(val) ?? false
                          : false;

                      ValueNotifier<bool> isSelected =
                          ValueNotifier(isContained);

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
                  ),
                );
              },
            ),
    );
  }

  String _getMultichoiceStringValue(List<T> items) =>
      items.map((e) => widget.convertItemToString(e)).toList().join(", ");

  void setVisualValue() {
    if (widget._isMultiChoice) {
      _mainTextFieldController.text = widget.value == null
          ? ''
          : _getMultichoiceStringValue(widget.value as List<T>);
    } else {
      _mainTextFieldController.text = widget.value == null
          ? ''
          : widget.convertItemToString(widget.value as T);
    }
  }

  void overwriteVisualValue(String val) {
    _mainTextFieldController.text = val;
  }

  @override
  void didUpdateWidget(covariant BoringDropdown<T> oldWidget) {
    setVisualValue();
    Future.microtask(() => _isWriting.value = widget.isLoading);
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _isWriting = ValueNotifier(widget.isLoading);
    setVisualValue();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _mainTextFieldFocusNode.addListener(() {
      if (_mainTextFieldFocusNode.hasFocus) {
        if (!_isOverlayOpened) {
          showOverlay(context);
        }
      } else {
        if (_isOverlayOpened && !_isMouseHoverOverylay) {
          hideOverlay();
        }
      }
    });

    return CompositedTransformTarget(
      link: layerLink,
      child: TextFormField(
        enabled: widget.enabled,
        validator: widget.validator,
        autovalidateMode: widget.autovalidateMode,
        decoration: widget.inputDecoration ?? const InputDecoration(),
        focusNode: _mainTextFieldFocusNode,
        controller: _mainTextFieldController,
        readOnly: true,
      ),
    );
  }
}
