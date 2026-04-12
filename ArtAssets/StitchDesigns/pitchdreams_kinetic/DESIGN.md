# Design System Strategy: The Kinetic Sanctuary

## 1. Overview & Creative North Star: "The Kinetic Sanctuary"
This design system is built to bridge the gap between high-octane performance and focused mental clarity. We are moving away from the "flat, data-heavy" spreadsheets of traditional sports apps and toward an immersive, editorial experience.

**The Creative North Star: Kinetic Sanctuary**
Imagine the focus of a locker room combined with the premium tranquility of a high-end wellness lounge. This system rejects rigid grids and harsh dividers in favor of **Organic Asymmetry** and **Tonal Depth**. We create "soul" through backlight blooms, glassmorphism, and a hierarchy defined by light rather than lines. The goal is to make a 14-year-old athlete feel like a professional while keeping the interface calm enough for deep focus during training.

---

## 2. Color & Materiality: Beyond the Flat Hex
Our palette is rooted in the deep shadows of the "Pitch" and the vibrant energy of "Gameday."

### The "No-Line" Rule
**Lines are banned.** You are prohibited from using 1px solid borders to section content. Boundaries must be defined through:
*   **Background Shifts:** Transitioning from `surface` (#0c1322) to `surface_container_low` (#151b2b).
*   **Tonal Transitions:** Using soft gradients to define where one thought ends and another begins.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers.
*   **Deepest Layer:** `surface_container_lowest` (#070e1d) for the main canvas.
*   **The Content Layer:** `surface_container` (#191f2f) for primary activity cards.
*   **The Focus Layer:** `surface_container_highest` (#2e3545) for active interactions.

### The "Glass & Gradient" Rule
To achieve the "Premium Game" aesthetic, use **Glassmorphism**. Floating elements (like navigation bars or stats overlays) should use semi-transparent `surface_variant` colors with a 20px–40px backdrop blur. 
*   **Signature Texture:** Primary CTAs should never be flat. Apply a subtle linear gradient from `primary` (#ffb59a) to `primary_container` (#ff6b2c) at a 135° angle to create a "bloom" effect.

---

## 3. Typography: Editorial Impact
We utilize **SF Pro Rounded** (mapped to `plusJakartaSans` and `beVietnamPro` tokens for web/cross-platform parity) to maintain a friendly yet professional tone.

*   **Display (L/M/S):** Use `display-lg` (3.5rem) for "Big Win" moments. These should be tight-tracked and bold. This is your "Sports Game" voice.
*   **Headlines:** `headline-lg` through `headline-sm` are the "Coach’s Voice"—authoritative and clear.
*   **Body & Titles:** `beVietnamPro` provides the "Wellness" aspect. It is highly legible, open, and provides breathing room for long-form training descriptions.

**Hierarchy Tip:** Use extreme scale. Pair a massive `display-md` stat (e.g., "98%") with a tiny, uppercase `label-md` ("COMPLETION RATE") to create a premium, intentional look.

---

## 4. Elevation & Depth: Tonal Layering
Traditional shadows look "cheap" here. We use **Ambient Light** and **Tonal Stacking**.

*   **The Layering Principle:** Place a `surface_container_low` card on top of the `surface` background. To create "lift," do not add a shadow—instead, add a 1px "Inner Glow" using `outline_variant` (#594139) at 15% opacity.
*   **The Backlight Bloom:** For Achievement Cards, use a `tertiary` (#edc157) or `secondary` (#46e5f8) shadow with a 60px blur and only 10% opacity. This creates a "glow" behind the card as if it’s an illuminated screen within the app.
*   **Ghost Borders:** If a boundary is required for accessibility, use `outline-variant` at 10% opacity. If you can see the line clearly, it’s too dark.

---

## 5. Components: Fluidity & Impact

### Buttons: The "Power" Component
*   **Primary:** Rounded `xl` (3rem), Gradient (`primary` to `primary_container`). Drop a subtle 12px blur shadow of the same color.
*   **Secondary:** Ghost style. No background, `outline` token at 20% opacity, `on_surface` text.

### Cards: The "Hero" Container
*   **Geometry:** Always use `lg` (2rem) or `xl` (3rem) corner radius.
*   **Content:** No dividers. Separate the header from the body using an 8px vertical gap and a font weight shift.
*   **Depth:** Use a `surface_container_low` background with a subtle "Backlight Bloom" when the card is in a "completed" or "active" state.

### Specialized Components
*   **The Skill Bloom:** A circular progress indicator using `secondary` (Cyan) with a soft glow effect to track training completion.
*   **Avatar Portals:** Hero avatars (Anime-style) should sit inside `full` rounded containers with a `tertiary` (Gold) ring to denote "Elite" status.
*   **The Training Sheet:** A bottom sheet using Glassmorphism (`surface_variant` at 80% opacity + heavy blur) that slides over the main content, allowing the navy background to "bleed" through.

---

## 6. Do’s and Don’ts

### Do
*   **Do** embrace negative space. If a screen feels crowded, increase the `surface` area, don't shrink the text.
*   **Do** use asymmetrical layouts for Hero sections. Let the anime-style avatar break the container bounds (overlap).
*   **Do** use `secondary_fixed` (Cyan) for instructional text—it acts as the "Player's Guide."

### Don't
*   **Don't** use 1px solid dividers. Ever. Use 24px–32px of white space instead.
*   **Don't** use pure black or pure white. Use the `surface` and `on_surface` tokens to maintain the premium "Navy & Soft White" aesthetic.
*   **Don't** use standard "Drop Shadows." Only use tinted ambient glows that match the component's accent color.