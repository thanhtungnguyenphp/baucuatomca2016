# AdMob Android release checklist

Godot 4.7.1 uses Poing Studios AdMob v5.1.0 with matching Android template. The production App ID is in `project.godot`; banner and interstitial unit IDs are in `scripts/core/ad_placement.gd`.

- Banner: 320 × 50 dp, anchored to the bottom. The board and navigation leave a reserved lower strip so it cannot cover gameplay controls.
- Interstitial: preloaded and shown only after the player covers the bowl, no more than once every eight completed rounds and with at least three minutes between ads. A failed load never blocks gameplay.
- Debug builds use Google's demo ad unit IDs. Release builds use the production IDs.
- On launch, the UMP consent state is refreshed before ad requests. If required, the consent form is displayed. The settings popup exposes a privacy options button when UMP requires one.

Before uploading the next release:

1. Test a debug build on a real Android device, including banner position, consent form, eight-round interstitial cadence, and closing/reopening popups.
2. In AdMob Privacy & messaging, publish the applicable privacy message for the regions served.
3. Update Google Play's Contains ads, Advertising ID, Data safety, and privacy policy declarations to match the SDK and the target countries.
4. Export a signed Release AAB and verify package name `vn.lamgame.baucuatomca`, the new version code, manifest App ID, and upload certificate.

Do not upload an earlier AAB for this update; it lacks the Hành trình and local party improvements.
