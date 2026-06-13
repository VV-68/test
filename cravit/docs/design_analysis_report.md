# Tinder for Food (Cravit) - Figma Design Analysis Report

This document provides a detailed analysis of the **Cravit (Tinder for Food)** app screens identified from the Figma design. For each screen, we outline the purpose, UI/UX structure, and recommended Flutter implementation strategies, along with proposed premium enhancements.

---

## 1. Splash Screen

### Analysis
*   **Purpose**: The entryway to the app. Displays the Cravit branding and builds excitement while initial assets are loading.
*   **Key Components**: Animated logo incorporating colorful food emojis (e.g., 🍕, 🍔, 🍣, 🌮).
*   **Aesthetic & Animation**: A soft, premium dark or gradient background. The food emojis can float around the central logo or scale up sequentially with smooth ease-in-out animations.

### Technical & UX Considerations
*   **Flutter Implementation**: Use a custom `StatefulWidget` with `AnimationController` to animate the logo scaling and floating icons. Use `ScaleTransition` and `FadeTransition`.
*   **Enhancements**: A subtle shimmering effect or a particle system of food emojis gently falling in the background. Ensure this screen transitions seamlessly into the **Auth Screen** using a slide-up or fade-out transition.

---

## 2. Auth Screen

### Analysis
*   **Purpose**: Account registration and login.
*   **Key Components**: 
    *   Sleek branding header.
    *   Social Sign-in Buttons: "Continue with Google", "Continue with Apple", and "Phone OTP".
*   **Visual Design**: A glassmorphic design language for the login cards overlying a smooth gradient background. Clean, rounded buttons with official brand logos.

### Technical & UX Considerations
*   **Flutter Implementation**: Use standard authentication buttons (e.g., standard Google/Apple sign-in buttons styling). Integrate a clean phone number input field with OTP auto-focus.
*   **Enhancements**: 
    *   Haptic feedback on tapping sign-in buttons.
    *   A brief loading overlay that uses a spinner decorated with food emojis.

---

## 3. Home Screen

### Analysis
*   **Purpose**: The central command deck of Cravit. Users can create a new collaborative session, join an existing one, or view their statistics.
*   **Key Components**:
    *   "Create Room" prominent button (with active glowing border).
    *   "Join Room" card containing a 5-digit room code text input and an action button.
    *   "Squad Stats" quick widget (historical details of swiping sessions).
*   **Layout**: Balanced vertical stack with clean padding, cards using shadows/glows, and clear visual hierarchy.

### Technical & UX Considerations
*   **Flutter Implementation**: Use a custom 5-digit SMS-style code input package (e.g., `pin_code_fields`) or a custom row of five `TextField`s with automatically shifting focus.
*   **Enhancements**:
    *   Include a real-time count or animated tickers for historical swipe statistics.
    *   Add a subtle neon-glow or gradient border animation around the "Create Room" button to encourage users to click it.

---

## 4. Filters Screen

### Analysis
*   **Purpose**: Customize preferences for the food matchmaking session (location, budget, diet, etc.).
*   **Key Components**:
    *   **Distance Radius Slider**: Smooth slider showing current selection in kilometers/miles.
    *   **Budget Picker**: Selectable dollar-sign items ($, $$, $$$, $$$$) with high contrast.
    *   **Dietary Tags**: Toggleable chips (e.g., Vegan, Vegetarian, Gluten-Free, Halal).
    *   **Session Timer Config**: Time limit for swiping (e.g., 5 min, 10 min).

### Technical & UX Considerations
*   **Flutter Implementation**: Use `Slider` or `RangeSlider` with custom `SliderThemeData`. Use `FilterChip` or custom wrapped toggles with springy scale-up animations on selection.
*   **Enhancements**:
    *   As the slider moves, show a mini map indicator or distance badge that dynamically bounces.
    *   Add rich color transitions to chips when selected (e.g., gray background transitioning to a gradient orange/pink Cravit color).

---

## 5. Lobby Screen

### Analysis
*   **Purpose**: The waiting room where players queue before starting the multiplayer swipe session.
*   **Key Components**:
    *   Large, copyable 5-digit room code with a "Copy Link" shortcut.
    *   Visual indicators of connected players (avatars showing active, waiting, or ready states).
    *   A developer simulator tool: "Partner Join" simulator button (very useful for prototyping).

### Technical & UX Considerations
*   **Flutter Implementation**: Use a responsive grid or horizontal list for player avatar cards. Integrate WebSockets (`socket_io_client` or similar) to handle dynamic participant join/leave events in real-time.
*   **Enhancements**:
    *   Add a "Ready" pulse animation around user avatars.
    *   Interactive elements (like sending mini-emojis/reactions to the lobby) to keep users engaged while waiting.

---

## 6. Stage 1 Swipe Screen (Cuisines)

### Analysis
*   **Purpose**: Collaborative broad filtering. Players swipe on overall categories (e.g., Burgers, Sushi, Italian, Chinese) to agree on a cuisine genre.
*   **Key Components**:
    *   Cuisine Card deck with vibrant dish images.
    *   "LIKE" (green/right) and "NOPE" (red/left) visual overlay stamps appearing dynamically as cards are dragged.
    *   Progress bars showing both player 1 and player 2 swipe progress.
    *   Utility controls: "Super Like" (star) and "Veto" (block) buttons.

### Technical & UX Considerations
*   **Flutter Implementation**: Use a robust swiper package (e.g., `flutter_card_swiper` or `swipeable_card_stack`). Connect swipe events to the WebSocket server to sync progress and count common likes.
*   **Enhancements**:
    *   Smooth card physics with springy rotations on release.
    *   Parallax scrolling effect on card background images.
    *   A high-energy overlay effect when a match is imminent.

---

## 7. Match Transition Screen

### Analysis
*   **Purpose**: A full-screen celebration screen triggered immediately when both users swipe right on a cuisine.
*   **Key Components**:
    *   "It's a Match!" text in bold typography.
    *   A split-screen or side-by-side display of the matched cuisine (e.g., Pizza).
    *   Confetti/sparkle animations.

### Technical & UX Considerations
*   **Flutter Implementation**: Use a canvas-based confetti overlay (e.g., `confetti` package). Perform a smooth, custom page route transition (e.g., Scale or Fade transition) into this screen and automatically route to the next stage after 2-3 seconds.
*   **Enhancements**:
    *   Play a pleasant chime/haptic double-vibe on match.
    *   Animate the matching item spinning or sliding in from opposite sides of the screen.

---

## 8. Stage 2 Swipe Screen (Restaurants)

### Analysis
*   **Purpose**: Collaborative restaurant selection. Swiping on specific local restaurants belonging to the matched cuisine.
*   **Key Components**:
    *   Rich cards showing specific restaurants.
    *   Crucial metadata display: Google/Yelp Rating (⭐), distance, average delivery time, price tier, and active "Open/Closed" badge.
    *   Detailed expand drawer showing menu items/reviews.

### Technical & UX Considerations
*   **Flutter Implementation**: Similar swipe card stack, but with a more detailed card layout. Implement a slide-up panel or bottom sheet (e.g., `sliding_up_panel`) to reveal additional restaurant details when tapped.
*   **Enhancements**:
    *   Vibrant, high-resolution food carousel inside each card.
    *   Tag badges (e.g., "Fastest Delivery", "Local Favorite") designed with glowing gradient borders.

---

## 9. Final Match Screen

### Analysis
*   **Purpose**: The crowning page showing the final selected restaurant. Gives options to proceed with booking or order.
*   **Key Components**:
    *   Hero image of the restaurant.
    *   Delivery App Buttons: Integrated deep-links for "Swiggy" and "Zomato" (or global alternatives like UberEats/DoorDash).
    *   "Who Pays?" action button to initiate the payment mini-game.

### Technical & UX Considerations
*   **Flutter Implementation**: Use standard URL launchers (`url_launcher`) to fire off deep links directly to Swiggy/Zomato.
*   **Enhancements**:
    *   Map widget displaying the route from the user's location to the restaurant.
    *   Share option to quickly export details to messaging apps.

---

## 10. Roulette Wheel Screen

### Analysis
*   **Purpose**: Tie-breaker mechanism. When swiping time runs out and players have disagreed or have multiple tied likes, this page spins a custom wheel to make a decision.
*   **Key Components**:
    *   Vibrant, segmented SVG spinning wheel with options.
    *   "Spin" CTA button.
    *   Indicator pointer.

### Technical & UX Considerations
*   **Flutter Implementation**: Use a custom painter or a wheel package (e.g., `flutter_fortune_wheel`) to build a high-performance interactive roulette spinner.
*   **Enhancements**:
    *   Allow users to drag-to-spin or click to trigger.
    *   Include a realistic clicking sound effect (audio track or haptic ticks) as each segment passes the needle pointer.

---

## 11. No Match Screen

### Analysis
*   **Purpose**: The fallback page when users finish swiping with absolutely zero common likes.
*   **Key Components**:
    *   "Merge & Spin" (combines top liked options into a wheel).
    *   "The Dictator" (performs a coin flip to delegate the decision to one user).
    *   "AI Compromise" (suggests a compromise restaurant nearby based on user profiles).

### Technical & UX Considerations
*   **Flutter Implementation**: Simple navigation grid leading to mini-screens (coin flip animation, roulette, or AI suggestion display).
*   **Enhancements**:
    *   Friendly, playful illustrations or food animations looking sad.
    *   A glowing, modern UI for these secondary features so they feel like fun mini-games rather than errors.

---

## 12. Who Pays Screen

### Analysis
*   **Purpose**: A fun payment mini-game to decide who picks up the bill.
*   **Key Components**:
    *   Two-player segmented roulette or slot spinner.
    *   "Whose wallet is lighter today?" or other humorous prompts.

### Technical & UX Considerations
*   **Flutter Implementation**: Similar roulette/slot animation component. Set results randomly or based on a pre-defined seed from the WebSocket lobby.
*   **Enhancements**:
    *   Playful animation showing a credit card flying into a wallet or a cash explosion.
    *   Sound effects and confetti upon landing on the "Winner (or Loser)".

---

## 13. Squads Screen

### Analysis
*   **Purpose**: Manage groups (friends, family, coworkers) and review historical swiping stats.
*   **Key Components**:
    *   Squads list: displays created groups with member avatars and names.
    *   "Food Wrapped" statistics card (similar to Spotify Wrapped, showing most swiped cuisines, favorite times of day, matching success rates).

### Technical & UX Considerations
*   **Flutter Implementation**: Use lists and grids with card layouts. Create custom interactive charts (e.g., using `fl_chart`) to build the "Food Wrapped" visual statistics dashboard.
*   **Enhancements**:
    *   Polished horizontal sliding transitions to navigate between squads.
    *   A beautiful, shareable "Food Wrapped" infographic page with gradient themes.

---

## Summary of Design & Theme System Recommendations

To make the app look and feel premium:
*   **Theme**: Dark Mode by default. Rich gradients of Coral/Orange (`#FF6B4A`) and Deep Rose (`#FF4B72`) representing heat/food/tinder, contrast against a deep obsidian background (`#121214`).
*   **Typography**: Clean sans-serif like **Outfit** or **Plus Jakarta Sans** for headings, and **Inter** for descriptions/metadata.
*   **Micro-interactions**: Scale/bounce animations on card clicks, drag physics, and smooth transition animations between screens to keep the experience seamless.
