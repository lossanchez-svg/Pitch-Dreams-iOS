# Design System Document

## 1. Overview & Creative North Star: "The Kinetic Stadium"
This design system is built to transform a standard training utility into a high-octane, gaming-inspired digital arena. Our Creative North Star is **"The Kinetic Stadium"**—a philosophy that treats the mobile interface as a live scoreboard, emphasizing momentum, high-contrast energy, and tactile depth. 

We break the "template" look by eschewing traditional iOS lists in favor of intentional asymmetry. By utilizing extreme typography scales—pairing massive monospaced digits with tight, tracked-out labels—we create an editorial experience that feels premium and authoritative. The UI should never feel static; it should feel like it is "leaning forward," ready for action.

## 2. Colors & Surface Architecture
The palette is rooted in deep nocturnal blues to allow our high-energy accents to "glow" with neon-like intensity.

### The Palette
*   **Background:** `#0C1322` (The foundation of the stadium)
*   **Surface:** `#191F2F` (Primary container color)
*   **Primary Accent:** `#FF6B2C` (The "Pitch Orange" for action and energy)
*   **Secondary:** `#46E5F8` (Cyan for data and secondary interactions)
*   **Tertiary:** `#FFE9BD` (Gold for achievements and "Rookie Wolf" progression)

### The "No-Line" Rule
Traditional 1px solid borders are strictly prohibited for sectioning content. To define boundaries, designers must rely exclusively on background color shifts. 
*   **Example:** A `surface_container_low` (`#151B2B`) card should sit on a `surface` (`#0C1322`) background. The edge is defined by the value shift, not a stroke.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers stacked within the handset.
*   **Base:** `surface_dim` or `background`
*   **Level 1 (Sections):** `surface_container`
*   **Level 2 (Cards/Interactive):** `surface_container_high`
*   **Level 3 (Pop-outs/Modals):** `surface_container_highest`
Each "step" up in hierarchy must correspond to a step up in the `surface_container` token scale.

### Signature Textures
While translucent blurs are forbidden per our style constraints, we achieve "soul" through the **CTA Gradient**: A transition from `#FFE6DE` to `#FFD4C8`. This "Peach-to-Orange" glow should be reserved for the most critical user paths, providing a professional polish that flat color cannot replicate.

## 3. Typography: The Scoreboard Aesthetic
Typography is our primary tool for hierarchy. We use **SF Rounded** to maintain a "Youth" feel while leaning into **Heavy/Bold** weights to ensure a "Pro" gaming aesthetic.

*   **Display (48-64pt Heavy):** Used for scores, timers, and progress percentages. Use **monospaced digits** to ensure numerical data feels like a stadium Jumbotron.
*   **Headings (18-24pt Heavy):** Forceful and direct. Use for screen titles and major card headings.
*   **Labels (9-11pt Bold):** Must be **UPPERCASE** with **2-3pt letter-spacing**. This "editorial" treatment provides a high-end feel for metadata and categories.
*   **Body (14pt Medium):** Optimized for legibility during active training sessions.

## 4. Elevation & Depth
In the absence of translucent blurs, depth is achieved through **Tonal Layering** and the **"Ghost Border."**

*   **The Layering Principle:** Stacking higher-value surfaces on lower-value surfaces. To create a "lifted" effect, place a `surface_container_high` element over a `surface_container_low` background. 
*   **Ambient Shadows:** For floating action buttons or extreme priority items, use extra-diffused shadows (30-40px blur) at 8% opacity. The shadow color should be a tinted version of the background (`#070E1D`), never pure black.
*   **The Ghost Border:** For accessibility on interactive cards, use a **1px Ghost Border** (White at 5% opacity). This provides a subtle "gleam" on the edge of the 16pt/24pt rounded corners without creating a hard structural line.

## 5. Components

### Buttons & CTAs
*   **Primary CTA:** 56pt tall Capsule (fully rounded). Uses the Orange/Peach gradient with `on_primary` (Dark Slate) text.
*   **Secondary Action:** Ghost style. 56pt tall Capsule with the 1px Ghost Border and `secondary` (Cyan) text.

### Cards & Hero Surfaces
*   **Standard Cards:** 16pt corner radius. Use `surface_container`.
*   **Hero/Featured Surfaces:** 24pt corner radius. Use `surface_container_high`.
*   **Rule:** Never use divider lines inside cards. Use vertical whitespace (16pt/24pt/32pt increments) to separate content blocks.

### The "Rookie Wolf" Avatar
The avatar should always be housed in a circular frame with a `tertiary` (Gold) 2px Ghost Border when the user has achieved "Legendary" status, or a `secondary` (Cyan) border for "Pro" status.

### Progress Gauges
Utilize the monospaced Display typography for percentages, paired with thick, 8pt stroke-width progress rings using the `primary` accent.

## 6. Do's and Don'ts

### Do:
*   **Use Asymmetry:** Place the "Rookie Wolf" avatar slightly off-center or overlapping a card edge to create a dynamic, gaming feel.
*   **Embrace the Dark:** Ensure the background remains `#0C1322`. There is no light mode.
*   **Respect the Spacing:** Use generous padding (24pt-32pt) around hero elements to give the heavy typography room to breathe.

### Don't:
*   **No Blurs:** Do not use `backdrop-blur` or any translucent effects. Depth must be solid and tonal.
*   **No Default Blue:** Never use the standard iOS "System Blue." Use `secondary` (#46E5F8) instead.
*   **No Sharp Corners:** Every container must have at least a 16pt radius.
*   **No Standard Case:** Avoid sentence case for labels; stick to the tracked-out uppercase standard defined in the typography section.