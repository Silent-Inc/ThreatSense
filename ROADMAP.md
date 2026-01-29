🔥 ThreatSense Roadmap
A structured, priority‑driven development plan for ThreatSense.

1. Core Display System (Completed)
Foundational UI components required for all other systems.
✔ 1.1 Multi‑Bar Threat List
- TinyThreat‑style list
- Sorting
- Class colors
- Tank indicator
- Threat %
- Smooth updates
✔ 1.2 Display Mode System
- Bar only
- List only
- Bar + List
✔ 1.3 Mode Wiring
- ThreatBar respects mode
- ThreatList respects mode
- Auto‑hide/show
✔ 1.4 Live Mode Updates
- EventBus integration
- No reload required
✔ 1.5 Display Preview System
- Fake threat data
- Live preview
- Auto‑stop on combat

2. Warning System (Completed)
Modern, role‑aware threat warnings.
✔ 2.1 WarningEngine
- Tank‑aware logic
- DPS threat logic
- Healer threat logic
- Hybrid warning model
✔ 2.2 WarningFrame
- Icon + text warnings
- Clean UI
- Event‑driven
✔ 2.3 WarningAnimations
- Flash
- Pulse
- Fade
✔ 2.4 WarningPreview
- Fake warnings
- Live rotation
- Auto‑stop
✔ 2.5 Warning Settings Panel
- Enable/disable
- Style selection
- Preview button

3. Profiles System (Completed)
Centralized configuration storage and management.
✔ 3.1 ProfileManager
- Load/save settings
- Character → profile mapping
✔ 3.2 Profile Switching
- Live updates
- EventBus integration
✔ 3.3 Create / Copy / Delete Profiles
✔ 3.4 Profile Settings Panel
✔ 3.5 Profile‑Aware Settings
- All modules read/write through ProfileManager

4. Role Detection & Role‑Aware Behavior (Next)
Enhances intelligence and automation.
🔜 4.1 Role Detection
- Tank / Healer / DPS
🔜 4.2 Role‑Specific Defaults
- Display mode
- Warning thresholds
- Warning types
🔜 4.3 Optional Auto‑Switch Profiles
🔜 4.4 Role‑Aware Display Behavior
🔜 4.5 Role‑Aware Warnings

5. Interface Options Expansion
Modern Settings API panels for full customization.
🔜 5.1 Parent Panel
- AddOn root
- Description, author, version
🔜 5.2 Display Customization
- Textures
- Fonts
- Colors
- Bar height
- Spacing
- Smoothing speed
- Combat fade
🔜 5.3 Warning Customization
- Threshold sliders
- Enable/disable specific warnings
- Sound alerts
- Icon size
- Warning position
🔜 5.4 Reset to Defaults
🔜 5.5 Slash Command
- /ts opens settings

6. Visual Polish & UX Enhancements
Premium feel and smoothness.
🔜 6.1 Rounded Edges
🔜 6.2 Enhanced Smooth Animations
🔜 6.3 Threat History (optional)
🔜 6.4 Combat Fade

7. Addon Integration & Convenience
Quality‑of‑life features.
🔜 7.1 Minimap Button
🔜 7.2 LibDataBroker Launcher
🔜 7.3 Additional Slash Commands

8. Maintenance & Fixes (Ongoing)
Continuous improvement.
🔄 8.1 Parent/Child Panel Nesting
🔄 8.2 ThreatEngine Edge Cases
🔄 8.3 Solo Mode
🔄 8.4 Performance Tuning
🔄 8.5 Code Cleanup & Refactoring