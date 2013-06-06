#lang pyret

import db as db

conn = db.sqlite.connect("test.db")
eq = checkers.check-equals
pred = checkers.check-pred

fun obj_eq(obj1, obj2):
  doc "Check if two objects have all the same keys with obj_eq fields"
  fun all_same(obj1, obj2):
    left_keys = builtins.keys(obj1)
    try:
      case:
        | builtins.has-field(obj1, "equals") => obj1 == obj2
        | Method(obj1).or(Function(obj2)) => false
        | else =>
          for list.fold(same from true, key from left_keys):
            case:
              | builtins.has-field(obj2, key).not() => false
              | else =>
                left_val = obj1.[key]
                right_val = obj2.[key]
                same.and(obj_eq(left_val, right_val))
            end
          end
      end
    except(_):
      false
    end
  end
  all_same(obj1, obj2).and(all_same(obj2, obj1))
check
  eq(obj_eq({}, {}), true)
  eq(obj_eq({x : 5}, {y : 6}), false)
  eq(obj_eq({x : 5}, {x : 6}), false)
  eq(obj_eq({x : 5}, {x : 5}), true)
  eq(obj_eq({x : 5, y : 6}, {y : 6, x : 5}), true)
  eq(obj_eq({x : {z: "foo"}, y : 6}, {y : 6, x : {z: "foo"}}), true)
  eq(obj_eq({x : {z: "foo"}, y : [true, 6]}, {y : [true, 6], x : {z: "foo"}}), true)
  eq(obj_eq(fun: end, fun: end), false)
  # TODO(joe & dbp): this should probably return true some day, with list helping
  # us out a little bit
  eq(obj_eq([{}], [{}]), false)
end

fun get_persistable(obj):
  init = { values_strs: [], values : [] }
  keys = builtins.keys(obj).sort()
  for list.fold(acc from init, field from keys):
    val = obj.[field]
    values_strs = acc.values_strs
    values = acc.values
    case:
      | Method(val).or(Function(val)) => acc # skip methods and functions
      | Number(val).or(String(val)).or(Bool(val)) =>
        acc.{ values_strs : values_strs.push(field),
              values : values.push(val) }
      | list.List(val) => raise("Lists not supported in persist " + tostring(val))
      | builtins.has-field(val, "id") =>
        acc.{ values_strs : values_strs.push(field),
              values : values.push(val.id) }
      | else =>
        raise("No id field on non-primitive, non-code value: " + tostring(val))
    end
  end
check
  fun check_result(initial, expected_result):
    pred(get_persistable(initial),
         fun(persistable):
           doc "Check that the result is persistable"
           obj_eq(persistable, expected_result)
         end)
  end

  check_result({}, { values_strs: [], values: [] })
  check_result({id : 5}, { values_strs: ['id'], values: [5] })
  check_result({o: {id : 5}}, { values_strs: ['o'], values: [5] })

  data TestData:
    | tester(x :: Number) with meth(self): nothing end
    | tester2(name :: String, field :: is-tester3) with meth(self): nothing end
    | tester3(id :: Number) with meth(self): nothing end
  end

  check_result(tester(5), { values_strs: ['x'], values: [5] })
  check_result(tester2("bob", tester3(42)),
               { values_strs: ['name', 'field'], values: ['bob', 42] })

end

fun mk_persist(table_name :: String):
  method(self):
  end
check
  
end

data Encounter:
  | replEncounter(
      id :: Number,
      instructions :: String,
      initialCode :: String,
      reviewable :: Bool
    ) with
    persist: mk_persist("replEncounter")
  | designRecipeEncounter(
      id :: Number,
      instructions :: String,
      data_definition :: is-replEncounter,
      examples :: is-replEncounter,
      template :: is-replEncounter,
      header :: is-replEncounter,
      tests :: is-replEncounter,
      function :: is-replEncounter
    ) with
    persist: mk_persist("designRecipeEncounter")
  | reviewEncounter(
      id :: Number,
      targetEncounter :: Encounter,
      review :: Review
    ) with
    persist: mk_persist("reviewEncounter")
check
  fun check_result(initial, expected_result):
    pred(get_persistable(initial),
         fun(persistable):
           doc "Check that the result is persistable"
           obj_eq(persistable, expected_result)
         end)
  end
  repl1 = replEncounter(0, "instruct", "code", true)
  check_result(repl1,
    { values_strs: ['reviewable', 'instructions', 'initialCode', 'id'],
      values: [true, 'instruct', 'code', 0] })
end

data Review: | review end

data UserEncounter:
  | userReplEncounter(
      id :: Number,
      code :: String,
      review, # Review U nothing
      encounter :: is-replEncounter
    )
  | userDesignRecipeEncounter(
      id :: Number,
      current_stage :: is-replEncounter, # Should be in the encounters
      data_definition, # is-replEncounter U nothing
      examples,
      template,
      header,
      tests,
      function
    )
end

