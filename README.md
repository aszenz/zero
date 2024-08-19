
# $Z\cdot e^{ro}$


_Advanced scientific number formatting._

[![Typst Package](https://img.shields.io/badge/dynamic/toml?url=https%3A%2F%2Fraw.githubusercontent.com%2FMc-Zen%2Fzero%2Fmain%2Ftypst.toml&query=%24.package.version&prefix=v&logo=typst&label=package&color=239DAD)](https://typst.app/universe/package/zero)
[![Test Status](https://github.com/Mc-Zen/zero/actions/workflows/run_tests.yml/badge.svg)](https://github.com/Mc-Zen/zero/actions/workflows/run_tests.yml)
[![MIT License](https://img.shields.io/badge/license-MIT-blue)](https://github.com/Mc-Zen/zero/blob/main/LICENSE)


- [Introduction](#introduction)
- [Quick Demo](#quick-demo)
- [Documentation](#documentation)
- [Table alignment](#table-alignment)
- [Zero for third-party packages](#zero-for-third-party-packages)

## Introduction

Proper number formatting requires some love for detail to guarantee a readable and clear output. This package provides tools to ensure consistent formatting and to simplify the process of following established publication practices. Key features are
- **standardized** formatting,
- digit [**grouping**](#grouping), e.g., $`299\,792\,458`$ instead of $299792458$,
- **plug-and-play** number [**alignment in tables**](#table-alignment),
- quick scientific notation, e.g., `"2e4"` becomes $2\times10^4$,
- symmetric and asymmetric [**uncertainties**](#specifying-uncertainties),
- [**rounding**](#rounding) in various modes,
- and some specials for package authors.
<!-- - and localization? -->

A number in scientific notation consists of three parts of which the latter two are optional. The first part is the _mantissa_ that may consist of an _integer_ and a _fractional_ part. In many fields of science, values are not known exactly and the corresponding _uncertainty_ is then given along with the mantissa. Lastly, to facilitate reading very large or small numbers, the mantissa may be multiplied with a _power_ of 10 (or another base). 

The anatomy of a formatted number is shown in the following figure.


<p align="center">
  <picture>
    <source media="(prefers-color-scheme: light)" srcset="docs/figures/anatomy.svg">
    <source media="(prefers-color-scheme: dark)" srcset="docs/figures/anatomy-dark.svg">
    <img alt="Anatomy of a formatted number" src="docs/figures/anatomy.svg">
  </picture>
</p>

<!-- For generating formatted numbers, *Zero* provides the `num` type along with the types `coefficient`, `uncertainty`, and `power` that allow for fine-grained customization with `show` and `set` rules.  -->

## Quick Demo

| Code | Output | Code | Output |
|------|--------|------|--------|
| `num("1.2e4")`        | $1.2\times 10^4$          | `num[1.2e4]`           | $1.2\times 10^4$       |
| `num("-5e-4")`        | $-5\times 10^{-4}$        | `num(fixed: -2)[0.02]` | $2\times 10^{-2}$      |
| `num("9.81+-.01")`    | $9.81\pm 0.01$            | `num("9.81+0.02-.01")` | $9.81^{+0.02}_{-0.01}$ |
| `num("9.81+-.01e2")`  | $(9.81\pm0.01)\times 10^2$| `num(base: 2)[3e4]`    | $3\times 2^4$          |




## Documentation

- [Function `num`](#num)
- [Grouping](#grouping)
- [Rounding](#rounding)
- [Uncertainties](#specifying-uncertainties)
- [Table alignment](#table-alignment)

### `num`

The function `num()` is the heart of *Zero*. It provides a wide range of number formatting utilities and its default values are configurable via `set-num()` which takes the same named arguments as `num()`. 

```typ
#let num(
  number:                 str | content | int | float | dictionary | array,
  digits:                 auto | int = auto,
  fixed:                  none | int = none,

  decimal-separator:      str = ".",
  product:                content = sym.times,
  tight:                  boolean = false,
  omit-unity-mantissa:    boolean = true,
  positive-sign:          boolean = false,
  positive-sign-exponent: boolean = false,
  base:                   int | content = 10,
  uncertainty-mode:       str = "separate",
  rounding:               dictionary,
  grouping:               dictionary,
)
```
- `number: str | content | int | float | array` : Number input; `str` is preferred. If the input is `content`, it may only contain text nodes. Numeric types `int` and `float` are supported but not encouraged because of information loss (e.g., the number of trailing "0" digits or the exponent). The remaining types `dictionary` and `array` are intended for advanced use, see [below](#zero-for-third-party-packages).
- `digits: auto | int = auto` : Truncates the number at a given (positive) number of decimal places or pads the number with zeros if necessary. This is independent of [rounding](#rounding).
- `fixed: none | int = none` : If not `none`, forces a fixed exponent. Additional exponents given in the number input are taken into account. 
- `decimal-separator: str = "."` : Specifies the marker that is used for separating integer and decimal part.
- `product: content = sym.times` : Specifies the multiplication symbol used for scientific notation. 
- `tight: boolean = false` : If true, tight spacing is applied between operands (applies to $\times$ and $\pm$). 
- `omit-unity-mantissa: boolean = false` : Determines whether a mantissa of 1 is omitted in scientific notation, e.g., $10^4$ instead of $1\cdot 10^4$. 
- `positive-sign: boolean = false` : If set to `true`, positive coefficients are shown with a $+$ sign. 
- `positive-sign-exponent: boolean = false` : If set to `true`, positive exponents are shown with a $+$ sign. 
- `base: int | content = 10` : The base used for scientific power notation. 
- `uncertainty-mode: str = "separate"` : Selects one of the modes `"separate"`, `"compact"`, or `"compact-separator"` for displaying uncertainties. The different behaviors are shown below:

| `"separate"` |  `"compact"` |  `"compact-separator"` |
|---|---|---|
| $1.7\pm0.2$ | $1.7(2)$  | $1.7(2)$   |
| $6.2\pm2.1$ | $6.2(21)$ | $6.2(2.1)$ |
| $1.7^{+0.2}_{-0.5}$ | $1.7^{+2}_{-5}$ | $1.7^{+2}_{-5}$ |
| $1.7^{+2.0}_{-5.0}$ | $1.7^{+20}_{-50}$ | $1.7^{+2.0}_{-5.0}$ |

- `rounding: dictionary` : You can provide one or more rounding options in a dictionary. Also see [rounding](#rounding). 
- `grouping: dictionary` : You can provide one or more grouping options in a dictionary. Also see [grouping](#grouping). 

Configuration example: 
```typ
#set-num(product: math.dot, tight: true)
```

### Grouping


Digit grouping is important for keeping large figures readable. It is customary to separate thousands with a thin space, a period, comma, or an apostrophe (however, we discourage using a period or a comma to avoid confusion since both are used for decimal separators in various countries). 


<p align="center">
  <picture>
    <source media="(prefers-color-scheme: light)" srcset="docs/figures/grouping.svg">
    <source media="(prefers-color-scheme: dark)" srcset="docs/figures/grouping-dark.svg">
    <img alt="Digit grouping" src="docs/figures/grouping.svg">
  </picture>
</p>


Digit grouping can be configured with the `set-group()` function. 


```typ
#let set-group(
  size:       int = 3, 
  separator:  content = sym.space.thin,
  threshold:  int = 5
)
```
- `size: int = 3` : Determines the size of the groups. 
- `separator: content = sym.space.thin` : Separator between groups. 
- `threshold: int = 5` : Necessary number of digits needed for digit grouping to kick in. Four-digit numbers for example are usually not grouped at all since they can still be read easily. 



Configuration example: 
```typ
#set-group(separator: "'", threshold: 4)
```

Grouping can be turned off altogether by setting the `threshold` to `calc.inf`. 



### Rounding

Rounding can be configured with the `set-round()` function. 

```typ
#let set-round(
  mode:       none | str = none,
  precision:  int = 2,
  pad:        boolean = true,
  direction:  str = "nearest",
)
```
- `mode: none | str = none` : Sets the rounding mode. The possible options are
  - `none` : Rounding is turned off. 
  - `"places"` : The number is rounded to the number of decimal places given by the `precision` parameter. 
  - `"figures"` : The number is rounded to a number of significant figures given by the `precision` parameter.
  - `"uncertainty"` : Requires giving an uncertainty value. The uncertainty is 
     rounded to significant figures according to the `precision` argument and 
    then the number is rounded to the same number of decimal places as the 
    uncertainty. 
- `precision: int = 2` : The precision to round to. Also see parameter `mode`. 
- `pad: boolean = true` : Whether to pad the number with zeros if the 
   number has fewer digits than the rounding precision. 
- `direction: str = "nearest"` : Sets the rounding direction. 
  - `"nearest"`: Rounding takes place in the usual fashion, rounding to the nearer 
    number, e.g., 2.34 → 2.3 and 2.36 → 2.4. 
  - `"down"`: Always rounds down, e.g., 2.38 → 2.3 and 2.30 → 2.3. 
  - `"up"`: Always rounds up, e.g., 2.32 → 2.4 and 2.30 → 2.3. 



### Specifying uncertainties

There are two ways of specifying uncertainties:
- Applying an uncertainty to the least significant digits using parentheses, e.g., `2.3(4)`,
- Denoting an absolute uncertainty, e.g., `2.3+-0.4` becomes $2.3\pm0.4$. 

Zero supports both and can convert between these two, so that you can pick the displayed style (configured via `uncertainty-mode`, see above) independently of the input style. 

How do uncertainties interplay with exponents? The uncertainty needs to come first, and the exponent applies to both the mantissa and the uncertainty, e.g., `num("1.23+-.04e2")` becomes

$$ (1.23\pm0.04)\times 10^2. $$

Note that the mantissa is now put in parentheses to disambiguate the application of the power. 

In some cases, the uncertainty is asymmetric which can be expressed via `num("1.23+0.02-0.01")`

$$ 1.23^{+0.02}_{-0.01}. $$

### Table alignment

In scientific publication, presenting many numbers in a readable fashion can be a difficult discipline. A good starting point is to align numbers in a table at the decimal separator. With _Zero_, this can be accomplished by using `ztable`, a wrapper for the built-in `table` function. It features an additional parameter `format` which takes an array of `none`, `auto`, or `dictionary` values to turn on number alignment for specific columns. 


```typ
#ztable(
  columns: 3,
  align: center,
  format: (none, auto, auto),
  $n$, $α$, $β$,
  [1], [3.45], [-11.1],
  ..
)
```

Non-number entries (e.g., in the header) are automatically recognized in some cases and will not be aligned. In ambiguous cases, adding a leading or trailing space tells _Zero_ not to apply alignment to this cell, e.g., `[Angle ]` instead of `[Angle]`. 


<p align="center">
  <picture>
    <source media="(prefers-color-scheme: light)" srcset="docs/figures/table1.svg">
    <source media="(prefers-color-scheme: dark)" srcset="docs/figures/table1-dark.svg">
    <img alt="Number alignment in tables" src="docs/figures/table1.svg">
  </picture>
</p>

Zero not only aligns numbers at the decimal point but also at the uncertainty and exponent part. Moreover, by passing a `dictionary` instead of `auto`, a set of `num()` arguments to apply to all numbers in a column can be specified. 

```typ
#ztable(
  columns: 4,
  align: center,
  format: (none, auto, auto, (digits: 1)),
  $n$, $α$, $β$, $γ$,
  [1], [3.45e2], [-11.1+-3], [0],
  ..
)
```

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: light)" srcset="docs/figures/table2.svg">
    <source media="(prefers-color-scheme: dark)" srcset="docs/figures/table2-dark.svg">
    <img alt="Advanced number alignment in tables" src="docs/figures/table2.svg">
  </picture>
</p>

## Zero for third-party packages

This package provides some useful extras for third-party packages that generate formatted numbers (for example graphics libraries). 

Instead of passing a `str` to `num()`, it is also possible to pass a dictionary of the form
```typ
(
  mantissa:  str | int | float,
  e:         none | str,
  pm:        none | array
)
```
This way, parsing the number can be avoided which makes especially sense for packages that generate numbers (e.g., tick labels for a diagram axis) with independent mantissa and exponent. 

Furthermore, `num()` also allows `array` arguments for `number` which allows for more efficient batch-processing of numbers with the same setup. In this case, the caller of the function needs to provide `context`. 