# Design System Strategy: Neon Stadium

## 1. Overview & Creative North Star

### Creative North Star: "The Neon Arena"
This design system is built to transform a training app into a high-stakes, aspirational digital arena. We are merging the high-energy kineticism of **Inazuma Eleven** (anime intensity) with the precision of **EA Sports FC** (professional performance) and the mindful flow of **Headspace** (intentionality). 

To move beyond the "standard template" look, we employ **Dynamic Asymmetry**. This means hero characters (cel-shaded avatars) may break the container bounds, and typography scales are pushed to the extreme to create an editorial, high-end feel. We avoid rigid, boxy layouts in favor of overlapping layers and "backlight bloom" that makes the UI feel like it is glowing from within a deep, midnight stadium.

---

## 2. Colors

### Palette & Sentiment
The color logic centers on a high-contrast dark mode. We use deep, nocturnal navies to provide a premium canvas where neon accents can "pop" with maximum luminance.

*   **Primary (`#FF9066`):** The "Ignition" color. Used for progress and primary momentum.
*   **Secondary (`#4FEBFE`):** The "Pulse." Used for guidance, metrics, and technological "intelligence."
*   **Tertiary (`#FFDB8F`):** The "Prestige." Reserved for achievement, streaks, and "Legend" status evolution.
*   **Background (`#070E1D`):** The "Infinite Pitch." A deep, desaturated navy that provides more depth than pure black.

### The "No-Line" Rule
**Explicit Instruction:** Traditional 1px solid borders are strictly prohibited for sectioning. Boundaries must be defined solely through background color shifts or tonal transitions. To separate a card from the background, use `surface-container-low` on top of `surface`.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers. Use the `surface-container` tiers to create depth:
1.  **Base Layer:** `surface` (The pitch).
2.  **Sectioning:** `surface-container-low` (The field).
3.  **Active Cards:** `surface-container-highest` (The spotlight).

### The "Glass & Gradient" Rule
For floating elements or modal overlays, use **Glassmorphism**. Apply `surface-variant` with a 60% opacity and a `20pt` backdrop-blur. 
*   **Signature Textures:** Main CTAs should not be flat. Use a linear gradient from `primary` to `primary-container` (top-left to bottom-right) to give buttons a "tactile" glow.

---

## 3. Typography

The typography strategy relies on the contrast between the technical precision of **Be Vietnam Pro** and the aggressive, modern energy of **Plus Jakarta Sans**.

*   **Display (Plus Jakarta Sans - Bold):** Used for "Big Wins" and character level-ups. It should feel loud and aspirational.
*   **Headlines (Plus Jakarta Sans - SemiBold):** Used for screen titles. These should utilize "Negative Tracking" (-2%) to feel tighter and more premium.
*   **Titles & Body (Be Vietnam Pro):** Used for all functional reading. The rounded terminals of the "Rounded SF Pro" aesthetic are mirrored here to keep the "Headspace-like" friendliness within a sports context.
*   **Labels (Be Vietnam Pro - Bold):** Small caps or high-weight labels are used for metrics (e.g., "RPM" or "KM/H") to evoke a sports broadcast HUD.

---

## 4. Elevation & Depth

### The Layering Principle
Depth is achieved by "stacking" tones. Place a `surface-container-lowest` card inside a `surface-container-high` section to create a "recessed" look, or vice versa for a "lifted" look.

### Ambient Shadows
Traditional black shadows are forbidden. If a "floating" effect is required (e.g., for a hero character avatar), use a **Bloom Shadow**:
*   **Color:** `primary_dim` at 12% opacity.
*   **Blur:** `32pt` to `48pt`.
*   **Spread:** `0`.
This mimics the way neon light spills onto a dark surface.

### The "Ghost Border" Fallback
If a container requires a boundary for accessibility (e.g., an input field), use a **Ghost Border**: `outline-variant` at 15% opacity. It should be felt, not seen.

---

## 5. Components

### Buttons
*   **Primary:** Gradient (`primary` to `primary-fixed-dim`), `xl` (3rem) rounded corners. Text is `on-primary-fixed` (Black) for maximum legibility.
*   **Secondary (Ghost):** No fill. Ghost border (`outline-variant` @ 20%). Text is `secondary`.
*   **Interaction:** On press, scale the button to 96% to simulate physical "squish."

### Cards & Lists
*   **Rule:** No divider lines. Use `md` (1.5rem) vertical spacing or a subtle shift to `surface-container-low` to separate items.
*   **Backlight Bloom:** For "Legend" tier cards, add a subtle inner-shadow or a gradient edge in `tertiary` to signify rarity.

### Progress Gauges (The "Inazuma" HUD)
*   Instead of standard bars, use thick (`12pt`) circular strokes with `secondary` glows. 
*   Incorporate the animal avatars (e.g., the cel-shaded cat/wolf) as the "centerpiece" of progress screens.

### Chips
*   **Action Chips:** Use `secondary-container` with `on-secondary-container` text. Corners must be `full` (pill-shaped).

---

## 6. Do's and Don'ts

### Do:
*   **Overlap Elements:** Let character ears or soccer balls break the edges of cards to create a 3D, SwiftUI-native feel.
*   **Use Tonal Shifts:** Define a "Header" area by using `surface-bright` and transitioning to `surface` in the scroll area.
*   **Embrace Bloom:** Use subtle glows behind icons to guide the user's eye to the "Guidance" (Cyan) elements.

### Don't:
*   **Don't use #000000:** Except for the `surface-container-lowest`, avoid pure black. It kills the "Deep Navy" premium atmosphere.
*   **Don't use 1px Dividers:** They make the app look like a generic list-view. Use white space.
*   **Don't use Default Corners:** Avoid small radii. If it’s not `20pt` or higher, it’s not part of this system. High-radius corners convey the "premium youth" friendly-but-pro energy.
*   **Don't crowd the character:** The cel-shaded avatars are the "Soul" of the app. Give them `xl` padding and allow them to be the largest visual element on hero screens.