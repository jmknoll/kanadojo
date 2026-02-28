# Styling & Typography Rationalization Plan

## Current State Analysis

### Problems Identified

1. **Inconsistent Font Sizes**: 15+ different font sizes used (10, 14, 16, 18, 20, 24, 28, 32, 48, 64, 72, 80, 120)
2. **Missing Line Heights**: Many text styles lack `lineHeight`, causing Japanese character clipping
3. **No Typography Scale**: Font sizes chosen arbitrarily per component
4. **Scattered Styles**: Each component defines its own text styles
5. **Japanese Text Not Handled**: No dedicated system for displaying kana characters
6. **Inconsistent Spacing**: Margins and paddings vary without a system
7. **Limited ThemedText**: Only 5 variants, doesn't cover app needs

### Files with Typography Issues

| File | Font Sizes Used |
|------|-----------------|
| `themed-text.tsx` | 16, 20, 32 |
| `kana-type-card.tsx` | 18, 20, 32 |
| `quiz-card.tsx` | 80, 120 (dynamic) |
| `feedback-overlay.tsx` | 14, 16, 18, 32, 48, 64 |
| `quiz-summary.tsx` | 14, 16, 18, 28, 32, 48, 64 |
| `group-card.tsx` | 14, 18 |
| `quiz-type-card.tsx` | 10, 14, 18 |
| `answer-input.tsx` | 18, 24 |
| `progress-bar.tsx` | 14 |
| Screen files | Various |

---

## Proposed Solution

### 1. Create Typography Scale

Define a consistent type scale in `constants/typography.ts`:

```typescript
// Font size scale (based on 4px increments)
export const FontSizes = {
  xs: 12,      // Captions, badges
  sm: 14,      // Secondary text, hints
  md: 16,      // Body text (default)
  lg: 18,      // Emphasized body
  xl: 20,      // Small headings
  '2xl': 24,   // Section headings
  '3xl': 28,   // Screen titles
  '4xl': 32,   // Large titles
  '5xl': 48,   // Hero text
  '6xl': 64,   // Display (kana quiz)
  '7xl': 80,   // Large kana (combinations)
  '8xl': 120,  // Huge kana (single chars)
} as const;

// Line height multipliers
export const LineHeights = {
  tight: 1.1,    // Large display text
  normal: 1.4,   // Body text
  relaxed: 1.6,  // Readable paragraphs
  kana: 1.25,    // Japanese characters (prevents clipping)
} as const;

// Font weights
export const FontWeights = {
  normal: '400',
  medium: '500',
  semibold: '600',
  bold: '700',
} as const;
```

### 2. Create Text Style Presets

Define reusable text styles in `constants/typography.ts`:

```typescript
export const TextStyles = StyleSheet.create({
  // Body text
  body: {
    fontSize: FontSizes.md,
    lineHeight: FontSizes.md * LineHeights.normal,
    fontWeight: FontWeights.normal,
  },
  bodySmall: {
    fontSize: FontSizes.sm,
    lineHeight: FontSizes.sm * LineHeights.normal,
    fontWeight: FontWeights.normal,
  },
  bodySemibold: {
    fontSize: FontSizes.md,
    lineHeight: FontSizes.md * LineHeights.normal,
    fontWeight: FontWeights.semibold,
  },

  // Headings
  heading1: {
    fontSize: FontSizes['4xl'],
    lineHeight: FontSizes['4xl'] * LineHeights.tight,
    fontWeight: FontWeights.bold,
  },
  heading2: {
    fontSize: FontSizes['3xl'],
    lineHeight: FontSizes['3xl'] * LineHeights.tight,
    fontWeight: FontWeights.bold,
  },
  heading3: {
    fontSize: FontSizes['2xl'],
    lineHeight: FontSizes['2xl'] * LineHeights.tight,
    fontWeight: FontWeights.semibold,
  },

  // Kana display (with proper line height for Japanese)
  kanaHuge: {
    fontSize: FontSizes['8xl'],
    lineHeight: FontSizes['8xl'] * LineHeights.kana,
    fontWeight: FontWeights.normal,
  },
  kanaLarge: {
    fontSize: FontSizes['7xl'],
    lineHeight: FontSizes['7xl'] * LineHeights.kana,
    fontWeight: FontWeights.normal,
  },
  kanaMedium: {
    fontSize: FontSizes['6xl'],
    lineHeight: FontSizes['6xl'] * LineHeights.kana,
    fontWeight: FontWeights.normal,
  },
  kanaSmall: {
    fontSize: FontSizes['4xl'],
    lineHeight: FontSizes['4xl'] * LineHeights.kana,
    fontWeight: FontWeights.normal,
  },
  kanaInline: {
    fontSize: FontSizes.xl,
    lineHeight: FontSizes.xl * LineHeights.kana,
    fontWeight: FontWeights.normal,
  },

  // UI elements
  button: {
    fontSize: FontSizes.md,
    lineHeight: FontSizes.md * LineHeights.normal,
    fontWeight: FontWeights.semibold,
  },
  buttonLarge: {
    fontSize: FontSizes.lg,
    lineHeight: FontSizes.lg * LineHeights.normal,
    fontWeight: FontWeights.semibold,
  },
  caption: {
    fontSize: FontSizes.xs,
    lineHeight: FontSizes.xs * LineHeights.normal,
    fontWeight: FontWeights.normal,
  },
  label: {
    fontSize: FontSizes.sm,
    lineHeight: FontSizes.sm * LineHeights.normal,
    fontWeight: FontWeights.medium,
  },
  hint: {
    fontSize: FontSizes.sm,
    lineHeight: FontSizes.sm * LineHeights.normal,
    fontWeight: FontWeights.normal,
    opacity: 0.6,
  },
});
```

### 3. Expand ThemedText Component

Update `ThemedText` to support all the new variants:

```typescript
export type TextVariant =
  | 'body' | 'bodySmall' | 'bodySemibold'
  | 'heading1' | 'heading2' | 'heading3'
  | 'kanaHuge' | 'kanaLarge' | 'kanaMedium' | 'kanaSmall' | 'kanaInline'
  | 'button' | 'buttonLarge'
  | 'caption' | 'label' | 'hint';

export function ThemedText({
  variant = 'body',
  style,
  ...props
}: ThemedTextProps) {
  const color = useThemeColor({}, 'text');
  return (
    <Text style={[{ color }, TextStyles[variant], style]} {...props} />
  );
}
```

### 4. Create Spacing Scale

Add to `constants/theme.ts`:

```typescript
export const Spacing = {
  xs: 4,
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
  '2xl': 24,
  '3xl': 32,
  '4xl': 48,
} as const;

export const BorderRadius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 24,
  full: 9999,
} as const;
```

### 5. Create KanaText Component

Specialized component for Japanese characters:

```typescript
// components/kana-text.tsx
interface KanaTextProps {
  children: string;
  size?: 'sm' | 'md' | 'lg' | 'xl' | 'huge';
  color?: string;
  style?: TextStyle;
}

export function KanaText({ children, size = 'lg', color, style }: KanaTextProps) {
  const textColor = useThemeColor({}, 'text');
  const variant = {
    sm: 'kanaInline',
    md: 'kanaSmall',
    lg: 'kanaMedium',
    xl: 'kanaLarge',
    huge: 'kanaHuge',
  }[size];

  return (
    <Text style={[TextStyles[variant], { color: color ?? textColor }, style]}>
      {children}
    </Text>
  );
}
```

---

## Implementation Steps

### Step 1: Create Typography Constants
- Create `constants/typography.ts` with FontSizes, LineHeights, FontWeights
- Add TextStyles preset object
- Export everything

### Step 2: Update Theme Constants
- Add Spacing scale to `constants/theme.ts`
- Add BorderRadius scale
- Keep Colors as-is

### Step 3: Update ThemedText Component
- Add all new variants
- Import TextStyles from typography
- Maintain backwards compatibility with old `type` prop

### Step 4: Create KanaText Component
- New component specifically for Japanese characters
- Auto-calculates proper line height
- Simple size API (sm, md, lg, xl, huge)

### Step 5: Refactor Components (one by one)
Priority order:
1. `quiz-card.tsx` - Most visible kana display
2. `feedback-overlay.tsx` - User sees after every answer
3. `kana-type-card.tsx` - Home screen
4. `quiz-summary.tsx` - Results screen
5. `group-card.tsx` - Selection screens
6. `quiz-type-card.tsx` - Selection screens
7. `answer-input.tsx` - Quiz input
8. `progress-bar.tsx` - Quiz progress
9. Screen files - Various screens

### Step 6: Update Screen Files
- Replace inline fontSize/lineHeight with TextStyles or ThemedText variants
- Use Spacing constants for margins/paddings

---

## Files to Create

```
constants/
├── theme.ts          # Update: add Spacing, BorderRadius
└── typography.ts     # Create: FontSizes, LineHeights, TextStyles

components/
├── themed-text.tsx   # Update: add new variants
└── kana-text.tsx     # Create: specialized kana component
```

## Files to Update

```
components/
├── cards/
│   ├── kana-type-card.tsx
│   ├── group-card.tsx
│   └── quiz-type-card.tsx
├── quiz/
│   ├── quiz-card.tsx
│   ├── answer-input.tsx
│   ├── feedback-overlay.tsx
│   ├── progress-bar.tsx
│   └── quiz-summary.tsx

app/
├── (tabs)/
│   ├── index.tsx
│   └── study.tsx
└── quiz/
    ├── [type]/index.tsx
    └── [type]/[group]/index.tsx
```

---

## Verification Checklist

- [ ] All Japanese characters display without clipping
- [ ] Consistent font sizes across similar UI elements
- [ ] No hardcoded fontSize values (use scale)
- [ ] All text has appropriate lineHeight
- [ ] Spacing is consistent (uses scale)
- [ ] ThemedText variants cover all use cases
- [ ] KanaText works for all kana sizes
- [ ] Dark mode still works correctly
