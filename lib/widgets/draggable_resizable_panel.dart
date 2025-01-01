import 'package:flutter/material.dart';

class DraggableResizablePanel extends StatefulWidget {
  final String title;
  final IconData icon;
  final Future<String> Function() fetchData; // Async function to fetch dynamic data
  final Color color;

  const DraggableResizablePanel({
    Key? key,
    required this.title,
    required this.icon,
    required this.fetchData,
    required this.color,
  }) : super(key: key);

  @override
  _DraggableResizablePanelState createState() =>
      _DraggableResizablePanelState();
}

class _DraggableResizablePanelState extends State<DraggableResizablePanel> {
  Offset _offset = Offset(50, 50); // Initial position
  double _width = 150; // Initial size
  double _height = 150;

  String? _data; // Dynamic data
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDynamicData();
  }

  Future<void> _fetchDynamicData() async {
    setState(() {
      _loading = true;
    });
    final data = await widget.fetchData();
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _offset += details.delta;
          });
        },
        child: SizedBox(
          width: _width,
          height: _height,
          child: Card(
            color: widget.color.withOpacity(0.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Column(
              children: [
                // Resize handle
                GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _width += details.delta.dx;
                      _height += details.delta.dy;
                      if (_width < 100) _width = 100;
                      if (_height < 100) _height = 100;
                    });
                  },
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.drag_handle, size: 18),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(widget.icon, size: 36, color: widget.color),
                      const SizedBox(height: 8),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _loading
                          ? CircularProgressIndicator()
                          : Text(
                              _data ?? "No Data",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
