# Design System Strategy: The Kinetic Oasis

## 1. Overview & Creative North Star
**Creative North Star: "The Kinetic Oasis"**

This design system is engineered to exist at the intersection of high-octane sports performance and mindful mental clarity. We are moving away from the cluttered, aggressive aesthetic of traditional sports apps and toward a "Kinetic Oasis"—a space that feels as fast and exciting as *EA Sports FC*, yet as grounded and intentional as a premium wellness platform. 

To break the "template" look, the layout utilizes **intentional asymmetry**. Primary character avatars and cel-shaded evolutions should break the bounding box of their containers, creating a sense of life and motion. We employ a high-contrast typography scale to ensure that key performance metrics feel authoritative and "pro," while secondary information breathes within generous negative space.

---

## 2. Colors & Surface Philosophy

The palette is anchored in a deep, atmospheric navy, allowing our "Electric" accents to vibrate with energy.

### The "No-Line" Rule
**Hard borders are strictly prohibited.** To section content, designers must use background tonal shifts. A section should never be divided by a `1px solid` line; instead, transition from `surface` to `surface-container-low`. This creates a sophisticated, seamless flow that feels architectural rather than "boxed in."

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of semi-translucent materials.
- **Base:** `surface` (#0c1322)
- **Primary Cards:** `surface-container` (#191f2f)
- **In-Card Details:** `surface-container-high` (#232a3a) or `highest` (#2e3545)

### The "Glass & Gradient" Rule
For floating elements (modals, navigation bars, or quick-action buttons), use **Glassmorphism**. Apply `surface-variant` with a 60% opacity and a `20px` to `40px` backdrop blur. 
*   **Signature Textures:** Use a subtle linear gradient for primary CTAs, transitioning from `primary` (#ffe6de) to `primary-container` (#ffc1aa) at a 135-degree angle. This adds "soul" and a tactile, premium finish that flat hex codes cannot replicate.

---

## 3. Typography: The Bold Editorial

We use **Plus Jakarta Sans** for its geometric precision and modern athletic feel.

*   **Display (lg/md/sm):** Reserved for big wins, level-ups, and hero headers. Use `bold` or `extra-bold` weights. This is your "Sports Broadcast" voice.
*   **Headline & Title:** Used for card titles and section headers. These should be tight, punchy, and high-contrast against the background.
*   **Body (lg/md/sm):** Set with generous line height (1.5x) to ensure the "Wellness" aspect of the North Star is maintained.
*   **Labels:** Always uppercase with a `0.05em` letter spacing to provide a technical, "pro-spec" appearance.

The hierarchy functions as a rhythmic guide: Headlines shout the achievement, while body text calmly explains the "how."

---

## 4. Elevation & Depth

Hierarchy is achieved through **Tonal Layering** rather than traditional drop shadows.

*   **The Layering Principle:** To lift an element, move it one step up the surface-container scale. A `surface-container-highest` card sitting on a `surface` background provides all the "lift" required.
*   **Ambient Shadows:** If a card must "float" (e.g., a character evolution pop-up), use an extra-diffused shadow: `Offset: 0 20px, Blur: 40px, Color: on-surface (8% opacity)`. This mimics natural light reflecting off a deep surface.
*   **Ghost Borders:** If accessibility requires a container edge, use the `outline-variant` token at **15% opacity**. It should be felt, not seen.
*   **Depth through Blur:** Use background blurs on parent containers when a child modal is active to create a "focus lens" effect, pulling the user's eye into the foreground.

---

## 5. Key Components

### Buttons & CTAs
*   **Primary:** Gradient fill (`primary` to `primary-container`), `XL` roundedness (3rem). Bold label.
*   **Secondary:** Glassmorphism style. `surface-variant` at 20% opacity with a `ghost border`.
*   **Tertiary:** No container. `secondary` (#42E2F5) text with an icon.

### Tactical Cards
Cards must use `lg` (2rem) or `xl` (3rem) corner radius. 
*   **Pro Tip:** Forbid divider lines within cards. Separate content using `body-md` spacing or a subtle shift to a darker surface-container tier for the footer of the card.

### Evolution Progress Bars
Rather than a thin line, use a thick, `full` rounded track. The progress fill should use a gradient of `secondary` to `secondary-fixed-dim` with a subtle outer glow (cyan) to signify "energy."

### Character Avatars
Characters should be housed in `surface-container-lowest` circular frames, but their "Stage 3" evolutions should overlap the frame, breaking the layout to signify power and growth.

---

## 6. Do's and Don'ts

### Do
*   **Do** use overlapping elements (e.g., a soccer ball icon peeking out from behind a stat card).
*   **Do** use `secondary` (Cyan) for technical stats and `tertiary` (Gold) for achievements/rewards.
*   **Do** embrace the "Kinetic" side—use micro-interactions where cards tilt slightly toward the user’s touch.

### Don't
*   **Don't** use pure black (#000000). Always use the deep navy `surface` tokens to maintain the "premium" depth.
*   **Don't** use 100% opaque borders or dividers. They kill the "Oasis" flow.
*   **Don't** crowd the interface. If a screen feels busy, increase the vertical spacing between containers rather than adding lines to organize them.
*   **Don't** use standard "Material" shadows. If it looks like a generic Android app, it has failed the premium requirement.