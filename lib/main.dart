import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'download.dart';

void main() {
  runApp(const FrameItApp());
}

class FrameItApp extends StatelessWidget {
  const FrameItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FrameIt Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const StudioPage(),
    );
  }
}

class StudioPage extends StatefulWidget {
  const StudioPage({super.key});

  @override
  State<StudioPage> createState() => _StudioPageState();
}

class _StudioPageState extends State<StudioPage> {
  final GlobalKey _previewKey = GlobalKey();
  final ImagePicker _picker = ImagePicker();

  List<StudioScene> _sceneOptions = scenes;
  List<FrameStyle> _frameOptions = frames;
  StudioScene _scene = scenes.first;
  FrameStyle _frame = frames.first;
  Color _paper = papers.first;
  ArtworkRatio _ratio = ArtworkRatio.portrait;
  ui.Image? _artwork;

  double _frameWidth = 28;
  double _cornerRadius = 8;
  double _matWidth = 24;
  double _smoothness = 22;
  double _shadowDepth = 58;
  double _artworkScale = 1;
  Offset _artworkOffset = Offset.zero;
  double _gestureStartScale = 1;

  @override
  void initState() {
    super.initState();
    _loadCustomAssets();
  }

  Future<void> _loadCustomAssets() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assets = manifest.listAssets();
    final customScenes = await _loadScenes(assets);
    final customFrames = await _loadFrames(assets);

    if (!mounted) return;
    setState(() {
      _sceneOptions = [...scenes, ...customScenes];
      _frameOptions = [...frames, ...customFrames];
    });
  }

  Future<List<StudioScene>> _loadScenes(List<String> assets) async {
    final sceneAssets = assets
        .where((asset) =>
            _isSupportedImage(asset) && asset.startsWith('assets/scenes/'))
        .toList()
      ..sort();

    final result = <StudioScene>[];
    for (final asset in sceneAssets) {
      try {
        final image = await _loadUiImage(asset);
        result.add(
          StudioScene(
            name: _labelFromAsset(asset),
            wall: const [Color(0xFFF9F7F1), Color(0xFFECE6DC)],
            floor: const [Color(0xFFD8C7AA), Color(0xFFBFA783)],
            trim: const Color(0xFFC9BDA8),
            previewColors: const [Color(0xFFF9F7F1), Color(0xFFD8C7AA)],
            furniture: Furniture.none,
            furnitureColor: const Color(0xFF483727),
            image: image,
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return result;
  }

  Future<List<FrameStyle>> _loadFrames(List<String> assets) async {
    final frameAssets = assets
        .where((asset) =>
            _isSupportedImage(asset) && asset.startsWith('assets/frames/'))
        .toList()
      ..sort();

    final result = <FrameStyle>[];
    for (final asset in frameAssets) {
      try {
        final image = await _loadUiImage(asset);
        result.add(
          FrameStyle(
            name: _labelFromAsset(asset),
            base: const Color(0xFF6D4B2F),
            edge: const Color(0xFF2F1A10),
            shine: const Color(0xFFE2C08B),
            texture: image,
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return result;
  }

  Future<ui.Image> _loadUiImage(String asset) async {
    final bytes = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Future<ui.Image?> _pickUiImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  bool _isSupportedImage(String asset) {
    final path = asset.toLowerCase();
    return path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.webp');
  }

  String _labelFromAsset(String asset) {
    final filename = asset.split('/').last.split('.').first;
    return filename.replaceAll(RegExp('[-_]+'), ' ').trim();
  }

  Future<void> _pickImage() async {
    final image = await _pickUiImage();
    if (image == null) return;

    setState(() {
      _artwork = image;
      _artworkScale = 1;
      _artworkOffset = Offset.zero;
    });
  }

  Future<void> _pickSceneImage() async {
    final image = await _pickUiImage();
    if (image == null) return;

    final scene = StudioScene(
      name: 'Cảnh tải lên ${_sceneOptions.length + 1}',
      wall: const [Color(0xFFF9F7F1), Color(0xFFECE6DC)],
      floor: const [Color(0xFFD8C7AA), Color(0xFFBFA783)],
      trim: const Color(0xFFC9BDA8),
      previewColors: const [Color(0xFFF9F7F1), Color(0xFFD8C7AA)],
      furniture: Furniture.none,
      furnitureColor: const Color(0xFF483727),
      image: image,
    );

    setState(() {
      _sceneOptions = [..._sceneOptions, scene];
      _scene = scene;
    });
  }

  Future<void> _pickFrameImage() async {
    final image = await _pickUiImage();
    if (image == null) return;

    final frame = FrameStyle(
      name: 'Khung tải lên ${_frameOptions.length + 1}',
      base: const Color(0xFF6D4B2F),
      edge: const Color(0xFF2F1A10),
      shine: const Color(0xFFE2C08B),
      texture: image,
    );

    setState(() {
      _frameOptions = [..._frameOptions, frame];
      _frame = frame;
    });
  }

  void _startArtworkInteraction(ScaleStartDetails details) {
    _gestureStartScale = _artworkScale;
  }

  void _updateArtworkInteraction(ScaleUpdateDetails details, Size previewSize) {
    final delta = Offset(
      details.focalPointDelta.dx / math.max(1, previewSize.width) * 2,
      details.focalPointDelta.dy / math.max(1, previewSize.height) * 2,
    );

    setState(() {
      _artworkScale =
          (_gestureStartScale * details.scale).clamp(0.25, 4).toDouble();
      _artworkOffset = _clampArtworkOffset(_artworkOffset + delta);
    });
  }

  Offset _clampArtworkOffset(Offset value) {
    return Offset(value.dx.clamp(-1.5, 1.5).toDouble(),
        value.dy.clamp(-1.5, 1.5).toDouble());
  }

  void _resetArtworkTransform() {
    setState(() {
      _artworkScale = 1;
      _artworkOffset = Offset.zero;
    });
  }

  Future<void> _exportPreview() async {
    final boundary = _previewKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 2);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null) return;

    if (kIsWeb) {
      await downloadPng(bytes, 'frameit-preview.png');
      return;
    }

    await Share.shareXFiles(
      [
        XFile.fromData(bytes,
            mimeType: 'image/png', name: 'frameit-preview.png')
      ],
      text: 'FrameIt preview',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 980;
    final controls = _ControlsPanel(
      scrollable: isWide,
      selectedScene: _scene,
      selectedFrame: _frame,
      selectedPaper: _paper,
      selectedRatio: _ratio,
      frameWidth: _frameWidth,
      cornerRadius: _cornerRadius,
      matWidth: _matWidth,
      smoothness: _smoothness,
      shadowDepth: _shadowDepth,
      artworkScale: _artworkScale,
      artworkOffset: _artworkOffset,
      onSceneChanged: (value) => setState(() => _scene = value),
      onFrameChanged: (value) => setState(() => _frame = value),
      onPaperChanged: (value) => setState(() => _paper = value),
      onRatioChanged: (value) => setState(() => _ratio = value),
      onFrameWidthChanged: (value) => setState(() => _frameWidth = value),
      onCornerRadiusChanged: (value) => setState(() => _cornerRadius = value),
      onMatWidthChanged: (value) => setState(() => _matWidth = value),
      onSmoothnessChanged: (value) => setState(() => _smoothness = value),
      onShadowDepthChanged: (value) => setState(() => _shadowDepth = value),
      onArtworkScaleChanged: (value) => setState(() => _artworkScale = value),
      onArtworkOffsetXChanged: (value) => setState(() => _artworkOffset =
          _clampArtworkOffset(Offset(value, _artworkOffset.dy))),
      onArtworkOffsetYChanged: (value) => setState(() => _artworkOffset =
          _clampArtworkOffset(Offset(_artworkOffset.dx, value))),
      onArtworkReset: _resetArtworkTransform,
      onAddScene: _pickSceneImage,
      onAddFrame: _pickFrameImage,
      scenes: _sceneOptions,
      frames: _frameOptions,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFEBE7DF),
      body: SafeArea(
        child: isWide
            ? Row(
                children: [
                  Expanded(child: _buildWorkspace()),
                  SizedBox(width: 360, child: controls),
                ],
              )
            : _buildMobileWorkspace(),
      ),
    );
  }

  Widget _buildMobileWorkspace() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: _MobileHeader(
            onPickImage: _pickImage,
            onExport: _exportPreview,
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildPreview(compact: true),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 260,
          child: _MobileControlsPanel(
            scenes: _sceneOptions,
            frames: _frameOptions,
            selectedScene: _scene,
            selectedFrame: _frame,
            selectedPaper: _paper,
            selectedRatio: _ratio,
            frameWidth: _frameWidth,
            cornerRadius: _cornerRadius,
            matWidth: _matWidth,
            smoothness: _smoothness,
            shadowDepth: _shadowDepth,
            artworkScale: _artworkScale,
            artworkOffset: _artworkOffset,
            onSceneChanged: (value) => setState(() => _scene = value),
            onFrameChanged: (value) => setState(() => _frame = value),
            onPaperChanged: (value) => setState(() => _paper = value),
            onRatioChanged: (value) => setState(() => _ratio = value),
            onFrameWidthChanged: (value) => setState(() => _frameWidth = value),
            onCornerRadiusChanged: (value) =>
                setState(() => _cornerRadius = value),
            onMatWidthChanged: (value) => setState(() => _matWidth = value),
            onSmoothnessChanged: (value) => setState(() => _smoothness = value),
            onShadowDepthChanged: (value) =>
                setState(() => _shadowDepth = value),
            onArtworkScaleChanged: (value) =>
                setState(() => _artworkScale = value),
            onArtworkOffsetXChanged: (value) => setState(() => _artworkOffset =
                _clampArtworkOffset(Offset(value, _artworkOffset.dy))),
            onArtworkOffsetYChanged: (value) => setState(() => _artworkOffset =
                _clampArtworkOffset(Offset(_artworkOffset.dx, value))),
            onArtworkReset: _resetArtworkTransform,
            onAddScene: _pickSceneImage,
            onAddFrame: _pickFrameImage,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkspace({bool compact = false}) {
    return Padding(
      padding: EdgeInsets.all(compact ? 14 : 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(onPickImage: _pickImage, onExport: _exportPreview),
          const SizedBox(height: 20),
          if (compact)
            SizedBox(
              height: _compactPreviewHeight(context),
              child: _buildPreview(compact: true),
            )
          else
            Expanded(child: _buildPreview()),
        ],
      ),
    );
  }

  double _compactPreviewHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return (size.height * 0.62).clamp(420.0, 620.0);
  }

  Widget _buildPreview({bool compact = false}) {
    return _PreviewSurface(
      previewKey: _previewKey,
      scene: _scene,
      frame: _frame,
      paper: _paper,
      ratio: _ratio,
      artwork: _artwork,
      frameWidth: _frameWidth,
      cornerRadius: _cornerRadius,
      matWidth: _matWidth,
      smoothness: _smoothness,
      shadowDepth: _shadowDepth,
      artworkScale: _artworkScale,
      artworkOffset: _artworkOffset,
      compact: compact,
      onArtworkScaleStart: _startArtworkInteraction,
      onArtworkScaleUpdate: _updateArtworkInteraction,
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onPickImage, required this.onExport});

  final VoidCallback onPickImage;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 680;
    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: onPickImage,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Tải ảnh'),
        ),
        OutlinedButton.icon(
          onPressed: onExport,
          icon: const Icon(Icons.ios_share_outlined),
          label: const Text('Xuất PNG'),
        ),
      ],
    );

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FrameIt Studio',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF0A5B55),
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Đóng khung và xem tác phẩm trong không gian thật',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                height: 1.05,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );

    if (isNarrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [title, const SizedBox(height: 14), actions],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: title),
        const SizedBox(width: 18),
        actions,
      ],
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader({required this.onPickImage, required this.onExport});

  final VoidCallback onPickImage;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'FrameIt Studio',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF0A5B55),
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        IconButton.filled(
          tooltip: 'Tải ảnh',
          onPressed: onPickImage,
          icon: const Icon(Icons.add_photo_alternate_outlined),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(
          tooltip: 'Xuất PNG',
          onPressed: onExport,
          icon: const Icon(Icons.ios_share_outlined),
        ),
      ],
    );
  }
}

class _PreviewSurface extends StatelessWidget {
  const _PreviewSurface({
    required this.previewKey,
    required this.scene,
    required this.frame,
    required this.paper,
    required this.ratio,
    required this.artwork,
    required this.frameWidth,
    required this.cornerRadius,
    required this.matWidth,
    required this.smoothness,
    required this.shadowDepth,
    required this.artworkScale,
    required this.artworkOffset,
    required this.compact,
    required this.onArtworkScaleStart,
    required this.onArtworkScaleUpdate,
  });

  final GlobalKey previewKey;
  final StudioScene scene;
  final FrameStyle frame;
  final Color paper;
  final ArtworkRatio ratio;
  final ui.Image? artwork;
  final double frameWidth;
  final double cornerRadius;
  final double matWidth;
  final double smoothness;
  final double shadowDepth;
  final double artworkScale;
  final Offset artworkOffset;
  final bool compact;
  final ValueChanged<ScaleStartDetails> onArtworkScaleStart;
  final void Function(ScaleUpdateDetails details, Size previewSize)
      onArtworkScaleUpdate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 70,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final maxHeight = constraints.maxHeight;
            final targetAspect = compact ? 0.78 : 1.5;
            final previewWidth = math.min(maxWidth, maxHeight * targetAspect);
            final previewHeight = previewWidth / targetAspect;

            return SizedBox(
              width: previewWidth,
              height: previewHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: onArtworkScaleStart,
                onScaleUpdate: (details) => onArtworkScaleUpdate(
                    details, Size(previewWidth, previewHeight)),
                child: RepaintBoundary(
                  key: previewKey,
                  child: CustomPaint(
                    painter: FramePreviewPainter(
                      scene: scene,
                      frame: frame,
                      paper: paper,
                      ratio: ratio,
                      artwork: artwork,
                      frameWidth: frameWidth,
                      cornerRadius: cornerRadius,
                      matWidth: matWidth,
                      smoothness: smoothness,
                      shadowDepth: shadowDepth,
                      artworkScale: artworkScale,
                      artworkOffset: artworkOffset,
                      compact: compact,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    this.scrollable = true,
    required this.scenes,
    required this.frames,
    required this.selectedScene,
    required this.selectedFrame,
    required this.selectedPaper,
    required this.selectedRatio,
    required this.frameWidth,
    required this.cornerRadius,
    required this.matWidth,
    required this.smoothness,
    required this.shadowDepth,
    required this.artworkScale,
    required this.artworkOffset,
    required this.onSceneChanged,
    required this.onFrameChanged,
    required this.onPaperChanged,
    required this.onRatioChanged,
    required this.onFrameWidthChanged,
    required this.onCornerRadiusChanged,
    required this.onMatWidthChanged,
    required this.onSmoothnessChanged,
    required this.onShadowDepthChanged,
    required this.onArtworkScaleChanged,
    required this.onArtworkOffsetXChanged,
    required this.onArtworkOffsetYChanged,
    required this.onArtworkReset,
    required this.onAddScene,
    required this.onAddFrame,
  });

  final bool scrollable;
  final List<StudioScene> scenes;
  final List<FrameStyle> frames;
  final StudioScene selectedScene;
  final FrameStyle selectedFrame;
  final Color selectedPaper;
  final ArtworkRatio selectedRatio;
  final double frameWidth;
  final double cornerRadius;
  final double matWidth;
  final double smoothness;
  final double shadowDepth;
  final double artworkScale;
  final Offset artworkOffset;
  final ValueChanged<StudioScene> onSceneChanged;
  final ValueChanged<FrameStyle> onFrameChanged;
  final ValueChanged<Color> onPaperChanged;
  final ValueChanged<ArtworkRatio> onRatioChanged;
  final ValueChanged<double> onFrameWidthChanged;
  final ValueChanged<double> onCornerRadiusChanged;
  final ValueChanged<double> onMatWidthChanged;
  final ValueChanged<double> onSmoothnessChanged;
  final ValueChanged<double> onShadowDepthChanged;
  final ValueChanged<double> onArtworkScaleChanged;
  final ValueChanged<double> onArtworkOffsetXChanged;
  final ValueChanged<double> onArtworkOffsetYChanged;
  final VoidCallback onArtworkReset;
  final VoidCallback onAddScene;
  final VoidCallback onAddFrame;

  @override
  Widget build(BuildContext context) {
    final children = [
      _Section(
        title: 'Cảnh trưng bày',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: onAddScene,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Tải cảnh'),
            ),
            const SizedBox(height: 12),
            _OptionGrid<StudioScene>(
              items: scenes,
              selected: selectedScene,
              labelOf: (item) => item.name,
              colorsOf: (item) => item.previewColors,
              imageOf: (item) => item.image,
              onChanged: onSceneChanged,
            ),
          ],
        ),
      ),
      _Section(
        title: 'Kiểu khung',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: onAddFrame,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Tải khung'),
            ),
            const SizedBox(height: 12),
            _OptionGrid<FrameStyle>(
              items: frames,
              selected: selectedFrame,
              labelOf: (item) => item.name,
              colorsOf: (item) => [item.shine, item.base, item.edge],
              imageOf: (item) => item.texture,
              onChanged: onFrameChanged,
            ),
          ],
        ),
      ),
      _Section(
        title: 'Tinh chỉnh',
        child: Column(
          children: [
            _SliderRow(
              label: 'Độ rộng khung',
              value: frameWidth,
              min: 18,
              max: 110,
              onChanged: onFrameWidthChanged,
            ),
            _SliderRow(
              label: 'Bo viền',
              value: cornerRadius,
              min: 0,
              max: 44,
              onChanged: onCornerRadiusChanged,
            ),
            _SliderRow(
              label: 'Viền giấy',
              value: matWidth,
              min: 0,
              max: 150,
              onChanged: onMatWidthChanged,
            ),
            _SliderRow(
              label: 'Khử nhăn',
              value: smoothness,
              min: 0,
              max: 100,
              onChanged: onSmoothnessChanged,
            ),
            _SliderRow(
              label: 'Bóng đổ',
              value: shadowDepth,
              min: 0,
              max: 100,
              onChanged: onShadowDepthChanged,
            ),
          ],
        ),
      ),
      _Section(
        title: 'Vị trí khung',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SliderRow(
              label: 'Thu phóng',
              value: artworkScale,
              min: 0.25,
              max: 4,
              onChanged: onArtworkScaleChanged,
            ),
            _SliderRow(
              label: 'Dịch ngang',
              value: artworkOffset.dx,
              min: -1.5,
              max: 1.5,
              onChanged: onArtworkOffsetXChanged,
            ),
            _SliderRow(
              label: 'Dịch dọc',
              value: artworkOffset.dy,
              min: -1.5,
              max: 1.5,
              onChanged: onArtworkOffsetYChanged,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onArtworkReset,
                icon: const Icon(Icons.center_focus_strong_outlined),
                label: const Text('Đặt lại khung'),
              ),
            ),
          ],
        ),
      ),
      _Section(
        title: 'Màu giấy',
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final paper in papers)
              _ColorSwatch(
                color: paper,
                selected: paper == selectedPaper,
                onTap: () => onPaperChanged(paper),
              ),
          ],
        ),
      ),
      _Section(
        title: 'Tỷ lệ tác phẩm',
        child: SegmentedButton<ArtworkRatio>(
          segments: const [
            ButtonSegment(value: ArtworkRatio.portrait, label: Text('Dọc')),
            ButtonSegment(value: ArtworkRatio.square, label: Text('Vuông')),
            ButtonSegment(value: ArtworkRatio.landscape, label: Text('Ngang')),
          ],
          selected: {selectedRatio},
          onSelectionChanged: (value) => onRatioChanged(value.first),
        ),
      ),
    ];

    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      child: scrollable
          ? ListView(padding: const EdgeInsets.all(24), children: children)
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: children),
            ),
    );
  }
}

class _MobileControlsPanel extends StatelessWidget {
  const _MobileControlsPanel({
    required this.scenes,
    required this.frames,
    required this.selectedScene,
    required this.selectedFrame,
    required this.selectedPaper,
    required this.selectedRatio,
    required this.frameWidth,
    required this.cornerRadius,
    required this.matWidth,
    required this.smoothness,
    required this.shadowDepth,
    required this.artworkScale,
    required this.artworkOffset,
    required this.onSceneChanged,
    required this.onFrameChanged,
    required this.onPaperChanged,
    required this.onRatioChanged,
    required this.onFrameWidthChanged,
    required this.onCornerRadiusChanged,
    required this.onMatWidthChanged,
    required this.onSmoothnessChanged,
    required this.onShadowDepthChanged,
    required this.onArtworkScaleChanged,
    required this.onArtworkOffsetXChanged,
    required this.onArtworkOffsetYChanged,
    required this.onArtworkReset,
    required this.onAddScene,
    required this.onAddFrame,
  });

  final List<StudioScene> scenes;
  final List<FrameStyle> frames;
  final StudioScene selectedScene;
  final FrameStyle selectedFrame;
  final Color selectedPaper;
  final ArtworkRatio selectedRatio;
  final double frameWidth;
  final double cornerRadius;
  final double matWidth;
  final double smoothness;
  final double shadowDepth;
  final double artworkScale;
  final Offset artworkOffset;
  final ValueChanged<StudioScene> onSceneChanged;
  final ValueChanged<FrameStyle> onFrameChanged;
  final ValueChanged<Color> onPaperChanged;
  final ValueChanged<ArtworkRatio> onRatioChanged;
  final ValueChanged<double> onFrameWidthChanged;
  final ValueChanged<double> onCornerRadiusChanged;
  final ValueChanged<double> onMatWidthChanged;
  final ValueChanged<double> onSmoothnessChanged;
  final ValueChanged<double> onShadowDepthChanged;
  final ValueChanged<double> onArtworkScaleChanged;
  final ValueChanged<double> onArtworkOffsetXChanged;
  final ValueChanged<double> onArtworkOffsetYChanged;
  final VoidCallback onArtworkReset;
  final VoidCallback onAddScene;
  final VoidCallback onAddFrame;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      elevation: 10,
      child: DefaultTabController(
        length: 5,
        child: Column(
          children: [
            const TabBar(
              isScrollable: false,
              labelPadding: EdgeInsets.zero,
              tabs: [
                Tab(icon: Icon(Icons.wallpaper_outlined), text: 'Cảnh'),
                Tab(icon: Icon(Icons.crop_square_outlined), text: 'Khung'),
                Tab(icon: Icon(Icons.open_with_outlined), text: 'Vị trí'),
                Tab(icon: Icon(Icons.tune_outlined), text: 'Chỉnh'),
                Tab(icon: Icon(Icons.palette_outlined), text: 'Giấy'),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: TabBarView(
                  children: [
                    Column(
                      children: [
                        _AddAssetButton(
                          label: 'Tải cảnh',
                          onPressed: onAddScene,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _OptionStrip<StudioScene>(
                            items: scenes,
                            selected: selectedScene,
                            labelOf: (item) => item.name,
                            colorsOf: (item) => item.previewColors,
                            imageOf: (item) => item.image,
                            onChanged: onSceneChanged,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        _AddAssetButton(
                          label: 'Tải khung',
                          onPressed: onAddFrame,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _OptionStrip<FrameStyle>(
                            items: frames,
                            selected: selectedFrame,
                            labelOf: (item) => item.name,
                            colorsOf: (item) =>
                                [item.shine, item.base, item.edge],
                            imageOf: (item) => item.texture,
                            onChanged: onFrameChanged,
                          ),
                        ),
                      ],
                    ),
                    _MobileSliderPanel(
                      children: [
                        _CompactSliderRow(
                          label: 'Thu phóng',
                          value: artworkScale,
                          min: 0.25,
                          max: 4,
                          onChanged: onArtworkScaleChanged,
                        ),
                        _CompactSliderRow(
                          label: 'Ngang',
                          value: artworkOffset.dx,
                          min: -1.5,
                          max: 1.5,
                          onChanged: onArtworkOffsetXChanged,
                        ),
                        _CompactSliderRow(
                          label: 'Dọc',
                          value: artworkOffset.dy,
                          min: -1.5,
                          max: 1.5,
                          onChanged: onArtworkOffsetYChanged,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: onArtworkReset,
                            icon:
                                const Icon(Icons.center_focus_strong_outlined),
                            label: const Text('Đặt lại'),
                          ),
                        ),
                      ],
                    ),
                    _MobileSliderPanel(
                      children: [
                        _CompactSliderRow(
                          label: 'Rộng khung',
                          value: frameWidth,
                          min: 6,
                          max: 70,
                          onChanged: onFrameWidthChanged,
                        ),
                        _CompactSliderRow(
                          label: 'Bo viền',
                          value: cornerRadius,
                          min: 0,
                          max: 44,
                          onChanged: onCornerRadiusChanged,
                        ),
                        _CompactSliderRow(
                          label: 'Viền giấy',
                          value: matWidth,
                          min: 0,
                          max: 90,
                          onChanged: onMatWidthChanged,
                        ),
                        _CompactSliderRow(
                          label: 'Khử nhăn',
                          value: smoothness,
                          min: 0,
                          max: 100,
                          onChanged: onSmoothnessChanged,
                        ),
                        _CompactSliderRow(
                          label: 'Bóng',
                          value: shadowDepth,
                          min: 0,
                          max: 100,
                          onChanged: onShadowDepthChanged,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final paper in papers)
                              _ColorSwatch(
                                color: paper,
                                selected: paper == selectedPaper,
                                onTap: () => onPaperChanged(paper),
                              ),
                          ],
                        ),
                        const Spacer(),
                        SegmentedButton<ArtworkRatio>(
                          segments: const [
                            ButtonSegment(
                              value: ArtworkRatio.portrait,
                              label: Text('Dọc'),
                            ),
                            ButtonSegment(
                              value: ArtworkRatio.square,
                              label: Text('Vuông'),
                            ),
                            ButtonSegment(
                              value: ArtworkRatio.landscape,
                              label: Text('Ngang'),
                            ),
                          ],
                          selected: {selectedRatio},
                          onSelectionChanged: (value) =>
                              onRatioChanged(value.first),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileSliderPanel extends StatelessWidget {
  const _MobileSliderPanel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: children,
    );
  }
}

class _AddAssetButton extends StatelessWidget {
  const _AddAssetButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
        label: Text(label),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          child,
          const SizedBox(height: 8),
          Divider(color: Colors.black.withValues(alpha: 0.1)),
        ],
      ),
    );
  }
}

class _OptionGrid<T> extends StatelessWidget {
  const _OptionGrid({
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.colorsOf,
    required this.imageOf,
    required this.onChanged,
  });

  final List<T> items;
  final T selected;
  final String Function(T item) labelOf;
  final List<Color> Function(T item) colorsOf;
  final ui.Image? Function(T item) imageOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1 / 0.86,
      children: [
        for (final item in items)
          _OptionTile(
            selected: item == selected,
            label: labelOf(item),
            colors: colorsOf(item),
            image: imageOf(item),
            onTap: () => onChanged(item),
          ),
      ],
    );
  }
}

class _OptionStrip<T> extends StatelessWidget {
  const _OptionStrip({
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.colorsOf,
    required this.imageOf,
    required this.onChanged,
  });

  final List<T> items;
  final T selected;
  final String Function(T item) labelOf;
  final List<Color> Function(T item) colorsOf;
  final ui.Image? Function(T item) imageOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(width: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return SizedBox(
          width: 96,
          child: _OptionTile(
            selected: item == selected,
            label: labelOf(item),
            colors: colorsOf(item),
            image: imageOf(item),
            onTap: () => onChanged(item),
          ),
        );
      },
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.selected,
    required this.label,
    required this.colors,
    required this.image,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final List<Color> colors;
  final ui.Image? image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? const Color(0xFF0F766E) : const Color(0xFFD8DDE1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
            ),
            if (image != null) RawImage(image: image, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.52)
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(9),
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF626B73), fontWeight: FontWeight.w700)),
          Slider(value: value, min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _CompactSliderRow extends StatelessWidget {
  const _CompactSliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF626B73),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch(
      {required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        width: 42,
        height: 42,
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color:
                  selected ? const Color(0xFF0F766E) : const Color(0xFFD8DDE1),
              width: selected ? 3 : 1),
        ),
      ),
    );
  }
}

class FramePreviewPainter extends CustomPainter {
  FramePreviewPainter({
    required this.scene,
    required this.frame,
    required this.paper,
    required this.ratio,
    required this.artwork,
    required this.frameWidth,
    required this.cornerRadius,
    required this.matWidth,
    required this.smoothness,
    required this.shadowDepth,
    required this.artworkScale,
    required this.artworkOffset,
    required this.compact,
  });

  final StudioScene scene;
  final FrameStyle frame;
  final Color paper;
  final ArtworkRatio ratio;
  final ui.Image? artwork;
  final double frameWidth;
  final double cornerRadius;
  final double matWidth;
  final double smoothness;
  final double shadowDepth;
  final double artworkScale;
  final Offset artworkOffset;
  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    _drawRoom(canvas, size);
    final artworkBox = _artworkBox(size);
    canvas.save();
    final transformCenter = artworkBox.center;
    canvas.translate(
      artworkOffset.dx * size.width * 0.5,
      artworkOffset.dy * size.height * 0.5,
    );
    canvas.translate(transformCenter.dx, transformCenter.dy);
    canvas.scale(artworkScale);
    canvas.translate(-transformCenter.dx, -transformCenter.dy);
    _drawFramePackage(canvas, artworkBox);
    canvas.restore();
  }

  void _drawRoom(Canvas canvas, Size size) {
    if (scene.image != null) {
      paintImage(
        canvas: canvas,
        rect: Offset.zero & size,
        image: scene.image!,
        fit: BoxFit.cover,
      );
      return;
    }

    final wallHeight = size.height * 0.66;
    final wallPaint = Paint()
      ..shader = LinearGradient(colors: scene.wall)
          .createShader(Rect.fromLTWH(0, 0, size.width, wallHeight));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, wallHeight), wallPaint);

    final texturePaint = Paint()
      ..color = const Color(0xFF262B2A).withValues(alpha: 0.09)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double y = 70; y < wallHeight - 35; y += 82) {
      final path = Path()
        ..moveTo(0, y + math.sin(y) * 7)
        ..cubicTo(size.width * 0.3, y - 15, size.width * 0.62, y + 18,
            size.width, y - 4);
      canvas.drawPath(path, texturePaint);
    }

    final floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: scene.floor,
      ).createShader(
          Rect.fromLTWH(0, wallHeight, size.width, size.height - wallHeight));
    canvas.drawRect(
        Rect.fromLTWH(0, wallHeight, size.width, size.height - wallHeight),
        floorPaint);

    canvas.drawRect(Rect.fromLTWH(0, wallHeight - 10, size.width, 18),
        Paint()..color = scene.trim);
    _drawFurniture(canvas, size);
  }

  void _drawFurniture(Canvas canvas, Size size) {
    final paint = Paint()..color = scene.furnitureColor.withValues(alpha: 0.82);
    switch (scene.furniture) {
      case Furniture.bench:
        canvas.drawRRect(
            _rrect(
                size.width * 0.18, size.height * 0.8, size.width * 0.64, 42, 8),
            paint);
        _drawLegs(canvas, size, [0.24, 0.76]);
        break;
      case Furniture.sofa:
        canvas.drawRRect(
            _rrect(size.width * 0.08, size.height * 0.77, size.width * 0.42, 92,
                18),
            paint);
        canvas.drawRRect(
            _rrect(size.width * 0.11, size.height * 0.71, size.width * 0.34, 70,
                14),
            paint..color = scene.furnitureColor);
        break;
      case Furniture.lamp:
        canvas.drawLine(
            Offset(size.width * 0.82, size.height * 0.44),
            Offset(size.width * 0.82, size.height * 0.84),
            Paint()
              ..color = const Color(0xFFECDDBC).withValues(alpha: 0.7)
              ..strokeWidth = 8);
        canvas.drawRRect(
            _rrect(
                size.width * 0.77, size.height * 0.38, size.width * 0.1, 56, 8),
            Paint()..color = const Color(0xFFECDDBC).withValues(alpha: 0.9));
        break;
      case Furniture.table:
        canvas.drawRRect(
            _rrect(size.width * 0.58, size.height * 0.79, size.width * 0.28, 34,
                8),
            paint);
        _drawLegs(canvas, size, [0.62, 0.82]);
        break;
      case Furniture.plant:
        final leafPaint = Paint()
          ..color = const Color(0xFF445B3B).withValues(alpha: 0.78);
        for (var i = 0; i < 8; i += 1) {
          canvas.drawOval(
            Rect.fromCenter(
                center: Offset(
                    size.width * 0.15 + i * 16, size.height * 0.74 - i * 9),
                width: 96,
                height: 28),
            leafPaint,
          );
        }
        canvas.drawRRect(
            _rrect(size.width * 0.14, size.height * 0.82, size.width * 0.08, 58,
                8),
            Paint()..color = const Color(0xFF705236).withValues(alpha: 0.9));
        break;
      case Furniture.screen:
        final screenPaint = Paint()
          ..color = const Color(0xFF393F3B).withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        for (var i = 0; i < 4; i += 1) {
          canvas.drawRect(
              Rect.fromLTWH(size.width * 0.72 + i * 42, size.height * 0.49, 38,
                  size.height * 0.28),
              screenPaint);
        }
        break;
      case Furniture.none:
        break;
    }
  }

  void _drawLegs(Canvas canvas, Size size, List<double> positions) {
    final legPaint = Paint()
      ..color = const Color(0xFF261E18).withValues(alpha: 0.62)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (final x in positions) {
      canvas.drawLine(Offset(size.width * x, size.height * 0.83),
          Offset(size.width * (x - 0.015), size.height * 0.92), legPaint);
    }
  }

  Rect _artworkBox(Size size) {
    final fallbackAspect = switch (ratio) {
      ArtworkRatio.portrait => 0.72,
      ArtworkRatio.square => 1.0,
      ArtworkRatio.landscape => 1.38,
    };
    final aspect =
        artwork == null ? fallbackAspect : artwork!.width / artwork!.height;
    final maxW = size.width * (compact ? 0.52 : 0.4);
    final maxH = size.height * (compact ? 0.34 : 0.47);
    var artW = maxW;
    var artH = artW / aspect;
    if (artH > maxH) {
      artH = maxH;
      artW = artH * aspect;
    }
    final centerY = compact ? size.height * 0.38 : size.height * 0.33;
    return Rect.fromLTWH(
        size.width * 0.5 - artW / 2, centerY - artH / 2, artW, artH);
  }

  void _drawFramePackage(Canvas canvas, Rect art) {
    final effectiveFrameWidth = compact ? frameWidth * 0.28 : frameWidth;
    final effectiveMatWidth = compact ? matWidth * 0.36 : matWidth;
    final outer = art.inflate(effectiveFrameWidth + effectiveMatWidth);
    final mat = art.inflate(effectiveMatWidth);
    final shadow = shadowDepth / 100;

    canvas.drawShadow(
        Path()..addRRect(_rrectFromRect(outer, cornerRadius + 8)),
        Colors.black.withValues(alpha: 0.32 + shadow * 0.26),
        18 + shadow * 26,
        false);
    _drawFrame(canvas, outer, mat);
    _drawMat(canvas, mat, art);
    _drawArtwork(canvas, art);
    _drawGlass(canvas, outer);
  }

  void _drawFrame(Canvas canvas, Rect outer, Rect inner) {
    final framePath = Path()
      ..addRRect(_rrectFromRect(outer, cornerRadius + 10))
      ..addRRect(_rrectFromRect(inner, cornerRadius))
      ..fillType = PathFillType.evenOdd;
    final framePaint = Paint()
      ..shader = LinearGradient(
        colors: [frame.shine, frame.base, frame.edge, frame.shine],
        stops: const [0, 0.22, 0.78, 1],
      ).createShader(outer);
    canvas.drawPath(framePath, framePaint);

    if (frame.texture != null) {
      canvas.save();
      canvas.clipPath(framePath);
      paintImage(
        canvas: canvas,
        rect: outer,
        image: frame.texture!,
        fit: BoxFit.cover,
        repeat: ImageRepeat.repeat,
      );
      canvas.drawPath(
        framePath,
        Paint()..color = Colors.black.withValues(alpha: 0.08),
      );
      canvas.restore();
    }

    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRRect(
        _rrectFromRect(outer.deflate(9), cornerRadius + 5), highlight);
  }

  void _drawMat(Canvas canvas, Rect mat, Rect art) {
    final matPath = Path()
      ..addRRect(_rrectFromRect(mat, cornerRadius))
      ..addRRect(_rrectFromRect(art, math.max(0, cornerRadius - 4)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(matPath, Paint()..color = paper);
    _drawPaperGrain(canvas, mat);
  }

  void _drawArtwork(Canvas canvas, Rect art) {
    canvas.save();
    canvas.clipRRect(_rrectFromRect(art, math.max(0, cornerRadius - 8)));
    canvas.drawRect(art, Paint()..color = paper);

    if (artwork == null) {
      _drawPlaceholderArt(canvas, art);
    } else {
      paintImage(canvas: canvas, rect: art, image: artwork!, fit: BoxFit.cover);
    }

    _applySmoothness(canvas, art);
    canvas.restore();
  }

  void _drawPlaceholderArt(Canvas canvas, Rect art) {
    final paint = Paint()
      ..shader = LinearGradient(colors: const [
        Color(0xFFE8D7BE),
        Color(0xFF5F8178),
        Color(0xFF252B2A)
      ]).createShader(art);
    canvas.drawRect(art, paint);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(5, art.width * 0.018);
    for (var i = 0; i < 5; i += 1) {
      final path = Path()
        ..moveTo(art.left + art.width * 0.16,
            art.top + art.height * (0.2 + i * 0.13))
        ..cubicTo(
          art.left + art.width * 0.35,
          art.top + art.height * (0.05 + i * 0.18),
          art.left + art.width * 0.62,
          art.top + art.height * (0.36 + i * 0.08),
          art.left + art.width * 0.82,
          art.top + art.height * (0.18 + i * 0.12),
        );
      canvas.drawPath(path, linePaint);
    }
  }

  void _drawPaperGrain(Canvas canvas, Rect box) {
    final paint = Paint()
      ..color = const Color(0xFF1F2428).withValues(alpha: 0.09);
    for (var i = 0; i < 260; i += 1) {
      final x = box.left + _noise(i * 13.13) * box.width;
      final y = box.top + _noise(i * 8.71 + 3) * box.height;
      canvas.drawRect(Rect.fromLTWH(x, y, 1.3, 1.3), paint);
    }
  }

  void _applySmoothness(Canvas canvas, Rect box) {
    final opacity = (smoothness / 100) * 0.28;
    if (opacity < 0.01) return;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: opacity),
          Colors.white.withValues(alpha: opacity * 0.2),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0, 0.45, 0.55, 1],
      ).createShader(box);
    canvas.drawRect(box, paint);
  }

  void _drawGlass(Canvas canvas, Rect box) {
    canvas.save();
    canvas.clipRRect(_rrectFromRect(box, cornerRadius + 8));
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.32),
          Colors.white.withValues(alpha: 0.02),
          Colors.white.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0),
        ],
        stops: const [0, 0.28, 0.45, 1],
      ).createShader(box);
    canvas.drawRect(box, paint);
    canvas.restore();
  }

  RRect _rrect(double x, double y, double width, double height, double radius) {
    return RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, width, height), Radius.circular(radius));
  }

  RRect _rrectFromRect(Rect rect, double radius) {
    return RRect.fromRectAndRadius(rect, Radius.circular(radius));
  }

  double _noise(double value) {
    final x = math.sin(value) * 10000;
    return x - x.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant FramePreviewPainter oldDelegate) {
    return oldDelegate.scene != scene ||
        oldDelegate.frame != frame ||
        oldDelegate.paper != paper ||
        oldDelegate.ratio != ratio ||
        oldDelegate.artwork != artwork ||
        oldDelegate.frameWidth != frameWidth ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.matWidth != matWidth ||
        oldDelegate.smoothness != smoothness ||
        oldDelegate.shadowDepth != shadowDepth ||
        oldDelegate.artworkScale != artworkScale ||
        oldDelegate.artworkOffset != artworkOffset ||
        oldDelegate.compact != compact;
  }
}

enum ArtworkRatio { portrait, square, landscape }

enum Furniture { bench, sofa, lamp, table, plant, screen, none }

class StudioScene {
  const StudioScene({
    required this.name,
    required this.wall,
    required this.floor,
    required this.trim,
    required this.previewColors,
    required this.furniture,
    required this.furnitureColor,
    this.image,
  });

  final String name;
  final List<Color> wall;
  final List<Color> floor;
  final Color trim;
  final List<Color> previewColors;
  final Furniture furniture;
  final Color furnitureColor;
  final ui.Image? image;
}

class FrameStyle {
  const FrameStyle({
    required this.name,
    required this.base,
    required this.edge,
    required this.shine,
    this.texture,
  });

  final String name;
  final Color base;
  final Color edge;
  final Color shine;
  final ui.Image? texture;
}

const scenes = [
  StudioScene(
    name: 'Phòng triển lãm',
    wall: [Color(0xFFF9F7F1), Color(0xFFECE6DC)],
    floor: [Color(0xFFD8C7AA), Color(0xFFBFA783)],
    trim: Color(0xFFC9BDA8),
    previewColors: [Color(0xFFF9F7F1), Color(0xFFD8C7AA)],
    furniture: Furniture.bench,
    furnitureColor: Color(0xFF483727),
  ),
  StudioScene(
    name: 'Phòng khách',
    wall: [Color(0xFFDFE8E5), Color(0xFFC9D8D4)],
    floor: [Color(0xFFB88563), Color(0xFF8A5B3E)],
    trim: Color(0xFF9EB7B0),
    previewColors: [Color(0xFFDFE8E5), Color(0xFFB88563)],
    furniture: Furniture.sofa,
    furnitureColor: Color(0xFF44756D),
  ),
  StudioScene(
    name: 'Studio tối',
    wall: [Color(0xFF3D4240), Color(0xFF252927)],
    floor: [Color(0xFF8C7356), Color(0xFF4F3B2B)],
    trim: Color(0xFF575D59),
    previewColors: [Color(0xFF3D4240), Color(0xFF8C7356)],
    furniture: Furniture.lamp,
    furnitureColor: Color(0xFFECDDBC),
  ),
  StudioScene(
    name: 'Bàn ăn',
    wall: [Color(0xFFEEE2D0), Color(0xFFDBC7AA)],
    floor: [Color(0xFF6D7D63), Color(0xFF3E4D3A)],
    trim: Color(0xFFBFAE91),
    previewColors: [Color(0xFFEEE2D0), Color(0xFF6D7D63)],
    furniture: Furniture.table,
    furnitureColor: Color(0xFF313726),
  ),
  StudioScene(
    name: 'Nền giấy',
    wall: [Color(0xFFFBF7EF), Color(0xFFE6DCC9)],
    floor: [Color(0xFFCAB58E), Color(0xFFA78B61)],
    trim: Color(0xFFD2C2A8),
    previewColors: [Color(0xFFFFFFFF), Color(0xFFC7B18D)],
    furniture: Furniture.plant,
    furnitureColor: Color(0xFF445B3B),
  ),
  StudioScene(
    name: 'Thủy mặc',
    wall: [Color(0xFFF2F3EE), Color(0xFFD4D9D2)],
    floor: [Color(0xFFAAB3AA), Color(0xFF707C75)],
    trim: Color(0xFFB6BDB5),
    previewColors: [Color(0xFFF2F3EE), Color(0xFF303734)],
    furniture: Furniture.screen,
    furnitureColor: Color(0xFF393F3B),
  ),
];

const frames = [
  FrameStyle(
      name: 'Óc chó',
      base: Color(0xFF5B3825),
      edge: Color(0xFF2F1A10),
      shine: Color(0xFF9D7254)),
  FrameStyle(
      name: 'Sồi sáng',
      base: Color(0xFFB68B54),
      edge: Color(0xFF6D4B2F),
      shine: Color(0xFFE2C08B)),
  FrameStyle(
      name: 'Đen mờ',
      base: Color(0xFF202322),
      edge: Color(0xFF050605),
      shine: Color(0xFF555C58)),
  FrameStyle(
      name: 'Trắng',
      base: Color(0xFFF2F0EA),
      edge: Color(0xFFB7B3A9),
      shine: Color(0xFFFFFFFF)),
  FrameStyle(
      name: 'Vàng cổ',
      base: Color(0xFFB8892D),
      edge: Color(0xFF5E4318),
      shine: Color(0xFFEDCE73)),
  FrameStyle(
      name: 'Kim loại',
      base: Color(0xFF717B81),
      edge: Color(0xFF343B40),
      shine: Color(0xFFC9D1D4)),
];

const papers = [
  Color(0xFFF8F3E8),
  Color(0xFFFFFDF7),
  Color(0xFFECE0C9),
  Color(0xFFD8C7AD),
  Color(0xFFEFF1EC),
  Color(0xFF222523),
];
