```markdown
# Design System Document: The Nostalgic Guardian

## 1. Overview & Creative North Star: "The Digital Curator"
This design system is built to bridge the gap between high-end parental oversight and the whimsical, creative world of childhood. Our Creative North Star is **"The Digital Curator."** 

Unlike standard dashboards that feel clinical or administrative, this system mimics the tactile, cherished feel of a premium physical scrapbook or a gallery archive. We move away from the "template" look by utilizing **intentional asymmetry**, **soft-focus depth**, and **overlapping editorial layouts**. By treating every data point as a "memory" or an "achievement," we transform parental management into a celebratory experience.

### Breaking the Grid
To achieve this premium feel, avoid rigid, perfectly aligned columns. Use the `lg` (2rem) and `xl` (3rem) corner radii to create overlapping card patterns. Elements should feel like they are "resting" on a surface rather than being locked into a frame.

---

## 2. Colors: Tonal Depth & Warmth
Our palette is rooted in the deep serenity of the night sky, illuminated by the warmth of achievement and the clarity of guidance.

### The "No-Line" Rule
**Strict Mandate:** Designers are prohibited from using 1px solid borders to define sections. Boundaries must be defined solely through:
1.  **Background Shifts:** e.g., A `surface-container-low` card resting on a `surface` background.
2.  **Tonal Transitions:** Using subtle shifts in the navy scale to suggest hierarchy.

### Surface Hierarchy & Nesting
Treat the UI as physical layers of fine, matte paper.
*   **Base:** `surface` (#0c1322) - The foundation.
*   **Level 1:** `surface-container-low` (#151b2b) - For large secondary sections.
*   **Level 2:** `surface-container` (#191f2f) - The standard card background.
*   **Level 3:** `surface-container-highest` (#2e3545) - For elevated, interactive elements.

### The "Glass & Gradient" Rule
To prevent the deep navy from feeling "flat," use **Glassmorphism** for floating headers or navigation bars. Use `surface_bright` with a 60% opacity and a 20px backdrop blur. 
*   **Signature Texture:** Main CTAs should use a linear gradient from `primary_fixed_dim` (#edc157) to `primary_container` (#ffd166) at a 135° angle to provide a "metallic silk" finish.

---

## 3. Typography: The Editorial Voice
We use **Plus Jakarta Sans** across the entire system. Its geometric yet friendly curves provide an authoritative yet approachable tone.

*   **The Display Scale:** Use `display-lg` (3.5rem) for celebratory moments (e.g., "Your child reached a milestone"). This should feel like a headline in a high-end magazine.
*   **The Title Scale:** `title-lg` (1.375rem) is the workhorse for card headers. It should always be high-contrast (`on_surface`) to ensure a premium feel.
*   **Body & Labels:** `body-md` (0.875rem) is used for descriptions. Maintain generous line height (1.6) to ensure the interface feels "airy" and expensive.

---

## 4. Elevation & Depth: Tonal Layering
We do not use shadows to create "fear" or "urgency." We use them to create "presence."

*   **The Layering Principle:** Depth is achieved by "stacking." Place a `surface-container-lowest` card inside a `surface-container-high` section to create a "recessed" or "inset" feel, reminiscent of a photo tucked into a scrapbook.
*   **Ambient Shadows:** For floating elements, use extra-diffused shadows: `box-shadow: 0 20px 40px rgba(7, 14, 29, 0.4)`. The shadow color must be a darker version of the background, never pure black.
*   **The "Ghost Border" Fallback:** If a container requires definition for accessibility, use the `outline-variant` token at **15% opacity**. It should be felt, not seen.
*   **Signature Glows:** Use `secondary_container` (#00c9db) as a 40px blurred "aura" behind child avatars to denote active sessions or guidance.

---

## 5. Components: The Premium Toolkit

### Buttons (The "Pill" Aesthetic)
*   **Primary:** Uses the `lg` (2rem) corner radius. Background is the Gold Gradient (`primary_fixed_dim` to `primary_container`). Text is `on_primary_fixed` (#251a00).
*   **Secondary:** Ghost style. No background, `outline-variant` at 20% opacity, text in `secondary` (#46e5f8).

### Cards (The "Scrapbook" Card)
*   **Structure:** Always use `lg` (2rem) or `xl` (3rem) corner radius. 
*   **Separation:** Forbid the use of divider lines. Use `surface_container_low` for the card body and `surface_container_high` for the card header to create a natural visual break.

### Celebratory Progress Indicators
*   Instead of thin lines, use thick, 12pt rounded tracks (`surface_variant`).
*   The active state is a gradient of `secondary` to `secondary_container` with a subtle outer glow of the same color.

### Input Fields
*   **State:** Soft-filled `surface_container_highest`. 
*   **Focus:** No high-contrast border. Instead, the background shifts to `surface_bright` and the label moves up in `secondary` (#46e5f8).

### Added Component: The "Memory Stack"
A unique component for this system where multiple `surface-container` cards are slightly rotated (-2 to +2 degrees) and stacked, allowing the parent to swipe through recent achievements or reports.

---

## 6. Do’s and Don’ts

### Do:
*   **Do** use overlapping elements. Let an avatar "break" the top edge of a card by 16px.
*   **Do** use "Soft Gold" (`primary`) for all positive reinforcement.
*   **Do** prioritize white space. If in doubt, add 16px of extra padding.
*   **Do** use the Cyan (`secondary`) specifically for "Actionable Insights" or "Guidance."

### Don’t:
*   **Don’t** use red or orange. If an error occurs, use `on_surface_variant` (muted gold/tan) with a clear, calm explanation.
*   **Don’t** use 90-degree corners. Everything must feel safe and "held."
*   **Don’t** use "Drop Shadows" that are small or dark. They break the scrapbook illusion.
*   **Don’t** use dividers or hair-lines. They make the UI look like a spreadsheet.