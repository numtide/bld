{ values, ... }:
{
  isEqual = a: b:
    if a != b then throw "expected ${a} == ${b}" else true;

  isTrue = cond:
    if !cond then throw "expected true, got ${cond}" else true;

  isType = type: val:
    let
      t = values.type val;
    in
    if t != type then
      throw "expected type to be ${type}, not ${t}"
    else true;
}
