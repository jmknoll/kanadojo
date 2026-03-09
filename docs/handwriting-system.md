The following document outlines an approach to character recognition grading for character production quizzes

## input layer

touch input of type B quizzes (character production)

## Reference Data

You need a canonical "correct" version of each character to compare against:

1. Reference strokes stored per character — ideally captured from expert writers, not synthesized
2. Store as normalized stroke sequences (scale/position-independent)
3. For kana/kanji: stroke order conventions matter (standard JIS stroke order)
4. There are a few characters which have multiple valid stylistic forms (sa, ri, ki). We should find and use a font which uses the modern version of these characters (typically the disconnected version)

## Similarity Computation

This is the core engine. Several techniques, often combined:
Per-stroke shape similarity:

DTW (Dynamic Time Warping) — the standard for comparing two point sequences of potentially different lengths/speeds. Gives a distance score per stroke.
Fréchet Distance — similar to DTW, measures how "close" two curves are
Procrustes Analysis — align two shapes optimally, measure residual difference

Stroke order & correspondence:

Match user strokes to reference strokes (Hungarian algorithm or greedy nearest-match)
Penalize out-of-order strokes

Global shape comparison (optional secondary signal):

Render both to a small raster (e.g., 64×64) and compare with pixel diff or structural similarity (SSIM)
Or embed both with a small CNN and compare embeddings

## metrics

1. Shape score — how closely does each stroke's path match the reference
2. Proportion score — relative lengths and angles between strokes
3. Stroke order score — penalty for wrong order
4. Consistency score — if practicing repeatedly, variance across attempts
5. Speed/fluency (optional) — hesitation, backtracking, uneven tempo

Overall grade in-quiz will be a weighted average of these values. A grade above a certain threshold will be passing, and below the average will not be passing. The averages will be stored to the spaced-repetition mastery system, so that characters with lower scores appear earlier and more often, rather than relying on the binary classificion like type A quizzes.

Type A quizzes can also be graded on a weighted average of consistency and fluency (e.g. erasing characters, hesitating, waiting before starting), but correctness is the majority of the weight. The spaced-mastery system should be updating accordingly for that as well.

## updates to stats page

a number of updates will be made to the stats page. they are as follows:

1. Top-level breakout of hiragana vs katakana. they are currently jumbled together.
2. A user should be able to see all characters within each rank (new, learning, reviewing, mastered)
3. When a user clicks into a character, they should an evolved version of the per-user stats page which will display a spiderweb chart of the metrics listed above (shape, proportion, stroke order, consistency, fluency)
