function ct_ajax(url, params) {
    if (!params.hasOwnProperty("failure")) {
        params.failure = function (error) {
            console.error(error);
        }
    }
    $.ajax(url, params);
}

function worldB(init, handlers, transformers) 
/*: ∀ α . α
        * Array<∃ β . {0: EventStream<β>, 1: α * β -> α}>
        * ∃ (γ₁ ...) { key₁: α -> γ₁, ... }
        -> { key₁: EventStream<γ₁>, ... }
        */
{
  var theWorld = mergeE.apply(zeroE,
    handlers.map(function(handler)
    /*: ∃ β . {0: EventStream<β>, 1: α * β -> α} -> EventStream<α -> α> */
    {
      return handler[0].mapE(function(eventValue) /*: β -> (α -> α) */ {
        return function(world) /*: α -> α */ {
          return handler[1](world, eventValue);
        };
      });
    }))
   .collectE(init, function(handler, world) /*: (α -> α) * α -> α */ {
      return handler(world);
    })
   .startsWith(init);

  var facets = {};
  Object.keys(transformers).forEach(function(key) {
    if (typeof transformers[key] === 'function') {
      facets[key] = theWorld.liftB(transformers[key]);
    } else {
      facets[key] = transformers[key];
    }
  });
  return facets;
}
