#import "state.typ": num-state, group-state, round-state
#import "formatting.typ": *
#import "rounding.typ": *
#import "assertations.typ": *
#import "parsing.typ"

#let update-state(state, args, name: none) = {
  state.update(s => {
    assert-settable-args(args, s, name: name)
    s + args.named()
  })
}


#let set-num(..args) = update-state(num-state, args, name: "set-num")
#let set-group(..args) = update-state(group-state, args, name: "set-group")
#let set-round(..args) = update-state(round-state, args, name: "set-round")


#let contextual-round(int, frac, pm, round-state) = {
  round(
    int, frac, 
    mode: round-state.mode,
    precision: round-state.precision,
    direction: round-state.direction,
    pad: round-state.pad,
    pm: pm
  )
}



#let show-num = it => {
  
  // Process input
  let info
  if type(it.number) == dictionary {
    info = it.number
    if "mantissa" in info {
      let mantissa = info.mantissa 
      if type(mantissa) in (int, float) { mantissa = str(mantissa).replace(sym.minus, "-") }
      let (sign, int, frac) = parsing.decompose-signed-float-string(mantissa)
      info += (sign: sign, int: int, frac: frac)
    }
    if "sign" not in info {info.sign = "" }
  } else {
    let num-str = number-to-string(it.number)
    if num-str == none {
      assert(false, message: "Cannot parse the number `" + repr(it.number) + "`")
    }
    info = decompose-normalized-number-string(num-str)
  }

  /// Maybe shift exponent
  if it.fixed != none {
    let e = if info.e == none { 0 } else { int(info.e) }
    info.e = str(it.fixed).replace(sym.minus, "-")
    (info.int, info.frac) = utility.shift-decimal-left(info.int, info.frac, it.fixed - e)
  }

  /// Round number and uncertainty
  if it.round.mode != none {
    (info.int, info.frac, info.pm) = contextual-round(info.int, info.frac, info.pm, it.round)
  }
  
  let digits = if it.digits == auto { info.frac.len() } else { it.digits }
  if digits < 0 { assert(false, message: "`digits` needs to be positive, got " + str(digits)) }
  
  if info.pm != none {
    let pm = info.pm
    if type(pm.first()) != array { pm = (pm,) }
    digits = calc.max(digits, ..pm.map(array.last).map(str.len))
  }

  // info.digits = digits
  it.digits = digits

  // Format number
  let components = show-num-impl(info + it)
  let collect = if it.math { make-equation } else { it => it.join() }
  if it.align == none { return collect(components.join()) }

  let (col-widths, col) = it.align
  components = components.map(collect)
  let widths = components.map(x => measure(x).width)
  
  if col-widths != auto {
    for i in range(4) {
      let alignment = if i == 0 { right } else { left }
      let content = align(alignment, components.at(i))
      components.at(i) = box(width: col-widths.at(i), content)
    }
  }

  [#components.join()#metadata((col,) + widths)<__pillar-num__>]
}



#let num(
  number, 
  align: none,
  ..args
) = {
  if type(number) == array {
    let named = args.named()
    let round-state = round-state.get()
    let group-state = group-state.get()
    if "round" in named { round-state += named.round }
    if "group" in named { group-state += named.group }
    let it = num-state.get() + (
      align: align,
      ..args.named()
    )
    it.round = round-state
    it.group = group-state
    return number.map(n => show-num(it + (number: n)))
  }
  context {
    let named = args.named()
    let round-state = round-state.get()
    let group-state = group-state.get()
    if "round" in named { round-state += named.round }
    if "group" in named { group-state += named.group }
    let it = num-state.get() + (
      align: align,
      number: number,
      ..args.named()
    )
    it.round = round-state
    it.group = group-state
    show-num(it)
  }
}









/*

- Mantissa (value or uncertainty): Doesn't really need a show rule?
- Power: A rule would be beneficial. Does the multiplier need to be included? 


Question: How to pass values on to the nested types

#set num.power(base: [5])
and then
#num(power: (base: [4]), "1.23e4")


show num.power: it => {
  - it.exponent [2.3]
  - it.base [10]
  - it.multiplier [×] ??

  math.attach([#it.base], t: [#it.exponent])

  or 

  (
    box(),
    it.multiplier,
    math.attach([#it.base], t: [#it.exponent])
  )
}


show num.exponent: it => {
  - it.sign
  - it.integer
  - it.fractional

  it.sign + format-integer(it.integer) + format-fractional(it.fractional).join()
}


show num.uncertainty: it => {
  - it.value ([0.2, 0.4])
  - it.mode
  - it.symmetric false
  if it.mode == ...
  
  if it.symmetric {
    return (
      math.class("normal", none),
      math.class(if state.tight {"normal"} else {"binary"}, sym.plus.minus),
      it.value
    )
  } else {
    math.attach(none, t: sym.plus + it.value.at(0), b: sym.minus + it.value.at(1)),
  }
}

show num.num: it => {
  
}



*/

