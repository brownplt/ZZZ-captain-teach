#lang scribble/base

@(require ct-scribble/ct-lang)

@assignment["Bubble Sort"]{

  @description{Soopoer easy}
  @instructions{longer desc}

  @function["Bubble Sort"]{
    
    @description{You'll be writing a function that sorts}
    @instructions{Do it}

    @header/given["bubble-sort"]{
      @instructions{
        Here is the header we'll be working with.
      }
      @fun-name["bubble-sort"]
      @argument["lst" "List<Number>"]
      @return["List<Number"]
      @purpose["Return the list of numbers sorted in ascending order"]
    }

    @check-block["bubble-sort"]{
      @instructions{Write some test cases for bubble-sort.  For example, you might write:
        check-equals(bubble-sort([2,1], [1,2]))
      }  
    }

    @definition["bubble-sort"]{
      @instructions{Now fill in the body for bubble-sort}
    }

  }

  @function["Insertion Sort"]{
    
    @description{You'll be writing a function that sorts}
    @instructions{Do it}

    @header/given["insertion-sort"]{
      @instructions{
        Here is the header we'll be working with.
      }
      @fun-name["insertion-sort"]
      @argument["lst" "List<Number>"]
      @return["List<Number"]
      @purpose["Return the list of numbers sorted in ascending order"]
    }

    @check-block["insertion-sort"]{
      @instructions{Write some test cases for insertion-sort.  For example, you might write:
        check-equals(insertion-sort([2,1], [1,2]))
      }  
    }

    @definition["insertion-sort"]{
      @instructions{Now fill in the body for bubble-sort}
    }

  }
}

