import 'package:debrify/widgets/player/player_focus_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late PlayerFocusController c;

  setUp(() {
    c = PlayerFocusController();
  });

  tearDown(() {
    c.dispose();
  });

  test('starts hidden', () {
    expect(c.chrome, PlayerChrome.hidden);
    expect(c.isControlsVisible, isFalse);
  });

  test('showControls moves to controls', () {
    c.showControls();
    expect(c.chrome, PlayerChrome.controls);
    expect(c.isControlsVisible, isTrue);
  });

  test('openPanel and closePanel restore controls', () {
    c.showControls();
    c.openPanel(PlayerSubPanelKind.subtitle);
    expect(c.chrome, PlayerChrome.subPanel);
    expect(c.openPanelKind, PlayerSubPanelKind.subtitle);
    c.closePanel();
    expect(c.chrome, PlayerChrome.controls);
    expect(c.openPanelKind, isNull);
  });

  test('handleBack layers: panel then chrome then exit signal', () {
    c.showControls();
    c.openPanel(PlayerSubPanelKind.audio);
    expect(c.handleBack(), isTrue);
    expect(c.chrome, PlayerChrome.controls);

    expect(c.handleBack(), isTrue);
    expect(c.chrome, PlayerChrome.hidden);

    expect(c.handleBack(), isFalse);
    expect(c.chrome, PlayerChrome.hidden);
  });

  test('hideControls sets hidden', () {
    c.showControls(prefer: c.progress);
    c.hideControls();
    expect(c.chrome, PlayerChrome.hidden);
  });
}
